//
//  RDPQualityConfiguration.swift
//  JMSProtocolHandler
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import Foundation

// MARK: - Quality Profile Enums

/// RDP显示质量配置文件类型
enum DisplayQualityProfile: String, CaseIterable, Codable {
    case performance = "performance"    // 优先性能
    case balanced = "balanced"         // 平衡模式
    case quality = "quality"           // 优先质量
    case custom = "custom"             // 自定义配置
    
    var displayName: String {
        switch self {
        case .performance:
            return "性能优先"
        case .balanced:
            return "平衡模式"
        case .quality:
            return "质量优先"
        case .custom:
            return "自定义配置"
        }
    }
    
    var description: String {
        switch self {
        case .performance:
            return "适合低带宽网络环境，优化连接速度"
        case .balanced:
            return "性能与质量的最佳平衡，适合大多数场景"
        case .quality:
            return "适合高带宽局域网环境，提供最佳显示质量"
        case .custom:
            return "用户自定义的配置参数"
        }
    }
}

/// 音频质量级别
enum AudioQuality: String, CaseIterable, Codable {
    case disabled = "disabled"         // 禁用音频
    case low = "low"                  // 低质量
    case medium = "medium"            // 中等质量
    case high = "high"                // 高质量
    
    var displayName: String {
        switch self {
        case .disabled: return "禁用"
        case .low: return "低质量"
        case .medium: return "中等"
        case .high: return "高质量"
        }
    }
    
    var audioMode: Int {
        switch self {
        case .disabled: return 2  // 禁用音频
        case .low: return 0       // 本地播放，低质量
        case .medium: return 0    // 本地播放，中等质量
        case .high: return 0      // 本地播放，高质量
        }
    }
}

/// 网络优化类型
enum NetworkOptimization: String, CaseIterable, Codable {
    case modem = "modem"              // 调制解调器
    case lowBroadband = "lowBroadband" // 低速宽带
    case broadband = "broadband"       // 宽带
    case lan = "lan"                  // 局域网
    case auto = "auto"                // 自动检测
    
    var displayName: String {
        switch self {
        case .modem: return "调制解调器"
        case .lowBroadband: return "低速宽带"
        case .broadband: return "宽带"
        case .lan: return "局域网"
        case .auto: return "自动检测"
        }
    }
    
    var connectionType: Int {
        switch self {
        case .modem: return 1
        case .lowBroadband: return 2
        case .broadband: return 6
        case .lan: return 6
        case .auto: return 7
        }
    }
}

/// 性能影响级别
enum PerformanceLevel: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "低"
        case .medium: return "中等"
        case .high: return "高"
        }
    }
}

/// 质量级别
enum QualityLevel: String, Codable {
    case basic = "basic"
    case standard = "standard"
    case premium = "premium"
    case ultra = "ultra"
    
    var displayName: String {
        switch self {
        case .basic: return "基础"
        case .standard: return "标准"
        case .premium: return "高级"
        case .ultra: return "极致"
        }
    }
}

// MARK: - Quality Settings

/// RDP质量设置
struct RDPQualitySettings: Codable, Equatable {
    let compressionLevel: Int           // 0-2 (0=无压缩, 1=RDP6.0, 2=RDP6.1)
    let colorDepth: Int                // 16/24/32 位
    let enableFontSmoothing: Bool      // 字体平滑
    let enableWallpaper: Bool          // 桌面壁纸
    let enableMenuAnimations: Bool     // 菜单动画
    let enableThemes: Bool             // 视觉主题
    let enableFullWindowDrag: Bool     // 完整窗口拖拽
    let bitmapCaching: Bool            // 位图缓存
    let audioQuality: AudioQuality     // 音频质量
    let networkOptimization: NetworkOptimization // 网络优化
    
    // 性能影响评估
    let estimatedBandwidth: String     // 预估带宽需求
    let performanceImpact: PerformanceLevel // 性能影响级别
    let qualityLevel: QualityLevel     // 质量级别
    
    // MARK: - Predefined Configurations
    
    /// 性能优先配置
    static let performanceOptimized = RDPQualitySettings(
        compressionLevel: 2,           // 最高压缩
        colorDepth: 16,               // 16位色彩
        enableFontSmoothing: false,   // 禁用字体平滑
        enableWallpaper: false,       // 禁用壁纸
        enableMenuAnimations: false,  // 禁用动画
        enableThemes: false,          // 禁用主题
        enableFullWindowDrag: false,  // 禁用完整窗口拖拽
        bitmapCaching: true,          // 启用位图缓存
        audioQuality: .low,           // 低音频质量
        networkOptimization: .broadband,
        estimatedBandwidth: "< 1 Mbps",
        performanceImpact: .low,
        qualityLevel: .basic
    )
    
    /// 平衡模式配置
    static let balanced = RDPQualitySettings(
        compressionLevel: 1,           // 中等压缩
        colorDepth: 24,               // 24位色彩
        enableFontSmoothing: true,    // 启用字体平滑
        enableWallpaper: false,       // 禁用壁纸
        enableMenuAnimations: true,   // 启用动画
        enableThemes: true,           // 启用主题
        enableFullWindowDrag: false,  // 禁用完整窗口拖拽
        bitmapCaching: true,          // 启用位图缓存
        audioQuality: .medium,        // 中等音频质量
        networkOptimization: .broadband,
        estimatedBandwidth: "1-3 Mbps",
        performanceImpact: .medium,
        qualityLevel: .standard
    )
    
