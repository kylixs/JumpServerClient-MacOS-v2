import Foundation
import Cocoa

/// Microsoft Remote Desktop集成器实现类
class RemoteDesktopIntegrator: RemoteDesktopIntegratorProtocol {
    
    // MARK: - Constants
    
    /// Microsoft Remote Desktop应用程序的Bundle ID
    private static let remoteDesktopBundleID = "com.microsoft.rdc.macos"
    
    /// Microsoft Remote Desktop应用程序的可能路径
    private static let remoteDesktopPaths = [
        "/Applications/Microsoft Remote Desktop.app",
        "/Applications/Microsoft Remote Desktop 10.app",
        "~/Applications/Microsoft Remote Desktop.app",
        "~/Applications/Microsoft Remote Desktop 10.app"
    ]
    
    /// 临时文件目录
    private let temporaryDirectory: URL
    
    /// 显示器检测器
    private let displayDetector: DisplayDetector
    
    /// RDP配置优化器
    private let configOptimizer: RDPConfigOptimizer
    
    /// 质量配置管理器
    private let qualityConfigManager: RDPQualityConfigManager
    
    // MARK: - Initialization
    
    init() {
        // 创建临时目录用于存储RDP文件
        self.temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("JMSProtocolHandler", isDirectory: true)
        
        // 初始化显示优化组件
        self.displayDetector = DisplayDetector()
        self.configOptimizer = RDPConfigOptimizer()
        
        // 初始化质量配置管理器
        self.qualityConfigManager = RDPQualityConfigManager.shared
        
        // 确保临时目录存在
        try? FileManager.default.createDirectory(at: temporaryDirectory, 
                                               withIntermediateDirectories: true, 
                                               attributes: nil)
    }
    
    // MARK: - RemoteDesktopIntegratorProtocol Implementation
    
    func checkRemoteDesktopAvailability() -> Bool {
        // 方法1: 通过Bundle ID检查应用程序是否已安装
        if let _ = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.remoteDesktopBundleID) {
            return true
        }
        
