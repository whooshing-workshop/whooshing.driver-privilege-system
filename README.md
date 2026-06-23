# Whooshing 权限管理驱动模块

本项目为 [Whooshing](https://github.com/whooshing-workshop/whooshing) 系统的**权限管理驱动模块**，作为 `WhooshingServer` 与权限系统/业务权限模块的连接桥梁。它本身不包含核心的权限仲裁与组织逻辑（核心逻辑由 [whooshing.toolbox-privilege-system](https://github.com/whooshing-workshop/whooshing.toolbox-privilege-system) 提供），而是专注于为 [WhooshingServer (主 Server 模块)](https://github.com/whooshing-workshop/whooshing.toolbox-server) 提供便捷的权限子系统初始化与配置读取能力。

### 特性

- **无缝集成**：将 `whooshing.toolbox-privilege-system` 的功能完美集成到 `WhooshingServer` 的环境中。
- **配置驱动**：作为 Server 的驱动，能直接从系统环境变量中自动提取配置参数（如 OPA 端口及协议等）进行初始化，用户**无需提供任何 Swift 参数来构建配置**。
- **双擎支持**：分离支持全局的 `PrivilegeSystem`（用户、群组和全局角色）以及模块私有的 `PrivilegeModule`（模块私有资源、具体策略），使模块权限配置彻底解耦。
- **环境隔离**：区分调试与生产环境，在调试时可自动应用测试用数据库配置并停用相关的 TDE 加密以方便调试。

----------

### 导入该依赖库

在你的 `Package.swift` 加入：

``` swift
.package(url: "https://github.com/whooshing-workshop/whooshing.driver-privilege-system.git", from: "1.0.1")
```

在依赖模块中引入（根据需要引入对应的 Driver）：

```swift
.product(name: "PrivilegeSystemDriver", package: "whooshing.driver-privilege-system"),
.product(name: "PrivilegeModuleDriver", package: "whooshing.driver-privilege-system")
```

在需要的地方:

```swift
import PrivilegeSystemDriver
import PrivilegeModuleDriver
```

--------

### 使用介绍

由于该库是依附于主 Server 的驱动模块，你需要先拥有 `Whooshing` Server 的实例环境。所有的环境配置均通过环境变量进行传入。

##### 注册 Driver 并启动 Server

要加载这个 Driver 并在 Server 启动时识别相关的环境变量，只需要在调用 `Whooshing.make(...)` 的时候，向 `driverKeys` 数组提供相应的 Driver Key：

```swift
import PrivilegeSystemDriver
import PrivilegeModuleDriver
import WhooshingServer

// 1. 初始化主 Server 模块，并注册所需权限系统的驱动
let whooshing = try await Whooshing.make(
    env: .independentDebug([
        // 在独立测试环境下，通过字典传入环境变量
        // 生产环境下，系统会自动读取宿主机的环境变量，用户无需书写 Swift 配置代码
        
        // PrivilegeSystem 相关的环境变量
        "PRIVILEGE_SYSTEM_EOPA_SCHEME": "http",
        "PRIVILEGE_SYSTEM_EOPA_PORT": "8181",
        
        // PrivilegeModule 相关的环境变量
        "PRIVILEGE_MODULE_EOPA_SCHEME": "http",
        "PRIVILEGE_MODULE_EOPA_HOST": "localhost",
        "PRIVILEGE_MODULE_EOPA_PORT": "8181"
    ]), 
    driverKeys: [
        PrivilegeSystemDriverKey.self, // <- 注册 System Driver
        PrivilegeModuleDriverKey.self  // <- 注册 Module Driver
    ]
)
```

##### 初始化并接入权限模块实例

在拥有 `whooshing` 实例后，可直接调用扩展方法对其进行自动接入：

``` swift
import PrivilegeSystem
import PrivilegeModule

// 2. 准备依赖的特定上下文（数据库、日志等）
let db: Environment.DB = ... 
let logger = Logger(label: "Driver-Test")

// 3A. 初始化全局权限系统 PrivilegeSystem
let systemResult = await whooshing.makePrivilegeSystem(
    for: db,
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

// 3B. 初始化业务服务权限模块 PrivilegeModule
let moduleResult: Res<PrivilegeModule<ResourceList>, PrivilegeModuleErrcase> = await whooshing.makePrivilegeModule(
    for: db,
    logger: logger,
    debugging: false
)

switch moduleResult {
case .success(let module):
    print("PrivilegeModule 初始化成功")
case .failure(let error):
    print("初始化失败: \(error)")
}
```

或者使用对应的同步版本（主要用于程序启动阶段的必须依赖项接入，如果发生错误将抛出异常）：

``` swift
let privilegeSystem = whooshing.syncMakePrivilegeSystem(
    for: db,
    logger: logger,
    debugging: false
)

let privilegeModule: PrivilegeModule<ResourceList> = whooshing.syncMakePrivilegeModule(
    for: db,
    logger: logger,
    debugging: false
)
```

-------

### 运行环境

* **macOS** (> 13.0)
* **iOS** (> 16.0)
* **Linux** (> 20)
* **Swift** (> 6.0)
* **watchOS** (> 6.0)
* **tvOS** (> 13.0)

-------

### 注意事项

- 驱动系统高度依赖 `WhooshingServer` 的配置解析管道。确保 `PrivilegeSystemDriverKey.self` 或 `PrivilegeModuleDriverKey.self` 被正确传入 `driverKeys`，否则系统将无法去环境变量中读取相关配置，导致随后调用初始化方法时找不到配置而报错。
- `PrivilegeSystem` 和 `PrivilegeModule` 可以独立存在，您可以根据当前微服务模块的具体需求只引入并挂载其中一个。例如：中心认证服务器可能只需要 `PrivilegeSystem`，而独立业务模块可能只需 `PrivilegeModule`。

如需了解底层完整的权限系统架构、权限判断流程、OPA策略配置说明，请参阅 [whooshing.toolbox-privilege-system 文档](https://github.com/whooshing-workshop/whooshing.toolbox-privilege-system)。

------

### 联系与反馈

如有使用问题或建议，请通过 [GitHub Issues](https://github.com/whooshing-workshop/whooshing.driver-privilege-system/issues) 提交反馈。

或发至邮箱 [contact@official.whooshings.space](mailto:contact@official.whooshings.space)
