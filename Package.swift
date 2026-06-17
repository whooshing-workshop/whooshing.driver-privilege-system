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
        .package(url: "https://github.com/whooshing-workshop/whooshing.toolbox-server.git", from: "1.2.5"),
        .package(url: "https://github.com/whooshing-workshop/whooshing.toolbox-privilege-system", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.9.1")
    ],
    targets: [
        .target(
            name: "PrivilegeSystemDriver",
            dependencies: [
                .product(name: "WhooshingServer", package: "whooshing.toolbox-server"),
                .product(name: "PrivilegeSystem", package: "whooshing.toolbox-privilege-system"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .target(
            name: "PrivilegeModuleDriver",
            dependencies: [
                .product(name: "WhooshingServer", package: "whooshing.toolbox-server"),
                .product(name: "PrivilegeModule", package: "whooshing.toolbox-privilege-system"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "privilege-system-driver-Tests",
            dependencies: [
                .target(name: "PrivilegeSystemDriver"),
                .product(name: "WhooshingServer", package: "whooshing.toolbox-server")
            ]
        ),
        .testTarget(
            name: "privilege-module-driver-Tests",
            dependencies: [
                .target(name: "PrivilegeModuleDriver"),
                .product(name: "WhooshingServer", package: "whooshing.toolbox-server")
            ]
        )
    ]
)
