import Testing
import Foundation
@testable import WhooshingServer
@testable import PrivilegeModuleDriver

let apiClientTokenStr = "jXTz4vTQk0O/XFIjWQIHLC7z9/E0/4VtEb+LkF8IcA4="
let wrongApiClientTokenStr = "9cCat+omad2WPRetG0VdqSdVhBPVz5kXJ2DssJtQshI="
let wrongApiClientToken = SendableSymmKey(key: .init(data: Data(base64Encoded: wrongApiClientTokenStr)!))
let apiClientToken = SendableSymmKey(key: .init(data: Data(base64Encoded: apiClientTokenStr)!))

@Suite("环境变量解析测试集")
struct EnvironmentParsingTests {
    @Test("测试环境变量读取")
    func testEnvironmentDetect() async throws {
        let project = try Environment.Config.parse(prefix: "WHOOSHING_API_SERVICE", driverKeys: [PrivilegeModuleDriverKey.self]) { key in [
            "WHOOSHING_API_SERVICE_ID": "C59C74DC-AF7F-4497-854B-75561D9FE995",
            "WHOOSHING_API_SERVICE_NAME": "Testing Project",
            "WHOOSHING_API_SERVICE_PORT": "7777",
            "WHOOSHING_API_SERVICE_DOMAIN": "testing.whooshing.space",
            "WHOOSHING_API_SERVICE_MANAGER_URL": "https://example.com",
            "WHOOSHING_API_SERVICE_HOSTNAME": "localhost",
            
            "WHOOSHING_API_SERVICE_LOG_DIRECTORY": "/User/tester/logfile.log",
            
            "WHOOSHING_API_SERVICE_PRIVILEGE_MODULE_EOPA_SCHEME": "http",
            "WHOOSHING_API_SERVICE_PRIVILEGE_MODULE_EOPA_HOST": "127.0.0.1",
            "WHOOSHING_API_SERVICE_PRIVILEGE_MODULE_EOPA_PORT": "8181",
            
            "WHOOSHING_API_SERVICE_DB_SERVICES_COUNT": "0"
        ][key] }
        
        #expect(project.id.uuidString == "C59C74DC-AF7F-4497-854B-75561D9FE995")
        #expect(project.name == "Testing Project")
        #expect(project.domain == "testing.whooshing.space")
        #expect(project.port == 7777)
        #expect(project.hostname == "localhost")
        #expect(project.dbServices.count == 0)
        #expect(project.managerUrl.absoluteString == "https://example.com")
        #expect(project.log.directory.absoluteString == "/User/tester/logfile.log")
        
        #expect(project.privilegeModule.eopa.scheme == .http)
        #expect(project.privilegeModule.eopa.host == "127.0.0.1")
        #expect(project.privilegeModule.eopa.port == 8181)
    }
    
    @Test("测试环境变量读取2")
    func testEnvironmentDetect2() async throws {
        #expect(throws: Environment.Errcase.ErrType.self, performing: {
            let _ = try Environment.Config.parse(prefix: "WHOOSHING_API_SERVICE", driverKeys: [PrivilegeModuleDriverKey.self]) { key in [
                "WHOOSHING_API_SERVICE_ID": "C59C74DC-AF7F-4497-854B-75561D9FE995",
                "WHOOSHING_API_SERVICE_NAME": "Testing Project",
                "WHOOSHING_API_SERVICE_PORT": "7777",
                "WHOOSHING_API_SERVICE_DOMAIN": "testing.whooshing.space",
                "WHOOSHING_API_SERVICE_MANAGER_URL": "https://example.com",
                "WHOOSHING_API_SERVICE_HOSTNAME": "localhost",
                
                "WHOOSHING_API_SERVICE_LOG_DIRECTORY": "/User/tester/logfile.log",
                
                "WHOOSHING_API_SERVICE_PRIVILEGE_MODULE_EOPA_SCHEME": "http",
                "WHOOSHING_API_SERVICE_PRIVILEGE_MODULE_EOPA_HOST": "127.0.0.1",
                
                "WHOOSHING_API_SERVICE_DB_SERVICES_COUNT": "0"
            ][key] }
        })
    }
    
    @Test("测试环境变量读取3")
    func testEnvironmentDetect3() async throws {
        #expect(throws: Environment.Errcase.ErrType.self, performing: {
            let _ = try Environment.Config.parse(prefix: "WHOOSHING_API_SERVICE", driverKeys: [PrivilegeModuleDriverKey.self]) { key in [
                "WHOOSHING_API_SERVICE_ID": "C59C74DC-AF7F-4497-854B-75561D9FE995",
                "WHOOSHING_API_SERVICE_NAME": "Testing Project",
                "WHOOSHING_API_SERVICE_PORT": "7777",
                "WHOOSHING_API_SERVICE_DOMAIN": "testing.whooshing.space",
                "WHOOSHING_API_SERVICE_MANAGER_URL": "https://example.com",
                "WHOOSHING_API_SERVICE_HOSTNAME": "localhost",
                
                "WHOOSHING_API_SERVICE_LOG_DIRECTORY": "/User/tester/logfile.log",
                
                "WHOOSHING_API_SERVICE_PRIVILEGE_MODULE_EOPA_HOST": "127.0.0.1",
                "WHOOSHING_API_SERVICE_PRIVILEGE_MODULE_EOPA_PORT": "8181",
                
                "WHOOSHING_API_SERVICE_DB_SERVICES_COUNT": "0"
            ][key] }
        })
    }
    
    @Test("测试环境变量读取4")
    func testEnvironmentDetect4() async throws {
        #expect(throws: Environment.Errcase.ErrType.self, performing: {
            let _ = try Environment.Config.parse(prefix: "WHOOSHING_API_SERVICE", driverKeys: [PrivilegeModuleDriverKey.self]) { key in [
                "WHOOSHING_API_SERVICE_ID": "C59C74DC-AF7F-4497-854B-75561D9FE995",
                "WHOOSHING_API_SERVICE_NAME": "Testing Project",
                "WHOOSHING_API_SERVICE_PORT": "7777",
                "WHOOSHING_API_SERVICE_DOMAIN": "testing.whooshing.space",
                "WHOOSHING_API_SERVICE_MANAGER_URL": "https://example.com",
                "WHOOSHING_API_SERVICE_HOSTNAME": "localhost",
                
                "WHOOSHING_API_SERVICE_LOG_DIRECTORY": "/User/tester/logfile.log",
                
                "WHOOSHING_API_SERVICE_PRIVILEGE_MODULE_EOPA_PORT": "8181",
                
                "WHOOSHING_API_SERVICE_DB_SERVICES_COUNT": "0"
            ][key] }
        })
    }
}

extension String: @retroactive Error {}
