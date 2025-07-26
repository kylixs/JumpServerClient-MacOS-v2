import Foundation

/// 错误处理器协议，定义错误处理和用户通知的接口
protocol ErrorHandlerProtocol {
    /// 处理JMS错误
    /// - Parameter error: 要处理的错误
    func handleError(_ error: JMSError)
    
    /// 显示用户通知
    /// - Parameter message: 通知消息
    func showUserNotification(_ message: String)
    
    /// 显示错误通知
    /// - Parameter error: 错误对象
    func showErrorNotification(_ error: JMSError)
    
    /// 记录错误日志
    /// - Parameters:
    ///   - error: 错误对象
    ///   - context: 错误上下文信息
    func logError(_ error: JMSError, context: String?)
}

/// 通知管理器协议，定义用户通知管理的接口
protocol NotificationManagerProtocol {
    /// 显示成功通知
    /// - Parameter message: 通知消息
    func showSuccessNotification(_ message: String)
    
    /// 显示错误通知
    /// - Parameter message: 错误消息
    func showErrorNotification(_ message: String)
    
    /// 显示信息通知
    /// - Parameter message: 信息消息
    func showInfoNotification(_ message: String)
}