//
//  RDPSettingsViewControllerTests.swift
//  RDP设置视图控制器测试
//
//  Created by JMS Protocol Handler on 2025-08-13.
//

import XCTest
@testable import JMSRDPModule
@testable import JMSCore

class RDPSettingsViewControllerTests: XCTestCase {
    
    var viewController: RDPSettingsViewController!
    
    override func setUp() {
        super.setUp()
        viewController = RDPSettingsViewController()
        viewController.loadView()
    }
    
    override func tearDown() {
        viewController = nil
        super.tearDown()
    }
    
    // MARK: - 分辨率设置测试
    
    func testResolutionPresets() {
        // 测试预设分辨率选项
        XCTAssertNotNil(viewController.view.subviews.first { $0 is NSPopUpButton })
        
        // 验证预设分辨率包含所需选项
        let resolutionPopup = viewController.view.subviews.compactMap { $0 as? NSPopUpButton }.first
        XCTAssertNotNil(resolutionPopup)
        
        let expectedTitles = [
            "1920×1080 (Full HD)",
            "2560×1440 (2K)",
            "3840×2160 (4K)",
            "自定义分辨率"
        ]
        
        for title in expectedTitles {
            XCTAssertTrue(resolutionPopup?.itemTitles.contains(title) ?? false, "缺少分辨率选项: \(title)")
        }
    }
    
    func testCustomResolutionValidation() {
        // 测试自定义分辨率验证
        let validResolution = ResolutionSettings(width: 1920, height: 1080, isCustom: true)
        XCTAssertTrue(validResolution.isValid, "有效分辨率应该通过验证")
        
        let invalidResolution1 = ResolutionSettings(width: 500, height: 400, isCustom: true)
        XCTAssertFalse(invalidResolution1.isValid, "过小的分辨率应该验证失败")
        
        let invalidResolution2 = ResolutionSettings(width: 8000, height: 5000, isCustom: true)
        XCTAssertFalse(invalidResolution2.isValid, "过大的分辨率应该验证失败")
    }
    
    func testResolutionBandwidthEstimation() {
        // 测试带宽预估
        let fullHD = ResolutionSettings.fullHD
        XCTAssertEqual(fullHD.estimatedBandwidth, "5-10 Mbps")
        
        let fourK = ResolutionSettings.fourK
        XCTAssertEqual(fourK.estimatedBandwidth, "> 25 Mbps")
    }
    
    // MARK: - HiDPI设置测试
    
    func testHiDPISettings() {
        // 测试HiDPI设置
        let hiDPISettings = HiDPISettings(enabled: true, scaleFactor: 2.0)
        XCTAssertEqual(hiDPISettings.scaleFactorDescription, "200% (大)")
        
        let standardSettings = HiDPISettings(enabled: false, scaleFactor: 1.0)
        XCTAssertEqual(standardSettings.scaleFactorDescription, "100% (标准)")
    }
    
    func testScaleFactorDescriptions() {
        // 测试缩放因子描述
        let testCases: [(Double, String)] = [
            (1.0, "100% (标准)"),
            (1.25, "125% (小)"),
            (1.5, "150% (中)"),
            (2.0, "200% (大)"),
            (2.5, "250% (更大)"),
            (3.0, "300% (最大)")
        ]
        
        for (scaleFactor, expectedDescription) in testCases {
            let hiDPISettings = HiDPISettings(enabled: true, scaleFactor: scaleFactor)
            XCTAssertEqual(hiDPISettings.scaleFactorDescription, expectedDescription)
        }
    }
    
    // MARK: - RDP配置生成测试
    
    func testRDPContentGeneration() {
        // 测试RDP配置文件内容生成
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
        
        XCTAssertTrue(rdpContent.contains("full address:s:test.server.com"))
        XCTAssertTrue(rdpContent.contains("username:s:testuser"))
        XCTAssertTrue(rdpContent.contains("desktopwidth:i:1920"))
        XCTAssertTrue(rdpContent.contains("desktopheight:i:1080"))
        XCTAssertTrue(rdpContent.contains("desktopscalefactor:i:200"))
        XCTAssertTrue(rdpContent.contains("compression:i:1"))
        XCTAssertTrue(rdpContent.contains("session bpp:i:24"))
    }
    
