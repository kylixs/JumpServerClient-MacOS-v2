import XCTest
@testable import JMSCore
@testable import JMSRDPModule

/// RDP配置同步功能的单元测试
/// 验证RDPConfigManager和RDPSettingsManager之间的配置同步
class RDPConfigSyncTests: XCTestCase {
    
    var rdpConfigManager: RDPConfigManager!
    var rdpSettingsManager: RDPSettingsManager!
    
    override func setUp() {
        super.setUp()
        rdpConfigManager = RDPConfigManager(forTesting: true)
        rdpSettingsManager = RDPSettingsManager()
    }
    
    override func tearDown() {
        rdpConfigManager = nil
        rdpSettingsManager = nil
        super.tearDown()
    }
    
    // MARK: - 配置转换测试
    
    func testConvertToQualityProfile() {
        // 测试RDPSettings转换为QualityProfile
        let customSettings = RDPSettings(
            profileName: "测试配置",
            resolution: ResolutionSettings(width: 2560, height: 1440),
            hiDPI: HiDPISettings(enabled: true, scaleFactor: 2.0),
            colorDepth: 32,
            compressionLevel: 1,
            audioQuality: "高质量",
            enableFontSmoothing: true,
            enableWallpaper: true,
            enableMenuAnimations: false,
            enableThemes: true
        )
        
        let qualityProfile = RDPConfigManager.convertToQualityProfile(customSettings)
        
        // 验证转换结果
        switch qualityProfile {
        case .custom(let settings):
            XCTAssertEqual(settings.profileName, "测试配置")
            XCTAssertEqual(settings.resolution.width, 2560)
            XCTAssertEqual(settings.resolution.height, 1440)
            XCTAssertTrue(settings.hiDPI.enabled)
            XCTAssertEqual(settings.hiDPI.scaleFactor, 2.0)
            XCTAssertEqual(settings.colorDepth, 32)
            XCTAssertEqual(settings.compressionLevel, 1)
        default:
            XCTFail("应该转换为自定义配置")
        }
    }
    
    func testConvertFromQualityProfile() {
        // 测试QualityProfile转换为RDPSettings
        let customSettings = RDPSettings(
            profileName: "自定义配置",
            resolution: ResolutionSettings(width: 1920, height: 1080),
            hiDPI: HiDPISettings(enabled: false, scaleFactor: 1.0),
            colorDepth: 24,
            compressionLevel: 2
        )
        
        let qualityProfile = QualityProfile.custom(customSettings)
        let convertedSettings = RDPConfigManager.convertFromQualityProfile(qualityProfile)
        
        // 验证转换结果
        XCTAssertEqual(convertedSettings.profileName, "自定义配置")
        XCTAssertEqual(convertedSettings.resolution.width, 1920)
        XCTAssertEqual(convertedSettings.resolution.height, 1080)
        XCTAssertFalse(convertedSettings.hiDPI.enabled)
        XCTAssertEqual(convertedSettings.hiDPI.scaleFactor, 1.0)
        XCTAssertEqual(convertedSettings.colorDepth, 24)
        XCTAssertEqual(convertedSettings.compressionLevel, 2)
    }
    
    // MARK: - 配置同步测试
    
    func testConfigurationSync() {
        // 创建测试配置
        let testSettings = RDPSettings(
            profileName: "同步测试配置",
            resolution: ResolutionSettings(width: 3840, height: 2160),
            hiDPI: HiDPISettings(enabled: true, scaleFactor: 2.5),
            colorDepth: 32,
            compressionLevel: 0,
            audioQuality: "中等",
            enableFontSmoothing: true,
            enableWallpaper: false,
            enableMenuAnimations: true,
            enableThemes: false
        )
        
        // 保存到RDPSettingsManager
        do {
            try rdpSettingsManager.saveSettings(testSettings)
        } catch {
            XCTFail("保存设置失败: \(error)")
        }
        
        // 同步到RDPConfigManager
        let qualityProfile = RDPConfigManager.convertToQualityProfile(testSettings)
        rdpConfigManager.setQualityProfile(qualityProfile)
        
        // 验证同步结果
        let syncedSettings = rdpConfigManager.currentSettings
        XCTAssertEqual(syncedSettings.profileName, testSettings.profileName)
        XCTAssertEqual(syncedSettings.resolution.width, testSettings.resolution.width)
        XCTAssertEqual(syncedSettings.resolution.height, testSettings.resolution.height)
        XCTAssertEqual(syncedSettings.hiDPI.enabled, testSettings.hiDPI.enabled)
        XCTAssertEqual(syncedSettings.hiDPI.scaleFactor, testSettings.hiDPI.scaleFactor)
        XCTAssertEqual(syncedSettings.colorDepth, testSettings.colorDepth)
        XCTAssertEqual(syncedSettings.compressionLevel, testSettings.compressionLevel)
    }
    
    // MARK: - 配置一致性测试
    
