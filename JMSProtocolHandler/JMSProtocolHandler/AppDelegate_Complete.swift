import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    // GUI验证系统
    private let guiValidator = GUIValidator()
    private let treeGenerator = UIComponentTreeGenerator()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("JMS Protocol Handler started - 支持RDP和SSH协议")
        
        // 设置应用程序菜单
        setupApplicationMenu()
        
        // 显示启动成功通知
        showNotification("JMS Protocol Handler 已启动，准备处理RDP和SSH连接请求")
        
        // 可选：运行GUI验证演示
        if CommandLine.arguments.contains("--gui-validation-demo") {
            runGUIValidationDemo()
        }
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
        
        // 启动RDP连接（使用基础配置）
        try launchBasicRemoteDesktop(with: connectionInfo)
        
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
    
    private func launchBasicRemoteDesktop(with connectionInfo: (server: String, username: String)) throws {
        // 创建基础RDP文件（不使用复杂的显示优化）
        let rdpContent = """
        full address:s:\(connectionInfo.server)
        username:s:\(connectionInfo.username)
        session bpp:i:32
        audiomode:i:0
        smart sizing:i:1
        screen mode id:i:2
        compression:i:1
        keyboardhook:i:2
        audiocapturemode:i:0
        videoplaybackmode:i:1
        connection type:i:6
        networkautodetect:i:1
        bandwidthautodetect:i:1
        enableworkspacereconnect:i:0
        disable wallpaper:i:0
        allow font smoothing:i:1
        allow desktop composition:i:1
        disable full window drag:i:1
        disable menu anims:i:1
        disable themes:i:0
        disable cursor setting:i:0
        bitmapcachepersistenable:i:1
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
        
        // GUI验证菜单项 🆕
        let guiValidationMenuItem = NSMenuItem(
            title: "运行GUI验证演示",
            action: #selector(runGUIValidationDemo),
            keyEquivalent: "g"
        )
        guiValidationMenuItem.keyEquivalentModifierMask = .command
        appMenu.addItem(guiValidationMenuItem)
        
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
    }
    
    // MARK: - Menu Actions
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "JMS Protocol Handler v1.2.0"
        alert.informativeText = """
        一个用于处理 jms:// 协议链接的 macOS 应用程序
        
        功能特性:
        • RDP协议支持
        • SSH协议支持 (自动密码输入)
        • GUI验证系统 🆕
        
        系统要求: macOS 10.15+
        架构支持: Apple Silicon (ARM64) + Intel (x86_64)
        
        © 2025 JMS Protocol Handler
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    @objc private func runGUIValidationDemo() {
        print("🚀 启动GUI验证演示...")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 创建测试视图控制器
            let testViewController = self.createTestRDPConfigViewController()
            
            DispatchQueue.main.async {
                // 执行GUI验证
                let report = self.guiValidator.validateRDPQualityConfigGUI(testViewController)
                
                // 显示验证结果
                let alert = NSAlert()
                alert.messageText = "GUI验证完成"
                alert.informativeText = """
                验证状态: \(report.status.rawValue)
                总组件数: \(report.summary.totalComponents)
                通过测试: \(report.summary.passedTests)
                失败测试: \(report.summary.failedTests)
                警告测试: \(report.summary.warningTests)
                执行时间: \(String(format: "%.3f", report.summary.executionTime))秒
                
                详细报告已保存到临时文件。
                """
                alert.alertStyle = report.status == .passed ? .informational : .warning
                alert.addButton(withTitle: "确定")
                alert.runModal()
                
                print("✅ GUI验证演示完成")
            }
        }
    }
    
    /// 创建测试RDP配置视图控制器
    private func createTestRDPConfigViewController() -> NSViewController {
        let viewController = NSViewController()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        
        // 创建模拟的RDP配置界面（与演示脚本中的相同）
        
        // 标题
        let titleLabel = NSTextField(labelWithString: "RDP质量配置")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.frame = NSRect(x: 20, y: 450, width: 200, height: 25)
        view.addSubview(titleLabel)
        
        // 预设配置分段控件
        let segmentedControl = NSSegmentedControl()
        segmentedControl.segmentCount = 3
        segmentedControl.setLabel("性能优先", forSegment: 0)
        segmentedControl.setLabel("平衡模式", forSegment: 1)
        segmentedControl.setLabel("质量优先", forSegment: 2)
        segmentedControl.selectedSegment = 1
        segmentedControl.frame = NSRect(x: 20, y: 400, width: 300, height: 30)
        view.addSubview(segmentedControl)
        
        // 压缩级别
        let compressionLabel = NSTextField(labelWithString: "压缩级别:")
        compressionLabel.frame = NSRect(x: 20, y: 350, width: 80, height: 20)
        view.addSubview(compressionLabel)
        
        let compressionSlider = NSSlider()
        compressionSlider.minValue = 0
        compressionSlider.maxValue = 2
        compressionSlider.doubleValue = 1
        compressionSlider.numberOfTickMarks = 3
        compressionSlider.allowsTickMarkValuesOnly = true
        compressionSlider.frame = NSRect(x: 110, y: 350, width: 150, height: 25)
        view.addSubview(compressionSlider)
        
        // 颜色深度和音频质量下拉框
        let colorDepthPopup = NSPopUpButton()
        colorDepthPopup.addItems(withTitles: ["16位", "24位", "32位"])
        colorDepthPopup.selectItem(at: 1)
        colorDepthPopup.frame = NSRect(x: 110, y: 300, width: 100, height: 25)
        view.addSubview(colorDepthPopup)
        
        let audioPopup = NSPopUpButton()
        audioPopup.addItems(withTitles: ["禁用", "低质量", "中等", "高质量"])
        audioPopup.selectItem(at: 2)
        audioPopup.frame = NSRect(x: 110, y: 250, width: 100, height: 25)
        view.addSubview(audioPopup)
        
        // 特效复选框
        let checkboxes = [
            ("启用字体平滑", NSRect(x: 20, y: 200, width: 150, height: 20)),
            ("显示桌面壁纸", NSRect(x: 20, y: 170, width: 150, height: 20)),
            ("启用菜单动画", NSRect(x: 200, y: 200, width: 150, height: 20)),
            ("启用视觉主题", NSRect(x: 200, y: 170, width: 150, height: 20))
        ]
        
        for (title, frame) in checkboxes {
            let checkbox = NSButton(checkboxWithTitle: title, target: nil, action: nil)
            checkbox.state = .on
            checkbox.frame = frame
            view.addSubview(checkbox)
        }
        
        // 操作按钮
        let buttons = [
            ("应用配置", NSRect(x: 480, y: 20, width: 100, height: 30)),
            ("重置默认", NSRect(x: 370, y: 20, width: 100, height: 30)),
            ("导出配置", NSRect(x: 20, y: 20, width: 100, height: 30)),
            ("导入配置", NSRect(x: 130, y: 20, width: 100, height: 30))
        ]
        
        for (title, frame) in buttons {
            let button = NSButton(title: title, target: nil, action: nil)
            button.bezelStyle = .rounded
            button.frame = frame
            view.addSubview(button)
        }
        
        viewController.view = view
        return viewController
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
