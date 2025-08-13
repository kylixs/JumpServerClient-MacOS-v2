import Foundation
import Cocoa
import CoreGraphics
import JMSCore

/// 统一的RDP配置管理器
/// 合并了显示器优化、质量配置和设置管理功能
public class RDPConfigManager {
    
    public static let shared = RDPConfigManager()
    
    private let displayDetector = DisplayDetector()
    private var currentQualityProfile: QualityProfile = .balanced
    
    private var isTestEnvironment: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
               ProcessInfo.processInfo.arguments.contains { $0.contains("xctest") }
    }
    
    private init() {
        if !isTestEnvironment {
            loadSavedSettings()
        }
    }
    
    // MARK: - 主要接口
    
    /// 生成优化的RDP配置
    /// - Parameters:
    ///   - connectionInfo: RDP连接信息
    ///   - qualityProfile: 质量配置文件
    /// - Returns: 完整的RDP配置文件内容
    /// - Throws: JMSError.configurationError
    public func generateOptimizedConfig(for connectionInfo: RDPConnectionInfo, quality: QualityProfile? = nil) throws -> String {
        // 1. 检测显示器配置
        let displayConfig = try displayDetector.detectPrimaryDisplay()
        
        // 2. 应用质量配置
        let qualityProfile = quality ?? currentQualityProfile
        let settings = RDPSettingsModel.convertFromQualityProfile(qualityProfile)
        let optimizedSettings = optimizeSettings(for: displayConfig, settings: settings)
        
        // 3. 生成RDP配置文件
        return generateRDPConfigFile(connectionInfo: connectionInfo, settings: optimizedSettings, displayConfig: displayConfig)
    }
    
    /// 更新质量配置文件
    /// - Parameter profile: 新的质量配置文件
    public func setQualityProfile(_ profile: QualityProfile) {
        currentQualityProfile = profile
        
        if !isTestEnvironment {
            saveSettings()
        }
        
        // 发送通知
        NotificationManager.shared.showInfoNotification(
            title: "RDP质量配置已更新",
            message: "已切换到\(profile.displayName)模式"
        )
    }
    
    /// 获取当前质量配置文件
    public var qualityProfile: QualityProfile {
        return currentQualityProfile
    }
    
    /// 获取所有可用的质量配置文件
    public var availableQualityProfiles: [QualityProfile] {
        return [.performance, .balanced, .quality]
    }
    
    /// 获取当前设置
    public var settings: RDPSettings {
        return RDPSettingsModel.convertFromQualityProfile(currentQualityProfile)
    }
    
    /// 重置为默认设置
    public func resetToDefaults() {
        currentQualityProfile = .balanced
        
        if !isTestEnvironment {
            saveSettings()
        }
    }
    
    // MARK: - 显示器优化
    
    private func optimizeSettings(for displayConfig: DisplayConfiguration, settings: RDPSettings) -> RDPSettings {
        var optimizedSettings = settings
        
        // 根据显示器配置优化设置
        optimizedSettings = optimizeForDisplay(optimizedSettings, displayConfig: displayConfig)
        
        return optimizedSettings
    }
    
    private func optimizeForDisplay(_ settings: RDPSettings, displayConfig: DisplayConfiguration) -> RDPSettings {
        var optimizedSettings = settings
        
        // 根据显示器特性调整设置
        if displayConfig.isHiDPI {
            // HiDPI显示器优化
            optimizedSettings.enableFontSmoothing = true
            
            // 根据分辨率调整压缩级别
            if displayConfig.width >= 3840 {
                // 4K及以上显示器，降低压缩以保证质量
                if optimizedSettings.compressionLevel > 1 {
                    optimizedSettings.compressionLevel = max(0, optimizedSettings.compressionLevel - 1)
                }
            }
        }
        
        return optimizedSettings
    }
    
    // MARK: - 配置文件生成
    
    private func generateRDPConfigFile(connectionInfo: RDPConnectionInfo, settings: RDPSettings, displayConfig: DisplayConfiguration) -> String {
        var configLines: [String] = []
        
        // 基本连接信息
        configLines.append("full address:s:\(connectionInfo.serverAddress)")
        configLines.append("username:s:\(connectionInfo.username)")
        
        // 显示设置
        configLines.append("desktopwidth:i:\(displayConfig.width)")
        configLines.append("desktopheight:i:\(displayConfig.height)")
        configLines.append("session bpp:i:\(settings.colorDepth)")
        
        // 性能设置
        configLines.append("compression:i:\(settings.compressionLevel)")
        configLines.append("font smoothing:i:\(settings.enableFontSmoothing ? 1 : 0)")
        
        // 特效设置
        configLines.append("disable wallpaper:i:\(settings.enableWallpaper ? 0 : 1)")
        configLines.append("disable menu anims:i:\(settings.enableMenuAnimations ? 0 : 1)")
        configLines.append("disable themes:i:\(settings.enableThemes ? 0 : 1)")
        
        // 音频设置
        let audioMode = getAudioMode(from: settings.audioQuality)
        configLines.append("audiomode:i:\(audioMode)")
        
        // 其他设置
        configLines.append("smart sizing:i:1")
        configLines.append("screen mode id:i:2")
        
        return configLines.joined(separator: "\n")
    }
    
    private func getAudioMode(from audioQuality: String) -> Int {
        switch audioQuality {
        case "禁用": return 2
        case "低质量": return 1
        case "中等": return 0
        case "高质量": return 0
        default: return 0
        }
    }
    
    // MARK: - 设置持久化
    
    private func saveSettings() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(currentQualityProfile.identifier, forKey: "RDPQualityProfile")
        
        // 保存自定义设置
        if case .custom(let settings) = currentQualityProfile {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(settings) {
                userDefaults.set(data, forKey: "RDPCustomSettings")
            }
        }
    }
    
    private func loadSavedSettings() {
        let userDefaults = UserDefaults.standard
        let profileIdentifier = userDefaults.string(forKey: "RDPQualityProfile") ?? "balanced"
        
        if let profile = QualityProfile.fromIdentifier(profileIdentifier) {
            currentQualityProfile = profile
        }
        
        // 加载自定义设置
        if case .custom = currentQualityProfile,
           let data = userDefaults.data(forKey: "RDPCustomSettings") {
            let decoder = JSONDecoder()
            if let settings = try? decoder.decode(RDPSettings.self, from: data) {
                currentQualityProfile = .custom(settings)
            }
        }
    }
}

