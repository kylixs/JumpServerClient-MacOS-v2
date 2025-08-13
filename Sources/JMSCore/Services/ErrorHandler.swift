import Foundation
import Cocoa

/// 统一错误处理服务
public class ErrorHandler {
    
    public static let shared = ErrorHandler()
    
    private init() {}
    
    /// 处理错误并显示用户友好的提示
    /// - Parameters:
    ///   - error: 要处理的错误
    ///   - context: 错误发生的上下文
    ///   - showAlert: 是否显示警告对话框
    public func handleError(_ error: Error, context: String = "", showAlert: Bool = true) {
        let jmsError = convertToJMSError(error)
        
        // 记录错误日志
        logError(jmsError, context: context)
        
        // 显示用户提示
        if showAlert {
            showErrorAlert(jmsError, context: context)
        }
        
        // 发送通知
        NotificationManager.shared.showErrorNotification(jmsError)
    }
    
    /// 处理JMS特定错误
    /// - Parameters:
    ///   - jmsError: JMS错误
    ///   - context: 错误上下文
    ///   - showAlert: 是否显示警告对话框
    public func handleJMSError(_ jmsError: JMSError, context: String = "", showAlert: Bool = true) {
        handleError(jmsError, context: context, showAlert: showAlert)
    }
    
    /// 记录错误信息
    /// - Parameters:
    ///   - error: 错误对象
    ///   - context: 错误上下文
    public func logError(_ error: JMSError, context: String = "") {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let contextInfo = context.isEmpty ? "" : " [Context: \(context)]"
        let logMessage = "[\(timestamp)] ERROR: \(error.localizedDescription)\(contextInfo)"
        
        // 输出到控制台
        print(logMessage)
        
        // 可以扩展到文件日志
        // writeToLogFile(logMessage)
    }
    
    /// 显示错误警告对话框
    /// - Parameters:
    ///   - error: JMS错误
    ///   - context: 错误上下文
    public func showErrorAlert(_ error: JMSError, context: String = "") {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "JMS协议处理错误"
            alert.informativeText = error.localizedDescription
            
            if let suggestion = error.recoverySuggestion {
                alert.informativeText += "\n\n建议: \(suggestion)"
            }
            
            if !context.isEmpty {
                alert.informativeText += "\n\n上下文: \(context)"
            }
            
            alert.alertStyle = .warning
            alert.addButton(withTitle: "确定")
            
            // 如果有可恢复的建议，添加帮助按钮
            if error.recoverySuggestion != nil {
                alert.addButton(withTitle: "获取帮助")
            }
            
            let response = alert.runModal()
            
            if response == .alertSecondButtonReturn {
                self.showHelpForError(error)
            }
        }
    }
    
    /// 显示错误相关的帮助信息
    /// - Parameter error: JMS错误
    public func showHelpForError(_ error: JMSError) {
        let helpURL: String
        
        switch error {
        case .remoteDesktopNotFound:
            helpURL = "https://apps.apple.com/app/microsoft-remote-desktop/id1295203466"
        case .terminalNotFound:
            helpURL = "https://iterm2.com/"
        case .displayDetectionFailed:
            helpURL = "https://support.apple.com/guide/mac-help/mchlp2281/mac"
        default:
            helpURL = "https://github.com/your-repo/jms-protocol-handler/wiki/troubleshooting"
        }
        
        if let url = URL(string: helpURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Private Methods
    
    private func convertToJMSError(_ error: Error) -> JMSError {
        if let jmsError = error as? JMSError {
            return jmsError
        } else {
            return JMSError.configurationError(error.localizedDescription)
        }
    }
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}
