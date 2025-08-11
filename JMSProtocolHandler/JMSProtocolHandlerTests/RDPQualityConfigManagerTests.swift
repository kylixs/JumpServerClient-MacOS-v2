//
//  RDPQualityConfigManagerTests.swift
//  JMSProtocolHandlerTests
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import XCTest
@testable import JMSProtocolHandler

class RDPQualityConfigManagerTests: XCTestCase {
    
    var configManager: RDPQualityConfigManager!
    
    override func setUp() {
        super.setUp()
        configManager = RDPQualityConfigManager()
        
        // 重置到默认配置
        configManager.resetToDefaultConfiguration()
    }
    
    override func tearDown() {
        configManager = nil
        super.tearDown()
    }
    
    // MARK: - Profile Management Tests
    
    func testDefaultQualityProfile() {
        // 测试默认配置文件是平衡模式
        let currentProfile = configManager.getCurrentQualityProfile()
        XCTAssertEqual(currentProfile, .balanced, "默认配置文件应该是平衡模式")
    }
    
    func testSetQualityProfile() {
        // 测试设置质量配置文件
        configManager.setQualityProfile(.performance)
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .performance)
        
        configManager.setQualityProfile(.quality)
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .quality)
        
        configManager.setQualityProfile(.custom)
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .custom)
    }
    
    func testGetQualityProfileSettings() {
        // 测试获取预设配置文件的设置
        let performanceSettings = configManager.getQualityProfileSettings(.performance)
        XCTAssertEqual(performanceSettings.compressionLevel, 2)
        XCTAssertEqual(performanceSettings.colorDepth, 16)
        XCTAssertFalse(performanceSettings.enableWallpaper)
        
        let balancedSettings = configManager.getQualityProfileSettings(.balanced)
        XCTAssertEqual(balancedSettings.compressionLevel, 1)
        XCTAssertEqual(balancedSettings.colorDepth, 24)
        
        let qualitySettings = configManager.getQualityProfileSettings(.quality)
        XCTAssertEqual(qualitySettings.compressionLevel, 0)
        XCTAssertEqual(qualitySettings.colorDepth, 32)
        XCTAssertTrue(qualitySettings.enableWallpaper)
    }
    
    // MARK: - Custom Configuration Tests
    
    func testSaveAndGetCustomConfiguration() {
        // 创建自定义配置
        let customSettings = RDPQualitySettings(
            compressionLevel: 1,
            colorDepth: 24,
            enableFontSmoothing: true,
            enableWallpaper: true,
            enableMenuAnimations: false,
            enableThemes: true,
            enableFullWindowDrag: false,
            bitmapCaching: true,
            audioQuality: .medium,
            networkOptimization: .broadband,
            estimatedBandwidth: "2 Mbps",
            performanceImpact: .medium,
            qualityLevel: .standard
        )
        
        let customConfig = RDPCustomConfiguration(
            name: "测试自定义配置",
            settings: customSettings,
            displayOptimization: true
        )
        
        // 保存自定义配置
        configManager.saveCustomConfiguration(customConfig)
        
        // 设置为自定义配置文件
        configManager.setQualityProfile(.custom)
        
        // 获取自定义配置
        let retrievedConfig = configManager.getCustomConfiguration()
        XCTAssertNotNil(retrievedConfig)
        XCTAssertEqual(retrievedConfig?.name, "测试自定义配置")
        XCTAssertEqual(retrievedConfig?.settings.compressionLevel, 1)
        XCTAssertEqual(retrievedConfig?.settings.colorDepth, 24)
    }
    
    func testGetAllCustomConfigurations() {
        // 创建多个自定义配置
        let config1 = RDPCustomConfiguration(
            name: "配置1",
            settings: RDPQualitySettings.performanceOptimized
        )
        
        let config2 = RDPCustomConfiguration(
            name: "配置2",
            settings: RDPQualitySettings.qualityOptimized
        )
        
        configManager.saveCustomConfiguration(config1)
        configManager.saveCustomConfiguration(config2)
        
        let allConfigs = configManager.getAllCustomConfigurations()
        XCTAssertEqual(allConfigs.count, 2)
        
        let configNames = allConfigs.map { $0.name }
        XCTAssertTrue(configNames.contains("配置1"))
        XCTAssertTrue(configNames.contains("配置2"))
    }
    
    func testDeleteCustomConfiguration() {
        // 创建并保存自定义配置
        let customConfig = RDPCustomConfiguration(
            name: "待删除配置",
            settings: RDPQualitySettings.balanced
        )
        
        configManager.saveCustomConfiguration(customConfig)
        XCTAssertEqual(configManager.getAllCustomConfigurations().count, 1)
        
        // 删除配置
        configManager.deleteCustomConfiguration(named: "待删除配置")
        XCTAssertEqual(configManager.getAllCustomConfigurations().count, 0)
    }
    
    // MARK: - Configuration Validation Tests
    
    func testValidateValidConfiguration() {
        let validConfig = RDPCustomConfiguration(
            name: "有效配置",
            settings: RDPQualitySettings.balanced
        )
        
        let result = configManager.validateConfiguration(validConfig)
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errorMessages.isEmpty)
    }
    
    func testValidateInvalidConfiguration() {
        // 测试空名称
        let invalidSettings = RDPQualitySettings(
            compressionLevel: -1, // 无效的压缩级别
            colorDepth: 15,       // 无效的颜色深度
            enableFontSmoothing: true,
            enableWallpaper: true,
            enableMenuAnimations: true,
            enableThemes: true,
            enableFullWindowDrag: true,
            bitmapCaching: true,
            audioQuality: .high,
            networkOptimization: .lan,
            estimatedBandwidth: "", // 空带宽估算
            performanceImpact: .high,
            qualityLevel: .premium
        )
        
        let invalidConfig = RDPCustomConfiguration(
            name: "", // 空名称
            settings: invalidSettings
        )
        
        let result = configManager.validateConfiguration(invalidConfig)
        XCTAssertFalse(result.isValid)
        XCTAssertFalse(result.errorMessages.isEmpty)
        
        // 检查具体的错误消息
        let errors = result.errorMessages
        XCTAssertTrue(errors.contains("配置名称不能为空"))
        XCTAssertTrue(errors.contains("压缩级别必须在0-2之间"))
        XCTAssertTrue(errors.contains("颜色深度必须是16、24或32位"))
        XCTAssertTrue(errors.contains("带宽估算不能为空"))
    }
    
    func testValidateConfigurationNameTooLong() {
        let longName = String(repeating: "a", count: 51) // 超过50个字符
        let config = RDPCustomConfiguration(
            name: longName,
            settings: RDPQualitySettings.balanced
        )
        
        let result = configManager.validateConfiguration(config)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessages.contains("配置名称不能超过50个字符"))
    }
    
    // MARK: - Reset Configuration Tests
    
    func testResetToDefaultConfiguration() {
        // 修改配置
        configManager.setQualityProfile(.performance)
        
        let customConfig = RDPCustomConfiguration(
            name: "测试配置",
            settings: RDPQualitySettings.qualityOptimized
        )
        configManager.saveCustomConfiguration(customConfig)
        
        // 重置配置
        configManager.resetToDefaultConfiguration()
        
        // 验证重置结果
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .balanced)
        XCTAssertEqual(configManager.getAllCustomConfigurations().count, 0)
    }
    
    // MARK: - Import/Export Tests
    
    func testExportConfiguration() {
        // 设置一些配置
        configManager.setQualityProfile(.performance)
        
        let customConfig = RDPCustomConfiguration(
            name: "导出测试配置",
            settings: RDPQualitySettings.qualityOptimized
        )
        configManager.saveCustomConfiguration(customConfig)
        
        // 导出配置
        let exportedString = configManager.exportConfiguration()
        XCTAssertNotNil(exportedString)
        XCTAssertFalse(exportedString!.isEmpty)
        
        // 验证导出的JSON包含预期内容
        XCTAssertTrue(exportedString!.contains("performance"))
        XCTAssertTrue(exportedString!.contains("导出测试配置"))
    }
    
    func testImportConfiguration() {
        // 创建一个配置并导出
        configManager.setQualityProfile(.quality)
        
        let customConfig = RDPCustomConfiguration(
            name: "导入测试配置",
            settings: RDPQualitySettings.performanceOptimized
        )
        configManager.saveCustomConfiguration(customConfig)
        
        let exportedString = configManager.exportConfiguration()!
        
        // 重置配置
        configManager.resetToDefaultConfiguration()
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .balanced)
        XCTAssertEqual(configManager.getAllCustomConfigurations().count, 0)
        
        // 导入配置
        let importSuccess = configManager.importConfiguration(exportedString)
        XCTAssertTrue(importSuccess)
        
        // 验证导入结果
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .quality)
        XCTAssertEqual(configManager.getAllCustomConfigurations().count, 1)
        XCTAssertEqual(configManager.getAllCustomConfigurations().first?.name, "导入测试配置")
    }
    
    func testImportInvalidConfiguration() {
        let invalidJSON = "{ invalid json }"
        let importSuccess = configManager.importConfiguration(invalidJSON)
        XCTAssertFalse(importSuccess)
    }
    
    // MARK: - Performance Analysis Tests
    
    func testAnalyzePerformanceImpact() {
        let performanceSettings = RDPQualitySettings.performanceOptimized
        let analysis = configManager.analyzePerformanceImpact(for: performanceSettings)
        
        XCTAssertEqual(analysis.performanceLevel, .low)
        XCTAssertEqual(analysis.qualityLevel, .basic)
        XCTAssertTrue(analysis.complexityScore < 30) // 性能优先配置应该有较低的复杂度
        
        let qualitySettings = RDPQualitySettings.qualityOptimized
        let qualityAnalysis = configManager.analyzePerformanceImpact(for: qualitySettings)
        
        XCTAssertEqual(qualityAnalysis.performanceLevel, .high)
        XCTAssertEqual(qualityAnalysis.qualityLevel, .premium)
        XCTAssertTrue(qualityAnalysis.complexityScore > 40) // 质量优先配置应该有较高的复杂度
    }
    
    func testGetConfigurationRecommendation() {
        XCTAssertEqual(configManager.getConfigurationRecommendation(for: .modem), .performance)
        XCTAssertEqual(configManager.getConfigurationRecommendation(for: .lowBroadband), .performance)
        XCTAssertEqual(configManager.getConfigurationRecommendation(for: .broadband), .balanced)
        XCTAssertEqual(configManager.getConfigurationRecommendation(for: .lan), .quality)
        XCTAssertEqual(configManager.getConfigurationRecommendation(for: .auto), .balanced)
    }
    
    func testOptimizeConfigurationForNetwork() {
        let originalSettings = RDPQualitySettings.balanced
        
        let optimizedForModem = configManager.optimizeConfigurationForNetwork(originalSettings, networkType: .modem)
        XCTAssertEqual(optimizedForModem.compressionLevel, 2) // 最高压缩
        XCTAssertEqual(optimizedForModem.colorDepth, 16)     // 最低色彩
        
        let optimizedForLAN = configManager.optimizeConfigurationForNetwork(originalSettings, networkType: .lan)
        XCTAssertEqual(optimizedForLAN.compressionLevel, 0)  // 无压缩
        XCTAssertEqual(optimizedForLAN.colorDepth, 32)       // 最高色彩
        
        let optimizedForAuto = configManager.optimizeConfigurationForNetwork(originalSettings, networkType: .auto)
        XCTAssertEqual(optimizedForAuto, originalSettings)   // 保持原设置
    }
    
    // MARK: - Notification Tests
    
    func testConfigurationChangeNotification() {
        let expectation = XCTestExpectation(description: "Configuration change notification")
        
        let observer = NotificationCenter.default.addObserver(
            forName: RDPQualityConfigManager.configurationDidChangeNotification,
            object: configManager,
            queue: .main
        ) { notification in
            if let profile = notification.userInfo?["profile"] as? DisplayQualityProfile {
                XCTAssertEqual(profile, .performance)
                expectation.fulfill()
            }
        }
        
        configManager.setQualityProfile(.performance)
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
}
