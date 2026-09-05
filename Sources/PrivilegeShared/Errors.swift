import Nexus
import ErrorHandle

@frozen
public enum PrivilegeErrcase: String, ErrList, Sendable {
    case nextResponedFailed = "处理请求失败"
    case apiValidateFailed = "用户身份验证失败"
}
