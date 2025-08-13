//
//  RDPSettingsModel.swift
//  RDP设置数据模型
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import Foundation

// MARK: - 分辨率设置
public struct ResolutionSettings: Codable {
    public var width: Int
    public var height: Int
    public var isCustom: Bool
    public var presetName: String?
    
    public init(width: Int, height: Int, isCustom: Bool = false, presetName: String? = nil) {
        self.width = width
        self.height = height
        self.isCustom = isCustom
        self.presetName = presetName
    }
    
    // 预设分辨率
    public static let fullHD = ResolutionSettings(width: 1920, height: 1080, presetName: "Full HD")
    public static let twoK = ResolutionSettings(width: 2560, height: 1440, presetName: "2K")
    public static let fourK = ResolutionSettings(width: 3840, height: 2160, presetName: "4K")
    
    public static var presets: [ResolutionSettings] {
        return [fullHD, twoK, fourK]
    }
    
    public var displayName: String {
        if let presetName = presetName {
            return "\(width)×\(height) (\(presetName))"
        } else if isCustom {
            return "\(width)×\(height) (自定义)"
        } else {
            return "\(width)×\(height)"
        }
    }
    
    public var isValid: Bool {
        return width >= 800 && width <= 7680 && height >= 600 && height <= 4320
    }
    
    public var estimatedBandwidth: String {
        let pixels = width * height
        switch pixels {
        case 0..<2073600: // < 1920x1080
            return "< 5 Mbps"
        case 2073600..<3686400: // 1920x1080 - 2560x1440
            return "5-10 Mbps"
        case 3686400..<8294400: // 2560x1440 - 3840x2160
            return "10-25 Mbps"
        default: // > 4K
            return "> 25 Mbps"
        }
    }
}

// MARK: - HiDPI设置
public struct HiDPISettings: Codable {
    public var enabled: Bool
    public var scaleFactor: Double
    public var autoDetect: Bool
    public var forceHiDPI: Bool
    
    public init(enabled: Bool = false, scaleFactor: Double = 1.0, autoDetect: Bool = true, forceHiDPI: Bool = false) {
        self.enabled = enabled
        self.scaleFactor = scaleFactor
        self.autoDetect = autoDetect
        self.forceHiDPI = forceHiDPI
    }
    
    public var scaleFactorDescription: String {
        switch scaleFactor {
        case 1.0:
            return "100% (标准)"
        case 1.25:
            return "125% (小)"
        case 1.5:
            return "150% (中)"
        case 2.0:
            return "200% (大)"
        case 2.5:
            return "250% (更大)"
        case 3.0:
            return "300% (最大)"
        default:
            return "\(Int(scaleFactor * 100))% (自定义)"
        }
    }
}

// MARK: - RDP设置数据模型
public struct RDPSettings: Codable {
    public var profileName: String
    public var compressionLevel: Int
    public var colorDepth: Int
    public var audioQuality: String
    public var enableFontSmoothing: Bool
    public var enableWallpaper: Bool
    public var enableMenuAnimations: Bool
    public var enableThemes: Bool
    
    // 新增：分辨率和HiDPI设置
    public var resolution: ResolutionSettings
    public var hiDPI: HiDPISettings
    public var useAutoDetection: Bool
    
    public init(
        profileName: String,
        compressionLevel: Int,
        colorDepth: Int,
        audioQuality: String,
        enableFontSmoothing: Bool,
        enableWallpaper: Bool,
        enableMenuAnimations: Bool,
        enableThemes: Bool,
        resolution: ResolutionSettings = ResolutionSettings.fullHD,
        hiDPI: HiDPISettings = HiDPISettings(),
        useAutoDetection: Bool = true
    ) {
        self.profileName = profileName
        self.compressionLevel = compressionLevel
        self.colorDepth = colorDepth
        self.audioQuality = audioQuality
        self.enableFontSmoothing = enableFontSmoothing
        self.enableWallpaper = enableWallpaper
        self.enableMenuAnimations = enableMenuAnimations
        self.enableThemes = enableThemes
        self.resolution = resolution
        self.hiDPI = hiDPI
        self.useAutoDetection = useAutoDetection
    }
    
    // MARK: - 预设配置
    public static let performance = RDPSettings(
        profileName: "性能优先",
        compressionLevel: 2,
        colorDepth: 16,
        audioQuality: "禁用",
        enableFontSmoothing: false,
        enableWallpaper: false,
        enableMenuAnimations: false,
        enableThemes: false,
        resolution: ResolutionSettings.fullHD,
        hiDPI: HiDPISettings(enabled: false, scaleFactor: 1.0),
        useAutoDetection: false
    )
    
    public static let balanced = RDPSettings(
        profileName: "平衡模式",
        compressionLevel: 1,
        colorDepth: 24,
        audioQuality: "中等",
        enableFontSmoothing: true,
        enableWallpaper: true,
        enableMenuAnimations: false,
        enableThemes: true,
        resolution: ResolutionSettings.fullHD,
        hiDPI: HiDPISettings(enabled: true, scaleFactor: 1.5),
        useAutoDetection: true
    )
    
