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
        configManager = RDPConfigManager(forTesting: true)
        displayDetector = DisplayDetector()
        rdpIntegrator = RemoteDesktopIntegrator()
    }
    
    override func tearDown() {
        configManager = nil
        displayDetector = nil
        rdpIntegrator = nil
        super.tearDown()
    }
    
    // MARK: - RDPSettings Tests
    
    func testRDPSettingsPresets() {
        // 测试性能优先预设
        let performance = RDPSettings.performance
        XCTAssertEqual(performance.profileName, "性能优先")
        XCTAssertEqual(performance.compressionLevel, 2)
        XCTAssertEqual(performance.colorDepth, 16)
        XCTAssertFalse(performance.hiDPI.enabled)
        XCTAssertFalse(performance.useAutoDetection)
        
        // 测试平衡模式预设
        let balanced = RDPSettings.balanced
        XCTAssertEqual(balanced.profileName, "平衡模式")
        XCTAssertEqual(balanced.compressionLevel, 1)
        XCTAssertEqual(balanced.colorDepth, 24)
        XCTAssertTrue(balanced.hiDPI.enabled)
        XCTAssertTrue(balanced.useAutoDetection)
        
        // 测试质量优先预设
        let quality = RDPSettings.quality
        XCTAssertEqual(quality.profileName, "质量优先")
        XCTAssertEqual(quality.compressionLevel, 0)
        XCTAssertEqual(quality.colorDepth, 32)
        XCTAssertTrue(quality.hiDPI.enabled)
        XCTAssertTrue(quality.useAutoDetection)
    }
    
    func testRDPSettingsAllPresets() {
        let allPresets = RDPSettings.allPresets
        XCTAssertEqual(allPresets.count, 3)
        
        let profileNames = allPresets.map { $0.profileName }
        XCTAssertTrue(profileNames.contains("性能优先"))
        XCTAssertTrue(profileNames.contains("平衡模式"))
        XCTAssertTrue(profileNames.contains("质量优先"))
    }
    
    func testRDPSettingsPresetByName() {
        let performance = RDPSettings.preset(named: "性能优先")
        XCTAssertNotNil(performance)
        XCTAssertEqual(performance?.profileName, "性能优先")
        
        let nonExistent = RDPSettings.preset(named: "不存在的预设")
        XCTAssertNil(nonExistent)
    }
    
    // MARK: - ResolutionSettings Tests
    
    func testResolutionSettingsPresets() {
        let fullHD = ResolutionSettings.fullHD
        XCTAssertEqual(fullHD.width, 1920)
        XCTAssertEqual(fullHD.height, 1080)
        XCTAssertEqual(fullHD.presetName, "Full HD")
        XCTAssertFalse(fullHD.isCustom)
        
        let twoK = ResolutionSettings.twoK
        XCTAssertEqual(twoK.width, 2560)
        XCTAssertEqual(twoK.height, 1440)
        XCTAssertEqual(twoK.presetName, "2K")
        
        let fourK = ResolutionSettings.fourK
        XCTAssertEqual(fourK.width, 3840)
        XCTAssertEqual(fourK.height, 2160)
        XCTAssertEqual(fourK.presetName, "4K")
    }
    
    func testResolutionSettingsValidation() {
        // 测试有效分辨率
        let validResolutions = [
            (800, 600),    // 最小值
            (1920, 1080),  // 常用值
            (3840, 2160),  // 4K
            (7680, 4320)   // 最大值
        ]
        
        for (width, height) in validResolutions {
            let resolution = ResolutionSettings(width: width, height: height, isCustom: true)
            XCTAssertTrue(resolution.isValid, "分辨率 \(width)×\(height) 应该有效")
        }
        
        // 测试无效分辨率
        let invalidResolutions = [
            (500, 400),    // 太小
            (8000, 5000),  // 太大
            (0, 0),        // 零值
            (-1, -1)       // 负值
        ]
        
        for (width, height) in invalidResolutions {
            let resolution = ResolutionSettings(width: width, height: height, isCustom: true)
            XCTAssertFalse(resolution.isValid, "分辨率 \(width)×\(height) 应该无效")
        }
    }
    
    func testResolutionSettingsDisplayName() {
        let preset = ResolutionSettings.fullHD
        XCTAssertEqual(preset.displayName, "1920×1080 (Full HD)")
        
        let custom = ResolutionSettings(width: 1366, height: 768, isCustom: true)
        XCTAssertEqual(custom.displayName, "1366×768 (自定义)")
        
        let regular = ResolutionSettings(width: 2560, height: 1440)
        XCTAssertEqual(regular.displayName, "2560×1440")
    }
    
    func testResolutionSettingsBandwidthEstimation() {
        let fullHD = ResolutionSettings.fullHD
        XCTAssertEqual(fullHD.estimatedBandwidth, "5-10 Mbps")
        
        let twoK = ResolutionSettings.twoK
        XCTAssertEqual(twoK.estimatedBandwidth, "10-25 Mbps")
        
        let fourK = ResolutionSettings.fourK
        XCTAssertEqual(fourK.estimatedBandwidth, "> 25 Mbps")
        
        let lowRes = ResolutionSettings(width: 1366, height: 768, isCustom: true)
        XCTAssertEqual(lowRes.estimatedBandwidth, "< 5 Mbps")
    }
    
    // MARK: - HiDPISettings Tests
    
    func testHiDPISettingsScaleFactorDescriptions() {
        let testCases: [(Double, String)] = [
            (1.0, "100% (标准)"),
            (1.25, "125% (小)"),
            (1.5, "150% (中)"),
            (2.0, "200% (大)"),
            (2.5, "250% (更大)"),
            (3.0, "300% (最大)"),
            (1.75, "175% (自定义)")
        ]
        
        for (scaleFactor, expectedDescription) in testCases {
            let hiDPISettings = HiDPISettings(enabled: true, scaleFactor: scaleFactor)
            XCTAssertEqual(hiDPISettings.scaleFactorDescription, expectedDescription)
        }
    }
    
    // MARK: - RDP Content Generation Tests
    
    func testRDPContentGeneration() {
        let settings = RDPSettings(
            profileName: "测试配置",
            compressionLevel: 1,
            colorDepth: 24,
            audioQuality: "中等",
            enableFontSmoothing: true,
            enableWallpaper: true,
            enableMenuAnimations: false,
            enableThemes: true,
            resolution: ResolutionSettings(width: 1920, height: 1080),
            hiDPI: HiDPISettings(enabled: true, scaleFactor: 2.0),
            useAutoDetection: true
        )
        
        let rdpContent = settings.generateRDPContent(server: "test.server.com", username: "testuser")
        
        // 验证基本连接信息
        XCTAssertTrue(rdpContent.contains("full address:s:test.server.com"))
        XCTAssertTrue(rdpContent.contains("username:s:testuser"))
        
        // 验证分辨率设置
        XCTAssertTrue(rdpContent.contains("desktopwidth:i:1920"))
        XCTAssertTrue(rdpContent.contains("desktopheight:i:1080"))
        
        // 验证HiDPI设置
        XCTAssertTrue(rdpContent.contains("desktopscalefactor:i:200"))
        XCTAssertTrue(rdpContent.contains("hidef color depth:i:24"))
        
        // 验证质量设置
        XCTAssertTrue(rdpContent.contains("compression:i:1"))
        XCTAssertTrue(rdpContent.contains("session bpp:i:24"))
        
        // 验证特效设置
        XCTAssertTrue(rdpContent.contains("font smoothing:i:1"))
        XCTAssertTrue(rdpContent.contains("disable wallpaper:i:0"))
        XCTAssertTrue(rdpContent.contains("disable menu anims:i:1"))
        XCTAssertTrue(rdpContent.contains("disable themes:i:0"))
    }
    
    func testRDPContentGenerationWithoutHiDPI() {
        let settings = RDPSettings(
            profileName: "无HiDPI配置",
            compressionLevel: 2,
            colorDepth: 16,
            audioQuality: "禁用",
            enableFontSmoothing: false,
            enableWallpaper: false,
            enableMenuAnimations: false,
            enableThemes: false,
            resolution: ResolutionSettings(width: 1366, height: 768, isCustom: true),
            hiDPI: HiDPISettings(enabled: false, scaleFactor: 1.0),
            useAutoDetection: false
        )
        
        let rdpContent = settings.generateRDPContent(server: "example.com", username: "user")
        
        // 验证HiDPI相关设置不存在
        XCTAssertFalse(rdpContent.contains("desktopscalefactor"))
        XCTAssertFalse(rdpContent.contains("hidef color depth"))
        
        // 验证其他设置
        XCTAssertTrue(rdpContent.contains("desktopwidth:i:1366"))
        XCTAssertTrue(rdpContent.contains("desktopheight:i:768"))
        XCTAssertTrue(rdpContent.contains("compression:i:2"))
        XCTAssertTrue(rdpContent.contains("session bpp:i:16"))
    }
    
    // MARK: - Configuration Preview Tests
    
    func testConfigurationPreview() {
        let settings = RDPSettings.balanced
        let preview = settings.generatePreview()
        
        XCTAssertTrue(preview.contains("# RDP配置预览"))
        XCTAssertTrue(preview.contains("配置文件: 平衡模式"))
        XCTAssertTrue(preview.contains("显示设置:"))
        XCTAssertTrue(preview.contains("分辨率:"))
        XCTAssertTrue(preview.contains("HiDPI:"))
        XCTAssertTrue(preview.contains("质量设置:"))
        XCTAssertTrue(preview.contains("特效设置:"))
        XCTAssertTrue(preview.contains("性能预估:"))
        XCTAssertTrue(preview.contains("清晰度评级:"))
        XCTAssertTrue(preview.contains("适用场景:"))
    }
    
    // MARK: - DisplayDetector Tests
    
    func testDisplayDetectorInitialization() {
        XCTAssertNotNil(displayDetector)
    }
    
    func testDisplayDetection() {
        do {
            let primaryDisplay = try displayDetector.detectPrimaryDisplay()
            
            XCTAssertGreaterThan(primaryDisplay.width, 0)
            XCTAssertGreaterThan(primaryDisplay.height, 0)
            XCTAssertGreaterThan(primaryDisplay.scaleFactor, 0)
            XCTAssertGreaterThan(primaryDisplay.colorDepth, 0)
            XCTAssertGreaterThanOrEqual(primaryDisplay.refreshRate, 0)
        } catch {
            // 在某些测试环境中可能无法检测显示器
            print("显示器检测跳过: \(error.localizedDescription)")
        }
    }
    
    func testAllDisplaysDetection() {
        do {
            let allDisplays = try displayDetector.detectAllDisplays()
            XCTAssertGreaterThan(allDisplays.count, 0)
            
            for display in allDisplays {
                XCTAssertGreaterThan(display.width, 0)
                XCTAssertGreaterThan(display.height, 0)
                XCTAssertGreaterThan(display.scaleFactor, 0)
            }
        } catch {
            // 在某些测试环境中可能无法检测显示器
            print("显示器检测跳过: \(error.localizedDescription)")
        }
    }
    
    // MARK: - RemoteDesktopIntegrator Tests
    
    func testRemoteDesktopIntegratorInitialization() {
        XCTAssertNotNil(rdpIntegrator)
    }
    
    // MARK: - RDPConfigManager Tests
    
    func testRDPConfigManagerInitialization() {
        XCTAssertNotNil(configManager)
        
        let currentSettings = configManager.currentSettings
        XCTAssertNotNil(currentSettings)
        XCTAssertEqual(currentSettings.profileName, "平衡模式")
    }
    
    // MARK: - Error Handling Tests
    
    func testRDPSettingsError() {
        let noSettingsError = RDPSettingsError.noCurrentSettings
        XCTAssertNotNil(noSettingsError.errorDescription)
        XCTAssertEqual(noSettingsError.errorDescription, "没有当前设置")
        
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "测试错误"])
        let saveFailedError = RDPSettingsError.saveFailed(testError)
        XCTAssertNotNil(saveFailedError.errorDescription)
        XCTAssertTrue(saveFailedError.errorDescription?.contains("保存设置失败") == true)
        
        let presetNotFoundError = RDPSettingsError.presetNotFound("不存在的预设")
        XCTAssertNotNil(presetNotFoundError.errorDescription)
        XCTAssertEqual(presetNotFoundError.errorDescription, "未找到预设配置: 不存在的预设")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceDisplayDetection() {
        measure {
            do {
                _ = try displayDetector.detectPrimaryDisplay()
            } catch {
                // 忽略检测错误，专注于性能测试
            }
        }
    }
    
    func testPerformanceRDPContentGeneration() {
        let settings = RDPSettings.balanced
        
        measure {
            _ = settings.generateRDPContent(server: "test.server.com", username: "testuser")
        }
    }
    
    func testPerformanceConfigurationPreview() {
        let settings = RDPSettings.quality
        
        measure {
            _ = settings.generatePreview()
        }
    }
    
    func testPerformanceResolutionValidation() {
        let testResolutions = [
            (1920, 1080), (2560, 1440), (3840, 2160),
            (1366, 768), (1680, 1050), (3440, 1440),
            (800, 600), (7680, 4320)
        ]
        
        measure {
            for (width, height) in testResolutions {
                let resolution = ResolutionSettings(width: width, height: height, isCustom: true)
                _ = resolution.isValid
                _ = resolution.estimatedBandwidth
                _ = resolution.displayName
            }
        }
    }
}