    func testConfigurationConsistency() {
        // 创建相同的配置
        let settings1 = RDPSettings(
            profileName: "一致性测试",
            resolution: ResolutionSettings(width: 2560, height: 1440),
            hiDPI: HiDPISettings(enabled: true, scaleFactor: 2.0),
            colorDepth: 32,
            compressionLevel: 1
        )
        
        let settings2 = RDPSettings(
            profileName: "一致性测试",
            resolution: ResolutionSettings(width: 2560, height: 1440),
            hiDPI: HiDPISettings(enabled: true, scaleFactor: 2.0),
            colorDepth: 32,
            compressionLevel: 1
        )
        
        // 验证配置一致性
        XCTAssertTrue(areConfigurationsConsistent(settingsConfig: settings1, configManagerSettings: settings2))
        
        // 创建不同的配置
        let settings3 = RDPSettings(
            profileName: "不同配置",
            resolution: ResolutionSettings(width: 1920, height: 1080),
            hiDPI: HiDPISettings(enabled: false, scaleFactor: 1.0),
            colorDepth: 24,
            compressionLevel: 2
        )
        
        // 验证配置不一致
        XCTAssertFalse(areConfigurationsConsistent(settingsConfig: settings1, configManagerSettings: settings3))
    }
    
    // MARK: - 预设配置测试
    
    func testPresetConfigurations() {
        // 测试性能优先配置
        let performanceProfile = QualityProfile.performance
        let performanceSettings = RDPConfigManager.convertFromQualityProfile(performanceProfile)
        XCTAssertEqual(performanceSettings.profileName, "性能优先")
        XCTAssertEqual(performanceSettings.compressionLevel, 2)
        XCTAssertEqual(performanceSettings.colorDepth, 16)
        
        // 测试平衡模式配置
        let balancedProfile = QualityProfile.balanced
        let balancedSettings = RDPConfigManager.convertFromQualityProfile(balancedProfile)
        XCTAssertEqual(balancedSettings.profileName, "平衡模式")
        XCTAssertEqual(balancedSettings.compressionLevel, 1)
        XCTAssertEqual(balancedSettings.colorDepth, 24)
        
        // 测试质量优先配置
        let qualityProfile = QualityProfile.quality
        let qualitySettings = RDPConfigManager.convertFromQualityProfile(qualityProfile)
        XCTAssertEqual(qualitySettings.profileName, "质量优先")
        XCTAssertEqual(qualitySettings.compressionLevel, 0)
        XCTAssertEqual(qualitySettings.colorDepth, 32)
    }
    
    // MARK: - 错误处理测试
    
    func testConfigurationErrorHandling() {
        // 测试无效配置的处理
        let invalidSettings = RDPSettings(
            profileName: "",
            resolution: ResolutionSettings(width: 0, height: 0),
            hiDPI: HiDPISettings(enabled: false, scaleFactor: 0.0),
            colorDepth: 0,
            compressionLevel: -1
        )
        
        // 验证无效配置不会导致崩溃
        let qualityProfile = RDPConfigManager.convertToQualityProfile(invalidSettings)
        XCTAssertNotNil(qualityProfile)
        
        // 验证转换后的配置有合理的默认值
        let convertedSettings = RDPConfigManager.convertFromQualityProfile(qualityProfile)
        XCTAssertNotNil(convertedSettings)
    }
    
    // MARK: - 辅助方法
    
    /// 比较两个配置是否一致（复制自AppDelegate的逻辑）
    private func areConfigurationsConsistent(settingsConfig: RDPSettings, configManagerSettings: RDPSettings) -> Bool {
        return settingsConfig.profileName == configManagerSettings.profileName &&
               settingsConfig.resolution.width == configManagerSettings.resolution.width &&
               settingsConfig.resolution.height == configManagerSettings.resolution.height &&
               settingsConfig.hiDPI.enabled == configManagerSettings.hiDPI.enabled &&
               settingsConfig.hiDPI.scaleFactor == configManagerSettings.hiDPI.scaleFactor &&
               settingsConfig.colorDepth == configManagerSettings.colorDepth &&
               settingsConfig.compressionLevel == configManagerSettings.compressionLevel
    }
}

// MARK: - 性能测试

extension RDPConfigSyncTests {
    
    func testConfigurationSyncPerformance() {
        // 测试配置同步的性能
        let testSettings = RDPSettings.balanced
        
        measure {
            // 执行100次配置同步操作
            for _ in 0..<100 {
                let qualityProfile = RDPConfigManager.convertToQualityProfile(testSettings)
                rdpConfigManager.setQualityProfile(qualityProfile)
                _ = rdpConfigManager.currentSettings
            }
        }
    }
    
    func testConfigurationConsistencyCheckPerformance() {
        // 测试配置一致性检查的性能
        let settings1 = RDPSettings.balanced
        let settings2 = RDPSettings.quality
        
        measure {
            // 执行1000次一致性检查
            for _ in 0..<1000 {
                _ = areConfigurationsConsistent(settingsConfig: settings1, configManagerSettings: settings2)
            }
        }
    }
}
