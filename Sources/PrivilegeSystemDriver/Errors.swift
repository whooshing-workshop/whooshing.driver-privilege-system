import Nexus
import ErrorHandle

public extension Nexus {
    @frozen
    enum PrivilegeSystemErrcase: String, ErrList, Sendable {
        case initFailed = "权限系统初始化失败"
    }
}
