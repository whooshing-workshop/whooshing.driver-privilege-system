import Vapor
import PrivilegeModuleExtended

public struct ArbitrateData: Content, Sendable, CustomStringConvertible, Loggerable {
    public let moduleId: UUID
    public let userId: UUID
    public let roleId: UUID
    public let resource: AnyResource
    public let operation: AnyOperation
    public let privilegeIds: [UUID]
    
    public init(moduleId: UUID, userId: UUID, roleId: UUID, resource: AnyResource, operation: AnyOperation, privilegeIds: [UUID]) {
        self.moduleId = moduleId
        self.userId = userId
        self.roleId = roleId
        self.resource = resource
        self.operation = operation
        self.privilegeIds = privilegeIds
    }
    
    public var json: [String: AnyCodable] {[
        "module_id": AnyCodable(self.moduleId),
        "user_id": AnyCodable(self.userId),
        "role_id": AnyCodable(self.roleId),
        "resource": AnyCodable(self.resource),
        "operation": AnyCodable(self.operation),
        "privilege_ids": AnyCodable(self.privilegeIds)
    ]}
    
    public var description: String {
        formatJson(json)
    }
}
