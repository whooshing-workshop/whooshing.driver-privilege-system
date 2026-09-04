import Vapor
import Cryptos
import LoggingAdvanced
import NIOFoundationEssentialsCompat
import PrivilegeModuleExtended

/// 用于对用户口令验证
///
/// 当有用户请求发起时，该 Middleware 负责将其凭据及Token 转发与认证模块
/// 若认证模块认证通过，则得到用户的具体信息及其解密的密钥(该密钥目前没有用处)
/// 若认证未通过，则拒绝连接
///
/// 该中间件提供了调试模式
/// 通过将 Strategy 指定为 debuging 以使用白名单验证而非认证服务验证
/// 白名单验证需提供所有允许用户的凭据及Token (Token 为 SymmKey 加密密钥自己加密自己的密文 base64)
public struct ApiValidator: AsyncMiddleware {
    /// 调试模式配置策略
    public enum Strategy: Sendable, CustomStringConvertible, Loggerable {
        /// 远程认证模式，将认证信息发往权限模块以认证
        case remote(authURL: URL)
        /// 本地认证模式，使用本地数据库进行权限认证，仅用于 Privilege System
        case local(transactor: Transactor)
        /// 调试白名单模式：白名单命中模式
        case debuging(whitelist: [WhitelistAuthData])
        
        public var description: String {
            switch self {
            case .remote(authURL: let url): ".normal(authURL: \(url)"
            case .local(transactor: let transactor): ".singleton(transactor: \(transactor))"
            case .debuging(whitelist: let whitelist): ".debuging(whitelist: [\(whitelist.count) Entries])"
            }
        }
    }

    /// 当前功能模块的 Module ID
    let moduleID: UUID
    /// 验证策略
    let strategy: Strategy
    
