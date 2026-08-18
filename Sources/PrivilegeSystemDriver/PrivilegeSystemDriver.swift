import Nexus
import ErrorHandle
import LoggingAdvanced
import PrivilegeSystem

// PrivilegeSystem 依赖环境变量
//  - <prefix>_PRIVILEGE_SYSTEM_EOPA_SCHEME: String
//  - <prefix>_PRIVILEGE_SYSTEM_EOPA_HOST: String
//  - <prefix>_PRIVILEGE_SYSTEM_EOPA_PORT: Int

public extension Nexus {
    /// 初始化一个权限主系统(同步，若初始化失败将直接导致程序崩溃)
    ///
    /// - Parameters:
    ///     - db: 用于存储权限结构的数据库
    ///     - logger: 日志实例，不会直接使用该 logger 的 label，会派生 .privilege.system 使用
    ///     - debugging: 调试状态，置为 true 则启动调试模式
    func syncMakePrivilegeSystem(
        for db: Environment.DB,
        logger: Logger,
        debugging: Bool = false
    ) -> PrivilegeSystem {
        asyncResultToSync {
            await self.makePrivilegeSystem(
                for: db,
                logger: logger,
                debugging: debugging
            )
        }
    }
    
    /// 初始化一个权限主系统(异步)
    ///
    /// - Parameters:
    ///     - db: 用于存储权限结构的数据库
    ///     - logger: 日志实例，不会直接使用该 logger 的 label，会派生 .privilege.system 使用
    ///     - debugging: 调试状态，置为 true 则启动调试模式
    func makePrivilegeSystem(
        for db: Environment.DB,
        logger: Logger,
        debugging: Bool = false
    ) async -> Res<PrivilegeSystem, PrivilegeSystemErrcase> {
        await .async { () throws(PrivilegeSystemErrcase.ErrType) in
            try await required(throws: PrivilegeSystemErrcase.initFailed, category: .inherit) {
                try await PrivilegeSystem(
                    eventLoop: self.eventLoopGroup.next(),
                    dbConfigure: debugging ? db.testingConfig : db.config,
                    opaConfigure: debugging ? config.privilegeSystem.eopa.testingConfig : config.privilegeSystem.eopa.config,
                    logger: logger.derive(subId: "privilege.system"),
                    debuging: .init(tdeEncrypt: !debugging)
                )
            }
        }
    }
}
