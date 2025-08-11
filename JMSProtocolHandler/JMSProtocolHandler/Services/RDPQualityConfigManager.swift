//
//  RDPQualityConfigManager.swift
//  JMSProtocolHandler
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import Foundation

// MARK: - Protocol Definition

/// RDP质量配置管理器协议
protocol RDPQualityConfigManagerProtocol {
    func getCurrentQualityProfile() -> DisplayQualityProfile
    func setQualityProfile(_ profile: DisplayQualityProfile)
    func getCustomConfiguration() -> RDPCustomConfiguration?
    func saveCustomConfiguration(_ config: RDPCustomConfiguration)
    func resetToDefaultConfiguration()
    func getQualityProfileSettings(_ profile: DisplayQualityProfile) -> RDPQualitySettings
    func validateConfiguration(_ config: RDPCustomConfiguration) -> ValidationResult
    func getAllCustomConfigurations() -> [RDPCustomConfiguration]
    func deleteCustomConfiguration(named name: String)
    func exportConfiguration() -> String?
    func importConfiguration(_ configString: String) -> Bool
}

// MARK: - Implementation

/// RDP质量配置管理器实现
class RDPQualityConfigManager: RDPQualityConfigManagerProtocol {
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let configKey = "RDPQualityConfiguration"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // 配置变更通知
    static let configurationDidChangeNotification = Notification.Name("RDPQualityConfigurationDidChange")
    
    // MARK: - Initialization
    
    init() {
        setupEncoder()
        setupDecoder()
        
        // 如果是首次运行，初始化默认配置
        if loadConfiguration() == nil {
            saveConfiguration(QualityConfigurationStore.defaultStore)
        }
    }
    
    private func setupEncoder() {
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
    }
    
    private func setupDecoder() {
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Configuration Storage
    
    /// 加载配置
    private func loadConfiguration() -> QualityConfigurationStore? {
        guard let data = userDefaults.data(forKey: configKey) else {
            return nil
        }
        
        do {
            return try decoder.decode(QualityConfigurationStore.self, from: data)
        } catch {
            print("Failed to decode quality configuration: \(error)")
            return nil
        }
    }
    
    /// 保存配置
    private func saveConfiguration(_ store: QualityConfigurationStore) {
        do {
            let data = try encoder.encode(store)
            userDefaults.set(data, forKey: configKey)
            
            // 发送配置变更通知
            NotificationCenter.default.post(
                name: Self.configurationDidChangeNotification,
                object: self,
                userInfo: ["profile": store.currentProfile]
            )
        } catch {
            print("Failed to encode quality configuration: \(error)")
        }
    }
    
    /// 获取当前配置存储
    private func getCurrentStore() -> QualityConfigurationStore {
        return loadConfiguration() ?? QualityConfigurationStore.defaultStore
    }
    
    // MARK: - Protocol Implementation
    
    func getCurrentQualityProfile() -> DisplayQualityProfile {
        return getCurrentStore().currentProfile
    }
    
    func setQualityProfile(_ profile: DisplayQualityProfile) {
        let currentStore = getCurrentStore()
        let updatedStore = currentStore.updatingCurrentProfile(profile)
        saveConfiguration(updatedStore)
    }
    
    func getCustomConfiguration() -> RDPCustomConfiguration? {
        let store = getCurrentStore()
        guard store.currentProfile == .custom else {
            return nil
        }
        
        // 返回第一个自定义配置，或者创建一个默认的
        return store.customConfigurations.values.first ?? createDefaultCustomConfiguration()
    }
    
    func saveCustomConfiguration(_ config: RDPCustomConfiguration) {
        let currentStore = getCurrentStore()
        let updatedStore = currentStore.addingCustomConfiguration(config)
        saveConfiguration(updatedStore)
    }
    
    func resetToDefaultConfiguration() {
        saveConfiguration(QualityConfigurationStore.defaultStore)
    }
    
    func getQualityProfileSettings(_ profile: DisplayQualityProfile) -> RDPQualitySettings {
        let store = getCurrentStore()
        
        switch profile {
        case .custom:
            return getCustomConfiguration()?.settings ?? RDPQualitySettings.balanced
        default:
            return store.profileSettings[profile] ?? RDPQualitySettings.getPresetConfiguration(for: profile)
        }
    }
    
    func validateConfiguration(_ config: RDPCustomConfiguration) -> ValidationResult {
        var errors: [String] = []
        
        // 验证配置名称
        if config.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("配置名称不能为空")
        }
        
        if config.name.count > 50 {
            errors.append("配置名称不能超过50个字符")
        }
        
        // 验证质量设置
        let settingsValidation = config.settings.validate()
        if !settingsValidation.isValid {
            errors.append(contentsOf: settingsValidation.errorMessages)
        }
        
        // 检查名称是否与现有配置冲突
        let store = getCurrentStore()
        if store.customConfigurations.keys.contains(config.name) {
            errors.append("配置名称已存在")
        }
        
        return errors.isEmpty ? .valid : .invalid(reasons: errors)
    }
    
