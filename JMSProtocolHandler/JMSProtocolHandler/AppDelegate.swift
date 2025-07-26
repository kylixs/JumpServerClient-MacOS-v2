import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("JMS Protocol Handler started")
        
        // 显示启动成功通知
        showNotification("JMS Protocol Handler 已启动，准备处理连接请求")
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
            print("Step 1: Parsing JMS URL...")
            guard url.scheme?.lowercased() == "jms" else {
                throw NSError(domain: "JMSError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL scheme"])
            }
            
            guard let host = url.host, !host.isEmpty else {
                throw NSError(domain: "JMSError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Empty payload"])
            }
            
            print("✅ URL parsed successfully. Payload length: \(host.count)")
            
            // 步骤2: Base64解码和JSON解析
            print("Step 2: Decoding payload...")
            guard let decodedData = Data(base64Encoded: host) else {
                throw NSError(domain: "JMSError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Base64 decoding failed"])
            }
            
            guard let jsonString = String(data: decodedData, encoding: .utf8) else {
                throw NSError(domain: "JMSError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 data"])
            }
            
            print("✅ Payload decoded successfully")
            
            // 步骤3: 提取连接信息
            print("Step 3: Extracting connection info...")
            let connectionInfo = try extractConnectionInfo(from: jsonString)
            print("✅ Connection info extracted. Server: \(connectionInfo.server), User: \(connectionInfo.username)")
            
            // 步骤4: 启动Microsoft Remote Desktop
            print("Step 4: Launching Microsoft Remote Desktop...")
            try launchRemoteDesktop(with: connectionInfo)
            print("✅ Microsoft Remote Desktop launched successfully")
            
            // 显示成功通知
            showNotification("成功连接到 \(connectionInfo.server)")
            
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            showNotification("连接失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractConnectionInfo(from jsonString: String) throws -> (server: String, username: String) {
        // 解析JSON配置
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let config = json["config"] as? String else {
            throw NSError(domain: "JMSError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
        }
        
        // 解析配置字符串
        let lines = config.components(separatedBy: "\n")
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
            throw NSError(domain: "JMSError", code: 6, userInfo: [NSLocalizedDescriptionKey: "Missing connection info"])
        }
        
        return (server: server, username: username)
    }
    
    private func launchRemoteDesktop(with connectionInfo: (server: String, username: String)) throws {
        // 检查Microsoft Remote Desktop是否可用
        guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.rdc.macos") != nil else {
            throw NSError(domain: "JMSError", code: 7, userInfo: [NSLocalizedDescriptionKey: "Microsoft Remote Desktop not found"])
        }
        
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
        
        // 设置文件权限
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: rdpFile.path)
        
        // 启动Microsoft Remote Desktop
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.rdc.macos") {
            try NSWorkspace.shared.open([rdpFile], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
        } else {
            let success = NSWorkspace.shared.open(rdpFile)
            if !success {
                throw NSError(domain: "JMSError", code: 8, userInfo: [NSLocalizedDescriptionKey: "Failed to launch Remote Desktop"])
            }
        }
        
        // 延迟清理临时文件
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            try? FileManager.default.removeItem(at: rdpFile)
        }
    }
    
    private func showNotification(_ message: String) {
        // 简单的通知实现
        print("📢 Notification: \(message)")
        
        // 尝试显示系统通知
        let notification = NSUserNotification()
        notification.title = "JMS Protocol Handler"
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}
