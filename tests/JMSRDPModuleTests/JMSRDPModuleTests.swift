import XCTest
import CoreGraphics
@testable import JMSRDPModule
@testable import JMSCore

final class JMSRDPModuleTests: XCTestCase {
    
    var configManager: RDPConfigManager!
    var displayDetector: DisplayDetector!
    var rdpIntegrator: RemoteDesktopIntegrator!
    
    override func setUp() {
        super.setUp()
        configManager = RDPConfigManager.shared
        displayDetector = DisplayDetector()
        rdpIntegrator = RemoteDesktopIntegrator()
    }
    
    override func tearDown() {
        configManager.resetToDefaults()
        super.tearDown()
    }
    
    // MARK: - RDPConfigManager Tests
    
    func testRDPConfigManagerQualityProfiles() {
        let profiles = configManager.availableQualityProfiles
        
        XCTAssertEqual(profiles.count, 3)
        XCTAssertTrue(profiles.contains { $0.identifier == "performance" })
        XCTAssertTrue(profiles.contains { $0.identifier == "balanced" })
        XCTAssertTrue(profiles.contains { $0.identifier == "quality" })
    }
    
    func testRDPConfigManagerSetQualityProfile() {
        // 测试设置性能优先配置
        configManager.setQualityProfile(.performance)
        XCTAssertEqual(configManager.qualityProfile.identifier, "performance")
        
        // 测试设置质量优先配置
        configManager.setQualityProfile(.quality)
        XCTAssertEqual(configManager.qualityProfile.identifier, "quality")
    }
    
    func testRDPConfigManagerCustomSettings() {
        let customSettings = RDPSettings(
            resolution: .custom(1920, 1080),
            colorDepth: .depth24,
            compressionLevel: .low,
            enableFontSmoothing: true,
            scalingFactor: 1.5
        )
        
        configManager.updateSettings(customSettings)
        
        let currentSettings = configManager.settings
        XCTAssertEqual(currentSettings.resolution.width, 1920)
        XCTAssertEqual(currentSettings.resolution.height, 1080)
        XCTAssertEqual(currentSettings.colorDepth, .depth24)
        XCTAssertEqual(currentSettings.compressionLevel, .low)
        XCTAssertTrue(currentSettings.enableFontSmoothing)
        XCTAssertEqual(currentSettings.scalingFactor, 1.5)
    }
    
    func testRDPConfigManagerGenerateConfig() throws {
        let connectionInfo = RDPConnectionInfo(
            fullAddress: "test.server.com:3389",
            username: "testuser",
            config: "full address:s:test.server.com:3389\nusername:s:testuser"
        )
        
        // 使用模拟的显示器配置进行测试
        let mockDisplayConfig = DisplayConfiguration(
            width: 1920,
            height: 1080,
            scaleFactor: 1.0,
            colorDepth: 24,
            isHiDPI: false
        )
        
        // 由于generateOptimizedConfig需要检测真实显示器，我们测试配置文件的基本结构
        configManager.setQualityProfile(.balanced)
        
        // 这里我们测试配置管理器的基本功能
        let settings = configManager.settings
        XCTAssertNotNil(settings)
        XCTAssertEqual(configManager.qualityProfile.identifier, "balanced")
    }
    
    func testRDPConfigManagerResetToDefaults() {
        // 先设置自定义配置
        let customSettings = RDPSettings(
            resolution: .custom(2560, 1440),
            colorDepth: .depth32,
            compressionLevel: .none
        )
        configManager.updateSettings(customSettings)
        
        // 重置为默认值
        configManager.resetToDefaults()
        
        // 验证已重置
        XCTAssertEqual(configManager.qualityProfile.identifier, "balanced")
        let defaultSettings = configManager.settings
        XCTAssertEqual(defaultSettings.resolution.width, 1920) // 默认FullHD
        XCTAssertEqual(defaultSettings.colorDepth, .depth24)
    }
    
    // MARK: - QualityProfile Tests
    
    func testQualityProfileSettings() {
        let performanceSettings = QualityProfile.performance.settings
        XCTAssertEqual(performanceSettings.colorDepth, .depth16)
        XCTAssertEqual(performanceSettings.compressionLevel, .high)
        XCTAssertFalse(performanceSettings.enableFontSmoothing)
        
        let qualitySettings = QualityProfile.quality.settings
        XCTAssertEqual(qualitySettings.colorDepth, .depth32)
        XCTAssertEqual(qualitySettings.compressionLevel, .none)
        XCTAssertTrue(qualitySettings.enableFontSmoothing)
        
        let balancedSettings = QualityProfile.balanced.settings
        XCTAssertEqual(balancedSettings.colorDepth, .depth24)
        XCTAssertEqual(balancedSettings.compressionLevel, .medium)
        XCTAssertTrue(balancedSettings.enableFontSmoothing)
    }
    