    /// 质量优先配置
    static let qualityOptimized = RDPQualitySettings(
        compressionLevel: 0,           // 无压缩
        colorDepth: 32,               // 32位色彩
        enableFontSmoothing: true,    // 启用字体平滑
        enableWallpaper: true,        // 启用壁纸
        enableMenuAnimations: true,   // 启用动画
        enableThemes: true,           // 启用主题
        enableFullWindowDrag: true,   // 启用完整窗口拖拽
        bitmapCaching: true,          // 启用位图缓存
        audioQuality: .high,          // 高音频质量
        networkOptimization: .lan,
        estimatedBandwidth: "> 5 Mbps",
        performanceImpact: .high,
        qualityLevel: .premium
    )
    
    /// 获取预设配置
    static func getPresetConfiguration(for profile: DisplayQualityProfile) -> RDPQualitySettings {
        switch profile {
        case .performance:
            return performanceOptimized
        case .balanced:
            return balanced
        case .quality:
            return qualityOptimized
        case .custom:
            return balanced // 自定义配置的默认基础
        }
    }
}

// MARK: - Custom Configuration

/// 自定义RDP配置
struct RDPCustomConfiguration: Codable, Equatable {
    let name: String                   // 自定义配置名称
    let settings: RDPQualitySettings   // 质量设置
    let displayOptimization: Bool      // 是否启用显示器优化
    let createdDate: Date             // 创建时间
    let lastModified: Date            // 最后修改时间
    
    init(name: String, settings: RDPQualitySettings, displayOptimization: Bool = true) {
        self.name = name
        self.settings = settings
        self.displayOptimization = displayOptimization
        self.createdDate = Date()
        self.lastModified = Date()
    }
}

// MARK: - Configuration Store

/// 质量配置存储
struct QualityConfigurationStore: Codable {
    let currentProfile: DisplayQualityProfile
    let customConfigurations: [String: RDPCustomConfiguration]
    let profileSettings: [DisplayQualityProfile: RDPQualitySettings]
    let lastUpdated: Date
    let version: String
    
    /// 默认配置存储
    static let defaultStore = QualityConfigurationStore(
        currentProfile: .balanced,
        customConfigurations: [:],
        profileSettings: [
            .performance: RDPQualitySettings.performanceOptimized,
            .balanced: RDPQualitySettings.balanced,
            .quality: RDPQualitySettings.qualityOptimized
        ],
        lastUpdated: Date(),
        version: "1.0"
    )
    
    /// 更新当前配置文件
    func updatingCurrentProfile(_ profile: DisplayQualityProfile) -> QualityConfigurationStore {
        return QualityConfigurationStore(
            currentProfile: profile,
            customConfigurations: customConfigurations,
            profileSettings: profileSettings,
            lastUpdated: Date(),
            version: version
        )
    }
    
    /// 添加自定义配置
    func addingCustomConfiguration(_ config: RDPCustomConfiguration) -> QualityConfigurationStore {
        var updatedCustomConfigs = customConfigurations
        updatedCustomConfigs[config.name] = config
        
        return QualityConfigurationStore(
            currentProfile: currentProfile,
            customConfigurations: updatedCustomConfigs,
            profileSettings: profileSettings,
            lastUpdated: Date(),
            version: version
        )
    }
    
    /// 移除自定义配置
    func removingCustomConfiguration(named name: String) -> QualityConfigurationStore {
        var updatedCustomConfigs = customConfigurations
        updatedCustomConfigs.removeValue(forKey: name)
        
        return QualityConfigurationStore(
            currentProfile: currentProfile == .custom ? .balanced : currentProfile,
            customConfigurations: updatedCustomConfigs,
            profileSettings: profileSettings,
            lastUpdated: Date(),
            version: version
        )
    }
}

// MARK: - Validation

/// 配置验证结果
enum ValidationResult: Equatable {
    case valid
    case invalid(reasons: [String])
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var errorMessages: [String] {
        switch self {
        case .valid:
            return []
        case .invalid(let reasons):
            return reasons
        }
    }
}

// MARK: - Configuration Validation

extension RDPQualitySettings {
    /// 验证配置的有效性
    func validate() -> ValidationResult {
        var errors: [String] = []
        
        // 验证压缩级别
        if compressionLevel < 0 || compressionLevel > 2 {
            errors.append("压缩级别必须在0-2之间")
        }
        
        // 验证颜色深度
        if ![16, 24, 32].contains(colorDepth) {
            errors.append("颜色深度必须是16、24或32位")
        }
        
        // 验证带宽估算格式
        if estimatedBandwidth.isEmpty {
            errors.append("带宽估算不能为空")
        }
        
        return errors.isEmpty ? .valid : .invalid(reasons: errors)
    }
    
    /// 计算配置的复杂度评分（用于性能评估）
    var complexityScore: Int {
        var score = 0
        
        // 压缩级别影响（压缩级别越低，复杂度越高）
        score += (2 - compressionLevel) * 10
        
        // 颜色深度影响
        score += colorDepth / 8
        
        // 特效影响
        if enableFontSmoothing { score += 5 }
        if enableWallpaper { score += 8 }
        if enableMenuAnimations { score += 3 }
        if enableThemes { score += 4 }
        if enableFullWindowDrag { score += 6 }
        
        // 音频质量影响
        switch audioQuality {
        case .disabled: score += 0
        case .low: score += 2
        case .medium: score += 4
        case .high: score += 6
        }
        
        return score
    }
}
