import Vapor
import PrivilegeModuleExtended

public struct ApiAuthGuard: AsyncMiddleware {
    public init() {}
    
    public func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try decoder.decode(AuthData.self, from: request.apiAuthData)
        request.auth.login(data)
        return try await next.respond(to: request)
    }
}
