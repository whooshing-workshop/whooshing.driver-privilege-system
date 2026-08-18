import Nexus
import PrivilegeModuleExtended

public extension Environment {
    @frozen
    struct EOPA: Sendable, Hashable, CustomStringConvertible, Loggerable {
        /// 连接 EOPA 使用的 URL scheme。
        public let scheme: OPA.ConnectionArgument.Scheme
        /// EOPA TCP 端口。
        public let port: Int
        /// 用于连接 EOPA 的主机名。
        public let host: String
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
            port: Int = 8181,
            host: String = "localhost",
            proxy: HTTPClient.Configuration.Proxy? = nil
        ) {
            self.scheme = scheme
            self.port = port
            self.host = host
            self.proxy = proxy
        }
        
        @inlinable
        public var json: [String: AnyCodable] {[
            "scheme": AnyCodable(scheme.rawValue),
            "port": AnyCodable(port),
            "host": AnyCodable(host),
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
        package var testingConfig: OPAConfiguration {
            let host: String
            
            // 测试环境下，需要考虑 GITHUB CI 测试提供的 Host 地址
            // 若 host 是 localhost，则需要根据 GITHUB 设置的环境变量决定
            if self.host != "localhost" {
                host = self.host
            } else {
                host = ProcessInfo.processInfo.environment["GITHUB_EOPA_TESTING_HOST"] ?? "localhost"
            }
            
            return .init(
                scheme: self.scheme,
                host: host,
                port: self.port,
                proxy: self.proxy
            )
        }
        
        @inlinable
        package var config: OPAConfiguration {
            .init(
                scheme: self.scheme,
                host: self.host,
                port: self.port,
                proxy: self.proxy
            )
        }
    }
}
