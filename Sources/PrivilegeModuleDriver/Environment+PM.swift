import PrivilegeModule
import WhooshingServer

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
    
    @frozen
    struct EOPA: Sendable, Hashable, CustomStringConvertible, Loggerable {
        /// 连接 EOPA 使用的 URL scheme。
        public let scheme: OPA.ConnectionArgument.Scheme
        /// 用于连接 至 PrivilegeSystem 主模块的 EOPA 的主机名。
        /// 生产环境中，权限系统主模块的 OPA 只允许连接 localhost
        /// 而 PrivilegeModule 的 OPA 允许远端连接
        public let host: String
        /// EOPA TCP 端口。
        public let port: Int
        /// 可选 HTTP 代理，常用于本地调试或 CI 路由。
        /// 该参数不会从环境变量中读取，仅用于本地独立测试使用
        public let proxy: HTTPClient.Configuration.Proxy?
        
        /// 创建 OPA 连接配置。
        /// 初始化环境配置，仅在 ``Whooshing.Env`` 为 `.independentDebug(...)` 时才可能使用
        /// 这些参数在非 `.independentDebug(...)` 模式下会自动从环境变量中读取
        ///
        /// ```swift
        /// let opa = Environment.EOPA(host: "localhost", port: 8181)
        /// ```
        ///
        /// - Parameters:
        ///   - scheme: EOPA 连接 scheme，默认使用 HTTP。
        ///   - port: EOPA 端口，默认是 `8181`。
        ///   - host: 用于连接 EOPA 的主机名，只有测试时会使用。EOPA 生产环境仅允许运行在本地
        ///   - proxy: 可选 HTTP 代理。
        @inlinable
        public init(
            scheme: OPA.ConnectionArgument.Scheme = .http,
            host: String = "localhost",
            port: Int = 8181,
            proxy: HTTPClient.Configuration.Proxy? = nil
        ) {
            self.scheme = scheme
            self.host = host
            self.port = port
            self.proxy = proxy
        }
        
        @inlinable
        public var json: [String: AnyCodable] {[
            "scheme": AnyCodable(scheme.rawValue),
            "host": AnyCodable(host),
            "port": AnyCodable(port),
            "proxy": AnyCodable(proxy == nil ? nil : [
                "host": proxy!.host,
                "port": proxy!.port
            ])
        ]}
        
        @inlinable
        public var description: String {
            formatJson(json)
        }
        
        /// 返回当前 EOPA 的实际连接配置对象
        /// 仅仅在测试时使用
        @inlinable
        var testingConfig: OPAConfiguration {
            let h: String
            
            // 测试环境下，需要考虑 GITHUB CI 测试提供的 Host 地址
            // 若 host 是 localhost，则需要根据 GITHUB 设置的环境变量决定
            if host != "localhost" {
                h = host
            } else {
                h = ProcessInfo.processInfo.environment["GITHUB_EOPA_TESTING_HOST"] ?? "localhost"
            }
            
            return .init(
                scheme: self.scheme,
                host: h,
                port: self.port,
                proxy: self.proxy
            )
        }
        
        @inlinable
        var config: OPAConfiguration {
            .init(
                scheme: self.scheme,
                host: self.host,
                port: self.port,
                proxy: self.proxy
            )
        }
    }
}
