// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JMSProtocolHandler",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // 主应用程序
        .executable(
            name: "JMSProtocolHandler",
            targets: ["JMSProtocolHandler"]
        ),
        // 核心服务库 (合并后)
        .library(
            name: "JMSCore",
            targets: ["JMSCore"]
        ),
        // RDP模块
        .library(
            name: "JMSRDPModule",
            targets: ["JMSRDPModule"]
        ),
        // SSH模块
        .library(
            name: "JMSSSHModule", 
            targets: ["JMSSSHModule"]
        ),
        // JMS协议管理模块
        .library(
            name: "JMSProtocolManager",
            targets: ["JMSProtocolManager"]
        ),
        // UI检查器模块
        .library(
            name: "UIInspector",
            targets: ["UIInspector"]
        )
    ],
    dependencies: [
        // 这里可以添加外部依赖
    ],
    targets: [
        // 主应用程序目标
        .executableTarget(
            name: "JMSProtocolHandler",
            dependencies: [
                "JMSCore",
                "JMSRDPModule", 
                "JMSSSHModule",
                "JMSProtocolManager",
                "UIInspector"
            ],
            path: "Sources/JMSProtocolHandler",
            exclude: [
                "Resources/Info.plist",
                "Resources/JMSProtocolHandler.entitlements"
            ],
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        ),
        
        // 核心服务模块 - 包含数据模型和基础服务 (合并后)
        .target(
            name: "JMSCore",
            dependencies: [],
            path: "Sources/JMSCore"
        ),
        
        // RDP模块 - RDP相关功能
        .target(
            name: "JMSRDPModule",
            dependencies: ["JMSCore"],
            path: "Sources/JMSRDPModule"
        ),
        
        // SSH模块 - SSH相关功能
        .target(
            name: "JMSSSHModule", 
            dependencies: ["JMSCore"],
            path: "Sources/JMSSSHModule"
        ),
        
        // JMS协议管理模块 - 协议检测和注册功能
        .target(
            name: "JMSProtocolManager",
            dependencies: ["JMSCore", "UIInspector"],
            path: "Sources/JMSProtocolManager"
        ),
        
        // UI检查器模块 - 通用GUI界面调试工具
        .target(
            name: "UIInspector",
            dependencies: ["JMSCore"],
            path: "Sources/UIInspector"
        ),
        
        // 测试目标
        .testTarget(
            name: "JMSCoreTests",
            dependencies: ["JMSCore"],
            path: "Tests/JMSCoreTests"
        ),
        .testTarget(
            name: "JMSRDPModuleTests",
            dependencies: ["JMSRDPModule", "JMSCore"],
            path: "Tests/JMSRDPModuleTests"
        ),
        .testTarget(
            name: "JMSSSHModuleTests",
            dependencies: ["JMSSSHModule", "JMSCore"],
            path: "Tests/JMSSSHModuleTests"
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["JMSCore", "JMSRDPModule", "JMSSSHModule"],
            path: "Tests/IntegrationTests"
        )
    ]
)
