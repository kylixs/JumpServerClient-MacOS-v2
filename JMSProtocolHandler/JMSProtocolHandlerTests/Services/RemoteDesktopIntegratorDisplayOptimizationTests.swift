//
//  RemoteDesktopIntegratorDisplayOptimizationTests.swift
//  JMSProtocolHandlerTests
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import XCTest
@testable import JMSProtocolHandler

class RemoteDesktopIntegratorDisplayOptimizationTests: XCTestCase {
    
    var integrator: RemoteDesktopIntegrator!
    
    override func setUp() {
        super.setUp()
        integrator = RemoteDesktopIntegrator()
    }
    
    override func tearDown() {
        integrator = nil
        super.tearDown()
    }
    
    // MARK: - Display Detection Tests
    
    func testDetectAndOptimizeDisplay_Success() {
        // Given & When
        do {
            let displaySettings = try integrator.detectAndOptimizeDisplay()
            
            // Then
            XCTAssertGreaterThan(displaySettings.desktopWidth, 0, "桌面宽度应大于0")
            XCTAssertGreaterThan(displaySettings.desktopHeight, 0, "桌面高度应大于0")
            XCTAssertTrue([16, 24, 32].contains(displaySettings.sessionBpp), "颜色深度应为有效值")
            XCTAssertGreaterThanOrEqual(displaySettings.desktopScaleFactor, 100, "缩放因子应至少为100%")
            XCTAssertTrue([1, 2].contains(displaySettings.screenModeId), "屏幕模式应为有效值")
            
        } catch {
            XCTFail("显示器检测和优化失败: \(error)")
        }
    }
    
    // MARK: - Optimized RDP File Creation Tests
    
    func testCreateOptimizedRDPFile_Success() {
        // Given
        let connectionInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser"
        )
        
        let displaySettings = RDPDisplaySettings(
            desktopWidth: 1920, desktopHeight: 1080,
            sessionBpp: 24, desktopScaleFactor: 100,
            smartSizing: true, compression: 1,
            bitmapCachePersistEnable: true, disableWallpaper: false,
            allowFontSmoothing: false, screenModeId: 2
        )
        
        // When
        do {
            let fileURL = try integrator.createOptimizedRDPFile(with: connectionInfo, displaySettings: displaySettings)
            
            // Then
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "RDP文件应该被创建")
            XCTAssertEqual(fileURL.pathExtension, "rdp", "文件扩展名应为.rdp")
            XCTAssertTrue(fileURL.lastPathComponent.contains("jms_optimized"), "文件名应包含优化标识")
            
            // 验证文件内容
            let content = try String(contentsOf: fileURL)
            XCTAssertTrue(content.contains("full address:s:test.example.com:3389"), "应包含服务器地址")
            XCTAssertTrue(content.contains("username:s:testuser"), "应包含用户名")
            XCTAssertTrue(content.contains("desktopwidth:i:1920"), "应包含桌面宽度")
            XCTAssertTrue(content.contains("desktopheight:i:1080"), "应包含桌面高度")
            XCTAssertTrue(content.contains("desktopscalefactor:i:100"), "应包含缩放因子")
            
            // 清理测试文件
            integrator.cleanupTemporaryFile(at: fileURL)
            
        } catch {
            XCTFail("创建优化RDP文件失败: \(error)")
        }
    }
    
    func testCreateOptimizedRDPFile_InvalidDisplaySettings() {
        // Given
        let connectionInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser"
        )
        
        let invalidDisplaySettings = RDPDisplaySettings(
            desktopWidth: 100, desktopHeight: 100, // 分辨率过小
            sessionBpp: 8, desktopScaleFactor: 50, // 无效参数
            smartSizing: true, compression: 5, // 压缩级别无效
            bitmapCachePersistEnable: true, disableWallpaper: false,
            allowFontSmoothing: false, screenModeId: 3 // 屏幕模式无效
        )
        
        // When & Then
        XCTAssertThrowsError(try integrator.createOptimizedRDPFile(with: connectionInfo, displaySettings: invalidDisplaySettings)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.invalidDisplayParameters, "应抛出无效显示参数错误")
        }
    }
    
    // MARK: - Optimized Launch Tests
    
    func testLaunchOptimizedRemoteDesktop_RemoteDesktopNotFound() {
        // Given
        let connectionInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser"
        )
        
        let displaySettings = RDPDisplaySettings(
            desktopWidth: 1920, desktopHeight: 1080,
            sessionBpp: 24, desktopScaleFactor: 100,
            smartSizing: true, compression: 1,
            bitmapCachePersistEnable: true, disableWallpaper: false,
            allowFontSmoothing: false, screenModeId: 2
        )
        
        // When & Then
        // 注意：这个测试可能会因为实际安装了Microsoft Remote Desktop而失败
        // 在CI环境中应该能正常测试
        if !integrator.checkRemoteDesktopAvailability() {
            XCTAssertThrowsError(try integrator.launchOptimizedRemoteDesktop(with: connectionInfo, displaySettings: displaySettings)) { error in
                XCTAssertEqual(error as? JMSError, JMSError.remoteDesktopNotFound, "应抛出Remote Desktop未找到错误")
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testCreateTemporaryRDPFile_UsesDisplayOptimization() {
        // Given
        let connectionInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser"
        )
        
        // When
        do {
            let fileURL = try integrator.createTemporaryRDPFile(with: connectionInfo)
            
            // Then
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "RDP文件应该被创建")
            
            // 验证文件内容包含显示优化参数
            let content = try String(contentsOf: fileURL)
            XCTAssertTrue(content.contains("desktopwidth:i:"), "应包含桌面宽度优化参数")
            XCTAssertTrue(content.contains("desktopheight:i:"), "应包含桌面高度优化参数")
            XCTAssertTrue(content.contains("desktopscalefactor:i:"), "应包含缩放因子优化参数")
            
            // 清理测试文件
            integrator.cleanupTemporaryFile(at: fileURL)
            
        } catch {
            XCTFail("创建临时RDP文件失败: \(error)")
        }
    }
    
    func testLaunchRemoteDesktop_UsesDisplayOptimization() {
        // Given
        let connectionInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser"
        )
        
        // When & Then
        // 这个测试主要验证方法调用不会抛出显示检测相关的错误
        // 实际的Remote Desktop启动可能会因为应用程序未安装而失败
        do {
            try integrator.launchRemoteDesktop(with: connectionInfo)
            // 如果到达这里，说明显示优化流程工作正常
        } catch JMSError.remoteDesktopNotFound {
            // 这是预期的错误，说明显示优化流程正常，只是Remote Desktop未安装
        } catch JMSError.displayDetectionFailed {
            XCTFail("显示器检测失败，显示优化集成有问题")
        } catch {
            // 其他错误可能是正常的（如文件权限等）
        }
    }
    
    // MARK: - Performance Tests
    
    func testDisplayOptimizationPerformance() {
        // Given
        let connectionInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser"
        )
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            _ = try integrator.detectAndOptimizeDisplay()
            let fileURL = try integrator.createTemporaryRDPFile(with: connectionInfo)
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            // Then
            XCTAssertLessThan(timeElapsed, 0.5, "显示优化和文件创建应在500ms内完成")
            
            // 清理测试文件
            integrator.cleanupTemporaryFile(at: fileURL)
            
        } catch {
            XCTFail("性能测试失败: \(error)")
        }
    }
}
