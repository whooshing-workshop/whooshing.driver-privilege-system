import PrivilegeSystem
import WhooshingServer
import Foundation

public struct AccountController: RouteCollection, Sendable {
    
    let privilegeSystem: PrivilegeSystem
    
    public init(privilegeSystem: PrivilegeSystem) {
        self.privilegeSystem = privilegeSystem
    }
    
    public func boot(routes: any RoutesBuilder) throws {
        let account = routes.grouped("account")
        account.post("register", use: register)
        account.post("login", use: login)
        account.post("authenticate", use: authenticate)
    }
    
    @Sendable
    func register(req: Request) async throws -> QUser {
        let infos = try req.content.decode(PUser.self)
        let result = try await privilegeSystem.account.register(for: infos)
        return result
    }
    
    @Sendable
    func login(req: Request) async throws -> QToken {
        let account = try req.content.decode(PUser.self)
        let result = try await privilegeSystem.account.login(by: account)
        return result
    }
    
    @Sendable
    func authenticate(req: Request) async throws -> SendableSymmKey {
        let token = try req.content.decode(Token.self)
        let result = try await privilegeSystem.account.authenticate(token: token)
        return result
    }
}
