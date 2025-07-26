import Foundation
import Cocoa

/// SSH终端集成器实现
/// 负责检测终端应用程序、构建SSH命令并启动SSH会话
class SSHTerminalIntegrator: SSHTerminalIntegratorProtocol {
    
    /// 启动SSH会话
    /// - Parameter connectionInfo: SSH连接信息
    /// - Throws: JMSError 如果启动失败
    func launchSSHSession(with connectionInfo: SSHConnectionInfo) throws {
        // 验证连接信息
        try connectionInfo.validate()
        
        // 检测可用的终端应用程序
        let terminalApp = detectAvailableTerminal()
        
        // 构建SSH命令
        let sshCommand = buildSSHCommand(from: connectionInfo)
        
        // 根据终端类型启动SSH会话
        switch terminalApp {
        case .iterm2:
            try launchITerm2WithSSH(command: sshCommand)
        case .terminal:
            try launchTerminalWithSSH(command: sshCommand)
        case .unavailable:
            throw JMSError.terminalNotAvailable
        }
    }
    
    /// 检测可用的终端应用程序
    /// - Returns: 可用的终端应用程序类型
    func detectAvailableTerminal() -> TerminalApp {
        let workspace = NSWorkspace.shared
        
        // 优先检测 iTerm2
        if isTerminalAppAvailable(.iterm2) {
            return .iterm2
        }
        
        // 检测系统默认 Terminal
        if isTerminalAppAvailable(.terminal) {
            return .terminal
        }
        
        return .unavailable
    }
    
    /// 构建SSH连接命令
    /// - Parameter connectionInfo: SSH连接信息
    /// - Returns: 完整的SSH命令字符串
    func buildSSHCommand(from connectionInfo: SSHConnectionInfo) -> String {
        if checkExpectAvailability() {
            // 使用expect脚本自动输入密码
            return buildExpectSSHCommand(from: connectionInfo)
        } else {
            // 使用基本SSH命令，需要手动输入密码
            return buildBasicSSHCommand(from: connectionInfo)
        }
    }
    
    /// 检查expect工具是否可用
    /// - Returns: true如果expect工具可用，否则false
    func checkExpectAvailability() -> Bool {
        let process = Process()
        process.launchPath = "/usr/bin/which"
        process.arguments = ["expect"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    /// 通过iTerm2启动SSH会话
    /// - Parameter command: SSH命令
    /// - Throws: JMSError 如果启动失败
    func launchITerm2WithSSH(command: String) throws {
        let escapedCommand = command.replacingOccurrences(of: "\"", with: "\\\"")
        
        let appleScript = """
        tell application "iTerm"
            activate
            create window with default profile
            tell current session of current window
                write text "\(escapedCommand)"
            end tell
        end tell
        """
        
        try executeAppleScript(appleScript)
    }
    
    /// 通过Terminal启动SSH会话
    /// - Parameter command: SSH命令
    /// - Throws: JMSError 如果启动失败
    func launchTerminalWithSSH(command: String) throws {
        let escapedCommand = command.replacingOccurrences(of: "\"", with: "\\\"")
        
        let appleScript = """
        tell application "Terminal"
            activate
            do script "\(escapedCommand)"
        end tell
        """
        
        try executeAppleScript(appleScript)
    }
    
    /// 验证终端应用程序是否可用
    /// - Parameter terminalApp: 终端应用程序类型
    /// - Returns: true如果应用程序可用，否则false
    func isTerminalAppAvailable(_ terminalApp: TerminalApp) -> Bool {
        guard let bundleId = terminalApp.bundleIdentifier else {
            return false
        }
        
        let workspace = NSWorkspace.shared
        
        // 检查应用程序是否存在
        if let _ = workspace.urlForApplication(withBundleIdentifier: bundleId) {
            return true
        }
        
        // 检查应用程序路径是否存在
        if let appPath = terminalApp.applicationPath {
            return FileManager.default.fileExists(atPath: appPath)
        }
        
        return false
    }
    
    // MARK: - Private Methods
    
    /// 构建使用expect的SSH命令
    /// - Parameter connectionInfo: SSH连接信息
    /// - Returns: expect脚本命令
    private func buildExpectSSHCommand(from connectionInfo: SSHConnectionInfo) -> String {
        let escapedPassword = connectionInfo.password.replacingOccurrences(of: "\"", with: "\\\"")
        
        let expectScript = """
        expect -c "
        set timeout 30
        spawn ssh -p \(connectionInfo.port) \(connectionInfo.username)@\(connectionInfo.ip)
        expect {
            \\"*password*\\" {
                send \\"\(escapedPassword)\\r\\"
                exp_continue
            }
            \\"*yes/no*\\" {
                send \\"yes\\r\\"
                exp_continue
            }
            \\"*$\\" {
                interact
            }
            timeout {
                puts \\"连接超时\\"
                exit 1
            }
            eof {
                puts \\"连接已断开\\"
                exit 0
            }
        }
        "
        """
        
        return expectScript
    }
    
    /// 构建基本SSH命令
    /// - Parameter connectionInfo: SSH连接信息
    /// - Returns: 基本SSH命令
    private func buildBasicSSHCommand(from connectionInfo: SSHConnectionInfo) -> String {
        return "ssh -p \(connectionInfo.port) \(connectionInfo.username)@\(connectionInfo.ip)"
    }
    
    /// 执行AppleScript
    /// - Parameter script: AppleScript代码
    /// - Throws: JMSError 如果执行失败
    private func executeAppleScript(_ script: String) throws {
        var error: NSDictionary?
        
        guard let scriptObject = NSAppleScript(source: script) else {
            throw JMSError.terminalLaunchFailed
        }
        
        let result = scriptObject.executeAndReturnError(&error)
        
        if let error = error {
            print("AppleScript执行错误: \(error)")
            throw JMSError.terminalLaunchFailed
        }
        
        // 检查执行结果
        if result.descriptorType == typeNull {
            // 某些AppleScript命令可能返回null，这是正常的
            return
        }
    }
}

// MARK: - Extensions

extension SSHTerminalIntegrator {
    /// 获取终端应用程序的详细信息
    /// - Parameter terminalApp: 终端应用程序类型
    /// - Returns: 应用程序信息字典
    func getTerminalAppInfo(_ terminalApp: TerminalApp) -> [String: Any] {
        var info: [String: Any] = [
            "name": terminalApp.displayName,
            "available": isTerminalAppAvailable(terminalApp)
        ]
        
        if let bundleId = terminalApp.bundleIdentifier {
            info["bundleId"] = bundleId
        }
        
        if let appPath = terminalApp.applicationPath {
            info["path"] = appPath
            info["exists"] = FileManager.default.fileExists(atPath: appPath)
        }
        
        return info
    }
    
    /// 获取所有终端应用程序的状态
    /// - Returns: 终端应用程序状态数组
    func getAllTerminalAppsStatus() -> [[String: Any]] {
        return [
            getTerminalAppInfo(.iterm2),
            getTerminalAppInfo(.terminal)
        ]
    }
}
