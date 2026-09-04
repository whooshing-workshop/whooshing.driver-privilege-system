import Nexus
import PrivilegeSystem
import PrivilegeShared

public extension Environment.Config {
    var privilegeSystem: Environment.PS { storage[PrivilegeSystemDriverKey.self]! } // 若指定为 Environment.PS?，则必须写为 ?? nil 而非 storage[XXX]!，否则可能引发崩溃
    
    /// 用于在无依赖 debug (Whooshing.Env.independentDebug) 模式下加载 PrivilegeSystem 依赖参数
    ///
    /// 伪造该权限系统所必需的参数
    ///
    /// > 在一般的 .production 或 .debug 模式下，
    /// 这些参数会通过 Whooshing 系统的环境变量解析得到，
    /// 而在独立无依赖运行模式下，需要手动提供
    func load(privilegeSystem: Environment.PS?) -> Self {
        var new = self
        new.storage[PrivilegeSystemDriverKey.self] = privilegeSystem
        return new
    }
}

public extension Environment {
    @frozen
    struct PS: Sendable, Hashable, CustomStringConvertible, Loggerable {
        /// EOPA 连接参数
        public let eopa: EOPA
        /// 角色创建的名称保留字，即，使用该列表中名称的角色不能被直接创建，除非通过提供的特殊方式
        public let reservedRoleName: [String]
        
        /// 创建 Privilege System 连接配置。
        /// 初始化环境配置，仅在 ``Whooshing.Env`` 为 `.independentDebug(...)` 时才可能使用
        /// 这些参数在非 `.independentDebug(...)` 模式下会自动从环境变量中读取
        ///
        /// - Parameters:
        ///   - eopa: EOPA 连接参数，默认使用 http://localhost:8181
        @inlinable
        public init(
            eopa: EOPA = .init(),
            reservedRoleName: [String] = ["admin"]
        ) {
            self.eopa = eopa
            self.reservedRoleName = reservedRoleName
        }
        
        @inlinable
        public var json: [String: AnyCodable] {[
            "eopa": AnyCodable(eopa.json),
            "reserved_role_name": AnyCodable(reservedRoleName)
        ]}
        
        @inlinable
        public var description: String {
            formatJson(json)
        }
    }
}
