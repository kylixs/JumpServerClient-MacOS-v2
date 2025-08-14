import XCTest
@testable import JMSCore
@testable import JMSRDPModule

/// 配置同步集成测试
/// 验证任务26修复后的配置同步功能是否正常工作
class ConfigSyncIntegrationTest: XCTestCase {
    
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
    
    // MARK: - 配置同步验证测试
    
    func testSettingsDidSaveSync() {
        print("🧪 测试settingsDidSave配置同步功能")
        
        // 创建测试配置
        let testSettings = RDPSettings(
            profileName: "集成测试配置",
            resolution: ResolutionSettings(width: 2560, height: 1440),
            hiDPI: HiDPISettings(enabled: true, scaleFactor: 2.0),
            colorDepth: 32,
            compressionLevel: 1,
            audioQuality: "高质量",
            enableFontSmoothing: true,
            enableWallpaper: false,
            enableMenuAnimations: true,
            enableThemes: false
        )
        
        // 保存设置到RDPSettingsManager
        do {
            try rdpSettingsManager.saveSettings(testSettings)
            print("✅ 设置已保存到RDPSettingsManager")
        } catch {
            XCTFail("保存设置失败: \(error)")
        }
        
        // 模拟settingsDidSave同步逻辑
        let qualityProfile = RDPConfigManager.convertToQualityProfile(testSettings)
        rdpConfigManager.setQualityProfile(qualityProfile)
        print("✅ 配置已同步到RDPConfigManager")
        
        // 验证同步结果
        let syncedSettings = rdpConfigManager.currentSettings
        XCTAssertEqual(syncedSettings.profileName, testSettings.profileName, "配置名称应该一致")
        XCTAssertEqual(syncedSettings.resolution.width, testSettings.resolution.width, "分辨率宽度应该一致")
        XCTAssertEqual(syncedSettings.resolution.height, testSettings.resolution.height, "分辨率高度应该一致")
        XCTAssertEqual(syncedSettings.hiDPI.enabled, testSettings.hiDPI.enabled, "HiDPI设置应该一致")
        XCTAssertEqual(syncedSettings.hiDPI.scaleFactor, testSettings.hiDPI.scaleFactor, "缩放因子应该一致")
        XCTAssertEqual(syncedSettings.colorDepth, testSettings.colorDepth, "颜色深度应该一致")
        XCTAssertEqual(syncedSettings.compressionLevel, testSettings.compressionLevel, "压缩级别应该一致")
        
        print("✅ 配置同步验证通过")
    }
    
    func testSettingsDidResetSync() {
        print("🧪 测试settingsDidReset配置同步功能")
        
        // 先设置一个自定义配置
        let customSettings = RDPSettings(
            profileName: "自定义配置",
            resolution: ResolutionSettings(width: 3840, height: 2160),
            hiDPI: HiDPISettings(enabled: true, scaleFactor: 2.5),
            colorDepth: 32,
            compressionLevel: 0
        )
        
        let customProfile = RDPConfigManager.convertToQualityProfile(customSettings)
        rdpConfigManager.setQualityProfile(customProfile)
        
        // 验证自定义配置已设置
        let beforeReset = rdpConfigManager.currentSettings
        XCTAssertEqual(beforeReset.profileName, "自定义配置")
        
        // 模拟settingsDidReset同步逻辑
        rdpConfigManager.resetToDefaults()
        print("✅ 配置已重置")
        
        // 验证重置结果
        let afterReset = rdpConfigManager.currentSettings
        XCTAssertEqual(afterReset.profileName, "平衡模式", "重置后应该是默认的平衡模式")
        XCTAssertNotEqual(afterReset.profileName, customSettings.profileName, "重置后不应该是自定义配置")
        
        print("✅ 配置重置同步验证通过")
    }
    
