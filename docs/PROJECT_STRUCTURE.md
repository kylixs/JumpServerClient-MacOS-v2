# JMS Protocol Handler 项目目录结构

## 📁 项目根目录结构

```
jumpserver-client/
├── JMSProtocolHandler/                 # 主项目源代码
│   ├── JMSProtocolHandler/            # 应用程序源代码
│   │   ├── Models/                    # 数据模型
│   │   ├── Services/                  # 服务实现
│   │   ├── Protocols/                 # 协议定义
│   │   └── AppDelegate.swift          # 主应用控制器
│   ├── Tests/                         # 单元测试
│   ├── build/                         # Xcode构建产物 (自动生成)
│   ├── .build/                        # Swift Package构建产物 (自动生成)
│   └── JMSProtocolHandler.xcodeproj   # Xcode项目文件
├── build/                             # 项目构建文件
│   ├── objects/                       # 编译对象文件 (.o)
│   ├── temp/                          # 临时构建文件
│   └── artifacts/                     # 构建产物
├── docs/                              # 项目文档
├── scripts/                           # 脚本文件
├── tests/                             # 测试文件
├── JMSProtocolHandler.app             # 构建的应用程序
├── JMS-Protocol-Handler-Distribution/ # 分发包
├── JMS-Protocol-Handler-v1.0.0.dmg   # 安装包
└── .gitignore                         # Git忽略文件配置
```

## 📚 docs/ - 文档目录

### docs/implementation/ - 实现文档
- `task5_implementation_summary.md` - 任务5实现总结
- `task6_implementation_summary.md` - 任务6实现总结
- `task7_implementation_summary.md` - 任务7实现总结
- `task8_implementation_summary.md` - 任务8实现总结
- `task9_implementation_summary.md` - 任务9实现总结
- `PROJECT_COMPLETION_SUMMARY.md` - 项目完成总结
- `FINAL_PROJECT_REPORT.md` - 最终项目报告

### docs/user-guide/ - 用户指南
- `JMS_PROTOCOL_REGISTRATION_GUIDE.md` - 协议注册指南
- `安装说明.txt` - 安装说明
- `用户手册.txt` - 用户手册
- `故障排除指南.txt` - 故障排除指南

### docs/testing/ - 测试文档
- 测试计划和测试报告
- 性能测试结果
- 兼容性测试报告

### docs/deployment/ - 部署文档
- 部署指南
- 打包说明
- 发布流程

## 🏗️ build/ - 构建文件目录

### build/objects/ - 编译对象文件
包含编译过程中生成的 .o 文件（目标文件）。

### build/temp/ - 临时文件
存放构建过程中的临时文件和中间产物。

### build/artifacts/ - 构建产物
存放最终的构建产物，如编译后的库文件、可执行文件等。

## 🔧 scripts/ - 脚本目录

### scripts/build/ - 构建脚本
- `create_dmg.sh` - DMG创建脚本
- `create_pkg.sh` - PKG创建脚本
- `clean.sh` - 构建文件清理脚本
- 其他构建相关脚本

### scripts/deployment/ - 部署脚本
- `register_jms_protocol.sh` - 协议注册脚本
- `deploy_package.swift` - 部署打包脚本
- `卸载脚本.sh` - 应用程序卸载脚本

### scripts/test/ - 测试脚本
- `test_jms_protocol.sh` - 协议测试脚本
- 其他测试辅助脚本

## 🧪 tests/ - 测试目录

### tests/unit/ - 单元测试
- `validate_connection_info_extractor.swift` - 连接信息提取器验证
- 其他单元测试文件

### tests/integration/ - 集成测试
- `test_app_delegate_integration.swift` - AppDelegate集成测试
- `test_complete_workflow_fixed.swift` - 完整工作流程测试
- `test_data_models.swift` - 数据模型测试
- `test_error_handling_integration.swift` - 错误处理集成测试
- `test_integration_e2e.swift` - 端到端集成测试
- `test_integration_e2e_complete.swift` - 完整集成测试
- `test_models.swift` - 模型测试
- `test_performance_compatibility.swift` - 性能兼容性测试
- `test_real_integration.swift` - 真实集成测试
- `test_remote_desktop_integrator.swift` - Remote Desktop集成测试

