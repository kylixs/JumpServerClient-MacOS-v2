//
//  RDPSettingsManager.swift
//  RDP设置管理器
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import Foundation

// MARK: - RDP设置管理器
public class RDPSettingsManager {
    
    // MARK: - 单例
    public static let shared = RDPSettingsManager()
    
    // MARK: - 属性
    private var settingsURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("JMSRDPSettings.json")
    }
    
    private var _currentSettings: RDPSettings?
    
    // MARK: - 初始化
    private init() {}
    
    // MARK: - 公共接口
    
    /// 检查是否有自定义设置
    public func hasCustomSettings() -> Bool {
        return FileManager.default.fileExists(atPath: settingsURL.path)
    }
    
    /// 获取当前设置
    public var currentSettings: RDPSettings {
        if let settings = _currentSettings {
            return settings
        }
        let settings = loadSettings()
        _currentSettings = settings
        return settings
    }
    
    /// 更新当前设置
    public func updateSettings(_ settings: RDPSettings) {
        _currentSettings = settings
        print("🔄 RDP设置已更新: \(settings.profileName)")
    }
    
    /// 加载设置
    public func loadSettings() -> RDPSettings {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            print("📄 使用默认RDP设置")
            return RDPSettings.balanced
        }
        
        do {
            let data = try Data(contentsOf: settingsURL)
            let settings = try JSONDecoder().decode(RDPSettings.self, from: data)
            print("✅ 已加载RDP设置: \(settings.profileName)")
            return settings
        } catch {
            print("❌ 加载RDP设置失败，使用默认设置: \(error.localizedDescription)")
            return RDPSettings.balanced
        }
    }
    
    /// 保存当前设置
    public func saveSettings() throws {
        guard let settings = _currentSettings else {
            throw RDPSettingsError.noCurrentSettings
        }
        
        try saveSettings(settings)
    }
    
    /// 保存指定设置
    public func saveSettings(_ settings: RDPSettings) throws {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(settings)
            try data.write(to: settingsURL)
            _currentSettings = settings
            print("💾 RDP设置已保存: \(settings.profileName)")
        } catch {
            print("❌ 保存RDP设置失败: \(error.localizedDescription)")
            throw RDPSettingsError.saveFailed(error)
        }
    }
    
    /// 重置为默认设置
    public func resetToDefault() throws {
        let defaultSettings = RDPSettings.balanced
        try saveSettings(defaultSettings)
        print("🔄 RDP设置已重置为默认")
    }
    
    /// 导出设置到指定URL
    public func exportSettings(to url: URL) throws {
        let settings = currentSettings
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(settings)
            try data.write(to: url)
            print("📤 RDP设置已导出到: \(url.path)")
        } catch {
            print("❌ 导出RDP设置失败: \(error.localizedDescription)")
            throw RDPSettingsError.exportFailed(error)
        }
    }
    
    /// 从指定URL导入设置
    public func importSettings(from url: URL) throws {
        do {
            let data = try Data(contentsOf: url)
            let settings = try JSONDecoder().decode(RDPSettings.self, from: data)
            try saveSettings(settings)
            print("📥 RDP设置已导入: \(settings.profileName)")
        } catch {
            print("❌ 导入RDP设置失败: \(error.localizedDescription)")
            throw RDPSettingsError.importFailed(error)
        }
    }
    
    /// 应用预设配置
    public func applyPreset(_ preset: RDPSettings) {
        updateSettings(preset)
        print("📊 应用RDP预设配置: \(preset.profileName)")
    }
    
    /// 应用预设配置（根据名称）
    public func applyPreset(named name: String) throws {
        guard let preset = RDPSettings.preset(named: name) else {
            throw RDPSettingsError.presetNotFound(name)
        }
        applyPreset(preset)
    }
    
    /// 验证设置有效性
    public func validateSettings(_ settings: RDPSettings) -> Bool {
        // 检查压缩级别
        guard settings.compressionLevel >= 0 && settings.compressionLevel <= 2 else {
            return false
        }
        
        // 检查颜色深度
        let validColorDepths = [16, 24, 32]
        guard validColorDepths.contains(settings.colorDepth) else {
            return false
        }
        
        // 检查音频质量
        let validAudioQualities = ["禁用", "低质量", "中等", "高质量"]
        guard validAudioQualities.contains(settings.audioQuality) else {
            return false
        }
        
        return true
    }
    
    /// 获取当前日期字符串（用于文件名）
    public func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }
}
