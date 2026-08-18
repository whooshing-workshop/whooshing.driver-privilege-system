import Nexus
import ErrorHandle

public extension Nexus {
    @frozen
    enum PrivilegeModuleErrcase: String, ErrList, Sendable {
        case initFailed = "权限模块初始化失败"
    }
}
