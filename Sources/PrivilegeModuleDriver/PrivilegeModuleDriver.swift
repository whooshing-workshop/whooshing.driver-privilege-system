import PrivilegeModule
import WhooshingServer

// PrivilegeModule 依赖环境变量
//  - <prefix>_PRIVILEGE_MODULE_EOPA_SCHEME: String
//  - <prefix>_PRIVILEGE_MODULE_EOPA_HOST: String
//  - <prefix>_PRIVILEGE_MODULE_EOPA_PORT: Int

public extension Whooshing {
    /// 初始化一个权限模块系统(同步，若初始化失败将直接导致程序崩溃)
    ///
    /// - Parameters:
    ///     - db: 用于存储权限结构的数据库
    ///     - logger: 日志实例，不会直接使用该 logger 的 label，会派生 .privilege.module 使用
    ///     - debugging: 调试状态，置为 true 则启动调试模式
    func syncMakePrivilegeModule<T: ResourceTypeList>(
        for db: Environment.DB,
        logger: Logger,
        debugging: Bool = false
    ) -> PrivilegeModule<T> {
        asyncResultToSync {
            await self.makePrivilegeModule(
                for: db,
                logger: logger,
                debugging: debugging
            )
        }
    }
    
    /// 初始化一个权限模块系统(异步)
    ///
    /// - Parameters:
    ///     - db: 用于存储权限结构的数据库
    ///     - logger: 日志实例，不会直接使用该 logger 的 label，会派生 .privilege.module 使用
    ///     - debugging: 调试状态，置为 true 则启动调试模式
    func makePrivilegeModule<T: ResourceTypeList>(
        for db: Environment.DB,
        logger: Logger,
        debugging: Bool = false
    ) async -> Res<PrivilegeModule<T>, PrivilegeModuleErrcase> {
        await .async { () throws(PrivilegeModuleErrcase.ErrType) in
            try await required(throws: PrivilegeModuleErrcase.initFailed, category: .inherit) {
                try await PrivilegeModule(
                    moduleId: config.id,
                    eventLoop: app.eventLoopGroup.next(),
                    dbConfigure: debugging ? db.testingConfig : db.config,
                    opaConfigure: debugging ? config.privilegeModule.eopa.testingConfig : config.privilegeModule.eopa.config,
                    logger: logger.derive(subId: "privilege.module"),
                    debuging: .init(tdeEncrypt: !debugging)
                )
            }
        }
    }
}