    // MARK: - 显示器检测测试
    
    func testDisplayDetector() {
        // 测试显示器检测器
        let detector = DisplayDetector()
        
        do {
            let primaryDisplay = try detector.detectPrimaryDisplay()
            XCTAssertGreaterThan(primaryDisplay.width, 0)
            XCTAssertGreaterThan(primaryDisplay.height, 0)
            XCTAssertGreaterThan(primaryDisplay.scaleFactor, 0)
            XCTAssertGreaterThan(primaryDisplay.colorDepth, 0)
        } catch {
            XCTFail("显示器检测失败: \(error.localizedDescription)")
        }
    }
    
    func testAllDisplaysDetection() {
        // 测试所有显示器检测
        let detector = DisplayDetector()
        
        do {
            let allDisplays = try detector.detectAllDisplays()
            XCTAssertGreaterThan(allDisplays.count, 0, "至少应该检测到一个显示器")
            
            for display in allDisplays {
                XCTAssertGreaterThan(display.width, 0)
                XCTAssertGreaterThan(display.height, 0)
            }
        } catch {
            XCTFail("显示器检测失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 预设配置测试
    
    func testPresetConfigurations() {
        // 测试预设配置
        let performance = RDPSettings.performance
        XCTAssertEqual(performance.profileName, "性能优先")
        XCTAssertEqual(performance.compressionLevel, 2)
        XCTAssertEqual(performance.colorDepth, 16)
        XCTAssertFalse(performance.hiDPI.enabled)
        
        let quality = RDPSettings.quality
        XCTAssertEqual(quality.profileName, "质量优先")
        XCTAssertEqual(quality.compressionLevel, 0)
        XCTAssertEqual(quality.colorDepth, 32)
        XCTAssertTrue(quality.hiDPI.enabled)
        
        let balanced = RDPSettings.balanced
        XCTAssertEqual(balanced.profileName, "平衡模式")
        XCTAssertEqual(balanced.compressionLevel, 1)
        XCTAssertEqual(balanced.colorDepth, 24)
    }
    
    // MARK: - 清晰度评级测试
    
    func testClarityRating() {
        // 测试清晰度评级算法
        let lowQuality = RDPSettings.performance
        let lowRating = lowQuality.generatePreview()
        XCTAssertTrue(lowRating.contains("⭐") || lowRating.contains("⭐⭐"))
        
        let highQuality = RDPSettings.quality
        let highRating = highQuality.generatePreview()
        XCTAssertTrue(highRating.contains("⭐⭐⭐") || highRating.contains("⭐⭐⭐⭐"))
    }
    
    // MARK: - 性能测试
    
    func testPerformanceDisplayDetection() {
        // 测试显示器检测性能
        let detector = DisplayDetector()
        
        measure {
            do {
                _ = try detector.detectPrimaryDisplay()
            } catch {
                XCTFail("显示器检测失败: \(error.localizedDescription)")
            }
        }
    }
    
    func testPerformanceConfigurationGeneration() {
        // 测试配置生成性能
        let settings = RDPSettings.balanced
        
        measure {
            _ = settings.generateRDPContent(server: "test.server.com", username: "testuser")
        }
    }
}

// MARK: - 测试辅助扩展

extension RDPSettingsViewControllerTests {
    
    /// 创建测试用的显示器配置
    func createTestDisplayConfiguration() -> DisplayConfiguration {
        return DisplayConfiguration(
            width: 2560,
            height: 1440,
            scaleFactor: 2.0,
            colorDepth: 32,
            isHiDPI: true,
            refreshRate: 60.0,
            displayID: 1
        )
    }
    
    /// 创建测试用的RDP设置
    func createTestRDPSettings() -> RDPSettings {
        return RDPSettings(
            profileName: "测试配置",
            compressionLevel: 1,
            colorDepth: 24,
            audioQuality: "中等",
            enableFontSmoothing: true,
            enableWallpaper: true,
            enableMenuAnimations: false,
            enableThemes: true,
            resolution: ResolutionSettings(width: 1920, height: 1080),
            hiDPI: HiDPISettings(enabled: true, scaleFactor: 1.5),
            useAutoDetection: true
        )
    }
}
