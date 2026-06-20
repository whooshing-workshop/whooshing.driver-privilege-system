import PrivilegeSystem
import WhooshingServer
import Foundation

public struct ArbitrateData: Content {
    let moduleId: UUID
    let userId: UUID
    let roleId: UUID
    let resource: AnyResource
    let operation: AnyOperation
    let privilegeIds: [UUID]
}

public struct PrivilegeController: RouteCollection, Sendable {
    
    let privilegeSystem: PrivilegeSystem
    
    public init(privilegeSystem: PrivilegeSystem) {
        self.privilegeSystem = privilegeSystem
    }
    
    public func boot(routes: any RoutesBuilder) throws {
        let privilege = routes.grouped("privilege")
        privilege.post(use: arbitrate)
    }
    
    @Sendable
    func arbitrate(req: Request) async throws -> Bool {
        let data = try req.content.decode(ArbitrateData.self)
        
        let report = try await privilegeSystem.arbitrator.judge(
            moduleId: data.moduleId,
            userId: data.userId,
            roleId: data.roleId,
            resource: data.resource,
            operation: data.operation,
            privilegeIds: .init(data.privilegeIds)
        )
        
        return report.result
    }
}
