import Vapor
import PrivilegeShared
import PrivilegeModuleExtended

public extension Nexus {
    /// 该函数将根据传入的参数收集需要进行权限认证的所有参数
    /// 后将其转发与权限仲裁模块进行仲裁
    func makeArbitrate<Z: Resource, F: OperationList, G>(
        from request: Request,
        to requestURL: URL,
        on module: PrivilegeModule<G>,
        resource: Z,
        operation: F
    ) async throws(PrivilegeModuleErrcase.ErrType) where Z.Operations == F, Z.ResourceType == G {
        let moduleId =  module.moduleId
        let userId = try required(throws: PrivilegeModuleErrcase.arbitrateRequestFailed, "用户 ID 不存在", category: .external(suggestions: ["请提供正确的用户 ID"], userdata: .init(HTTPResponseStatus.unauthorized))) {
            try request.auth.require(AuthData.self).token.user.id
        }
        let roleId = try required(throws: PrivilegeModuleErrcase.arbitrateRequestFailed, "角色 ID 不存在", category: .external(suggestions: ["请提供正确的角色 ID"], userdata: .init(HTTPResponseStatus.unauthorized))) {
            try request.auth.require(QRole.self).id
        }
        
        let logger = request.logger.derive(metadata: [
            "user_id": .summaryData(userId),
            "role_id": .summaryData(roleId),
            "module_id": .summaryData(moduleId),
            "resource_app_id": .summaryData(resource.appId)
        ])
        
        logger.info("正在查询资源")
        
        guard
            let rsc = try await required(throws: PrivilegeModuleErrcase.arbitrateRequestFailed, "查询资源失败", category: .inherit, {
                try await PrivilegeModule<G>.QResource<Z>.query(on: module.origin)
                    .filter(\.appId == resource.appId)
                    .first()
            }),
            let anyResource = AnyResource(rsc)
        else {
            throw PrivilegeModuleErrcase.arbitrateRequestFailed.d("未找到资源", category: .external(suggestions: ["请提供正确的资源以操作"], userdata: .init(HTTPResponseStatus.unauthorized)))
        }
        
        logger.debug("资源详情", metadata: ["resource": .data(rsc)])
        
        let anyOp = AnyOperation(op: operation)
        
        logger.info("正在查询资源权限")
        
        let privileges = try await required(throws: PrivilegeModuleErrcase.arbitrateRequestFailed, "查询资源权限失败", category: .inherit) {
            try await PrivilegeModule<G>.PrivilegeTAnyResource.query(on: module.origin)
                .filter(\.resourceId == rsc.id)
                .all()
        }
        
        logger.debug("资源权限详情", metadata: ["privileges": .data(privileges)])
        
        let privilegeIds = privileges.map { $0.id }
        
        let arbitrateData = ArbitrateData(
            moduleId: moduleId,
            userId: userId,
            roleId: roleId,
            resource: anyResource,
            operation: anyOp,
            privilegeIds: privilegeIds
        )
        
        let uri = URI(string: requestURL.appending(components: "inline", "arbitrate").absoluteString)
        
        logger.info("向权限仲裁模块请求仲裁", metadata: ["arbitrate_data": .data(arbitrateData)])
        
        let response = try await required(throws: PrivilegeModuleErrcase.arbitrateRequestFailed, "向权限仲裁模块请求失败", category: .inherit) {
            try await request.client.post(uri, headers: ["X-Module-ID": moduleId.uuidString], content: arbitrateData)
        }
        
        logger.debug("权限仲裁详情", metadata: ["response": .stringConvertible(response)])
        
        guard response.status == .ok else {
            throw PrivilegeModuleErrcase.arbitrateRequestFailed.d("向权限仲裁模块请求发生错误，状态码: \(response.status)", category: .external(suggestions: ["请提供正确的用户身份，角色及操作资源以进行操作"], userdata: .init(HTTPResponseStatus.unauthorized)))
        }
        
        let result = try required(throws: PrivilegeModuleErrcase.arbitrateRequestFailed, "解码权限仲裁模块响应失败", category: .inherit) {
            try response.content.decode(Bool.self)
        }
        
        guard result else {
            throw PrivilegeModuleErrcase.arbitrateRequestFailed.d("权限被否决，无权限进行本次操作", category: .external(suggestions: ["请先确定有权限再进行操作", "尝试使用不同的角色身份进行操作"], userdata: .init(HTTPResponseStatus.unauthorized)))
        }
        
        logger.info("权限仲裁通过，允许操作", metadata: ["privilege_ids": .summaryData(privilegeIds), "operation": .summaryData(anyOp)])
    }
}
