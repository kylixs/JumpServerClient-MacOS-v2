//
//  RDPConfigOptimizerTests.swift
//  JMSProtocolHandlerTests
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import XCTest
@testable import JMSProtocolHandler

class RDPConfigOptimizerTests: XCTestCase {
    
    var optimizer: RDPConfigOptimizer!
    
    override func setUp() {
        super.setUp()
        optimizer = RDPConfigOptimizer()
    }
    
    override func tearDown() {
        optimizer = nil
        super.tearDown()
    }
    
    // MARK: - Display Optimization Tests
    
    func testOptimizeForDisplay_RetinaDisplay() {
        // Given
        let retinaDisplay = DisplayConfiguration(
            width: 2880, height: 1800,
            scaleFactor: 2.0, colorDepth: 32,
            refreshRate: 60, isRetina: true, isExternal: false
        )
        
        // When
        let settings = optimizer.optimizeForDisplay(retinaDisplay)
        
        // Then
        XCTAssertEqual(settings.desktopWidth, 2880, "Retina显示器应使用原生分辨率宽度")
        XCTAssertEqual(settings.desktopHeight, 1800, "Retina显示器应使用原生分辨率高度")
        XCTAssertEqual(settings.sessionBpp, 32, "Retina显示器应使用32位颜色深度")
        XCTAssertEqual(settings.desktopScaleFactor, 200, "Retina显示器应使用200%缩放")
        XCTAssertEqual(settings.compression, 0, "Retina显示器应使用无压缩")
        XCTAssertTrue(settings.allowFontSmoothing, "Retina显示器应启用字体平滑")
        XCTAssertTrue(settings.smartSizing, "应启用智能调整")
        XCTAssertEqual(settings.screenModeId, 2, "应使用全屏模式")
    }
    
    func testOptimizeForDisplay_StandardDisplay() {
        // Given
        let standardDisplay = DisplayConfiguration(
            width: 1920, height: 1080,
            scaleFactor: 1.0, colorDepth: 24,
            refreshRate: 60, isRetina: false, isExternal: true
        )
        
        // When
        let settings = optimizer.optimizeForDisplay(standardDisplay)
        
        // Then
        XCTAssertEqual(settings.desktopWidth, 1920, "标准显示器应使用原生分辨率宽度")
        XCTAssertEqual(settings.desktopHeight, 1080, "标准显示器应使用原生分辨率高度")
        XCTAssertEqual(settings.sessionBpp, 24, "标准显示器应使用24位颜色深度")
        XCTAssertEqual(settings.desktopScaleFactor, 100, "标准显示器应使用100%缩放")
        XCTAssertEqual(settings.compression, 1, "标准显示器应使用适度压缩")
        XCTAssertFalse(settings.allowFontSmoothing, "标准显示器不需要字体平滑")
        XCTAssertTrue(settings.smartSizing, "应启用智能调整")
    }
    
    func testOptimizeForDisplay_4KDisplay() {
        // Given
        let display4K = DisplayConfiguration(
            width: 4096, height: 2304,
            scaleFactor: 1.0, colorDepth: 32,
            refreshRate: 60, isRetina: false, isExternal: true
        )
        
        // When
        let settings = optimizer.optimizeForDisplay(display4K)
        
        // Then
        XCTAssertLessThanOrEqual(settings.desktopWidth, 3840, "4K显示器宽度应限制在3840以内")
        XCTAssertLessThanOrEqual(settings.desktopHeight, 2160, "4K显示器高度应限制在2160以内")
        XCTAssertEqual(settings.desktopWidth % 16, 0, "宽度应是16的倍数")
        XCTAssertEqual(settings.desktopHeight % 16, 0, "高度应是16的倍数")
    }
    
    // MARK: - Quality Profile Tests
    
    func testOptimizeForProfile_Performance() {
        // Given
        let display = DisplayConfiguration(
            width: 2560, height: 1440,
            scaleFactor: 1.0, colorDepth: 32,
            refreshRate: 144, isRetina: false, isExternal: true
        )
        
        // When
        let settings = optimizer.optimizeForProfile(.performance, display: display)
        
        // Then
        XCTAssertLessThanOrEqual(settings.desktopWidth, 1920, "性能模式应限制分辨率")
        XCTAssertLessThanOrEqual(settings.desktopHeight, 1080, "性能模式应限制分辨率")
        XCTAssertEqual(settings.sessionBpp, 16, "性能模式应使用16位颜色深度")
        XCTAssertEqual(settings.compression, 2, "性能模式应使用最高压缩")
        XCTAssertFalse(settings.bitmapCachePersistEnable, "性能模式应禁用位图缓存")
        XCTAssertTrue(settings.disableWallpaper, "性能模式应禁用壁纸")
        XCTAssertEqual(settings.screenModeId, 1, "性能模式应使用窗口模式")
    }
    
