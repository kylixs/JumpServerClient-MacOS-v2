import Foundation
import Cocoa
import JMSCore

/// Microsoft Remote Desktop集成服务
public class RemoteDesktopIntegrator {
    
    private let configManager = RDPConfigManager.shared
    private let tempDirectory: URL
    
    public init() {
        // 创建临时目录用于存储RDP配置文件
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("JMSProtocolHandler")
        createTempDirectoryIfNeeded()
    }
    
    /// 启动RDP连接
    /// - Parameters:
    ///   - connectionInfo: RDP连接信息
    ///   - qualityProfile: 质量配置文件（可选）
    /// - Throws: JMSError相关错误
    public func launchRDPConnection(_ connectionInfo: RDPConnectionInfo, quality: QualityProfile? = nil) throws {
        logInfo("🔍 RemoteDesktopIntegrator: 开始启动RDP连接")
        logInfo("🔍 服务器地址: \(connectionInfo.serverAddress)")
        logInfo("🔍 用户名: \(connectionInfo.username)")
        
        // 1. 检查Microsoft Remote Desktop是否已安装
        logInfo("🔍 步骤1: 检查Microsoft Remote Desktop安装...")
        try verifyRemoteDesktopInstallation()
        logInfo("✅ Microsoft Remote Desktop 已安装")
        
        // 2. 生成RDP配置 - 优先使用保存的设置
        logInfo("🔍 步骤2: 生成RDP配置...")
        let configContent: String
        
        // 检查是否有保存的RDP设置
        let settingsManager = RDPSettingsManager.shared
        let hasCustomSettings = settingsManager.hasCustomSettings()
        
        logInfo("🔍 检查配置文件状态:")
        logInfo("   配置文件路径: ~/Documents/JMSRDPSettings.json")
        logInfo("   是否存在自定义设置: \(hasCustomSettings)")
        
        if hasCustomSettings {
            // 使用保存的RDP设置
            logInfo("🔧 检测到自定义RDP设置，使用保存的配置")
            let savedSettings = settingsManager.currentSettings
            logInfo("   配置名称: \(savedSettings.profileName)")
            logInfo("   自动检测: \(savedSettings.useAutoDetection)")
            logInfo("   HiDPI启用: \(savedSettings.hiDPI.enabled)")
            logInfo("   分辨率: \(savedSettings.resolution.width)×\(savedSettings.resolution.height)")
            configContent = try configManager.generateConfigWithSavedSettings(for: connectionInfo)
        } else {
            // 使用质量配置文件（首次使用或未保存设置时）
            logInfo("🔧 未检测到自定义设置，使用质量配置文件")
            logInfo("   质量配置: \(quality?.displayName ?? "balanced")")
            configContent = try configManager.generateOptimizedConfig(for: connectionInfo, quality: quality)
        }
        
        logInfo("✅ RDP配置生成成功")
        logDebug("📄 配置内容预览: \(configContent.prefix(200))\(configContent.count > 200 ? "..." : "")")
        
        // 3. 创建临时RDP文件
        logInfo("🔍 步骤3: 创建临时RDP文件...")
        let rdpFile = try createTemporaryRDPFile(content: configContent, connectionInfo: connectionInfo)
        logInfo("✅ 临时RDP文件创建成功: \(rdpFile.path)")
        
        // 4. 启动Microsoft Remote Desktop
        logInfo("🔍 步骤4: 启动Microsoft Remote Desktop...")
        try launchRemoteDesktop(with: rdpFile)
        logInfo("✅ Microsoft Remote Desktop 启动成功")
        
        // 5. 发送成功通知
        NotificationManager.shared.showRDPConnectionSuccess(connectionInfo)
        
        // 6. 清理临时文件（延迟执行）
        scheduleFileCleanup(rdpFile)
        logInfo("🎉 RDP连接启动流程完成")
    }
    
    /// 验证Microsoft Remote Desktop是否已安装
    /// - Throws: JMSError.remoteDesktopNotFound
    public func verifyRemoteDesktopInstallation() throws {
        logDebug("🔍 检查Microsoft Remote Desktop安装状态...")
        
        let possiblePaths = [
            "/Applications/Microsoft Remote Desktop.app",
            "/System/Applications/Microsoft Remote Desktop.app",
            "/Applications/Utilities/Microsoft Remote Desktop.app"
        ]
        
        let fileManager = FileManager.default
        for path in possiblePaths {
            logDebug("🔍 检查路径: \(path)")
            if fileManager.fileExists(atPath: path) {
                logDebug("✅ 在路径找到Microsoft Remote Desktop: \(path)")
                return // 找到了应用程序
            }
        }
        
        // 尝试通过Bundle ID查找
        logDebug("🔍 通过Bundle ID查找: com.microsoft.rdc.macos")
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.rdc.macos") {
            logDebug("✅ 通过Bundle ID找到Microsoft Remote Desktop: \(appURL.path)")
            return // 通过Bundle ID找到了
        }
        
