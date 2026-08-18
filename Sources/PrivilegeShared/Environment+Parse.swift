import Nexus

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
        self.port = data["port"] as! Int
        self.host = data["host"] as! String
        self.proxy = nil
    }
}
