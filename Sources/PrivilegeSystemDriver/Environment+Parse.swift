import OPA
import Nexus

public enum PrivilegeSystemDriverKey: Environment.DriverKey {
    public typealias Value = Environment.PS
    public static let label = "privilege_system"
    public static let valueType: Environment.Types = .template(Environment.PS.self)
    public static func loggerStrategies(for directory: URL) -> [LoggerStrategy] {
        do {
            return [
                try .init(
                    label: "privilege_system",
                    level: .info,
                    config: .file(
                        match: { $0.contains("privilege.system") },
                        directory: directory.appendingPathComponent("privilege_system_logs"),
                        name: "privilege_system.log"
                    )
                )
            ]
        } catch {
            fatalError("创建 privilege_system.log 策略失败: \(error)")
        }
    }
}

extension Environment.PS: Environment.Template {
    @inlinable
    public static func withEnv(dic origin: inout OrderedDictionary<String, Environment.Types>) {
        origin["eopa"] = .template(Environment.EOPA.self)
        origin["reserved_role_name"] = .array(.string())
    }
    
    @inlinable
    public init(data: [String : Any], driverKeys: [any Environment.DriverKey.Type], extra: [String : Any]) {
        self.eopa = data["eopa"] as! Environment.EOPA
        self.reservedRoleName = data["reserved_role_name"] as! [String]
    }
}