    func testOptimizeForProfile_Quality() {
        // Given
        let display = DisplayConfiguration(
            width: 1920, height: 1080,
            scaleFactor: 1.0, colorDepth: 24,
            refreshRate: 60, isRetina: false, isExternal: false
        )
        
        // When
        let settings = optimizer.optimizeForProfile(.quality, display: display)
        
        // Then
        XCTAssertEqual(settings.sessionBpp, 32, "质量模式应使用32位颜色深度")
        XCTAssertEqual(settings.compression, 0, "质量模式应使用无压缩")
        XCTAssertTrue(settings.bitmapCachePersistEnable, "质量模式应启用位图缓存")
        XCTAssertFalse(settings.disableWallpaper, "质量模式应保持壁纸")
        XCTAssertTrue(settings.allowFontSmoothing, "质量模式应启用字体平滑")
        XCTAssertEqual(settings.screenModeId, 2, "质量模式应使用全屏模式")
    }
    
    // MARK: - RDP Config Generation Tests
    
    func testGenerateRDPConfigString() {
        // Given
        let settings = RDPDisplaySettings(
            desktopWidth: 1920, desktopHeight: 1080,
            sessionBpp: 24, desktopScaleFactor: 100,
            smartSizing: true, compression: 1,
            bitmapCachePersistEnable: true, disableWallpaper: false,
            allowFontSmoothing: false, screenModeId: 2
        )
        
        let connectionInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser",
            additionalConfig: [:]
        )
        
        // When
        let configString = optimizer.generateRDPConfigString(settings, connectionInfo: connectionInfo)
        
        // Then
        XCTAssertTrue(configString.contains("full address:s:test.example.com:3389"), "应包含服务器地址")
        XCTAssertTrue(configString.contains("username:s:testuser"), "应包含用户名")
        XCTAssertTrue(configString.contains("desktopwidth:i:1920"), "应包含桌面宽度")
        XCTAssertTrue(configString.contains("desktopheight:i:1080"), "应包含桌面高度")
        XCTAssertTrue(configString.contains("session bpp:i:24"), "应包含颜色深度")
        XCTAssertTrue(configString.contains("desktopscalefactor:i:100"), "应包含缩放因子")
        XCTAssertTrue(configString.contains("compression:i:1"), "应包含压缩设置")
        XCTAssertTrue(configString.contains("connection type:i:6"), "应包含连接类型")
        XCTAssertTrue(configString.contains("audiomode:i:0"), "应包含音频设置")
        XCTAssertTrue(configString.contains("redirectclipboard:i:1"), "应包含剪贴板重定向")
    }
    
    // MARK: - Validation Tests
    
    func testValidateRDPSettings_ValidSettings() {
        // Given
        let validSettings = RDPDisplaySettings(
            desktopWidth: 1920, desktopHeight: 1080,
            sessionBpp: 24, desktopScaleFactor: 100,
            smartSizing: true, compression: 1,
            bitmapCachePersistEnable: true, disableWallpaper: false,
            allowFontSmoothing: false, screenModeId: 2
        )
        
        // When & Then
        XCTAssertTrue(optimizer.validateRDPSettings(validSettings), "有效设置应通过验证")
    }
    
    func testValidateRDPSettings_InvalidResolution() {
        // Given
        let invalidSettings = RDPDisplaySettings(
            desktopWidth: 100, desktopHeight: 100, // 分辨率过小
            sessionBpp: 24, desktopScaleFactor: 100,
            smartSizing: true, compression: 1,
            bitmapCachePersistEnable: true, disableWallpaper: false,
            allowFontSmoothing: false, screenModeId: 2
        )
        
        // When & Then
        XCTAssertFalse(optimizer.validateRDPSettings(invalidSettings), "无效分辨率应验证失败")
    }
    
    func testValidateRDPSettings_InvalidColorDepth() {
        // Given
        let invalidSettings = RDPDisplaySettings(
            desktopWidth: 1920, desktopHeight: 1080,
            sessionBpp: 8, // 无效的颜色深度
            desktopScaleFactor: 100,
            smartSizing: true, compression: 1,
            bitmapCachePersistEnable: true, disableWallpaper: false,
            allowFontSmoothing: false, screenModeId: 2
        )
        
        // When & Then
        XCTAssertFalse(optimizer.validateRDPSettings(invalidSettings), "无效颜色深度应验证失败")
    }
    
    func testValidateRDPSettings_InvalidScaleFactor() {
        // Given
        let invalidSettings = RDPDisplaySettings(
            desktopWidth: 1920, desktopHeight: 1080,
            sessionBpp: 24, desktopScaleFactor: 50, // 缩放因子过小
            smartSizing: true, compression: 1,
            bitmapCachePersistEnable: true, disableWallpaper: false,
            allowFontSmoothing: false, screenModeId: 2
        )
        
        // When & Then
        XCTAssertFalse(optimizer.validateRDPSettings(invalidSettings), "无效缩放因子应验证失败")
    }
    
    // MARK: - Performance Tests
    
    func testOptimizationPerformance() {
        // Given
        let display = DisplayConfiguration(
            width: 2560, height: 1440,
            scaleFactor: 2.0, colorDepth: 32,
            refreshRate: 60, isRetina: true, isExternal: false
        )
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<1000 {
            _ = optimizer.optimizeForDisplay(display)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertLessThan(timeElapsed, 0.1, "1000次优化操作应在100ms内完成")
    }
}