// MARK: - 质量配置文件

/// 质量配置文件
public enum QualityProfile {
    case performance    // 性能优先
    case balanced      // 平衡模式
    case quality       // 质量优先
    case custom(RDPSettings)
    
    public var displayName: String {
        switch self {
        case .performance: return "性能优先"
        case .balanced: return "平衡模式"
        case .quality: return "质量优先"
        case .custom: return "自定义配置"
        }
    }
    
    public var identifier: String {
        switch self {
        case .performance: return "performance"
        case .balanced: return "balanced"
        case .quality: return "quality"
        case .custom: return "custom"
        }
    }
    
    public static func fromIdentifier(_ identifier: String) -> QualityProfile? {
        switch identifier {
        case "performance": return .performance
        case "balanced": return .balanced
        case "quality": return .quality
        case "custom": return .custom(RDPSettings.balanced)
        default: return nil
        }
    }
}

// MARK: - RDPSettings转换辅助

/// RDPSettings模型转换辅助类
public struct RDPSettingsModel {
    
    /// 从质量配置文件转换为RDPSettings
    public static func convertFromQualityProfile(_ profile: QualityProfile) -> RDPSettings {
        switch profile {
        case .performance:
            return RDPSettings.performance
        case .balanced:
            return RDPSettings.balanced
        case .quality:
            return RDPSettings.quality
        case .custom(let settings):
            return settings
        }
    }
    
    /// 从RDPSettings转换为质量配置文件
    public static func convertToQualityProfile(_ settings: RDPSettings) -> QualityProfile {
        // 检查是否匹配预设配置
        if settings.profileName == RDPSettings.performance.profileName {
            return .performance
        } else if settings.profileName == RDPSettings.balanced.profileName {
            return .balanced
        } else if settings.profileName == RDPSettings.quality.profileName {
            return .quality
        } else {
            return .custom(settings)
        }
    }
}
