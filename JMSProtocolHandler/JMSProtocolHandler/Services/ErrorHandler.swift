import Foundation
import Cocoa

/// 错误处理器实现类，统一处理各种错误类型
class ErrorHandler: ErrorHandlerProtocol {
    private let notificationManager: NotificationManagerProtocol
    private let logger: LoggerProtocol
    
    /// 初始化错误处理器
    /// - Parameters:
    ///   - notificationManager: 通知管理器
    ///   - logger: 日志记录器
    init(notificationManager: NotificationManagerProtocol = NotificationManager(),
         logger: LoggerProtocol = Logger.shared) {
        self.notificationManager = notificationManager
        self.logger = logger
    }
    
    /// 处理JMS错误
    /// - Parameter error: 要处理的错误
    func handleError(_ error: JMSError) {
        // 记录错误日志
        logError(error, context: nil)
        
        // 显示错误通知
        showErrorNotification(error)
    }
    
    /// 显示用户通知
    /// - Parameter message: 通知消息
    func showUserNotification(_ message: String) {
        notificationManager.showInfoNotification(message)
    }
    
    /// 显示错误通知
    /// - Parameter error: 错误对象
    func showErrorNotification(_ error: JMSError) {
        let message = formatErrorMessage(error)
        notificationManager.showErrorNotification(message)
    }
    
    /// 记录错误日志
    /// - Parameters:
    ///   - error: 错误对象
    ///   - context: 错误上下文信息
    func logError(_ error: JMSError, context: String?) {
        let logMessage = formatLogMessage(error, context: context)
        logger.error(logMessage)
    }
    
    // MARK: - Private Methods
    
    /// 格式化错误消息用于用户通知
    /// - Parameter error: 错误对象
    /// - Returns: 格式化的错误消息
    private func formatErrorMessage(_ error: JMSError) -> String {
        var message = error.localizedDescription
        
        if let suggestion = error.recoverySuggestion {
            message += "\n\n建议: \(suggestion)"
        }
        
        return message
    }
    
    /// 格式化日志消息
    /// - Parameters:
    ///   - error: 错误对象
    ///   - context: 错误上下文
    /// - Returns: 格式化的日志消息
    private func formatLogMessage(_ error: JMSError, context: String?) -> String {
        var logMessage = "JMSError: \(error.localizedDescription)"
        
        if let reason = error.failureReason {
            logMessage += " | Reason: \(reason)"
        }
        
        if let context = context {
            logMessage += " | Context: \(context)"
        }
        
        return logMessage
    }
}

/// 日志记录器协议
protocol LoggerProtocol {
    func error(_ message: String)
    func info(_ message: String)
}

/// 简单的日志记录器
class Logger: LoggerProtocol {
    static let shared = Logger()
    
    private init() {}
    
    /// 记录错误日志
    /// - Parameter message: 日志消息
    func error(_ message: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        print("[\(timestamp)] ERROR: \(message)")
        
        // 在实际应用中，这里可以写入到文件或发送到日志服务
        // 目前使用控制台输出用于调试
    }
    
    /// 记录信息日志
    /// - Parameter message: 日志消息
    func info(_ message: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        print("[\(timestamp)] INFO: \(message)")
    }
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}