        logError("❌ 未找到Microsoft Remote Desktop应用程序")
        throw JMSError.remoteDesktopNotFound
    }
    
    /// 获取Microsoft Remote Desktop的路径
    /// - Returns: 应用程序路径
    /// - Throws: JMSError.remoteDesktopNotFound
    public func getRemoteDesktopPath() throws -> URL {
        // 首先尝试通过Bundle ID查找
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.rdc.macos") {
            return appURL
        }
        
        // 然后尝试常见路径
        let possiblePaths = [
            "/Applications/Microsoft Remote Desktop.app",
            "/System/Applications/Microsoft Remote Desktop.app",
            "/Applications/Utilities/Microsoft Remote Desktop.app"
        ]
        
        let fileManager = FileManager.default
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        
        throw JMSError.remoteDesktopNotFound
    }
    
    // MARK: - Private Methods
    
    private func createTempDirectoryIfNeeded() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: tempDirectory.path) {
            try? fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    private func createTemporaryRDPFile(content: String, connectionInfo: RDPConnectionInfo) throws -> URL {
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "rdp_connection_\(timestamp).rdp"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        // 使用LogManager记录RDP配置到专门的日志文件
        LogManager.shared.logRDPConfig(
            server: connectionInfo.serverAddress,
            username: connectionInfo.username,
            filePath: fileURL.path,
            configContent: content
        )
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            throw JMSError.fileOperationFailed("无法创建RDP配置文件: \(error.localizedDescription)")
        }
    }
    
    private func launchRemoteDesktop(with rdpFile: URL) throws {
        print("🔍 获取Microsoft Remote Desktop路径...")
        let remoteDesktopURL = try getRemoteDesktopPath()
        print("✅ Microsoft Remote Desktop路径: \(remoteDesktopURL.path)")
        
        print("🔍 检查RDP文件是否存在: \(rdpFile.path)")
        guard FileManager.default.fileExists(atPath: rdpFile.path) else {
            print("❌ RDP文件不存在: \(rdpFile.path)")
            throw JMSError.fileOperationFailed("RDP文件不存在")
        }
        print("✅ RDP文件存在")
        
        // 使用同步方式直接打开RDP文件
        print("🔍 直接打开RDP文件...")
        do {
            let success = NSWorkspace.shared.open(rdpFile)
            if success {
                print("✅ RDP文件打开成功")
            } else {
                print("❌ RDP文件打开失败")
                // 尝试备用方法：先启动应用程序，再打开文件
                print("🔍 尝试备用方法：先启动应用程序...")
                try launchRemoteDesktopAlternative(with: rdpFile, appURL: remoteDesktopURL)
            }
        } catch {
            print("❌ 打开RDP文件时出错: \(error.localizedDescription)")
            throw JMSError.configurationError("打开RDP文件失败: \(error.localizedDescription)")
        }
    }
    
    private func launchRemoteDesktopAlternative(with rdpFile: URL, appURL: URL) throws {
        print("🔍 使用备用方法启动Microsoft Remote Desktop...")
        
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        
        var launchError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { app, error in
            if let error = error {
                print("❌ 启动Microsoft Remote Desktop失败: \(error.localizedDescription)")
                launchError = error
            } else {
                print("✅ Microsoft Remote Desktop启动成功")
                // 应用程序启动成功后，打开RDP文件
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    print("🔍 延迟打开RDP文件...")
                    let openSuccess = NSWorkspace.shared.open(rdpFile)
                    print(openSuccess ? "✅ RDP文件打开成功" : "❌ RDP文件打开失败")
                    semaphore.signal()
                }
            }
            if launchError != nil {
                semaphore.signal()
            }
        }
        
        // 等待最多10秒
        let result = semaphore.wait(timeout: .now() + 10.0)
        if result == .timedOut {
            print("⚠️ 启动Microsoft Remote Desktop超时")
        }
        
        if let error = launchError {
            throw JMSError.configurationError("启动Microsoft Remote Desktop失败: \(error.localizedDescription)")
        }
    }
    
    private func scheduleFileCleanup(_ fileURL: URL) {
        // 30秒后清理临时文件
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 30.0) {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    // MARK: - 配置管理
    
    /// 获取当前RDP质量配置
    public var currentQualityProfile: QualityProfile {
        return configManager.qualityProfile
    }
    
    /// 设置RDP质量配置
    /// - Parameter profile: 质量配置文件
    public func setQualityProfile(_ profile: QualityProfile) {
        configManager.setQualityProfile(profile)
    }
    
    /// 获取所有可用的质量配置文件
    public var availableQualityProfiles: [QualityProfile] {
        return configManager.availableQualityProfiles
    }
    
    /// 更新自定义RDP设置
    /// - Parameter settings: 新的RDP设置
    public func updateCustomSettings(_ settings: RDPSettings) {
        let qualityProfile = RDPConfigManager.convertToQualityProfile(settings)
        configManager.setQualityProfile(qualityProfile)
    }
    
    /// 重置为默认设置
    public func resetToDefaults() {
        configManager.resetToDefaults()
    }
}
