//
//  RDPSettingsModel.swift
//  RDP设置数据模型
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import Foundation

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
    
    public init(
        profileName: String,
        compressionLevel: Int,
        colorDepth: Int,
        audioQuality: String,
        enableFontSmoothing: Bool,
        enableWallpaper: Bool,
        enableMenuAnimations: Bool,
        enableThemes: Bool
    ) {
        self.profileName = profileName
        self.compressionLevel = compressionLevel
        self.colorDepth = colorDepth
        self.audioQuality = audioQuality
        self.enableFontSmoothing = enableFontSmoothing
        self.enableWallpaper = enableWallpaper
        self.enableMenuAnimations = enableMenuAnimations
        self.enableThemes = enableThemes
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
        enableThemes: false
    )
    
    public static let balanced = RDPSettings(
        profileName: "平衡模式",
        compressionLevel: 1,
        colorDepth: 24,
        audioQuality: "中等",
        enableFontSmoothing: true,
        enableWallpaper: true,
        enableMenuAnimations: false,
        enableThemes: true
    )
    
    public static let quality = RDPSettings(
        profileName: "质量优先",
        compressionLevel: 0,
        colorDepth: 32,
        audioQuality: "高质量",
        enableFontSmoothing: true,
        enableWallpaper: true,
        enableMenuAnimations: true,
        enableThemes: true
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
        return """
        full address:s:\(server)
        username:s:\(username)
        audiomode:i:\(getAudioMode())
        compression:i:\(compressionLevel)
        session bpp:i:\(colorDepth)
        smart sizing:i:1
        screen mode id:i:2
        desktopwidth:i:1920
        desktopheight:i:1080
        font smoothing:i:\(enableFontSmoothing ? 1 : 0)
        disable wallpaper:i:\(enableWallpaper ? 0 : 1)
        disable menu anims:i:\(enableMenuAnimations ? 0 : 1)
        disable themes:i:\(enableThemes ? 0 : 1)
        """
    }
    
    /// 生成配置预览文本
    public func generatePreview() -> String {
        return """
        # RDP配置预览
        
        配置文件: \(profileName)
        压缩级别: \(compressionLevel == 0 ? "无压缩" : (compressionLevel == 1 ? "中等" : "高压缩"))
        颜色深度: \(colorDepth)位
        音频质量: \(audioQuality)
        
        特效设置:
        \(enableFontSmoothing ? "✓" : "✗") 字体平滑
        \(enableWallpaper ? "✓" : "✗") 桌面壁纸
        \(enableMenuAnimations ? "✓" : "✗") 菜单动画
        \(enableThemes ? "✓" : "✗") 视觉主题
        
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
