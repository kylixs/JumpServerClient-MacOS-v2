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
        // 1. 检查Microsoft Remote Desktop是否已安装
        try verifyRemoteDesktopInstallation()
        
        // 2. 生成优化的RDP配置
        let configContent = try configManager.generateOptimizedConfig(for: connectionInfo, quality: quality)
        
        // 3. 创建临时RDP文件
        let rdpFile = try createTemporaryRDPFile(content: configContent, connectionInfo: connectionInfo)
        
        // 4. 启动Microsoft Remote Desktop
        try launchRemoteDesktop(with: rdpFile)
        
        // 5. 发送成功通知
        NotificationManager.shared.showRDPConnectionSuccess(connectionInfo)
        
        // 6. 清理临时文件（延迟执行）
        scheduleFileCleanup(rdpFile)
    }
    
    /// 验证Microsoft Remote Desktop是否已安装
    /// - Throws: JMSError.remoteDesktopNotFound
    public func verifyRemoteDesktopInstallation() throws {
        let possiblePaths = [
            "/Applications/Microsoft Remote Desktop.app",
            "/System/Applications/Microsoft Remote Desktop.app",
            "/Applications/Utilities/Microsoft Remote Desktop.app"
        ]
        
        let fileManager = FileManager.default
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                return // 找到了应用程序
            }
        }
        
        // 尝试通过Bundle ID查找
        if let _ = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.rdc.macos") {
            return // 通过Bundle ID找到了
        }
        
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
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            throw JMSError.fileOperationFailed("无法创建RDP配置文件: \(error.localizedDescription)")
        }
    }
    
    private func launchRemoteDesktop(with rdpFile: URL) throws {
        do {
            let remoteDesktopURL = try getRemoteDesktopPath()
            
            // 使用NSWorkspace启动应用程序并打开RDP文件
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            
            NSWorkspace.shared.openApplication(at: remoteDesktopURL, configuration: configuration) { app, error in
                if let error = error {
                    print("启动Microsoft Remote Desktop失败: \(error.localizedDescription)")
                } else {
                    // 应用程序启动成功后，打开RDP文件
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        NSWorkspace.shared.open(rdpFile)
                    }
                }
            }
            
        } catch {
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
        let qualityProfile = RDPSettingsModel.convertToQualityProfile(settings)
        configManager.setQualityProfile(qualityProfile)
    }
    
    /// 重置为默认设置
    public func resetToDefaults() {
        configManager.resetToDefaults()
    }
}
