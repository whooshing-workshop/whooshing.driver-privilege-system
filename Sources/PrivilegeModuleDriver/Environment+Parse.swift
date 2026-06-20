import OPA
import WhooshingServer

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
    }
    
    @inlinable
    public init(data: [String : Any], driverKeys: [any Environment.DriverKey.Type], extra: [String : Any]) {
        self.eopa = data["eopa"] as! Environment.EOPA
    }
}

extension Environment.EOPA: Environment.Template {
    @inlinable
    public static func withEnv(dic origin: inout OrderedDictionary<String, Environment.Types>) {
        origin["scheme"] = .string()
        origin["host"] = .string()
        origin["port"] = .int(Int.self)
    }
    
    @inlinable
    public init(data: [String : Any], driverKeys: [any Environment.DriverKey.Type], extra: [String : Any]) {
        self.scheme = .init(rawValue: data["scheme"] as! String)!
        self.host = data["host"] as! String
        self.port = data["port"] as! Int
        self.proxy = nil
    }
}
