import Vapor
import PrivilegeShared

public struct ResourceAutoRegister<T: ResourceTypeList>: LifecycleHandler {
    public let module: PrivilegeModule<T>
    
    public init(module: PrivilegeModule<T>) {
        self.module = module
    }
    
    public func didBootAsync(_ app: Application) async throws {
        try await run(app)
    }
    
    private func run(_ app: Application) async throws(PrivilegeModuleErrcase.ErrType) {
        try await module.origin.atrans(throws: PrivilegeModuleErrcase.resourceRegisterFailed, "数据库事务执行失败", category: .inherit) { t throws(PrivilegeModuleErrcase.ErrType) in
            app.logger.info("正在同步本服务资源列表至数据库中")
            var resources: OrderedSet<AnyResource> = []
            var privileges: [String: OrderedSet<PrivilegeModule<T>.PPrivilege>] = [:]
            
            for route in app.routes.all {
                guard
                    let rs = route.userInfo[Route.resourceKey] as? OrderedSet<AnyResource>,
                    let pss = route.userInfo[Route.privilegesKey] as? OrderedSet<OrderedSet<PrivilegeModule<T>.PPrivilege>>
                else { continue }
                
                guard rs.count == pss.count else {
                    throw PrivilegeModuleErrcase.resourceRegisterFailed.d(category: .external(suggestions: ["请提供正确的资源与权限"], userdata: .init(HTTPResponseStatus.unauthorized)))
                }
                
                resources.append(contentsOf: rs)
                for (i, r) in rs.enumerated() {
                    privileges[r.appId] = pss[i]
                }
            }
            
            app.logger.info("正在取得所有资源列表")
            var dbResources = try await required(throws: PrivilegeModuleErrcase.resourceRegisterFailed, "取得资源列表失败", category: .inherit) {
                try await GResource.query(on: t).all()
            }
            
            app.logger.info("已取得的资源列表", metadata: ["resources_summary_max_5": .summaryData([GResource](dbResources.prefix(5))), "count": .stringConvertible(dbResources.count)])
            app.logger.debug("详细资源列表", metadata: ["resources": .data(dbResources)])
            
            var resourcesNeedAdd: OrderedSet<AnyResource> = []
            var resourcesNeedDelete: OrderedSet<GResource> = []
            
            for dbResource in dbResources {
                if let existed = resources.first(where: { $0.appId == dbResource.appId }) {
                    if !compare(existed, with: dbResource) {
                        resourcesNeedDelete.append(dbResource)
                        resourcesNeedAdd.append(existed)
                        resources.remove(existed)
                    }
                } else {
                    resourcesNeedDelete.append(dbResource)
                }
            }
            
            for resource in resources {
                resourcesNeedAdd.append(resource)
            }
            
            if resourcesNeedAdd.isEmpty && resourcesNeedDelete.isEmpty {
                app.logger.info("资源未曾改动，无需更新")
            } else {
                
                let resourceIdsNeedDelete = resourcesNeedDelete.mapToSet { $0.id }
                
                app.logger.info("正在删除无效资源", metadata: ["resource_ids_need_delete_max_5": .summaryData([GResource](resourcesNeedDelete.prefix(5))), "count": .stringConvertible(resourcesNeedDelete.count)])
                app.logger.debug("详细无效资源列表", metadata: ["resource_ids_need_delete": .data(resourcesNeedDelete)])
                
                try await required(throws: PrivilegeModuleErrcase.resourceRegisterFailed, "删除无效资源时失败", category: .inherit) {
                    try await module.resource.delete(ids: resourceIdsNeedDelete, on: t)
                }
                
                dbResources.removeAll { resourceIdsNeedDelete.contains($0.id) }
                
                app.logger.info("正在插入资源", metadata: ["resource_ids_need_add_max_5": .summaryData([AnyResource](resourcesNeedAdd.prefix(5))), "count": .stringConvertible(resourcesNeedAdd.count)])
                app.logger.debug("详细无效资源列表", metadata: ["resource_ids_need_add": .data(resourcesNeedAdd)])
                
                let addedResources = try await required(throws: PrivilegeModuleErrcase.resourceRegisterFailed, "插入资源时失败", category: .inherit) {
                    try await module.resource.create(resources: resourcesNeedAdd, on: t)
                }
                
                guard addedResources.count == resourcesNeedAdd.count else {
                    throw PrivilegeModuleErrcase.resourceRegisterFailed.d("同步新增资源的数量不符", category: .internal)
                }
                
                dbResources.append(contentsOf: addedResources)
            }
            
            app.logger.info("删除旧有的权限设置")
            
            try await required(throws: PrivilegeModuleErrcase.resourceRegisterFailed, "删除无效权限时失败", category: .inherit) {
                let oldPrivileges = try await PrivilegeModule<T>.QPrivilege.query(on: t).all()
                
                app.logger.debug("旧权限列表", metadata: ["old_privileges": .data(privileges)])
                
                for oldPrivilege in oldPrivileges {
                    try await module.privilege.delete(policy: oldPrivilege, on: t)
                }
            }
            
            app.logger.info("创建新的权限")
            
            var relationsNeedAdd: OrderedSet<MTMRelation<UUID, UUID>> = []
            
            for dbResource in dbResources {
                guard let privileges = privileges[dbResource.appId] else {
                    throw PrivilegeModuleErrcase.resourceRegisterFailed.d("资源权限未正确设置", category: .internal)
                }
                
                guard privileges.count > 0 else { continue }
                
                app.logger.debug("为资源创建权限", metadata: ["resource": .data(dbResource), "privileges": .data(privileges)])
                
                let addedPrivilege = try await required(throws: PrivilegeModuleErrcase.resourceRegisterFailed, "创建资源权限时失败", category: .inherit) {
                    try await module.privilege.createWithReturning(privileges: privileges, on: t)
                }
    
                let left = OrderedSet<UUID>(addedPrivilege.map { $0.id })
                relationsNeedAdd.append(.init(left: left, right: [dbResource.id]))
            }
            
            if relationsNeedAdd.isEmpty {
                app.logger.info("无任何资源权限需要设置，无需配置")
            } else {
                app.logger.info("设置资源与权限关系", metadata: ["relations_count": .stringConvertible(relationsNeedAdd.count)])
                app.logger.debug("详细关系", metadata: ["relations": .data(relationsNeedAdd)])
                
                try await required(throws: PrivilegeModuleErrcase.resourceRegisterFailed, "创建权限关系时失败", category: .inherit) {
                    try await module.privilege.attach(privilegeToResource: relationsNeedAdd, on: t)
                }
            }
            
            app.logger.info("资源同步更新完成")
        }
    }
    
    private func compare(_ resource: AnyResource, with dbResource: GResource) -> Bool {
        resource.appId == dbResource.appId &&
        resource.type == dbResource.type &&
        resource.json == dbResource.data
    }
}