### tests/e2e/ - 端到端测试
- 端到端测试场景
- 用户流程测试

## 🏗️ JMSProtocolHandler/ - 主项目

### 源代码结构
```
JMSProtocolHandler/
├── JMSProtocolHandler/
│   ├── Models/                        # 数据模型
│   │   ├── JMSError.swift            # 错误定义
│   │   ├── JMSConfig.swift           # 配置模型
│   │   ├── ConnectionInfo.swift      # 连接信息模型
│   │   └── JMSURLComponents.swift    # URL组件模型
│   ├── Protocols/                     # 协议定义
│   │   ├── URLParserProtocol.swift
│   │   ├── PayloadDecoderProtocol.swift
│   │   ├── ConnectionInfoExtractorProtocol.swift
│   │   ├── RemoteDesktopIntegratorProtocol.swift
│   │   ├── ErrorHandlerProtocol.swift
│   │   └── NotificationManagerProtocol.swift
│   ├── Services/                      # 服务实现
│   │   ├── URLParser.swift
│   │   ├── PayloadDecoder.swift
│   │   ├── ConnectionInfoExtractor.swift
│   │   ├── RemoteDesktopIntegrator.swift
│   │   ├── ErrorHandler.swift
│   │   └── NotificationManager.swift
│   ├── AppDelegate.swift              # 主应用控制器
│   ├── Info.plist                     # 应用配置
│   └── Assets.xcassets               # 资源文件
├── Tests/                             # 单元测试
└── JMSProtocolHandler.xcodeproj       # Xcode项目
```

## 📦 分发文件

### JMS-Protocol-Handler-Distribution/
- `JMSProtocolHandler.app` - 应用程序
- `README.md` - 用户说明
- `VERSION.txt` - 版本信息

### 安装包
- `JMS-Protocol-Handler-v1.0.0.dmg` - macOS安装包

## 📋 文件分类说明

### 📄 文档文件 (.md, .txt)
- **实现文档**: 开发过程中的技术实现总结
- **用户文档**: 面向最终用户的使用指南
- **测试文档**: 测试计划、结果和报告

### 🔧 脚本文件 (.sh, .swift)
- **构建脚本**: 用于构建和打包应用程序
- **部署脚本**: 用于部署和安装应用程序
- **测试脚本**: 用于自动化测试和验证

### 🧪 测试文件 (.swift)
- **单元测试**: 测试单个组件的功能
- **集成测试**: 测试组件间的协作
- **端到端测试**: 测试完整的用户流程

### 📱 应用程序文件
- **源代码**: Swift源文件和项目配置
- **构建产物**: 编译后的应用程序
- **分发包**: 用户可安装的软件包

## 🔍 快速导航

### 开发者
- 源代码: `JMSProtocolHandler/JMSProtocolHandler/`
- 实现文档: `docs/implementation/`
- 测试文件: `tests/`

### 用户
- 用户指南: `docs/user-guide/`
- 应用程序: `JMSProtocolHandler.app`
- 安装包: `JMS-Protocol-Handler-v1.0.0.dmg`

### 部署人员
- 部署脚本: `scripts/deployment/`
- 构建脚本: `scripts/build/`
- 部署文档: `docs/deployment/`

## 📝 维护说明

### 添加新文档
- 实现文档 → `docs/implementation/`
- 用户文档 → `docs/user-guide/`
- 测试文档 → `docs/testing/`

### 添加新脚本
- 构建脚本 → `scripts/build/`
- 部署脚本 → `scripts/deployment/`
- 测试脚本 → `scripts/test/`

### 添加新测试
- 单元测试 → `tests/unit/`
- 集成测试 → `tests/integration/`
- 端到端测试 → `tests/e2e/`

---
**目录结构版本**: 1.0  
**最后更新**: 2025-07-25  
**维护者**: JMS Protocol Handler Team
