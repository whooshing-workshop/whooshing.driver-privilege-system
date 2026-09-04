import Nexus
import ErrorHandle

@frozen
public enum PrivilegeSystemErrcase: String, ErrList, Sendable {
    case initFailed = "权限系统初始化失败"
}
