import Nexus
import PrivilegeShared

// PrivilegeModule 依赖环境变量
//  - <prefix>_PRIVILEGE_MODULE_EOPA_SCHEME: String
//  - <prefix>_PRIVILEGE_MODULE_EOPA_HOST: String
//  - <prefix>_PRIVILEGE_MODULE_EOPA_PORT: Int
//  - <prefix>_PRIVILEGE_MODULE_API_STRATEGY_AUTH_URL: URL
//  - <prefix>_PRIVILEGE_MODULE_ARBITRATE_STRATEGY_ARBI_URL: URL

public extension Nexus {
    /// 初始化一个权限模块系统(同步，若初始化失败将直接导致程序崩溃)
    ///
    /// - Parameters:
    ///     - db: 用于存储权限结构的数据库
    ///     - logger: 日志实例，不会直接使用该 logger 的 label，会派生 .privilege.module 使用
    ///     - debugging: 调试状态，置为 true 则启动调试模式
    func syncMakePrivilegeModule<G: ResourceTypeList>(
        for db: Environment.DB,
        logger: Logger,
        debugging: Bool = false
    ) -> PrivilegeModule<G> {
        try! asyncResultToSync {
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
    func makePrivilegeModule<G: ResourceTypeList>(
        for db: Environment.DB,
        logger: Logger,
        debugging: Bool = false
    ) async -> Res<PrivilegeModule<G>, PrivilegeModuleErrcase> {
        await .async { () throws(PrivilegeModuleErrcase.ErrType) in
            try await required(throws: PrivilegeModuleErrcase.initFailed, category: .inherit) {
                try await PrivilegeModule(
                    moduleId: config.id,
                    eventLoop: self.eventLoopGroup.next(),
                    dbConfigure: debugging ? db.testingConfig : db.config,
                    opaConfigure: debugging ? config.privilegeModule.eopa.testingConfig : config.privilegeModule.eopa.config,
                    logger: logger.derive(subId: "privilege.module"),
                    debuging: .init(tdeEncrypt: !debugging)
                )
            }
        }
    }
}

public extension Nexus {
    func makeApiValidator() -> ApiValidator {
        .init(
            moduleID: self.config.id,
            strategy: self.config.privilegeModule.apiStrategy
        )
    }
}

public extension RoutesBuilder {
    func apiProtectGrouped<T>(in nexus: Nexus<T>) -> RoutesBuilder {
        self.grouped("api").grouped(
            nexus.makeApiValidator(),
            AuthData.guardMiddleware()
        )
    }
    
    func arbitratorGrouped<T, G>(in nexus: Nexus<T>, on module: PrivilegeModule<G>) -> RoutesBuilder {
        self.grouped(
            Arbitrator(
                strategy: nexus.config.privilegeModule.arbitrateStrategy,
                on: module
            )
        )
    }
}
