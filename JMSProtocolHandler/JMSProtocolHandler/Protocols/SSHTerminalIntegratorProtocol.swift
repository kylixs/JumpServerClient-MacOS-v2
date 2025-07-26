import Foundation

/// 终端应用程序类型枚举
enum TerminalApp {
    /// iTerm2终端
    case iterm2
    
    /// 系统默认Terminal
    case terminal
    
    /// 无可用终端
    case unavailable
    
    /// 获取应用程序Bundle ID
    var bundleIdentifier: String? {
        switch self {
        case .iterm2:
            return "com.googlecode.iterm2"
        case .terminal:
            return "com.apple.Terminal"
        case .unavailable:
            return nil
        }
    }
    
    /// 获取应用程序显示名称
    var displayName: String {
        switch self {
        case .iterm2:
            return "iTerm2"
        case .terminal:
            return "Terminal"
        case .unavailable:
            return "无可用终端"
        }
    }
    
    /// 获取应用程序路径
    var applicationPath: String? {
        switch self {
        case .iterm2:
            return "/Applications/iTerm.app"
        case .terminal:
            return "/System/Applications/Utilities/Terminal.app"
        case .unavailable:
            return nil
        }
    }
}

/// SSH终端集成器协议
/// 负责检测终端应用程序、构建SSH命令并启动SSH会话
protocol SSHTerminalIntegratorProtocol {
    /// 启动SSH会话
    /// - Parameter connectionInfo: SSH连接信息
    /// - Throws: JMSError 如果启动失败
    func launchSSHSession(with connectionInfo: SSHConnectionInfo) throws
    
    /// 检测可用的终端应用程序
    /// - Returns: 可用的终端应用程序类型
    func detectAvailableTerminal() -> TerminalApp
    
    /// 构建SSH连接命令
    /// - Parameter connectionInfo: SSH连接信息
    /// - Returns: 完整的SSH命令字符串
    func buildSSHCommand(from connectionInfo: SSHConnectionInfo) -> String
    
    /// 检查expect工具是否可用
    /// - Returns: true如果expect工具可用，否则false
    func checkExpectAvailability() -> Bool
    
    /// 通过iTerm2启动SSH会话
    /// - Parameter command: SSH命令
    /// - Throws: JMSError 如果启动失败
    func launchITerm2WithSSH(command: String) throws
    
    /// 通过Terminal启动SSH会话
    /// - Parameter command: SSH命令
    /// - Throws: JMSError 如果启动失败
    func launchTerminalWithSSH(command: String) throws
    
    /// 验证终端应用程序是否可用
    /// - Parameter terminalApp: 终端应用程序类型
    /// - Returns: true如果应用程序可用，否则false
    func isTerminalAppAvailable(_ terminalApp: TerminalApp) -> Bool
}
