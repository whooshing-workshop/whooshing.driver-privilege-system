import Nexus
import ErrorHandle

@frozen
public enum PrivilegeSystemErrcase: String, ErrList, Sendable {
    case initFailed = "权限系统初始化失败"
    case adminAuthFailed = "管理员身份认证失败"
    case nextHandleFailed = "下一个处理器处理失败"
}
