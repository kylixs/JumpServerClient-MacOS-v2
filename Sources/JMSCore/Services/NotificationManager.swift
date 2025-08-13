import Foundation
import Cocoa

/// 用户通知管理服务
public class NotificationManager {
    
    public static let shared = NotificationManager()
    
    private var isTestEnvironment: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
               ProcessInfo.processInfo.arguments.contains { $0.contains("xctest") }
    }
    
    private init() {
        // 在测试环境中不初始化通知系统
        if !isTestEnvironment {
            requestNotificationPermission()
        }
    }
    
    /// 显示成功通知
    /// - Parameters:
    ///   - title: 通知标题
    ///   - message: 通知内容
    public func showSuccessNotification(title: String, message: String) {
        showNotification(title: title, message: message, type: .success)
    }
    
    /// 显示错误通知
    /// - Parameter error: JMS错误
    public func showErrorNotification(_ error: JMSError) {
        let title = "连接失败"
        let message = error.localizedDescription
        showNotification(title: title, message: message, type: .error)
    }
    
    /// 显示信息通知
    /// - Parameters:
    ///   - title: 通知标题
    ///   - message: 通知内容
    public func showInfoNotification(title: String, message: String) {
        showNotification(title: title, message: message, type: .info)
    }
    
    /// 显示RDP连接成功通知
    /// - Parameter connectionInfo: RDP连接信息
    public func showRDPConnectionSuccess(_ connectionInfo: RDPConnectionInfo) {
        let title = "RDP连接已建立"
        let message = "已成功连接到 \(connectionInfo.serverAddress)"
        showSuccessNotification(title: title, message: message)
    }
    
    /// 显示SSH连接成功通知
    /// - Parameter connectionInfo: SSH连接信息
    public func showSSHConnectionSuccess(_ connectionInfo: SSHConnectionInfo) {
        let title = "SSH连接已建立"
        let message = "已成功连接到 \(connectionInfo.ip):\(connectionInfo.port)"
        showSuccessNotification(title: title, message: message)
    }
    
    /// 显示显示器优化通知
    /// - Parameter displayConfig: 显示器配置
    public func showDisplayOptimizationNotification(_ displayConfig: DisplayConfiguration) {
        let title = "显示器配置已优化"
        let message = "已为 \(displayConfig.resolutionString) \(displayConfig.densityType.description) 优化RDP设置"
        showInfoNotification(title: title, message: message)
    }
    
    // MARK: - Private Methods
    
    private enum NotificationType {
        case success
        case error
        case info
        
        var iconName: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "xmark.circle.fill"
            case .info:
                return "info.circle.fill"
            }
        }
    }
    
    private func showNotification(title: String, message: String, type: NotificationType) {
        // 在测试环境中，只打印通知信息
        if isTestEnvironment {
            print("通知 [\(type)]: \(title) - \(message)")
            return
        }
        
        // 在正常环境中显示通知
        showLegacyNotification(title: title, message: message)
    }
    
    private func showLegacyNotification(title: String, message: String) {
        DispatchQueue.main.async {
            let notification = NSUserNotification()
            notification.title = title
            notification.informativeText = message
            notification.soundName = NSUserNotificationDefaultSoundName
            
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
    
    private func requestNotificationPermission() {
        // 在正常环境中请求通知权限
        print("通知权限已请求")
    }
}
