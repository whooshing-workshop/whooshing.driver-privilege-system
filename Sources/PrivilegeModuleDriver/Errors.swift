import Nexus
import ErrorHandle

@frozen
public enum PrivilegeModuleErrcase: String, ErrList, Sendable {
    case initFailed = "权限模块初始化失败"
    case arbitrateRequestFailed = "权限仲裁请求失败"
    case resourceRegisterFailed = "资源注册失败"
    case privilegeArbitrateFailed = "权限仲裁失败"
    case nextResponedFailed = "处理请求失败"
}
