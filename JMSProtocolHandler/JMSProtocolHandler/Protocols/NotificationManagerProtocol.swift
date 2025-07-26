import Foundation

/// 通知管理器协议，定义用户通知相关的接口
protocol NotificationManagerProtocol {
    /// 显示成功通知
    /// - Parameter message: 成功消息
    func showSuccessNotification(_ message: String)
    
    /// 显示错误通知
    /// - Parameter message: 错误消息
    func showErrorNotification(_ message: String)
    
    /// 显示信息通知
    /// - Parameter message: 信息消息
    func showInfoNotification(_ message: String)
}