    public static let quality = RDPSettings(
        profileName: "质量优先",
        compressionLevel: 0,
        colorDepth: 32,
        audioQuality: "高质量",
        enableFontSmoothing: true,
        enableWallpaper: true,
        enableMenuAnimations: true,
        enableThemes: true,
        resolution: ResolutionSettings.twoK,
        hiDPI: HiDPISettings(enabled: true, scaleFactor: 2.0),
        useAutoDetection: true
    )
    
    // MARK: - 静态方法
    
    /// 获取所有预设配置
    public static var allPresets: [RDPSettings] {
        return [performance, balanced, quality]
    }
    
    /// 根据名称获取预设配置
    public static func preset(named name: String) -> RDPSettings? {
        return allPresets.first { $0.profileName == name }
    }
    
    // MARK: - 实例方法
    
    /// 生成RDP配置文件内容
    public func generateRDPContent(server: String, username: String) -> String {
        var content = """
        full address:s:\(server)
        username:s:\(username)
        audiomode:i:\(getAudioMode())
        compression:i:\(compressionLevel)
        session bpp:i:\(colorDepth)
        smart sizing:i:1
        screen mode id:i:2
        desktopwidth:i:\(resolution.width)
        desktopheight:i:\(resolution.height)
        font smoothing:i:\(enableFontSmoothing ? 1 : 0)
        disable wallpaper:i:\(enableWallpaper ? 0 : 1)
        disable menu anims:i:\(enableMenuAnimations ? 0 : 1)
        disable themes:i:\(enableThemes ? 0 : 1)
        """
        
        // 添加HiDPI相关设置
        if hiDPI.enabled {
            content += "\ndesktopscalefactor:i:\(Int(hiDPI.scaleFactor * 100))"
            content += "\nhidef color depth:i:\(colorDepth)"
        }
        
        return content
    }
    
    /// 生成配置预览文本
    public func generatePreview() -> String {
        return """
        # RDP配置预览
        
        配置文件: \(profileName)
        
        显示设置:
        分辨率: \(resolution.displayName)
        HiDPI: \(hiDPI.enabled ? "启用 (\(hiDPI.scaleFactorDescription))" : "禁用")
        自动检测: \(useAutoDetection ? "启用" : "禁用")
        
        质量设置:
        压缩级别: \(compressionLevel == 0 ? "无压缩" : (compressionLevel == 1 ? "中等" : "高压缩"))
        颜色深度: \(colorDepth)位
        音频质量: \(audioQuality)
        
        特效设置:
        \(enableFontSmoothing ? "✓" : "✗") 字体平滑
        \(enableWallpaper ? "✓" : "✗") 桌面壁纸
        \(enableMenuAnimations ? "✓" : "✗") 菜单动画
        \(enableThemes ? "✓" : "✗") 视觉主题
        
        性能预估:
        预计带宽: \(resolution.estimatedBandwidth)
        清晰度评级: \(getClarityRating())
        
        适用场景:
        \(getScenarioDescription())
        
        最后更新: \(getCurrentTimeString())
        """
    }
    
    // MARK: - 私有方法
    
    private func getAudioMode() -> Int {
        switch audioQuality {
        case "禁用": return 2
        case "低质量": return 1
        case "中等": return 0
        case "高质量": return 0
        default: return 0
        }
    }
    
    private func getClarityRating() -> String {
        let pixels = resolution.width * resolution.height
        let hiDPIBonus = hiDPI.enabled ? 1 : 0
        let colorBonus = colorDepth >= 24 ? 1 : 0
        let compressionPenalty = compressionLevel
        
        let score = (pixels / 1000000) + hiDPIBonus + colorBonus - compressionPenalty
        
        switch score {
        case ..<1:
            return "基础 ⭐"
        case 1..<3:
            return "良好 ⭐⭐"
        case 3..<5:
            return "优秀 ⭐⭐⭐"
        case 5..<8:
            return "极佳 ⭐⭐⭐⭐"
        default:
            return "完美 ⭐⭐⭐⭐⭐"
        }
    }
    
    private func getScenarioDescription() -> String {
        if compressionLevel == 2 && !enableWallpaper {
            return "• 低带宽网络环境\n• 移动网络连接\n• 性能优先场景"
        } else if compressionLevel == 0 && enableThemes {
            return "• 高速网络环境\n• 设计和图形工作\n• 质量优先场景"
        } else {
            return "• 一般办公环境\n• 宽带网络连接\n• 平衡性能和质量"
        }
    }
    
    private func getCurrentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
}

// MARK: - RDP设置错误类型
public enum RDPSettingsError: LocalizedError {
    case noCurrentSettings
    case saveFailed(Error)
    case exportFailed(Error)
    case importFailed(Error)
    case presetNotFound(String)
    case invalidSettings
    
    public var errorDescription: String? {
        switch self {
        case .noCurrentSettings:
            return "没有当前设置"
        case .saveFailed(let error):
            return "保存设置失败: \(error.localizedDescription)"
        case .exportFailed(let error):
            return "导出设置失败: \(error.localizedDescription)"
        case .importFailed(let error):
            return "导入设置失败: \(error.localizedDescription)"
        case .presetNotFound(let name):
            return "未找到预设配置: \(name)"
        case .invalidSettings:
            return "设置参数无效"
        }
    }
}
