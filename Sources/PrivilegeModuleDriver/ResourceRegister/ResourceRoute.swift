import Vapor
import PrivilegeModuleExtended

public struct ResourceBundle<T: ResourceTypeList>: Content, Hashable, Codable, Sendable, CustomStringConvertible, Loggerable {
    public let resource: AnyResource
    public let operation: AnyOperation
    public let privileges: OrderedSet<PrivilegeModule<T>.PPrivilege>
    
    public init(
        _ resource: AnyResource,
        op: AnyOperation,
        using privileges: OrderedSet<PrivilegeModule<T>.PPrivilege> = []
    ) {
        self.resource = resource
        self.operation = op
        self.privileges = privileges
    }
    
    public init<F: Resource>(
        _ resource: F,
        op: F.Operations,
        using privileges: OrderedSet<PrivilegeModule<T>.PPrivilege> = []
    ) where F.ResourceType == T {
        self.resource = .init(from: resource)
        self.operation = .init(op: op)
        self.privileges = privileges
    }
    
    public var json: [String: AnyCodable] {[
        "resource": AnyCodable(resource),
        "operation": AnyCodable(operation),
        "privileges": AnyCodable(privileges)
    ]}
    
    public var description: String {
        formatJson(json)
    }
}

public extension Route {
    internal static let resourceKey = "resource_key"
    internal static let operationKey = "operation_key"
    internal static let privilegesKey = "privileges_key"
    
    @discardableResult
    func privilege<T: Resource>(
        resource: AnyResource,
        op: AnyOperation,
        using privileges: OrderedSet<PrivilegeModule<T>.PPrivilege> = []
    ) -> Self {
        self.privilege(
            bundle: .init(
                resource,
                op: op,
                using: privileges
            )
        )
    }
    
    @discardableResult
    func privilege<T: Resource>(
        resource: T,
        op: T.Operations,
        using privileges: OrderedSet<PrivilegeModule<T.ResourceType>.PPrivilege> = []
    ) -> Self {
        self.privilege(
            bundle: .init(
                resource,
                op: op,
                using: privileges
            )
        )
    }
    
    @discardableResult
    func privilege<T: ResourceTypeList>(bundle: ResourceBundle<T>) -> Self {
        privilege(bundle: [bundle])
    }
    
    @discardableResult
    func privilege<T: ResourceTypeList>(bundle: OrderedSet<ResourceBundle<T>>) -> Self {
        let resource = bundle.mapToSet { $0.resource }
        let operation = bundle.mapToSet { $0.operation }
        let privileges = bundle.mapToSet { $0.privileges }
        
        if
            let rscs = self.userInfo[Self.resourceKey] as? OrderedSet<AnyResource>,
            let oprs = self.userInfo[Self.operationKey] as? OrderedSet<AnyOperation>,
            let pris = self.userInfo[Self.resourceKey] as? OrderedSet<OrderedSet<PrivilegeModule<T>.PPrivilege>>
        {
            self.userInfo[Self.resourceKey] = rscs.appending(contentsOf: resource)
            self.userInfo[Self.operationKey] = oprs.appending(contentsOf: operation)
            self.userInfo[Self.privilegesKey] = pris.appending(contentsOf: privileges)
        } else {
            self.userInfo[Self.resourceKey] = resource
            self.userInfo[Self.operationKey] = operation
            self.userInfo[Self.privilegesKey] = privileges
        }
        return self
    }
}
