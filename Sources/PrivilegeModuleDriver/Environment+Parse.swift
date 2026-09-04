import OPA
import Nexus

public enum PrivilegeModuleDriverKey: Environment.DriverKey {
    public typealias Value = Environment.PM
    public static let label = "privilege_module"
    public static let valueType: Environment.Types = .template(Environment.PM.self)
    public static func loggerStrategies(for directory: URL) -> [LoggerStrategy] {
        do {
            return [
                try .init(
                    label: "privilege_module",
                    level: .info,
                    config: .file(
                        match: { $0.contains("privilege.module") },
                        directory: directory.appendingPathComponent("privilege_module_logs"),
                        name: "privilege_module.log"
                    )
                )
            ]
        } catch {
            fatalError("创建 privilege_module.log 策略失败: \(error)")
        }
    }
}

extension Environment.PM: Environment.Template {
    @inlinable
    public static func withEnv(dic origin: inout OrderedDictionary<String, Environment.Types>) {
        origin["eopa"] = .template(Environment.EOPA.self)
        origin["api_strategy_auth_url"] = .url()
    }
    
    @inlinable
    public init(data: [String : Any], driverKeys: [any Environment.DriverKey.Type], extra: [String : Any]) {
        self.eopa = data["eopa"] as! Environment.EOPA
        self.apiStrategy = .remote(authURL: data["api_strategy_auth_url"] as! URL)
    }
}
