import Vapor
import PrivilegeModuleExtended

public struct ApiAuthGuardMiddleware: AsyncMiddleware {
    public init() {}
    
    public func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let data = try JSONDecoder().decode(AuthData.self, from: request.apiAuthData)
        request.auth.login(data)
        return try await next.respond(to: request)
    }
}
