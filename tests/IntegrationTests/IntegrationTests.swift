//
//  IntegrationTests.swift
//  集成测试
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import XCTest
@testable import JMSCore
@testable import JMSRDPModule
@testable import JMSSSHModule

class IntegrationTests: XCTestCase {
    
    var configManager: RDPConfigManager!
    
    override func setUp() {
        super.setUp()
        configManager = RDPConfigManager(forTesting: true)
    }
    
    override func tearDown() {
        configManager = nil
        super.tearDown()
    }
    
    // MARK: - RDP配置管理测试
    
    func testRDPConfigManagerBasicFunctionality() {
        // 测试基本的配置管理功能
        XCTAssertNotNil(configManager)
        
        // 测试默认设置
        let defaultSettings = configManager.currentSettings
        XCTAssertNotNil(defaultSettings)
        XCTAssertEqual(defaultSettings.profileName, "平衡模式")
    }
    
    func testRDPSettingsPresets() {
        // 测试预设配置
        let performance = RDPSettings.performance
        XCTAssertEqual(performance.profileName, "性能优先")
        XCTAssertEqual(performance.compressionLevel, 2)
        XCTAssertEqual(performance.colorDepth, 16)
        XCTAssertFalse(performance.hiDPI.enabled)
        
        let balanced = RDPSettings.balanced
        XCTAssertEqual(balanced.profileName, "平衡模式")
        XCTAssertEqual(balanced.compressionLevel, 1)
        XCTAssertEqual(balanced.colorDepth, 24)
        XCTAssertTrue(balanced.hiDPI.enabled)
        
        let quality = RDPSettings.quality
        XCTAssertEqual(quality.profileName, "质量优先")
        XCTAssertEqual(quality.compressionLevel, 0)
        XCTAssertEqual(quality.colorDepth, 32)
        XCTAssertTrue(quality.hiDPI.enabled)
    }
    
    func testResolutionSettings() {
        // 测试分辨率设置
        let fullHD = ResolutionSettings.fullHD
        XCTAssertEqual(fullHD.width, 1920)
        XCTAssertEqual(fullHD.height, 1080)
        XCTAssertEqual(fullHD.presetName, "Full HD")
        XCTAssertTrue(fullHD.isValid)
        
        let twoK = ResolutionSettings.twoK
        XCTAssertEqual(twoK.width, 2560)
        XCTAssertEqual(twoK.height, 1440)
        XCTAssertEqual(twoK.presetName, "2K")
        
        let fourK = ResolutionSettings.fourK
        XCTAssertEqual(fourK.width, 3840)
        XCTAssertEqual(fourK.height, 2160)
        XCTAssertEqual(fourK.presetName, "4K")
        
        // 测试自定义分辨率
        let customValid = ResolutionSettings(width: 1366, height: 768, isCustom: true)
        XCTAssertTrue(customValid.isValid)
        
        let customInvalid = ResolutionSettings(width: 500, height: 400, isCustom: true)
        XCTAssertFalse(customInvalid.isValid)
    }
    
    func testHiDPISettings() {
        // 测试HiDPI设置
        let standardDPI = HiDPISettings(enabled: false, scaleFactor: 1.0)
        XCTAssertEqual(standardDPI.scaleFactorDescription, "100% (标准)")
        
        let hiDPI = HiDPISettings(enabled: true, scaleFactor: 2.0)
        XCTAssertEqual(hiDPI.scaleFactorDescription, "200% (大)")
        
        let customScale = HiDPISettings(enabled: true, scaleFactor: 1.5)
        XCTAssertEqual(customScale.scaleFactorDescription, "150% (中)")
    }
    
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
    
    func testConfigurationPreview() {
        // 测试配置预览生成
        let settings = RDPSettings.balanced
        let preview = settings.generatePreview()
        
        XCTAssertTrue(preview.contains("配置文件: 平衡模式"))
        XCTAssertTrue(preview.contains("分辨率:"))
        XCTAssertTrue(preview.contains("HiDPI:"))
        XCTAssertTrue(preview.contains("清晰度评级:"))
        XCTAssertTrue(preview.contains("预计带宽:"))
    }
    
    // MARK: - 显示器检测测试
    