    package init(moduleID: UUID, strategy: Strategy) {
        self.moduleID = moduleID
        self.strategy = strategy
    }

    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        try await run(to: request, chainingTo: next)
    }
    
    public func run(to request: Request, chainingTo next: AsyncResponder) async throws(NexusErrcase.ErrType) -> Response {
        guard let credential = request.headers.first(name: "X-Credential"), !credential.isEmpty else {
            throw NexusErrcase.apiValidateFailed.d("未找到 'X-Credential' 请求头", category: .external(suggestions: ["请提供用户登陆身份"], userdata: .init(HTTPResponseStatus.unauthorized)))
        }
        
        guard let tokenEncrypted = request.headers.first(name: "X-Encrypted-Token"), !tokenEncrypted.isEmpty else {
            throw NexusErrcase.apiValidateFailed.d("未找到 'X-Encrypted-Token' 请求头", category: .external(suggestions: ["请提供用户的加密 Token"], userdata: .init(HTTPResponseStatus.unauthorized)))
        }
        
        let logger = request.logger.derive(metadata: ["credential": .string(credential)])
        logger.info("正在进行 API 用户身份验证")
        logger.debug("用户身份", metadata: ["token_encrypted": .string(tokenEncrypted)])
        
        let authData: AuthData
        
        switch strategy {
        case .remote(authURL: let authURL):
            logger.info("以 <远程认证> 模式认证登陆身份")
            
            guard let roleIdString = request.headers.first(name: "X-Role-Id"), let roleId = UUID(roleIdString) else {
                throw NexusErrcase.apiValidateFailed.d("未找到 'X-Role-Id' 请求头", category: .external(suggestions: ["请提供用户的登陆角色身份"], userdata: .init(HTTPResponseStatus.unauthorized)))
            }
            
            struct AuthExchangeData: Content {
                let token: EncryptedToken
                let roleId: UUID
                
                enum CodingKeys: String, CodingKey {
                    case token
                    case roleId = "role_id"
                }
            }
            
            let payload = AuthExchangeData(
                token: .init(
                    credential: credential,
                    tokenEncrypted: tokenEncrypted
                ),
                roleId: roleId
            )
            
            let uri = URI(string: authURL.appending(components: "inline", "authenticate").absoluteString)
            logger.info("向身份认证模块请求认证", metadata: ["auth_url": .stringConvertible(uri), "module_id": .summaryData(moduleID)])
            logger.debug("完整模块 ID", metadata: ["module_id": .data(moduleID)])
            
            let clientResponse: ClientResponse
            do {
                clientResponse = try await request.client.post(uri) { clientReq in
                    clientReq.headers.replaceOrAdd(name: "X-Module-ID", value: moduleID.uuidString)
                    try clientReq.content.encode(payload, as: .json)
                }
            } catch {
                request.logger.error("身份认证模块不可及: \(error)")
                throw NexusErrcase.apiValidateFailed.d("身份认证模块不可及", category: .external(suggestions: ["请稍后再试"], userdata: .init(HTTPResponseStatus.serviceUnavailable)))
            }
            
            logger.debug("认证模块详细相应", metadata: ["response": .stringConvertible(clientResponse)])
            guard clientResponse.status == .ok else {
                var suggestions: [String] = ["请提供正确的用户凭据及加密 Token"]
                if
                    let encryptedData = try? Base64String(tokenEncrypted).dataRes.get(),
                    let possibleToken = try? Crypto.Symm.encrypt(Crypto.hash(encryptedData), key: .init(data: encryptedData)).get().base64EncodedString()
                {
                    suggestions.append("可能是由于提供的 Token 为未加密格式，尝试加密格式: \(possibleToken)")
                }
                
                throw NexusErrcase.apiValidateFailed.d("身份不合法: 状态码 \(clientResponse.status.code)", category: .external(suggestions: suggestions, userdata: .init(HTTPResponseStatus.unauthorized)))
            }
            
            authData = try required(throws: NexusErrcase.apiValidateFailed, "本服务认证服务响应异常，响应体解析失败", category: .inherit) {
                try clientResponse.content.decode(AuthData.self)
            }
            
        case .local(transactor: let transactor):
            logger.info("以 <本地认证> 模式认证登陆身份")
            let roleId = try required(throws: NexusErrcase.apiValidateFailed, "未找到角色身份登陆信息", category: .external(suggestions: ["请提供用户用于操作的角色身份"], userdata: .init(HTTPResponseStatus.unauthorized))) {
                try request.auth.require(QRole.self).id
            }
            
            guard
                let dbToken = try await required(throws: NexusErrcase.apiValidateFailed, "从数据库查询 Token 失败", category: .inherit, {
                    try await QToken.query(on: transactor)
                        .filter(\.credential == credential)
                        .first()
                })
            else {
                throw NexusErrcase.apiValidateFailed.d("凭据无效或已撤销", category: .external(suggestions: ["请提供有效的凭据"], userdata: .init(HTTPResponseStatus.unauthorized)))
            }
            
            let key = try required(throws: NexusErrcase.apiValidateFailed, category: .inherit) {
                try dbToken.verify(encryptedToken: tokenEncrypted)
            }
            
            guard
                let dbRole = try await required(throws: NexusErrcase.apiValidateFailed, "从数据库查询 Token 失败", category: .inherit, {
                    try await QRole.query(on: transactor)
                        .filter(\.id == roleId)
                        .first()
                })
            else {
                throw NexusErrcase.apiValidateFailed.d("用户角色无效", category: .external(suggestions: ["请提供有效的角色"], userdata: .init(HTTPResponseStatus.unauthorized)))
            }
            
            authData = .init(key: .init(key: key), token: dbToken, role: dbRole)
            
        case .debuging(whitelist: let whitelist):
            logger.info("[Debug] 从白名单认证用户")
            guard let roleIdString = request.headers.first(name: "X-Role-Id"), let roleId = UUID(roleIdString) else {
                throw NexusErrcase.apiValidateFailed.d("未找到 'X-Role-Id' 请求头", category: .external(suggestions: ["请提供用户的登陆角色身份"], userdata: .init(HTTPResponseStatus.unauthorized)))
            }
            
            if let authenticateData = whitelist.first(where: { $0.token.credential == credential }) {
                guard let role = authenticateData.roles.first(where: { $0.id == roleId }) else {
                    throw NexusErrcase.apiValidateFailed.d("[Debug] 角色无效", category: .external(suggestions: ["请提供在 Debug 白名单中的角色"], userdata: .init(HTTPResponseStatus.unauthorized)))
                }
                
                let key = try required(throws: NexusErrcase.apiValidateFailed, category: .inherit) {
                    try authenticateData.token.verify(encryptedToken: tokenEncrypted)
                }

                authData = .init(key: .init(key: key), token: authenticateData.token, role: role)
                logger.warning("[Debug] 凭据与 Token 命中白名单，跳过远程认证直接放行")
            } else {
                logger.warning("[Debug] 凭据或 Token 不在白名单中/不匹配，调试模式拒绝访问")
                throw NexusErrcase.apiValidateFailed.d("[Debug] 凭据或 Token 未在白名单中", category: .external(suggestions: ["请提供在 Debug 白名单中的用户凭据和加密 Token"], userdata: .init(HTTPResponseStatus.unauthorized)))
            }
        }
        
        logger.info("成功取得用户身份信息，身份合法", metadata: ["auth_data": .summaryData(authData)])
        logger.debug("用户身份信息", metadata: ["buffer": .data(authData)])
        
        request.auth.login(authData)
        
        return try await required(throws: NexusErrcase.nextResponedFailed, category: .inherit) {
            try await next.respond(to: request)
        }
    }
}