        // 方法2: 检查常见的安装路径
        for path in Self.remoteDesktopPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expandedPath) {
                return true
            }
        }
        
        return false
    }
    
    func launchRemoteDesktop(with connectionInfo: RDPConnectionInfo) throws {
        // 获取当前质量配置
        let currentProfile = qualityConfigManager.getCurrentQualityProfile()
        let qualitySettings = qualityConfigManager.getQualityProfileSettings(currentProfile)
        
        // 检测显示器配置
        let displayConfig = try displayDetector.detectPrimaryDisplay()
        
        // 合并质量配置和显示器优化
        let optimizedSettings = try mergeQualityAndDisplaySettings(
            qualitySettings: qualitySettings,
            displayConfig: displayConfig
        )
        
        // 使用优化后的设置启动RDP连接
        try launchOptimizedRemoteDesktop(with: connectionInfo, displaySettings: optimizedSettings)
    }
    
    func launchOptimizedRemoteDesktop(with connectionInfo: RDPConnectionInfo, displaySettings: RDPDisplaySettings) throws {
        // 检查Microsoft Remote Desktop是否可用
        guard checkRemoteDesktopAvailability() else {
            throw JMSError.remoteDesktopNotFound
        }
        
        // 创建优化的临时RDP文件
        let rdpFileURL = try createOptimizedRDPFile(with: connectionInfo, displaySettings: displaySettings)
        
        do {
            // 方法1: 尝试使用Bundle ID启动应用程序
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.remoteDesktopBundleID) {
                try NSWorkspace.shared.open([rdpFileURL], 
                                          withApplicationAt: appURL, 
                                          configuration: NSWorkspace.OpenConfiguration())
            } else {
                // 方法2: 使用系统默认方式打开RDP文件
                let success = NSWorkspace.shared.open(rdpFileURL)
                if !success {
                    throw JMSError.remoteDesktopLaunchFailed
                }
            }
            
            // 延迟清理临时文件（给应用程序足够时间读取文件）
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.cleanupTemporaryFile(at: rdpFileURL)
            }
            
        } catch {
            // 清理临时文件
            cleanupTemporaryFile(at: rdpFileURL)
            throw JMSError.remoteDesktopLaunchFailed
        }
    }
    
    func createTemporaryRDPFile(with connectionInfo: RDPConnectionInfo) throws -> URL {
        // 使用显示优化的方式创建文件
        let displaySettings = try detectAndOptimizeDisplay()
        return try createOptimizedRDPFile(with: connectionInfo, displaySettings: displaySettings)
    }
    
    func createOptimizedRDPFile(with connectionInfo: RDPConnectionInfo, displaySettings: RDPDisplaySettings) throws -> URL {
        // 验证连接信息
        try connectionInfo.validate()
        
        // 验证显示设置
        guard configOptimizer.validateRDPSettings(displaySettings) else {
            throw JMSError.invalidDisplayParameters
        }
        
        // 生成唯一的文件名
        let fileName = "jms_optimized_\(UUID().uuidString).rdp"
        let fileURL = temporaryDirectory.appendingPathComponent(fileName)
        
        // 生成优化的RDP文件内容
        let rdpContent = configOptimizer.generateRDPConfigString(displaySettings, connectionInfo: connectionInfo)
        
        do {
            // 写入RDP文件
            try rdpContent.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // 设置文件权限（只有当前用户可读写）
            try FileManager.default.setAttributes([.posixPermissions: 0o600], 
                                                ofItemAtPath: fileURL.path)
            
            return fileURL
        } catch {
            throw JMSError.rdpConfigGenerationFailed
        }
    }
    
    func detectAndOptimizeDisplay() throws -> RDPDisplaySettings {
        do {
            // 检测主显示器配置
            let displayConfig = try displayDetector.detectPrimaryDisplay()
            
            // 根据显示器特性优化RDP设置
            let optimizedSettings = configOptimizer.optimizeForDisplay(displayConfig)
            
            return optimizedSettings
        } catch {
            throw JMSError.displayDetectionFailed
        }
    }
    
    func cleanupTemporaryFile(at fileURL: URL) {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            // 静默处理清理错误，不影响主要功能
            print("Warning: Failed to cleanup temporary file at \(fileURL.path): \(error)")
        }
    }
    
    // MARK: - Additional Helper Methods
    
    /// 清理所有临时文件
    func cleanupAllTemporaryFiles() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: temporaryDirectory, 
                                                                     includingPropertiesForKeys: nil)
            for fileURL in contents where fileURL.pathExtension == "rdp" {
                cleanupTemporaryFile(at: fileURL)
            }
        } catch {
            print("Warning: Failed to cleanup temporary directory: \(error)")
        }
    }
    
    /// 获取Microsoft Remote Desktop的版本信息
    func getRemoteDesktopVersion() -> String? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.remoteDesktopBundleID) else {
            return nil
        }
        
        guard let bundle = Bundle(url: appURL) else {
            return nil
        }
        
        return bundle.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    /// 验证RDP文件内容格式
    private func validateRDPContent(_ content: String) -> Bool {
        // 检查必要的字段是否存在
        let requiredFields = ["full address:s:", "username:s:"]
        
        for field in requiredFields {
            if !content.contains(field) {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Quality Configuration Integration
    
    /// 合并质量配置和显示器设置
    /// - Parameters:
    ///   - qualitySettings: 用户选择的质量设置
    ///   - displayConfig: 检测到的显示器配置
    /// - Returns: 合并后的RDP显示设置
    /// - Throws: 如果合并过程中出现错误
    private func mergeQualityAndDisplaySettings(
        qualitySettings: RDPQualitySettings,
        displayConfig: DisplayConfiguration
    ) throws -> RDPDisplaySettings {
        
        // 基于显示器配置计算最优分辨率
        let optimalWidth = min(displayConfig.width, 3840) // 限制最大4K分辨率
        let optimalHeight = min(displayConfig.height, 2160)
        
        // 根据显示器特性调整缩放因子
        let scaleFactor = displayConfig.isRetina ? Int(displayConfig.scaleFactor * 100) : 100
        
        // 合并用户质量偏好和显示器优化
        let mergedSettings = RDPDisplaySettings(
            desktopWidth: optimalWidth,
            desktopHeight: optimalHeight,
            sessionBpp: qualitySettings.colorDepth,
            desktopScaleFactor: scaleFactor,
            smartSizing: true, // 始终启用智能调整
            compression: qualitySettings.compressionLevel,
            bitmapCachePersistEnable: qualitySettings.bitmapCaching,
            disableWallpaper: !qualitySettings.enableWallpaper,
            allowFontSmoothing: qualitySettings.enableFontSmoothing && displayConfig.isRetina,
            screenModeId: 2 // 全屏模式
        )
        
        return mergedSettings
    }
    
    /// 快速切换质量配置
    /// - Parameter profile: 要切换到的质量配置文件
    func switchQualityProfile(_ profile: DisplayQualityProfile) {
        qualityConfigManager.setQualityProfile(profile)
        
        // 发送通知告知配置已更改
        NotificationCenter.default.post(
            name: Notification.Name("RDPQualityProfileChanged"),
            object: self,
            userInfo: ["profile": profile]
        )
    }
    
    /// 获取当前质量配置的性能分析
    /// - Returns: 当前配置的性能分析结果
    func getCurrentQualityAnalysis() -> PerformanceAnalysis {
        let currentProfile = qualityConfigManager.getCurrentQualityProfile()
        let qualitySettings = qualityConfigManager.getQualityProfileSettings(currentProfile)
        return qualityConfigManager.analyzePerformanceImpact(for: qualitySettings)
    }
    
    /// 根据网络条件推荐质量配置
    /// - Parameter networkType: 网络类型
    /// - Returns: 推荐的质量配置文件
    func recommendQualityProfile(for networkType: NetworkOptimization) -> DisplayQualityProfile {
        return qualityConfigManager.getConfigurationRecommendation(for: networkType)
    }
    
    /// 创建包含质量配置的RDP文件
    /// - Parameters:
    ///   - connectionInfo: RDP连接信息
    ///   - qualitySettings: 质量设置
    /// - Returns: 临时RDP文件的URL
    /// - Throws: 如果创建文件失败
    func createRDPFileWithQuality(
        connectionInfo: RDPConnectionInfo,
        qualitySettings: RDPQualitySettings
    ) throws -> URL {
        
        // 检测显示器配置
        let displayConfig = try displayDetector.detectPrimaryDisplay()
        
        // 合并质量配置和显示器优化
        let optimizedSettings = try mergeQualityAndDisplaySettings(
            qualitySettings: qualitySettings,
            displayConfig: displayConfig
        )
        
        // 创建优化的RDP文件
        return try createOptimizedRDPFile(with: connectionInfo, displaySettings: optimizedSettings)
    }
}