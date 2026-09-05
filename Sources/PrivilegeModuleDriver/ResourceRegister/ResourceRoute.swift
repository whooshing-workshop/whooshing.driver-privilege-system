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
    
    public init<F: Resource, G: OperationList>(
        _ resource: F,
        op: G,
        using privileges: OrderedSet<PrivilegeModule<T>.PPrivilege> = []
    ) where F.Operations == G, F.ResourceType == T {
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
    
    func resource<T: Resource, G: OperationList, Z: ResourceTypeList>(
        _ resource: AnyResource,
        op: AnyOperation,
        using privileges: OrderedSet<PrivilegeModule<T>.PPrivilege> = []
    ) where T.Operations == G, T.ResourceType == Z {
        self.resource(.init(
            resource,
            op: op,
            using: privileges
        ))
    }
    
    func resource<T: Resource, G: OperationList, Z: ResourceTypeList>(
        _ resource: T,
        op: G,
        using privileges: OrderedSet<PrivilegeModule<Z>.PPrivilege> = []
    ) where T.Operations == G, T.ResourceType == Z {
        self.resource(.init(
            resource,
            op: op,
            using: privileges
        ))
    }
    
    func resource<T: ResourceTypeList>(_ resource: ResourceBundle<T>) {
        resources([resource])
    }
    
    func resources<T: ResourceTypeList>(_ resources: OrderedSet<ResourceBundle<T>>) {
        self.userInfo[Self.resourceKey] = resources.mapToSet { $0.resource }
        self.userInfo[Self.operationKey] = resources.mapToSet { $0.operation }
        self.userInfo[Self.privilegesKey] = resources.mapToSet { $0.privileges }
    }
}

//public enum OperationSetting<T: OperationList>: Codable, Sendable, CustomStringConvertible, Loggerable {
//    case all
//    case none
//    case allow(T)
//    case allows([T])
//    case deny(T)
//    case denies([T])
//
//    public var ops: [T] {
//        switch self {
//        case .all: Array(T.allCases)
//        case .none: []
//        case .allow(let allow): [allow]
//        case .allows(let array): array
//        case .deny(let deny): T.allCases.filter { $0 != deny }
//        case .denies(let array):
//            {
//                let excluded = Set(array)
//                return T.allCases.filter { !excluded.contains($0) }
//            }()
//        }
//    }
//
//    public var description: String {
//        ops.description
//    }
//}
//
//public extension OperationSetting {
//    static func allows(_ items: T...) -> Self {
//        .allows(items)
//    }
//
//    static func denies(_ items: T...) -> Self {
//        .denies(items)
//    }
//}
