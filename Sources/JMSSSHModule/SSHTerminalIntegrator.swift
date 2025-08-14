import Foundation
import Cocoa
import JMSCore

/// SSH终端集成服务
public class SSHTerminalIntegrator {
    
    private let tempDirectory: URL
    
    public init() {
        // 创建临时目录用于存储脚本文件
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("JMSProtocolHandler")
        createTempDirectoryIfNeeded()
    }
    
    /// 启动SSH连接
    /// - Parameter connectionInfo: SSH连接信息
    /// - Throws: JMSError相关错误
    public func launchSSHConnection(_ connectionInfo: SSHConnectionInfo) throws {
        // 1. 检测可用的终端应用程序
        let terminalApp = try detectAvailableTerminal()
        
        // 2. 构建SSH连接命令
        let sshCommand = buildSSHCommand(connectionInfo)
        
        // 3. 启动终端并执行SSH连接
        try launchTerminal(terminalApp, with: sshCommand, connectionInfo: connectionInfo)
        
        // 4. 发送成功通知
        NotificationManager.shared.showSSHConnectionSuccess(connectionInfo)
    }
    
    /// 检测可用的终端应用程序
    /// - Returns: 可用的终端应用程序类型
    /// - Throws: JMSError.terminalNotFound
    public func detectAvailableTerminal() throws -> TerminalApp {
        // 按优先级检测：iTerm2 > Terminal
        if isApplicationInstalled("com.googlecode.iterm2") {
            return .iTerm2
        } else if isApplicationInstalled("com.apple.Terminal") {
            return .terminal
        } else {
            throw JMSError.terminalNotFound
        }
    }
    
    /// 构建SSH连接命令
    /// - Parameter connectionInfo: SSH连接信息
    /// - Returns: SSH命令字符串
    public func buildSSHCommand(_ connectionInfo: SSHConnectionInfo) -> String {
        var command = "ssh"
        
        // 添加端口参数
        if connectionInfo.port != 22 {
            command += " -p \(connectionInfo.port)"
        }
        
        // 添加用户和主机
        command += " \(connectionInfo.username)@\(connectionInfo.ip)"
        
        // 添加其他SSH选项
        command += " -o StrictHostKeyChecking=no"  // 跳过主机密钥检查
        command += " -o UserKnownHostsFile=/dev/null"  // 不保存主机密钥
        
        return command
    }
    
    /// 构建带自动密码输入的SSH命令
    /// - Parameter connectionInfo: SSH连接信息
    /// - Returns: 完整的命令字符串（包含expect脚本）
    /// - Throws: JMSError.fileOperationFailed
    public func buildSSHCommandWithPassword(_ connectionInfo: SSHConnectionInfo) throws -> String {
        guard let password = connectionInfo.password, !password.isEmpty else {
            // 没有密码，返回普通SSH命令
            return buildSSHCommand(connectionInfo)
        }
        
        // 检查expect是否可用
        if !isExpectAvailable() {
            print("expect不可用，将使用普通SSH连接（需要手动输入密码）")
            return buildSSHCommand(connectionInfo)
        }
        
        // 创建expect脚本
        let expectScript = try createExpectScript(connectionInfo)
        return "expect \(expectScript.path)"
    }
    
    // MARK: - Private Methods
    
    private func createTempDirectoryIfNeeded() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: tempDirectory.path) {
            try? fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    private func isApplicationInstalled(_ bundleIdentifier: String) -> Bool {
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) != nil
    }
    
    private func isExpectAvailable() -> Bool {
        let process = Process()
        process.launchPath = "/usr/bin/which"
        process.arguments = ["expect"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private func createExpectScript(_ connectionInfo: SSHConnectionInfo) throws -> URL {
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "ssh_expect_\(timestamp).exp"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        let sshCommand = buildSSHCommand(connectionInfo)
        let password = connectionInfo.password ?? ""
        
        let expectScript = """
        #!/usr/bin/expect -f
        
        set timeout 30
        
        spawn \(sshCommand)
        
        expect {
            "password:" {
                send "\(password)\\r"
                interact
            }
            "Password:" {
                send "\(password)\\r"
                interact
            }
            "(yes/no)?" {
                send "yes\\r"
                exp_continue
            }
            timeout {
                puts "连接超时"
                exit 1
            }
            eof {
                puts "连接已断开"
                exit 0
            }
        }
        """
        
        do {
            try expectScript.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // 设置执行权限
            let attributes = [FileAttributeKey.posixPermissions: 0o755]
            try FileManager.default.setAttributes(attributes, ofItemAtPath: fileURL.path)
            
            // 安排保留文件（不自动清理）
            // scheduleFileCleanup(fileURL) // 已禁用自动清理
            logInfo("📁 SSH expect脚本已保存: \(fileURL.path)")
            
            return fileURL
        } catch {
            throw JMSError.fileOperationFailed("无法创建expect脚本: \(error.localizedDescription)")
        }
    }
    
    private func launchTerminal(_ terminalApp: TerminalApp, with command: String, connectionInfo: SSHConnectionInfo) throws {
        switch terminalApp {
        case .iTerm2:
            try launchiTerm2(with: command)
        case .terminal:
            try launchTerminal(with: command)
        }
    }
    
    private func launchiTerm2(with command: String) throws {
        let script = """
        tell application "iTerm"
            activate
            create window with default profile
            tell current session of current window
                write text "\(command)"
            end tell
        end tell
        """
        
        try executeAppleScript(script)
    }
    
    private func launchTerminal(with command: String) throws {
        let script = """
        tell application "Terminal"
            activate
            do script "\(command)"
        end tell
        """
        
        try executeAppleScript(script)
    }
    
    private func executeAppleScript(_ script: String) throws {
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        
        appleScript?.executeAndReturnError(&error)
        
        if let error = error {
            throw JMSError.configurationError("AppleScript执行失败: \(error)")
        }
    }
    
    private func scheduleFileCleanup(_ fileURL: URL) {
        // 临时文件清理已禁用 - 保留文件供调试和重用
        logInfo("📁 SSH临时文件保留: \(fileURL.path)")
        // 原来的清理逻辑已注释：
        // DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 30.0) {
        //     try? FileManager.default.removeItem(at: fileURL)
        // }
    }
}

// MARK: - 终端应用程序类型

/// 支持的终端应用程序类型
public enum TerminalApp {
    case iTerm2
    case terminal
    
    public var displayName: String {
        switch self {
        case .iTerm2:
            return "iTerm2"
        case .terminal:
            return "Terminal"
        }
    }
    
    public var bundleIdentifier: String {
        switch self {
        case .iTerm2:
            return "com.googlecode.iterm2"
        case .terminal:
            return "com.apple.Terminal"
        }
    }
}
