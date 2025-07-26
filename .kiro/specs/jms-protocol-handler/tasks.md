# Implementation Plan

- [x] 1. 创建macOS应用程序项目结构和基础配置
  - 创建新的macOS应用程序项目，配置Swift 5.0+和Cocoa框架
  - 设置Info.plist文件注册jms://协议处理
  - 配置应用程序基本属性和权限
  - 创建基础的目录结构和文件组织
  - _Requirements: 3.1, 3.2, 5.1_

- [x] 2. 实现数据模型和协议定义
  - 创建JMSConfig、ConnectionInfo等核心数据结构
  - 定义各个模块的协议接口
  - 实现JMSError错误枚举和错误处理协议
  - 编写数据模型的单元测试
  - _Requirements: 1.3, 4.1, 4.2, 4.3, 4.4_

- [x] 3. 实现URL解析和验证模块
  - 创建URLParser类实现URL格式验证
  - 实现jms://协议的URL解析逻辑
  - 提取base64编码的payload部分
  - 编写URL解析的单元测试，包括各种边界情况
  - _Requirements: 1.1, 1.2, 4.1_

- [x] 4. 实现Base64解码和JSON解析模块
  - 创建PayloadDecoder类实现base64解码功能
  - 实现JSON配置信息的解析逻辑
  - 添加解码失败和JSON格式错误的处理
  - 编写解码模块的单元测试，验证解码准确性
  - _Requirements: 1.2, 1.3, 4.2, 4.3_

- [x] 5. 实现连接信息提取模块
  - 创建ConnectionInfoExtractor类解析config字符串
  - 实现"full address:s:"和"username:s:"的提取逻辑
  - 解析其他RDP配置参数（session bpp、audiomode等）
  - 编写连接信息提取的单元测试
  - _Requirements: 1.4, 1.5, 4.4_

- [x] 6. 实现错误处理和用户通知系统
  - 创建ErrorHandler类统一处理各种错误类型
  - 实现NotificationManager管理用户通知
  - 为每种错误类型提供用户友好的消息
  - 编写错误处理的单元测试
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 7. 实现Microsoft Remote Desktop集成模块
  - 创建RemoteDesktopIntegrator类检查应用程序可用性
  - 实现RDP配置文件的生成逻辑
  - 使用NSWorkspace API启动Microsoft Remote Desktop
  - 实现临时文件管理和清理机制
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 8. 更新主应用程序控制器集成所有模块
  - 更新AppDelegate集成URLParser和PayloadDecoder
  - 集成ConnectionInfoExtractor和ErrorHandler
  - 实现完整的URL处理工作流程
  - 协调各个模块的工作流程和错误处理
  - _Requirements: 3.3, 3.4_

- [x] 9. 集成所有模块并实现完整工作流程
  - 将所有模块集成到主应用程序中
  - 实现从URL接收到Remote Desktop启动的完整流程
  - 添加流程中的错误处理和状态管理
  - 确保各模块间的正确数据传递
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4_

- [x] 10. 编写集成测试和端到端测试
  - 创建完整流程的集成测试用例
  - 测试各种URL格式和配置组合
  - 验证与Microsoft Remote Desktop的实际集成
  - 测试错误场景和异常处理
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 11. 性能优化和macOS M4兼容性验证
  - 优化应用程序启动时间（目标3秒内）
  - 优化URL处理性能（目标1秒内）
  - 验证在macOS M4芯片上的运行效果
  - 进行内存使用和CPU性能测试
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 12. 应用程序打包和部署准备
  - 配置应用程序签名和公证
  - 创建应用程序安装包
  - 编写用户安装和使用说明
  - 测试在全新macOS系统上的安装和运行
  - _Requirements: 3.1, 3.2, 5.5_