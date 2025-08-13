import Foundation
import Cocoa
import JMSCore
import JMSRDPModule
import JMSSSHModule

// 创建应用程序实例
let app = NSApplication.shared

// 设置应用程序委托
let delegate = AppDelegate()
app.delegate = delegate

// 确保应用程序正确初始化
app.setActivationPolicy(.regular)

print("🚀 启动JMS Protocol Handler...")

// 运行应用程序
app.run()
