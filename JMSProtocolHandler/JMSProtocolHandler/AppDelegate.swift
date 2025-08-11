import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    private let qualityConfigManager = RDPQualityConfigManager.shared
    private let remoteDesktopIntegrator = RemoteDesktopIntegrator()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("JMS Protocol Handler started - 支持RDP和SSH协议")
        
        // 设置应用程序菜单
        setupApplicationMenu()
        
        // 显示启动成功通知
        showNotification("JMS Protocol Handler 已启动，准备处理RDP和SSH连接请求")
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        print("JMS Protocol Handler terminating")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - URL Handling
    
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleJMSURL(url)
        }
    }
    
    /// 处理JMS协议URL的完整工作流程
    /// - Parameter url: 要处理的JMS URL
    private func handleJMSURL(_ url: URL) {
        print("Received URL: \(url.absoluteString)")
        
        do {
            // 步骤1: URL解析和验证
            print("Step 1: 解析JMS URL...")
            guard url.scheme?.lowercased() == "jms" else {
                throw NSError(domain: "JMSError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL scheme"])
            }
            
            guard let host = url.host, !host.isEmpty else {
                throw NSError(domain: "JMSError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Empty payload"])
            }
            
            print("✅ URL解析成功. Payload长度: \(host.count)")
            
            // 步骤2: Base64解码和JSON解析
            print("Step 2: 解码payload...")
            guard let decodedData = Data(base64Encoded: host) else {
                throw NSError(domain: "JMSError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Base64解码失败"])
            }
            
            guard let jsonString = String(data: decodedData, encoding: .utf8) else {
                throw NSError(domain: "JMSError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 data"])
            }
            
            print("✅ Payload解码成功")
            
            // 步骤3: 解析JSON配置
            guard let jsonData = jsonString.data(using: .utf8),
                  let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let protocolType = json["protocol"] as? String else {
                throw NSError(domain: "JMSError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
            }
            
            print("✅ JSON解析成功. 协议类型: \(protocolType)")
            
            // 步骤4: 根据协议类型处理
            switch protocolType.lowercased() {
            case "rdp":
                try handleRDPConnection(json: json)
            case "ssh":
                try handleSSHConnection(json: json)
            default:
                throw NSError(domain: "JMSError", code: 6, userInfo: [NSLocalizedDescriptionKey: "不支持的协议类型: \(protocolType)"])
            }
            
            // 显示成功通知
            showNotification("成功启动\(protocolType.uppercased())连接")
            
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            showNotification("连接失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - RDP Connection Handling
    
    private func handleRDPConnection(json: [String: Any]) throws {
        print("处理RDP连接...")
        
        guard let config = json["config"] as? String else {
            throw NSError(domain: "JMSError", code: 7, userInfo: [NSLocalizedDescriptionKey: "缺少RDP配置信息"])
        }
        
        // 解析RDP配置
        let connectionInfo = try parseRDPConfig(config)
        
        // 检查Microsoft Remote Desktop是否可用
        guard checkRemoteDesktopAvailability() else {
            throw NSError(domain: "JMSError", code: 8, userInfo: [NSLocalizedDescriptionKey: "未找到Microsoft Remote Desktop应用程序"])
        }
        
        // 启动RDP连接
        try launchRemoteDesktop(with: connectionInfo)
        
        print("✅ RDP连接启动成功")
    }
    
    // MARK: - SSH Connection Handling
    
    private func handleSSHConnection(json: [String: Any]) throws {
        print("处理SSH连接...")
        
        guard let token = json["token"] as? String, !token.isEmpty else {
            throw NSError(domain: "JMSError", code: 9, userInfo: [NSLocalizedDescriptionKey: "缺少SSH Token信息"])
        }
        
        // 解析SSH Token
        let sshInfo = try parseSSHToken(token)
        
        // 检测终端应用程序
        let terminalApp = detectAvailableTerminal()
        guard terminalApp != .unavailable else {
            throw NSError(domain: "JMSError", code: 10, userInfo: [NSLocalizedDescriptionKey: "无法找到可用的终端应用程序"])
        }
        
        // 启动SSH连接
        try launchSSHSession(with: sshInfo, using: terminalApp)
        
        print("✅ SSH连接启动成功")
    }
    
    // MARK: - Helper Methods
    
    private func parseRDPConfig(_ config: String) throws -> (server: String, username: String) {
        let lines = config.replacingOccurrences(of: "\\n", with: "\n").components(separatedBy: "\n")
        var server = ""
        var username = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("full address:s:") {
                server = String(trimmed.dropFirst("full address:s:".count))
            } else if trimmed.hasPrefix("username:s:") {
                username = String(trimmed.dropFirst("username:s:".count))
            }
        }
        
        guard !server.isEmpty, !username.isEmpty else {
            throw NSError(domain: "JMSError", code: 11, userInfo: [NSLocalizedDescriptionKey: "RDP连接信息不完整"])
        }
        
        return (server: server, username: username)
    }
    
    private func parseSSHToken(_ token: String) throws -> (ip: String, port: String, username: String, password: String) {
        guard let tokenData = token.data(using: .utf8),
              let tokenJson = try JSONSerialization.jsonObject(with: tokenData) as? [String: Any],
              let ip = tokenJson["ip"] as? String,
              let port = tokenJson["port"] as? String,
              let username = tokenJson["username"] as? String,
              let password = tokenJson["password"] as? String else {
            throw NSError(domain: "JMSError", code: 12, userInfo: [NSLocalizedDescriptionKey: "SSH Token解析失败"])
        }
        
        return (ip: ip, port: port, username: username, password: password)
    }
    
    private func checkRemoteDesktopAvailability() -> Bool {
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.rdc.macos") != nil
    }
    
    private func launchRemoteDesktop(with connectionInfo: (server: String, username: String)) throws {
        // 创建临时RDP文件
        let rdpContent = """
        full address:s:\(connectionInfo.server)
        username:s:\(connectionInfo.username)
        session bpp:i:32
        audiomode:i:0
        smart sizing:i:1
        screen mode id:i:2
        """
        
        let tempDir = FileManager.default.temporaryDirectory
        let rdpFile = tempDir.appendingPathComponent("jms_connection_\(UUID().uuidString).rdp")
        
        try rdpContent.write(to: rdpFile, atomically: true, encoding: .utf8)
        
        // 启动Microsoft Remote Desktop
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.rdc.macos") {
            try NSWorkspace.shared.open([rdpFile], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
        } else {
            let success = NSWorkspace.shared.open(rdpFile)
            if !success {
                throw NSError(domain: "JMSError", code: 13, userInfo: [NSLocalizedDescriptionKey: "启动Remote Desktop失败"])
            }
        }
        
        // 延迟清理临时文件
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            try? FileManager.default.removeItem(at: rdpFile)
        }
    }
    
    enum TerminalApp {
        case iterm2, terminal, unavailable
        
        var displayName: String {
            switch self {
            case .iterm2: return "iTerm2"
            case .terminal: return "Terminal"
            case .unavailable: return "无可用终端"
            }
        }
    }
    
    private func detectAvailableTerminal() -> TerminalApp {
        if NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.googlecode.iterm2") != nil {
            return .iterm2
        } else if NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") != nil {
            return .terminal
        } else {
            return .unavailable
        }
    }
    
    private func checkExpectAvailability() -> Bool {
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
    
    private func launchSSHSession(with sshInfo: (ip: String, port: String, username: String, password: String), using terminalApp: TerminalApp) throws {
        let expectAvailable = checkExpectAvailability()
        let sshCommand: String
        
        if expectAvailable {
            // 使用expect脚本自动输入密码
            let escapedPassword = sshInfo.password.replacingOccurrences(of: "\"", with: "\\\"")
            sshCommand = """
            expect -c "
            set timeout 30
            spawn ssh -p \(sshInfo.port) \(sshInfo.username)@\(sshInfo.ip)
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
        } else {
            // 基本SSH命令，需要手动输入密码
            sshCommand = "ssh -p \(sshInfo.port) \(sshInfo.username)@\(sshInfo.ip)"
        }
        
        // 启动终端
        switch terminalApp {
        case .iterm2:
            try launchITerm2WithSSH(command: sshCommand)
        case .terminal:
            try launchTerminalWithSSH(command: sshCommand)
        case .unavailable:
            throw NSError(domain: "JMSError", code: 14, userInfo: [NSLocalizedDescriptionKey: "无可用终端"])
        }
    }
    
    private func launchITerm2WithSSH(command: String) throws {
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
    
    private func launchTerminalWithSSH(command: String) throws {
        let escapedCommand = command.replacingOccurrences(of: "\"", with: "\\\"")
        
        let appleScript = """
        tell application "Terminal"
            activate
            do script "\(escapedCommand)"
        end tell
        """
        
        try executeAppleScript(appleScript)
    }
    
    private func executeAppleScript(_ script: String) throws {
        var error: NSDictionary?
        
        guard let scriptObject = NSAppleScript(source: script) else {
            throw NSError(domain: "JMSError", code: 15, userInfo: [NSLocalizedDescriptionKey: "AppleScript创建失败"])
        }
        
        let result = scriptObject.executeAndReturnError(&error)
        
        if let error = error {
            print("AppleScript执行错误: \(error)")
            throw NSError(domain: "JMSError", code: 16, userInfo: [NSLocalizedDescriptionKey: "终端启动失败"])
        }
    }
    
    // MARK: - Menu Setup
    
    /// 设置应用程序菜单
    private func setupApplicationMenu() {
        let mainMenu = NSMenu()
        
        // 应用程序菜单
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        
        // 应用程序名称菜单项
        let appNameMenuItem = NSMenuItem(title: "JMS Protocol Handler", action: nil, keyEquivalent: "")
        appMenu.addItem(appNameMenuItem)
        appMenu.addItem(NSMenuItem.separator())
        
        // RDP质量配置菜单项
        let configMenuItem = NSMenuItem(
            title: "RDP质量配置...",
            action: #selector(showQualityConfiguration),
            keyEquivalent: ","
        )
        configMenuItem.keyEquivalentModifierMask = .command
        appMenu.addItem(configMenuItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // 快速切换质量配置子菜单
        let quickSwitchMenuItem = NSMenuItem(title: "快速切换质量", action: nil, keyEquivalent: "")
        let quickSwitchMenu = NSMenu()
        
        let performanceMenuItem = NSMenuItem(
            title: "性能优先 (适合低带宽)",
            action: #selector(switchToPerformanceMode),
            keyEquivalent: "1"
        )
        performanceMenuItem.keyEquivalentModifierMask = .command
        quickSwitchMenu.addItem(performanceMenuItem)
        
        let balancedMenuItem = NSMenuItem(
            title: "平衡模式 (推荐)",
            action: #selector(switchToBalancedMode),
            keyEquivalent: "2"
        )
        balancedMenuItem.keyEquivalentModifierMask = .command
        quickSwitchMenu.addItem(balancedMenuItem)
        
        let qualityMenuItem = NSMenuItem(
            title: "质量优先 (适合局域网)",
            action: #selector(switchToQualityMode),
            keyEquivalent: "3"
        )
        qualityMenuItem.keyEquivalentModifierMask = .command
        quickSwitchMenu.addItem(qualityMenuItem)
        
        quickSwitchMenu.addItem(NSMenuItem.separator())
        
        // 当前配置状态显示
        let currentConfigMenuItem = NSMenuItem(
            title: getCurrentConfigurationStatus(),
            action: nil,
            keyEquivalent: ""
        )
        currentConfigMenuItem.isEnabled = false
        quickSwitchMenu.addItem(currentConfigMenuItem)
        
        quickSwitchMenuItem.submenu = quickSwitchMenu
        appMenu.addItem(quickSwitchMenuItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // 关于菜单项
        let aboutMenuItem = NSMenuItem(
            title: "关于 JMS Protocol Handler",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        appMenu.addItem(aboutMenuItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // 退出菜单项
        let quitMenuItem = NSMenuItem(
            title: "退出 JMS Protocol Handler",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitMenuItem.keyEquivalentModifierMask = .command
        appMenu.addItem(quitMenuItem)
        
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // 设置主菜单
        NSApplication.shared.mainMenu = mainMenu
        
        // 监听配置变更通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(qualityConfigurationDidChange(_:)),
            name: RDPQualityConfigManager.configurationDidChangeNotification,
            object: nil
        )
    }
    
    /// 获取当前配置状态描述
    private func getCurrentConfigurationStatus() -> String {
        let currentProfile = qualityConfigManager.getCurrentQualityProfile()
        let analysis = remoteDesktopIntegrator.getCurrentQualityAnalysis()
        
        return "当前配置: \(currentProfile.displayName) (\(analysis.recommendedBandwidth))"
    }
    
    /// 更新菜单中的配置状态显示
    private func updateConfigurationStatusInMenu() {
        guard let mainMenu = NSApplication.shared.mainMenu,
              let appMenuItem = mainMenu.items.first,
              let appMenu = appMenuItem.submenu,
              let quickSwitchMenuItem = appMenu.items.first(where: { $0.title == "快速切换质量" }),
              let quickSwitchMenu = quickSwitchMenuItem.submenu else {
            return
        }
        
        // 找到状态显示菜单项并更新
        for menuItem in quickSwitchMenu.items {
            if menuItem.title.hasPrefix("当前配置:") {
                menuItem.title = getCurrentConfigurationStatus()
                break
            }
        }
    }
    
    // MARK: - Menu Actions
    
    @objc private func showQualityConfiguration() {
        let configViewController = RDPQualityConfigViewController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "RDP质量配置"
        window.contentViewController = configViewController
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // 确保窗口在前台
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func switchToPerformanceMode() {
        remoteDesktopIntegrator.switchQualityProfile(.performance)
        showNotification("已切换到性能优先模式 - 适合低带宽网络环境")
        updateConfigurationStatusInMenu()
    }
    
    @objc private func switchToBalancedMode() {
        remoteDesktopIntegrator.switchQualityProfile(.balanced)
        showNotification("已切换到平衡模式 - 性能与质量的最佳平衡")
        updateConfigurationStatusInMenu()
    }
    
    @objc private func switchToQualityMode() {
        remoteDesktopIntegrator.switchQualityProfile(.quality)
        showNotification("已切换到质量优先模式 - 适合高带宽局域网环境")
        updateConfigurationStatusInMenu()
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "JMS Protocol Handler v1.2.0"
        alert.informativeText = """
        一个用于处理 jms:// 协议链接的 macOS 应用程序
        
        功能特性:
        • RDP协议支持 (含智能显示优化)
        • SSH协议支持 (自动密码输入)
        • 质量配置管理 (性能/平衡/质量)
        • HiDPI显示器优化
        • 多显示器支持
        
        系统要求: macOS 10.15+
        架构支持: Apple Silicon (ARM64) + Intel (x86_64)
        
        © 2025 JMS Protocol Handler
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    @objc private func qualityConfigurationDidChange(_ notification: Notification) {
        // 更新菜单状态显示
        updateConfigurationStatusInMenu()
        
        // 如果有配置文件信息，显示通知
        if let profile = notification.userInfo?["profile"] as? DisplayQualityProfile {
            let analysis = remoteDesktopIntegrator.getCurrentQualityAnalysis()
            showNotification("配置已更新: \(profile.displayName) (\(analysis.recommendedBandwidth))")
        }
    }
    
    private func showNotification(_ message: String) {
        print("📢 Notification: \(message)")
        
        // 尝试显示系统通知
        let notification = NSUserNotification()
        notification.title = "JMS Protocol Handler"
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}
