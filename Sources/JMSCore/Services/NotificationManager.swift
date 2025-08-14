import Foundation
import Cocoa
import UserNotifications

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
            // 使用现代的UserNotifications框架
            if #available(macOS 10.14, *) {
                self.showModernNotification(title: title, message: message)
            } else {
                // 对于macOS 10.14以下的系统，使用简单的控制台输出
                // 因为这些系统版本已经很少使用，且项目最低支持版本是macOS 10.15
                print("通知: \(title) - \(message)")
            }
        }
    }
    
    @available(macOS 10.14, *)
    private func showModernNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知发送失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func requestNotificationPermission() {
        // 使用现代的UserNotifications框架请求权限
        if #available(macOS 10.14, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("通知权限请求失败: \(error.localizedDescription)")
                } else if granted {
                    print("通知权限已授予")
                } else {
                    print("通知权限被拒绝")
                }
            }
        } else {
            // 对于不支持UserNotifications的旧系统，简单记录
            print("通知权限已请求（系统版本过低，使用控制台输出）")
        }
    }
}
