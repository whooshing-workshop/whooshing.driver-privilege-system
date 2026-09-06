# Whooshing 权限管理驱动模块

本项目为 [Whooshing](https://github.com/whooshing-workshop/whooshing) 系统的**权限管理驱动模块**，作为 `Nexus` 与权限系统 / 业务权限模块的连接桥梁。它本身不包含核心的权限仲裁与组织逻辑（核心逻辑由 [whooshing.toolbox-privilege-system](https://github.com/whooshing-workshop/whooshing.toolbox-privilege-system) 提供），而是专注于为 [whooshing.nexus (服务模块核心)](https://github.com/whooshing-workshop/whooshing.nexus) 提供权限子系统的配置读取、初始化，以及一整套开箱即用的 Vapor 中间件：用户身份验证、权限仲裁、资源自动注册。

### 特性

- **无缝集成**：将 `whooshing.toolbox-privilege-system` 的功能完美集成到 `Nexus` 的环境中。
- **配置驱动**：作为 Nexus 的驱动，能直接从系统环境变量中自动提取配置参数（EOPA 地址、认证 / 仲裁服务地址、角色保留名等）进行初始化，用户**无需提供任何 Swift 参数来构建配置**。
- **双擎支持**：分离提供 `PrivilegeSystemDriver`（全局权限主系统：用户、群组、角色、域与策略）以及 `PrivilegeModuleDriver`（业务模块私有：资源、资源权限），使模块权限配置彻底解耦。
- **身份验证中间件**：`ApiValidator` 校验请求头中的用户凭据与加密 Token，支持远程认证（转发至权限主系统）、本地认证（直连权限主系统数据库）与调试白名单三种策略。
- **权限仲裁中间件**：`Arbitrator` 依据路由所声明的资源与操作，自动收集资源权限并向权限主系统发起仲裁；支持调试模式下以闭包模拟仲裁结果。
- **资源自动注册**：`ResourceAutoRegister` 在应用启动后扫描所有路由上声明的资源与策略，与数据库中的记录做差量同步。
- **环境隔离**：区分调试与生产环境，在调试时自动应用测试用数据库 / EOPA 配置并停用相关的 TDE 加密以方便调试。

----------

### 导入该依赖库

在你的 `Package.swift` 加入：

``` swift
.package(url: "https://github.com/whooshing-workshop/whooshing.driver-privilege-system.git", from: "1.0.8")
```

在依赖模块中引入（根据需要引入对应的 Driver）：

```swift
.product(name: "PrivilegeSystemDriver", package: "whooshing.driver-privilege-system"),
.product(name: "PrivilegeModuleDriver", package: "whooshing.driver-privilege-system")
```

在需要的地方:

```swift
import PrivilegeSystemDriver   // 权限主系统模块使用
import PrivilegeModuleDriver   // 业务模块使用
```

> 两个 Driver 均已通过 `@_exported` 重新导出了 `Nexus`、`ResourceMacros` 与 `PrivilegeModuleExtended`，并分别重新导出 `PrivilegeSystem` / `PrivilegeModule`，导入后无需再单独导入这些模块。

--------

### 使用介绍

由于该库是依附于 Nexus 的驱动模块，你需要先拥有 `Nexus` 实例。所有的环境配置均通过环境变量进行传入。

#### 1. 注册 Driver 并执行 Bootstrap

要加载这个 Driver 并在启动时识别相关的环境变量，只需要在调用 `Bootstrap.run(...)` 的时候，向 `driverKeys` 数组提供相应的 Driver Key：

```swift
import VaporTube
import PrivilegeSystemDriver
import PrivilegeModuleDriver

// 1. 独立调试模式下，通过 .load(...) 伪造参数
//    生产环境下，系统会自动读取宿主机的环境变量，用户无需书写 Swift 配置代码
let config = Environment.Config(id: UUID(), name: "my-module", port: 6500, dbServices: [...])
    // 权限主系统参数
    .load(privilegeSystem: Environment.PS(
        eopa: .init(scheme: .http, port: 8181, host: "localhost"),
        reservedRoleName: ["admin"]
    ))
    // 业务权限模块参数
    .load(privilegeModule: Environment.PM(
        eopa: .init(scheme: .http, port: 8181, host: "localhost"),
        apiStrategy: .remote(authURL: .init(string: "http://localhost:6501")!),
        arbitrateStrategy: .remote(arbiURL: .init(string: "http://localhost:6501")!)
    ))

// 2. 执行 Bootstrap 并注册 Driver
let paras = try await Bootstrap.run(
    .detect(config),
    driverKeys: [
        PrivilegeSystemDriverKey.self, // <- 注册 System Driver
        PrivilegeModuleDriverKey.self  // <- 注册 Module Driver
    ],
    logger: Logger(label: "app")
).get()

let tube = try await VaporTube.make(paras).get()
let nexus = Nexus(tube: tube, bootstrap: paras)
```

生产环境下，两个 Driver 分别读取以下环境变量：

```
# PrivilegeSystemDriver
WHOOSHING_PRIVILEGE_SYSTEM_EOPA_SCHEME=http
WHOOSHING_PRIVILEGE_SYSTEM_EOPA_HOST=localhost
WHOOSHING_PRIVILEGE_SYSTEM_EOPA_PORT=8181
WHOOSHING_PRIVILEGE_SYSTEM_RESERVED_ROLE_NAME_COUNT=1
WHOOSHING_PRIVILEGE_SYSTEM_RESERVED_ROLE_NAME_1=admin

# PrivilegeModuleDriver
WHOOSHING_PRIVILEGE_MODULE_EOPA_SCHEME=http
WHOOSHING_PRIVILEGE_MODULE_EOPA_HOST=localhost
WHOOSHING_PRIVILEGE_MODULE_EOPA_PORT=8181
WHOOSHING_PRIVILEGE_MODULE_API_STRATEGY_AUTH_URL=http://privilege-system:6501       # 身份认证服务地址
WHOOSHING_PRIVILEGE_MODULE_ARBITRATE_STRATEGY_ARBI_URL=http://privilege-system:6501 # 权限仲裁服务地址
```

> 生产环境下 `apiStrategy` / `arbitrateStrategy` 固定为 `.remote`，`.debuging` 与 `.local` 仅能在独立调试配置中通过 Swift 代码指定。

#### 2. 初始化并接入权限实例

在拥有 `nexus` 实例后，可直接调用扩展方法对其进行自动接入：

``` swift
// 3A. 初始化全局权限主系统 PrivilegeSystem
let systemResult = await nexus.makePrivilegeSystem(
    for: db,             // Environment.DB
    logger: logger,
    debugging: false
)

switch systemResult {
case .success(let system):
    print("PrivilegeSystem 初始化成功")
case .failure(let error):
    print("初始化失败: \(error)")
}

// =======================================================

// 声明该模块下允许存在的资源类型集合
enum ResourceList: String, ResourceTypeList {
    case document
    case record
}

// 3B. 初始化业务服务权限模块 PrivilegeModule，moduleId 自动取自 nexus.config.id
let moduleResult: Res<PrivilegeModule<ResourceList>, PrivilegeModuleErrcase> = await nexus.makePrivilegeModule(
    for: db,
    logger: logger,
    debugging: false
)
```

或者使用对应的同步版本（主要用于程序启动阶段的必须依赖项接入，如果发生错误将直接崩溃）：

``` swift
let privilegeSystem = nexus.syncMakePrivilegeSystem(for: db, logger: logger, debugging: false)

let privilegeModule: PrivilegeModule<ResourceList> = nexus.syncMakePrivilegeModule(for: db, logger: logger, debugging: false)
```

#### 3. 业务模块：受保护的路由

`PrivilegeModuleDriver` 为 `RoutesBuilder` 提供两个分组扩展：

``` swift
import PrivilegeModuleDriver

// /api 路由组：ApiValidator 按 config.privilegeModule.apiStrategy 校验用户身份，
// 校验通过后 AuthData（用户、Token、角色）会登录到 req.auth
let apiProtected = app
    .apiProtectGrouped(in: nexus)
    // 叠加 Arbitrator：按路由声明的资源与操作向权限主系统发起仲裁
    .arbitratorGrouped(in: nexus, on: privilegeModule)

apiProtected.get("documents", ":id") { req async throws -> String in
    let auth = try req.auth.require(AuthData.self)
    return "hello \(auth.token.user.email)"
}
// 为路由声明所保护的资源、操作以及资源权限策略
.privilege(
    resource: DocumentResource(appId: "doc-list"),
    op: .read,
    using: [.init(name: "doc_reader", policy: PrivilegePolicy().allow { $0.operation == "read" }.policy)]
)
```

客户端访问 `/api` 路由时需携带三个请求头：

| 请求头 | 含义 |
|---|---|
| `X-Credential` | 登录后获得的凭据 |
| `X-Encrypted-Token` | 以 Token 密钥加密其自身哈希后的 base64 密文 |
| `X-Role-Id` | 本次操作所使用的角色 ID |

路由上声明的资源与策略需在启动后同步到数据库，注册 `ResourceAutoRegister` 生命周期处理器即可：

``` swift
app.lifecycle.use(ResourceAutoRegister(module: privilegeModule))
```

`ResourceAutoRegister` 会对比数据库中已有资源与路由声明的资源：删除失效资源、插入新资源，随后重建所有资源权限及其绑定关系。

#### 4. 权限主系统模块：受保护的管理路由

`PrivilegeSystemDriver` 提供 `apiProtectGrouped(for:in:)`，其保护链为 `RoleAuthenticator → AdminAuthGuard → ApiValidator(.local)`，即只有持有 `admin` 角色的用户才可访问：

``` swift
import PrivilegeSystemDriver

let adminApi = app.apiProtectGrouped(for: privilegeSystem, in: nexus)

adminApi.put("role") { req async throws -> [QRole] in
    let roles = try req.content.decode([PRole].self)
    return try await privilegeSystem.role.create(roles: roles)
}
```

同时，业务模块所依赖的两个服务间接口需由权限主系统模块在 `/inline` 下提供，请求 / 响应体类型由本库统一定义：

``` swift
let inline = app.inlineProtectGrouped()

// ApiValidator(.remote) 调用：POST <authURL>/inline/authenticate
inline.post("authenticate") { req async throws -> AuthData in
    let data = try req.content.decode(AuthenticateData.self)
    return try await privilegeSystem.account.authenticate(token: data.token, roleId: data.roleId)
}

// Arbitrator(.remote) 调用：POST <arbiURL>/inline/arbitrate
inline.post("arbitrate") { req async throws -> Bool in
    let data = try req.content.decode(ArbitrateData.self)
    return try await privilegeSystem.arbitrator.judge(
        moduleId: data.moduleId,
        userId: data.userId,
        roleId: data.roleId,
        resource: data.resource,
        operation: data.operation,
        privilegeIds: .init(data.privilegeIds)
    ).result
}
```

#### 5. 调试策略

独立调试时可以完全脱离权限主系统运行业务模块：

``` swift
// 身份验证：命中白名单即放行
let apiStrategy: ApiValidator.Strategy = .debuging(whitelist: [
    WhitelistAuthData(
        token: .testMake(credential: "...", token: "...", user: .set(testingUser)),
        roles: [testingRole]
    )
])

// 权限仲裁：以闭包决定是否放行
let arbitrateStrategy: ArbitrateStrategy = .debuging { req, resource, operation in
    operation.rawValue == "read"
}
```

-------

### 运行环境

* **macOS** (> 13.0)
* **iOS** (> 16.0)
* **Linux** (> 20)
* **Swift** (> 6.3)
* **watchOS** (> 6.0) **[未测试]**
* **tvOS** (> 13.0) **[未测试]**

-------

### 注意事项

- 驱动系统高度依赖 `Nexus` 的配置解析管道。确保 `PrivilegeSystemDriverKey.self` 或 `PrivilegeModuleDriverKey.self` 被正确传入 `driverKeys`，否则系统将无法去环境变量中读取相关配置，导致随后调用初始化方法时找不到配置而崩溃。
- `PrivilegeSystem` 和 `PrivilegeModule` 可以独立存在，您可以根据当前微服务模块的具体需求只引入并挂载其中一个。例如：中心认证服务器只需要 `PrivilegeSystemDriver`，而独立业务模块只需 `PrivilegeModuleDriver`。
- `ApiValidator.Strategy.local` 仅供权限主系统模块使用（直连其数据库），业务模块请使用 `.remote` 或 `.debuging`。
- `Arbitrator` 要求路由上声明的资源数与操作数一致，否则会以内部错误拒绝请求；未声明 `.privilege(...)` 的路由在经过 `arbitratorGrouped` 时同样会被拒绝。
- `debugging: true` 时会使用 `testingConfig` 连接数据库与 EOPA 并关闭 TDE 加密，请勿在生产环境开启。

如需了解底层完整的权限系统架构、权限判断流程、OPA 策略配置说明，请参阅 [whooshing.toolbox-privilege-system 文档](https://github.com/whooshing-workshop/whooshing.toolbox-privilege-system)。

------

### 联系与反馈

如有使用问题或建议，请通过 [GitHub Issues](https://github.com/whooshing-workshop/whooshing.driver-privilege-system/issues) 提交反馈。

或发至邮箱 [contact@official.whooshings.space](mailto:contact@official.whooshings.space)
