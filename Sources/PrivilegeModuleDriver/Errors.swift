import ErrorHandle
import WhooshingServer

public extension Whooshing {
    @frozen
    enum PrivilegeModuleErrcase: String, ErrList, Sendable {
        case initFailed = "权限模块初始化失败"
    }
}
