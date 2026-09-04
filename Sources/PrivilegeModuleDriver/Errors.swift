import Nexus
import ErrorHandle

@frozen
public enum PrivilegeModuleErrcase: String, ErrList, Sendable {
    case initFailed = "权限模块初始化失败"
    case arbitrateRequestFailed = "权限仲裁请求失败"
}