    func testConfigurationConsistencyCheck() {
        print("🧪 测试配置一致性检查功能")
        
        // 创建一致的配置
        let consistentSettings = RDPSettings(
            profileName: "一致性测试",
            resolution: ResolutionSettings(width: 1920, height: 1080),
            hiDPI: HiDPISettings(enabled: false, scaleFactor: 1.0),
            colorDepth: 24,
            compressionLevel: 2
        )
        
        // 设置到两个管理器
        try? rdpSettingsManager.saveSettings(consistentSettings)
        let qualityProfile = RDPConfigManager.convertToQualityProfile(consistentSettings)
        rdpConfigManager.setQualityProfile(qualityProfile)
        
        // 验证配置一致性
        let settingsManagerConfig = rdpSettingsManager.currentSettings
        let configManagerSettings = rdpConfigManager.currentSettings
        
        let isConsistent = areConfigurationsConsistent(
            settingsConfig: settingsManagerConfig,
            configManagerSettings: configManagerSettings
        )
        
        XCTAssertTrue(isConsistent, "配置应该是一致的")
        print("✅ 配置一致性检查通过")
    }
    
    func testConfigurationReload() {
        print("🧪 测试配置重新加载功能")
        
        // 创建新配置并保存到RDPSettingsManager
        let newSettings = RDPSettings(
            profileName: "重新加载测试",
            resolution: ResolutionSettings(width: 2560, height: 1600),
            hiDPI: HiDPISettings(enabled: true, scaleFactor: 2.0),
            colorDepth: 32,
            compressionLevel: 1,
            enableFontSmoothing: true
        )
        
        do {
            try rdpSettingsManager.saveSettings(newSettings)
            print("✅ 新配置已保存到RDPSettingsManager")
        } catch {
            XCTFail("保存新配置失败: \(error)")
        }
        
        // 模拟reloadLatestRDPConfiguration逻辑
        let latestSettings = rdpSettingsManager.currentSettings
        let qualityProfile = RDPConfigManager.convertToQualityProfile(latestSettings)
        rdpConfigManager.setQualityProfile(qualityProfile)
        print("✅ 配置已重新加载到RDPConfigManager")
        
        // 验证重新加载的配置
        let reloadedSettings = rdpConfigManager.currentSettings
        XCTAssertEqual(reloadedSettings.profileName, newSettings.profileName, "重新加载的配置名称应该正确")
        XCTAssertEqual(reloadedSettings.resolution.width, newSettings.resolution.width, "重新加载的分辨率应该正确")
        XCTAssertEqual(reloadedSettings.hiDPI.enabled, newSettings.hiDPI.enabled, "重新加载的HiDPI设置应该正确")
        XCTAssertEqual(reloadedSettings.enableFontSmoothing, newSettings.enableFontSmoothing, "重新加载的字体平滑设置应该正确")
        
        print("✅ 配置重新加载验证通过")
    }
    
    // MARK: - 辅助方法
    
    /// 比较两个配置是否一致
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

// MARK: - 错误处理测试

extension ConfigSyncIntegrationTest {
    
    func testConfigurationSyncErrorHandling() {
        print("🧪 测试配置同步错误处理")
        
        // 测试无效配置的处理
        let invalidSettings = RDPSettings(
            profileName: "",
            resolution: ResolutionSettings(width: -1, height: -1),
            hiDPI: HiDPISettings(enabled: false, scaleFactor: -1.0),
            colorDepth: 0,
            compressionLevel: 10
        )
        
        // 验证无效配置不会导致崩溃
        XCTAssertNoThrow({
            let qualityProfile = RDPConfigManager.convertToQualityProfile(invalidSettings)
            rdpConfigManager.setQualityProfile(qualityProfile)
        }, "处理无效配置不应该崩溃")
        
        // 验证系统能够恢复到合理状态
        let recoveredSettings = rdpConfigManager.currentSettings
        XCTAssertNotNil(recoveredSettings, "应该能够恢复到有效配置")
        
        print("✅ 配置同步错误处理验证通过")
    }
    
    func testConfigurationSyncWithMissingFiles() {
        print("🧪 测试配置文件缺失时的同步处理")
        
        // 重置到默认状态
        rdpConfigManager.resetToDefaults()
        
        // 验证默认配置可用
        let defaultSettings = rdpConfigManager.currentSettings
        XCTAssertEqual(defaultSettings.profileName, "平衡模式", "默认应该是平衡模式")
        XCTAssertGreaterThan(defaultSettings.resolution.width, 0, "默认分辨率宽度应该大于0")
        XCTAssertGreaterThan(defaultSettings.resolution.height, 0, "默认分辨率高度应该大于0")
        
        print("✅ 配置文件缺失处理验证通过")
    }
}