    func getAllCustomConfigurations() -> [RDPCustomConfiguration] {
        let store = getCurrentStore()
        return Array(store.customConfigurations.values).sorted { $0.createdDate < $1.createdDate }
    }
    
    func deleteCustomConfiguration(named name: String) {
        let currentStore = getCurrentStore()
        let updatedStore = currentStore.removingCustomConfiguration(named: name)
        saveConfiguration(updatedStore)
    }
    
    func exportConfiguration() -> String? {
        let store = getCurrentStore()
        
        do {
            let data = try encoder.encode(store)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Failed to export configuration: \(error)")
            return nil
        }
    }
    
    func importConfiguration(_ configString: String) -> Bool {
        guard let data = configString.data(using: .utf8) else {
            return false
        }
        
        do {
            let importedStore = try decoder.decode(QualityConfigurationStore.self, from: data)
            
            // 验证导入的配置
            if validateImportedStore(importedStore) {
                saveConfiguration(importedStore)
                return true
            }
        } catch {
            print("Failed to import configuration: \(error)")
        }
        
        return false
    }
    
    // MARK: - Helper Methods
    
    /// 创建默认自定义配置
    private func createDefaultCustomConfiguration() -> RDPCustomConfiguration {
        return RDPCustomConfiguration(
            name: "我的自定义配置",
            settings: RDPQualitySettings.balanced,
            displayOptimization: true
        )
    }
    
    /// 验证导入的配置存储
    private func validateImportedStore(_ store: QualityConfigurationStore) -> Bool {
        // 验证版本兼容性
        guard store.version == "1.0" else {
            return false
        }
        
        // 验证所有自定义配置
        for config in store.customConfigurations.values {
            let validation = config.settings.validate()
            if !validation.isValid {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Performance Analysis
    
    /// 分析配置的性能影响
    func analyzePerformanceImpact(for settings: RDPQualitySettings) -> PerformanceAnalysis {
        let complexityScore = settings.complexityScore
        
        let performanceLevel: PerformanceLevel
        let estimatedLatency: String
        let recommendedBandwidth: String
        
        switch complexityScore {
        case 0...20:
            performanceLevel = .low
            estimatedLatency = "< 50ms"
            recommendedBandwidth = "< 1 Mbps"
        case 21...40:
            performanceLevel = .medium
            estimatedLatency = "50-100ms"
            recommendedBandwidth = "1-3 Mbps"
        default:
            performanceLevel = .high
            estimatedLatency = "> 100ms"
            recommendedBandwidth = "> 3 Mbps"
        }
        
        return PerformanceAnalysis(
            complexityScore: complexityScore,
            performanceLevel: performanceLevel,
            estimatedLatency: estimatedLatency,
            recommendedBandwidth: recommendedBandwidth,
            qualityLevel: settings.qualityLevel
        )
    }
    
    /// 获取配置建议
    func getConfigurationRecommendation(for networkType: NetworkOptimization) -> DisplayQualityProfile {
        switch networkType {
        case .modem, .lowBroadband:
            return .performance
        case .broadband:
            return .balanced
        case .lan:
            return .quality
        case .auto:
            return .balanced
        }
    }
    
    /// 优化配置以适应网络条件
    func optimizeConfigurationForNetwork(_ settings: RDPQualitySettings, networkType: NetworkOptimization) -> RDPQualitySettings {
        switch networkType {
        case .modem, .lowBroadband:
            return RDPQualitySettings.performanceOptimized
        case .broadband:
            return RDPQualitySettings.balanced
        case .lan:
            return RDPQualitySettings.qualityOptimized
        case .auto:
            return settings // 保持当前设置
        }
    }
}

// MARK: - Performance Analysis Model

/// 性能分析结果
struct PerformanceAnalysis {
    let complexityScore: Int
    let performanceLevel: PerformanceLevel
    let estimatedLatency: String
    let recommendedBandwidth: String
    let qualityLevel: QualityLevel
    
    var summary: String {
        return """
        复杂度评分: \(complexityScore)
        性能影响: \(performanceLevel.displayName)
        预估延迟: \(estimatedLatency)
        推荐带宽: \(recommendedBandwidth)
        质量级别: \(qualityLevel.displayName)
        """
    }
}

// MARK: - Singleton Access

extension RDPQualityConfigManager {
    /// 共享实例
    static let shared = RDPQualityConfigManager()
}