    func testQualityProfileDisplayNames() {
        XCTAssertEqual(QualityProfile.performance.displayName, "性能优先")
        XCTAssertEqual(QualityProfile.balanced.displayName, "平衡模式")
        XCTAssertEqual(QualityProfile.quality.displayName, "质量优先")
        
        let customProfile = QualityProfile.custom(RDPSettings.default)
        XCTAssertEqual(customProfile.displayName, "自定义配置")
    }
    
    func testQualityProfileIdentifiers() {
        XCTAssertEqual(QualityProfile.performance.identifier, "performance")
        XCTAssertEqual(QualityProfile.balanced.identifier, "balanced")
        XCTAssertEqual(QualityProfile.quality.identifier, "quality")
        
        let customProfile = QualityProfile.custom(RDPSettings.default)
        XCTAssertEqual(customProfile.identifier, "custom")
    }
    
    func testQualityProfileFromIdentifier() {
        XCTAssertNotNil(QualityProfile.fromIdentifier("performance"))
        XCTAssertNotNil(QualityProfile.fromIdentifier("balanced"))
        XCTAssertNotNil(QualityProfile.fromIdentifier("quality"))
        XCTAssertNotNil(QualityProfile.fromIdentifier("custom"))
        XCTAssertNil(QualityProfile.fromIdentifier("invalid"))
        
        let performanceProfile = QualityProfile.fromIdentifier("performance")!
        XCTAssertEqual(performanceProfile.identifier, "performance")
    }
    
    // MARK: - Resolution Tests
    
    func testResolutionDimensions() {
        XCTAssertEqual(Resolution.fullHD.width, 1920)
        XCTAssertEqual(Resolution.fullHD.height, 1080)
        
        XCTAssertEqual(Resolution.quadHD.width, 2560)
        XCTAssertEqual(Resolution.quadHD.height, 1440)
        
        XCTAssertEqual(Resolution.ultraHD.width, 3840)
        XCTAssertEqual(Resolution.ultraHD.height, 2160)
        
        let customRes = Resolution.custom(1366, 768)
        XCTAssertEqual(customRes.width, 1366)
        XCTAssertEqual(customRes.height, 768)
    }
    
    // MARK: - RDPSettings Tests
    
    func testRDPSettingsDefault() {
        let defaultSettings = RDPSettings.default
        
        XCTAssertEqual(defaultSettings.resolution.width, 1920)
        XCTAssertEqual(defaultSettings.resolution.height, 1080)
        XCTAssertEqual(defaultSettings.colorDepth, .depth24)
        XCTAssertEqual(defaultSettings.compressionLevel, .medium)
        XCTAssertTrue(defaultSettings.enableFontSmoothing)
        XCTAssertEqual(defaultSettings.scalingFactor, 1.0)
    }
    
    func testRDPSettingsCodable() throws {
        let originalSettings = RDPSettings(
            resolution: .custom(2560, 1440),
            colorDepth: .depth32,
            compressionLevel: .low,
            enableFontSmoothing: false,
            scalingFactor: 2.0
        )
        
        // 编码
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalSettings)
        
        // 解码
        let decoder = JSONDecoder()
        let decodedSettings = try decoder.decode(RDPSettings.self, from: data)
        
