import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Service Dependencies
    private let urlParser = URLParser()
    private let payloadDecoder = PayloadDecoder()
    private let connectionInfoExtractor = ConnectionInfoExtractor()
    private let remoteDesktopIntegrator = RemoteDesktopIntegrator()
    private let sshTerminalIntegrator = SSHTerminalIntegrator()
    private let errorHandler = ErrorHandler()
    private let notificationManager = NotificationManager()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("JMS Protocol Handler started - 支持RDP和SSH协议")
        
        // 显示启动成功通知
        notificationManager.showNotification("JMS Protocol Handler 已启动，准备处理RDP和SSH连接请求")
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
            let urlComponents = try urlParser.parseJMSURL(url)
            print("✅ URL解析成功. Payload长度: \(urlComponents.encodedPayload.count)")
            
            // 步骤2: Base64解码和JSON解析
            print("Step 2: 解码payload...")
            let decodedData = try payloadDecoder.decodeBase64Payload(urlComponents.encodedPayload)
            let jmsConfig = try payloadDecoder.parseJSONConfig(decodedData)
            print("✅ Payload解码成功. 协议类型: \(jmsConfig.protocol)")
            
            // 步骤3: 提取连接信息
            print("Step 3: 提取连接信息...")
            let connectionInfo = try connectionInfoExtractor.extractConnectionInfo(from: jmsConfig)
            print("✅ 连接信息提取成功: \(connectionInfo.description)")
            
            // 步骤4: 根据协议类型启动相应的连接
            print("Step 4: 启动连接...")
            try launchConnection(with: connectionInfo)
            print("✅ 连接启动成功")
            
            // 显示成功通知
            notificationManager.showNotification("成功启动连接: \(connectionInfo.description)")
            
        } catch let error as JMSError {
            print("❌ JMS错误: \(error.localizedDescription)")
            errorHandler.handleError(error)
        } catch {
            print("❌ 未知错误: \(error.localizedDescription)")
            let jmsError = JMSError.jsonParsingFailed
            errorHandler.handleError(jmsError)
        }
    }
    
    /// 根据连接信息类型启动相应的连接
    /// - Parameter connectionInfo: 连接信息（RDP或SSH）
    /// - Throws: JMSError 如果启动失败
    private func launchConnection(with connectionInfo: ConnectionInfo) throws {
        switch connectionInfo {
        case .rdp(let rdpInfo):
            try launchRDPConnection(with: rdpInfo)
        case .ssh(let sshInfo):
            try launchSSHConnection(with: sshInfo)
        }
    }
    
    /// 启动RDP远程桌面连接
    /// - Parameter rdpInfo: RDP连接信息
    /// - Throws: JMSError 如果启动失败
    private func launchRDPConnection(with rdpInfo: RDPConnectionInfo) throws {
        print("启动RDP连接到: \(rdpInfo.fullAddress)")
        
        // 检查Microsoft Remote Desktop是否可用
        guard remoteDesktopIntegrator.checkRemoteDesktopAvailability() else {
            throw JMSError.remoteDesktopNotFound
        }
        
        // 启动Remote Desktop
        try remoteDesktopIntegrator.launchRemoteDesktop(with: rdpInfo)
        
        print("RDP连接启动成功")
    }
    
    /// 启动SSH终端连接
    /// - Parameter sshInfo: SSH连接信息
    /// - Throws: JMSError 如果启动失败
    private func launchSSHConnection(with sshInfo: SSHConnectionInfo) throws {
        print("启动SSH连接到: \(sshInfo.connectionString)")
        
        // 检测可用的终端应用程序
        let terminalApp = sshTerminalIntegrator.detectAvailableTerminal()
        print("检测到终端应用程序: \(terminalApp.displayName)")
        
        // 检查expect工具可用性
        let expectAvailable = sshTerminalIntegrator.checkExpectAvailability()
        print("Expect工具可用性: \(expectAvailable ? "可用" : "不可用")")
        
        if !expectAvailable {
            notificationManager.showNotification("注意：expect工具不可用，需要手动输入SSH密码")
        }
        
        // 启动SSH会话
        try sshTerminalIntegrator.launchSSHSession(with: sshInfo)
        
        print("SSH连接启动成功")
    }
}

// MARK: - Extensions

extension AppDelegate {
    /// 获取应用程序状态信息
    /// - Returns: 状态信息字典
    func getApplicationStatus() -> [String: Any] {
        return [
            "name": "JMS Protocol Handler",
            "version": "1.0.0",
            "supportedProtocols": ["rdp", "ssh"],
            "rdpIntegration": [
                "available": remoteDesktopIntegrator.checkRemoteDesktopAvailability()
            ],
            "sshIntegration": [
                "availableTerminals": sshTerminalIntegrator.getAllTerminalAppsStatus(),
                "expectAvailable": sshTerminalIntegrator.checkExpectAvailability()
            ]
        ]
    }
    
    /// 测试连接功能
    /// - Parameters:
    ///   - protocol: 协议类型 ("rdp" 或 "ssh")
    ///   - testData: 测试数据
    func testConnection(protocol: String, testData: [String: Any]) {
        print("测试\(protocol.uppercased())连接功能...")
        
        // 这里可以添加测试逻辑
        switch protocol.lowercased() {
        case "rdp":
            print("RDP集成状态: \(remoteDesktopIntegrator.checkRemoteDesktopAvailability())")
        case "ssh":
            print("SSH终端状态: \(sshTerminalIntegrator.detectAvailableTerminal().displayName)")
            print("Expect工具状态: \(sshTerminalIntegrator.checkExpectAvailability())")
        default:
            print("不支持的协议类型: \(protocol)")
        }
    }
}
