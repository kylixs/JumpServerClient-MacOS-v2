import Foundation
import UserNotifications
import Cocoa

/// 通知管理器实现类，管理用户通知
class NotificationManager: NSObject, NotificationManagerProtocol {
    
    override init() {
        super.init()
        requestNotificationPermission()
    }
    
    /// 显示成功通知
    /// - Parameter message: 通知消息
    func showSuccessNotification(_ message: String) {
        showNotification(title: "JMS Protocol Handler", 
                        message: message, 
                        type: .success)
    }
    
    /// 显示错误通知
    /// - Parameter message: 错误消息
    func showErrorNotification(_ message: String) {
        showNotification(title: "JMS Protocol Handler - 错误", 
                        message: message, 
                        type: .error)
    }
    
    /// 显示信息通知
    /// - Parameter message: 信息消息
    func showInfoNotification(_ message: String) {
        showNotification(title: "JMS Protocol Handler", 
                        message: message, 
                        type: .info)
    }
    
    /// 显示警告通知
    /// - Parameter message: 警告消息
    func showWarningNotification(_ message: String) {
        showNotification(title: "JMS Protocol Handler - 警告", 
                        message: message, 
                        type: .warning)
    }
    
    // MARK: - Private Methods
    
    /// 通知类型枚举
    private enum NotificationType {
        case success
        case error
        case info
        case warning
        
        var soundName: UNNotificationSoundName {
            switch self {
            case .success:
                return .default
            case .error:
                return .defaultCritical
            case .info:
                return .default
            case .warning:
                return .default
            }
        }
    }
    
    /// 显示通知
    /// - Parameters:
    ///   - title: 通知标题
    ///   - message: 通知消息
    ///   - type: 通知类型
    private func showNotification(title: String, message: String, type: NotificationType) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = type.soundName
        
        // 添加类别标识符用于区分不同类型的通知
        switch type {
        case .success:
            content.categoryIdentifier = "SUCCESS_CATEGORY"
        case .error:
            content.categoryIdentifier = "ERROR_CATEGORY"
        case .info:
            content.categoryIdentifier = "INFO_CATEGORY"
        case .warning:
            content.categoryIdentifier = "WARNING_CATEGORY"
        }
        
        // 创建通知请求
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        // 发送通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error.localizedDescription)")
                // 如果用户通知失败，回退到使用NSAlert
                DispatchQueue.main.async {
                    self.showAlertFallback(title: title, message: message, type: type)
                }
            }
        }
    }
    
    /// 回退到使用NSAlert显示通知
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息
    ///   - type: 类型
    private func showAlertFallback(title: String, message: String, type: NotificationType) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        
        switch type {
        case .success:
            alert.alertStyle = .informational
        case .error:
            alert.alertStyle = .critical
        case .info:
            alert.alertStyle = .informational
        case .warning:
            alert.alertStyle = .warning
        }
        
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    /// 请求通知权限
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Failed to request notification permission: \(error.localizedDescription)")
            }
            
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
        
        // 设置通知类别
        setupNotificationCategories()
    }
    
    /// 设置通知类别
    private func setupNotificationCategories() {
        let successCategory = UNNotificationCategory(
            identifier: "SUCCESS_CATEGORY",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        let errorCategory = UNNotificationCategory(
            identifier: "ERROR_CATEGORY",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        let infoCategory = UNNotificationCategory(
            identifier: "INFO_CATEGORY",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        let warningCategory = UNNotificationCategory(
            identifier: "WARNING_CATEGORY",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            successCategory,
            errorCategory,
            infoCategory,
            warningCategory
        ])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// 当应用程序在前台时显示通知
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 在前台显示通知
        completionHandler([.alert, .sound])
    }
    
    /// 处理用户点击通知的响应
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        // 处理通知响应
        print("User responded to notification: \(response.notification.request.identifier)")
        completionHandler()
    }
}