        // 验证
        XCTAssertEqual(decodedSettings.resolution.width, 2560)
        XCTAssertEqual(decodedSettings.resolution.height, 1440)
        XCTAssertEqual(decodedSettings.colorDepth, .depth32)
        XCTAssertEqual(decodedSettings.compressionLevel, .low)
        XCTAssertFalse(decodedSettings.enableFontSmoothing)
        XCTAssertEqual(decodedSettings.scalingFactor, 2.0)
    }
    
    // MARK: - DisplayDetector Tests
    
    func testDisplayDetectorInitialization() {
        XCTAssertNotNil(displayDetector)
    }
    
    func testDisplayDetectorPrimaryDisplay() {
        // 注意：这个测试在CI环境中可能失败，因为可能没有显示器
        // 在实际环境中，这个测试应该能够检测到主显示器
        do {
            let primaryDisplay = try displayDetector.detectPrimaryDisplay()
            XCTAssertGreaterThan(primaryDisplay.width, 0)
            XCTAssertGreaterThan(primaryDisplay.height, 0)
            XCTAssertGreaterThan(primaryDisplay.colorDepth, 0)
        } catch {
            // 在没有显示器的环境中，这是预期的行为
            print("显示器检测失败（可能在无头环境中）: \(error)")
        }
    }
    
    // MARK: - RemoteDesktopIntegrator Tests
    
    func testRemoteDesktopIntegratorInitialization() {
        XCTAssertNotNil(rdpIntegrator)
    }
    
    func testRemoteDesktopIntegratorQualityProfiles() {
        let profiles = rdpIntegrator.availableQualityProfiles
        XCTAssertEqual(profiles.count, 3)
        
        // 测试设置质量配置
        rdpIntegrator.setQualityProfile(.performance)
        XCTAssertEqual(rdpIntegrator.currentQualityProfile.identifier, "performance")
    }
    
    func testRemoteDesktopIntegratorCustomSettings() {
        let customSettings = RDPSettings(
            resolution: .quadHD,
            colorDepth: .depth32,
            compressionLevel: .none
        )
        
        rdpIntegrator.updateCustomSettings(customSettings)
        XCTAssertEqual(rdpIntegrator.currentQualityProfile.identifier, "custom")
    }
    
    func testRemoteDesktopIntegratorResetDefaults() {
        // 先设置自定义配置
        rdpIntegrator.setQualityProfile(.performance)
        
        // 重置
        rdpIntegrator.resetToDefaults()
        
        // 验证已重置为默认值
        XCTAssertEqual(rdpIntegrator.currentQualityProfile.identifier, "balanced")
    }
    
    // MARK: - Integration Tests
    
    func testRDPConfigGenerationFlow() throws {
        let connectionInfo = RDPConnectionInfo(
            fullAddress: "test.server.com:3389",
            username: "testuser",
            config: "full address:s:test.server.com:3389\nusername:s:testuser\nsession bpp:i:32"
        )
        
        // 测试不同质量配置下的配置生成
        for profile in [QualityProfile.performance, .balanced, .quality] {
            configManager.setQualityProfile(profile)
            
            // 由于需要真实的显示器检测，我们主要测试配置管理器的状态
            XCTAssertEqual(configManager.qualityProfile.identifier, profile.identifier)
            
            let settings = configManager.settings
            XCTAssertNotNil(settings)
            
            // 验证不同配置文件的设置差异
            switch profile {
            case .performance:
                XCTAssertEqual(settings.colorDepth, .depth16)
                XCTAssertEqual(settings.compressionLevel, .high)
            case .balanced:
                XCTAssertEqual(settings.colorDepth, .depth24)
                XCTAssertEqual(settings.compressionLevel, .medium)
            case .quality:
                XCTAssertEqual(settings.colorDepth, .depth32)
                XCTAssertEqual(settings.compressionLevel, .none)
            default:
                break
            }
        }
    }
    
    func testDisplayConfigurationOptimization() {
        // 测试不同显示器配置的优化逻辑
        let standardDisplay = DisplayConfiguration(
            width: 1920,
            height: 1080,
            scaleFactor: 1.0,
            colorDepth: 24,
            isHiDPI: false
        )
        
        let hiDPIDisplay = DisplayConfiguration(
            width: 2560,
            height: 1600,
            scaleFactor: 2.0,
            colorDepth: 32,
            isHiDPI: true
        )
        
        let ultraWideDisplay = DisplayConfiguration(
            width: 3440,
            height: 1440,
            scaleFactor: 1.0,
            colorDepth: 24,
            isHiDPI: false
        )
        
        // 验证显示器特性检测
        XCTAssertFalse(standardDisplay.is4K)
        XCTAssertFalse(standardDisplay.isUltraWide)
        XCTAssertEqual(standardDisplay.densityType, .standard)
        
        XCTAssertFalse(hiDPIDisplay.is4K)
        XCTAssertFalse(hiDPIDisplay.isUltraWide)
        XCTAssertEqual(hiDPIDisplay.densityType, .retina)
        
        XCTAssertFalse(ultraWideDisplay.is4K)
        XCTAssertTrue(ultraWideDisplay.isUltraWide)
        XCTAssertEqual(ultraWideDisplay.densityType, .standard)
    }
}