    func testDisplayDetection() {
        let detector = DisplayDetector()
        
        do {
            let primaryDisplay = try detector.detectPrimaryDisplay()
            XCTAssertGreaterThan(primaryDisplay.width, 0)
            XCTAssertGreaterThan(primaryDisplay.height, 0)
            XCTAssertGreaterThan(primaryDisplay.scaleFactor, 0)
            XCTAssertGreaterThan(primaryDisplay.colorDepth, 0)
        } catch {
            // 在某些测试环境中可能无法检测显示器，这是正常的
            print("显示器检测跳过: \(error.localizedDescription)")
        }
    }
    
    func testAllDisplaysDetection() {
        let detector = DisplayDetector()
        
        do {
            let allDisplays = try detector.detectAllDisplays()
            XCTAssertGreaterThan(allDisplays.count, 0, "至少应该检测到一个显示器")
            
            for display in allDisplays {
                XCTAssertGreaterThan(display.width, 0)
                XCTAssertGreaterThan(display.height, 0)
            }
        } catch {
            // 在某些测试环境中可能无法检测显示器，这是正常的
            print("显示器检测跳过: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 带宽预估测试
    
    func testBandwidthEstimation() {
        let fullHD = ResolutionSettings.fullHD
        XCTAssertEqual(fullHD.estimatedBandwidth, "5-10 Mbps")
        
        let twoK = ResolutionSettings.twoK
        XCTAssertEqual(twoK.estimatedBandwidth, "10-25 Mbps")
        
        let fourK = ResolutionSettings.fourK
        XCTAssertEqual(fourK.estimatedBandwidth, "> 25 Mbps")
        
        let lowRes = ResolutionSettings(width: 1366, height: 768, isCustom: true)
        XCTAssertEqual(lowRes.estimatedBandwidth, "< 5 Mbps")
    }
    
    // MARK: - SSH集成测试
    
    func testSSHTerminalIntegrator() {
        let sshIntegrator = SSHTerminalIntegrator()
        XCTAssertNotNil(sshIntegrator)
        
        // 测试SSH连接信息创建
        let sshConnectionInfo = SSHConnectionInfo(
            ip: "test.server.com",
            port: 22,
            username: "testuser",
            password: "testpass"
        )
        
        let connectionInfo = ConnectionInfo.ssh(sshConnectionInfo)
        
        XCTAssertEqual(connectionInfo.protocolType, "ssh")
        
        // 验证SSH连接信息
        if case .ssh(let sshInfo) = connectionInfo {
            XCTAssertEqual(sshInfo.ip, "test.server.com")
            XCTAssertEqual(sshInfo.port, 22)
            XCTAssertEqual(sshInfo.username, "testuser")
        } else {
            XCTFail("连接信息应该是SSH类型")
        }
    }
    
    // MARK: - 错误处理测试
    
    func testErrorHandling() {
        // 测试RDP设置错误
        let error = RDPSettingsError.noCurrentSettings
        XCTAssertNotNil(error.errorDescription)
        
        let saveError = RDPSettingsError.saveFailed(NSError(domain: "test", code: 1))
        XCTAssertNotNil(saveError.errorDescription)
        
        let presetError = RDPSettingsError.presetNotFound("不存在的预设")
        XCTAssertNotNil(presetError.errorDescription)
    }
    
    // MARK: - 性能测试
    
    func testPerformanceDisplayDetection() {
        let detector = DisplayDetector()
        
        measure {
            do {
                _ = try detector.detectPrimaryDisplay()
            } catch {
                // 忽略检测错误，专注于性能测试
            }
        }
    }
    
    func testPerformanceConfigurationGeneration() {
        let settings = RDPSettings.balanced
        
        measure {
            _ = settings.generateRDPContent(server: "test.server.com", username: "testuser")
            _ = settings.generatePreview()
        }
    }
    
    func testPerformanceResolutionValidation() {
        let testResolutions = [
            (1920, 1080), (2560, 1440), (3840, 2160),
            (1366, 768), (1680, 1050), (3440, 1440)
        ]
        
        measure {
            for (width, height) in testResolutions {
                let resolution = ResolutionSettings(width: width, height: height, isCustom: true)
                _ = resolution.isValid
                _ = resolution.estimatedBandwidth
            }
        }
    }
}

// MARK: - 测试辅助扩展

extension IntegrationTests {
    
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
