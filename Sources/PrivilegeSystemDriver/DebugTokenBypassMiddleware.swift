import Vapor
import PrivilegeSystem

/// 用于 Privilege System 模块的 Debug 测试阶段
///
/// 允许提供白名单账号，来通过 Api 的 Token 验证
/// 从而不需要操作数据库就可进行测试，更加方便
/// 如果白名单未命中，则应该按照原来的 Api Token 验证方式进行验证
/// 若两者都未命中，则拒绝访问
public struct DebugTokenBypassMiddleware: AsyncMiddleware {
    private let mockTokens: [QToken]

    public init(mockTokens: [QToken]) {
        self.mockTokens = mockTokens
    }

    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // 尝试从 Request Body 中解析 AuthorizationToken（不影响抛错，解析失败则忽略）
        if let authData = try? request.content.decode(AuthorizationToken.self) {
            // 匹配测试账号白名单
            if let matchedToken = mockTokens.first(where: { $0.credential == authData.credential }) {
                // 登录 Mock Token
                request.auth.login(matchedToken)
            }
        }
        
        // 继续传递给下一个中间件（未命中则由 TokenAuthenticator 处理）
        return try await next.respond(to: request)
    }
}
