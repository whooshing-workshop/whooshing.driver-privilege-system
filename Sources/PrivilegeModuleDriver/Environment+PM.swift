import Nexus
import PrivilegeModule
import PrivilegeShared

public extension Environment.Config {
    var privilegeModule: Environment.PM { storage[PrivilegeModuleDriverKey.self]! } // 若指定为 Environment.PM?，则必须写为 ?? nil 而非 storage[XXX]!，否则可能引发崩溃
    
    /// 用于在无依赖 debug (Whooshing.Env.independentDebug) 模式下加载 PrivilegeModule 依赖参数
    ///
    /// 伪造该权限系统所必需的参数
    ///
    /// > 在一般的 .production 或 .debug 模式下，
    /// 这些参数会通过 Whooshing 系统的环境变量解析得到，
    /// 而在独立无依赖运行模式下，需要手动提供
    func load(privilegeModule: Environment.PM?) -> Self {
        var new = self
        new.storage[PrivilegeModuleDriverKey.self] = privilegeModule
        return new
    }
}

public extension Environment {
    @frozen
    struct PM: Sendable, Hashable, CustomStringConvertible, Loggerable {
        /// EOPA 连接参数
        public let eopa: EOPA
        
        /// 创建 Privilege System 连接配置。
        /// 初始化环境配置，仅在 ``Whooshing.Env`` 为 `.independentDebug(...)` 时才可能使用
        /// 这些参数在非 `.independentDebug(...)` 模式下会自动从环境变量中读取
        ///
        /// - Parameters:
        ///   - eopa: EOPA 连接参数，默认使用 http://localhost:8181
        @inlinable
        public init(eopa: EOPA = .init()) {
            self.eopa = eopa
        }
        
        @inlinable
        public var json: [String: AnyCodable] {[
            "eopa": AnyCodable(eopa.json)
        ]}
        
        @inlinable
        public var description: String {
            formatJson(json)
        }
    }
}
