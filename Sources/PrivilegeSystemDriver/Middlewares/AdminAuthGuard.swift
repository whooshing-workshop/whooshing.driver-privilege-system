import Vapor
import PrivilegeSystem

/// 用于 Privilege System 模块的 Debug 测试阶段
///
/// 允许提供白名单账号，来通过 Api 的 Token 验证
/// 从而不需要操作数据库就可进行测试，更加方便
/// 如果白名单未命中，则应该按照原来的 Api Token 验证方式进行验证
/// 若两者都未命中，则拒绝访问
public struct AdminAuthGuard: AsyncMiddleware {
    public init() {}
    
    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        try await run(to: request, chainingTo: next)
    }
    
    func run(to request: Request, chainingTo next: AsyncResponder) async throws(PrivilegeSystemErrcase.ErrType) -> Response {
        guard let role = request.auth.get(QRole.self) else {
            throw PrivilegeSystemErrcase.adminAuthFailed.d("未指定登陆角色", category: .external(suggestions: ["请指定正确的管理员角色"], userdata: .init(HTTPResponseStatus.unauthorized)))
        }
        
        guard role.name == "admin" else {
            throw PrivilegeSystemErrcase.adminAuthFailed.d("登陆角色并无管理员角色", category: .external(suggestions: ["请指定正确的管理员角色"], userdata: .init(HTTPResponseStatus.unauthorized)))
        }
        
        return try await required(throws: PrivilegeSystemErrcase.nextHandleFailed, category: .inherit) {
            try await next.respond(to: request)
        }
    }
}
