// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "whooshing.driver-privilege-system",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library( name: "PrivilegeSystemDriver", targets: ["PrivilegeSystemDriver"] ),
        .library( name: "PrivilegeModuleDriver", targets: ["PrivilegeModuleDriver"] )
    ],
    dependencies: [
        .package(url: "https://github.com/whooshing-workshop/whooshing.toolbox-server.git", from: "1.3.0"),
        .package(url: "https://github.com/whooshing-workshop/whooshing.toolbox-privilege-system", from: "1.0.6")
    ],
    targets: [
        .target(
            name: "PrivilegeShared",
            dependencies: [
                .product(name: "WhooshingServer", package: "whooshing.toolbox-server"),
                .product(name: "PrivilegeModuleExtended", package: "whooshing.toolbox-privilege-system")
            ]
        ),
        .target(
            name: "PrivilegeModuleDriver",
            dependencies: [
                .target(name: "PrivilegeShared")
            ]
        ),
        .target(
            name: "PrivilegeSystemDriver",
            dependencies: [
                .target(name: "PrivilegeShared"),
                .product(name: "PrivilegeSystem", package: "whooshing.toolbox-privilege-system")
            ]
        ),
        .testTarget(
            name: "privilege-system-driver-Tests",
            dependencies: [
                .target(name: "PrivilegeSystemDriver")
            ]
        ),
        .testTarget(
            name: "privilege-module-driver-Tests",
            dependencies: [
                .target(name: "PrivilegeModuleDriver")
            ]
        )
    ]
)
