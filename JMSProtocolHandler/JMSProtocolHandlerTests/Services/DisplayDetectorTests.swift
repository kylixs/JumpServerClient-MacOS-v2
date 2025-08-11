//
//  DisplayDetectorTests.swift
//  JMSProtocolHandlerTests
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import XCTest
@testable import JMSProtocolHandler

class DisplayDetectorTests: XCTestCase {
    
    var displayDetector: DisplayDetector!
    
    override func setUp() {
        super.setUp()
        displayDetector = DisplayDetector()
    }
    
    override func tearDown() {
        displayDetector = nil
        super.tearDown()
    }
    
    // MARK: - Primary Display Detection Tests
    
    func testDetectPrimaryDisplay_Success() {
        // Given & When
        do {
            let display = try displayDetector.detectPrimaryDisplay()
            
            // Then
            XCTAssertGreaterThan(display.width, 0, "显示器宽度应大于0")
            XCTAssertGreaterThan(display.height, 0, "显示器高度应大于0")
            XCTAssertGreaterThan(display.scaleFactor, 0, "缩放因子应大于0")
            XCTAssertGreaterThan(display.colorDepth, 0, "颜色深度应大于0")
            XCTAssertGreaterThan(display.refreshRate, 0, "刷新率应大于0")
            
            // 验证Retina检测逻辑
            if display.scaleFactor > 1.0 {
                XCTAssertTrue(display.isRetina, "缩放因子>1.0时应识别为Retina显示器")
            } else {
                XCTAssertFalse(display.isRetina, "缩放因子=1.0时应识别为非Retina显示器")
            }
            
        } catch {
            XCTFail("检测主显示器失败: \(error)")
        }
    }
    
    // MARK: - All Displays Detection Tests
    
    func testDetectAllDisplays_Success() {
        // Given & When
        do {
            let displays = try displayDetector.detectAllDisplays()
            
            // Then
            XCTAssertGreaterThan(displays.count, 0, "至少应检测到一个显示器")
            
            for display in displays {
                XCTAssertGreaterThan(display.width, 0, "显示器宽度应大于0")
                XCTAssertGreaterThan(display.height, 0, "显示器高度应大于0")
                XCTAssertGreaterThan(display.scaleFactor, 0, "缩放因子应大于0")
                XCTAssertGreaterThan(display.colorDepth, 0, "颜色深度应大于0")
                XCTAssertGreaterThan(display.refreshRate, 0, "刷新率应大于0")
            }
            
        } catch {
            XCTFail("检测所有显示器失败: \(error)")
        }
    }
    
    // MARK: - HiDPI Detection Tests
    
    func testIsHiDPIDisplay() {
        // Given & When
        let isHiDPI = displayDetector.isHiDPIDisplay()
        
        // Then
        // 这个测试结果取决于运行测试的实际硬件
        // 我们只验证方法能正常执行，不验证具体结果
        XCTAssertNotNil(isHiDPI, "HiDPI检测应返回有效结果")
    }
    
    // MARK: - Optimal RDP Settings Tests
    
    func testGetOptimalRDPSettings_Success() {
        // Given & When
        do {
            let settings = try displayDetector.getOptimalRDPSettings()
            
            // Then
            XCTAssertGreaterThan(settings.desktopWidth, 0, "桌面宽度应大于0")
            XCTAssertGreaterThan(settings.desktopHeight, 0, "桌面高度应大于0")
            XCTAssertGreaterThan(settings.sessionBpp, 0, "颜色深度应大于0")
            XCTAssertGreaterThan(settings.desktopScaleFactor, 0, "桌面缩放因子应大于0")
            
            // 验证合理的分辨率范围
            XCTAssertLessThanOrEqual(settings.desktopWidth, 3840, "桌面宽度不应超过4K")
            XCTAssertLessThanOrEqual(settings.desktopHeight, 2160, "桌面高度不应超过4K")
            
            // 验证颜色深度
            XCTAssertTrue([16, 24, 32].contains(settings.sessionBpp), "颜色深度应为16、24或32位")
            
            // 验证缩放因子
            XCTAssertTrue([100, 125, 150, 200, 250, 300].contains(settings.desktopScaleFactor), 
                         "缩放因子应为常见的百分比值")
            
            // 验证屏幕模式
            XCTAssertTrue([1, 2].contains(settings.screenModeId), "屏幕模式应为1（窗口）或2（全屏）")
            
        } catch {
            XCTFail("获取最优RDP设置失败: \(error)")
        }
    }
    
    // MARK: - Display Configuration Validation Tests
    
    func testDisplayConfiguration_ValidValues() {
        // Given
        do {
            let display = try displayDetector.detectPrimaryDisplay()
            
            // Then - 验证显示器配置的合理性
            XCTAssertTrue(display.width >= 800, "显示器宽度应至少为800像素")
            XCTAssertTrue(display.height >= 600, "显示器高度应至少为600像素")
            XCTAssertTrue(display.scaleFactor >= 1.0, "缩放因子应至少为1.0")
            XCTAssertTrue(display.scaleFactor <= 3.0, "缩放因子不应超过3.0")
            XCTAssertTrue([16, 24, 32].contains(display.colorDepth), "颜色深度应为16、24或32位")
            XCTAssertTrue(display.refreshRate >= 30, "刷新率应至少为30Hz")
            XCTAssertTrue(display.refreshRate <= 240, "刷新率不应超过240Hz")
            
        } catch {
            XCTFail("显示器配置验证失败: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testDisplayDetection_Performance() {
        // Given
        let expectation = XCTestExpectation(description: "显示器检测性能测试")
        
        // When
        DispatchQueue.global().async {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                _ = try self.displayDetector.detectPrimaryDisplay()
                _ = try self.displayDetector.detectAllDisplays()
                _ = self.displayDetector.isHiDPIDisplay()
                _ = try self.displayDetector.getOptimalRDPSettings()
                
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                
                // Then - 显示器检测应在100ms内完成
                XCTAssertLessThan(timeElapsed, 0.1, "显示器检测应在100ms内完成")
                expectation.fulfill()
                
            } catch {
                XCTFail("性能测试中发生错误: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
