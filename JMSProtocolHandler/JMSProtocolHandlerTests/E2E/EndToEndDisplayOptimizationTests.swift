//
//  EndToEndDisplayOptimizationTests.swift
//  JMSProtocolHandlerTests
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import XCTest
@testable import JMSProtocolHandler

class EndToEndDisplayOptimizationTests: XCTestCase {
    
    var remoteDesktopIntegrator: RemoteDesktopIntegrator!
    var displayDetector: DisplayDetector!
    var configOptimizer: RDPConfigOptimizer!
    
    override func setUp() {
        super.setUp()
        remoteDesktopIntegrator = RemoteDesktopIntegrator()
        displayDetector = DisplayDetector()
        configOptimizer = RDPConfigOptimizer()
    }
    
    override func tearDown() {
        remoteDesktopIntegrator.cleanupAllTemporaryFiles()
        remoteDesktopIntegrator = nil
        displayDetector = nil
        configOptimizer = nil
        super.tearDown()
    }
    
    // MARK: - Display Configuration Tests
    
    func testVariousDisplayConfigurations() {
        // Given - 模拟不同的显示器配置
        let testConfigurations = [
            // 标准1080p显示器
            DisplayConfiguration(
                width: 1920, height: 1080, scaleFactor: 1.0,
                colorDepth: 24, isRetina: false
            ),
            // 4K显示器
            DisplayConfiguration(
                width: 3840, height: 2160, scaleFactor: 1.0,
                colorDepth: 32, isRetina: false
            ),
            // MacBook Pro Retina显示器
            DisplayConfiguration(
                width: 2880, height: 1800, scaleFactor: 2.0,
                colorDepth: 32, isRetina: true
            ),
            // 超宽屏显示器
            DisplayConfiguration(
                width: 3440, height: 1440, scaleFactor: 1.0,
                colorDepth: 24, isRetina: false
            )
        ]
        
        // When & Then - 测试每种配置
        for (index, config) in testConfigurations.enumerated() {
            print("🔄 测试显示器配置 \(index + 1): \(config.width)x\(config.height)")
            
            let optimizedSettings = configOptimizer.optimizeForDisplay(config)
            
            // 验证优化结果
            XCTAssertGreaterThan(optimizedSettings.desktopWidth, 0, "桌面宽度应大于0")
            XCTAssertGreaterThan(optimizedSettings.desktopHeight, 0, "桌面高度应大于0")
            XCTAssertLessThanOrEqual(optimizedSettings.desktopWidth, 3840, "桌面宽度不应超过4K")
            XCTAssertLessThanOrEqual(optimizedSettings.desktopHeight, 2160, "桌面高度不应超过4K")
            
            // HiDPI显示器特殊验证
            if config.isRetina {
                XCTAssertGreaterThan(optimizedSettings.desktopScaleFactor, 100, "Retina显示器应有缩放因子")
                XCTAssertEqual(optimizedSettings.compression, 0, "Retina显示器应使用无压缩")
                XCTAssertTrue(optimizedSettings.allowFontSmoothing, "Retina显示器应启用字体平滑")
            }
            
            print("✅ 显示器配置 \(index + 1) 优化成功")
        }
    }
    
    func testQualityProfiles() {
        // Given
        let testDisplay = DisplayConfiguration(
            width: 1920, height: 1080, scaleFactor: 1.0,
            colorDepth: 24, isRetina: false
        )
        
        let profiles: [DisplayQualityProfile] = [.performance, .balanced, .quality, .custom]
        
        // When & Then
        for profile in profiles {
            print("🔄 测试质量配置文件: \(profile)")
            
            let settings = configOptimizer.optimizeForProfile(profile, display: testDisplay)
            
            switch profile {
            case .performance:
                XCTAssertLessThanOrEqual(settings.desktopWidth, 1920, "性能模式应限制分辨率")
                XCTAssertEqual(settings.sessionBpp, 16, "性能模式应使用16位颜色")
                XCTAssertEqual(settings.compression, 2, "性能模式应使用最高压缩")
                XCTAssertTrue(settings.disableWallpaper, "性能模式应禁用壁纸")
                
            case .quality:
                XCTAssertEqual(settings.sessionBpp, 32, "质量模式应使用32位颜色")
                XCTAssertEqual(settings.compression, 0, "质量模式应使用无压缩")
                XCTAssertFalse(settings.disableWallpaper, "质量模式应保持壁纸")
                XCTAssertTrue(settings.allowFontSmoothing, "质量模式应启用字体平滑")
                
            case .balanced, .custom:
                XCTAssertTrue([16, 24, 32].contains(settings.sessionBpp), "平衡模式颜色深度应合理")
                XCTAssertTrue((0...2).contains(settings.compression), "平衡模式压缩级别应合理")
            }
            
            print("✅ 质量配置文件 \(profile) 测试通过")
        }
    }
    
    // MARK: - Microsoft Remote Desktop Integration Tests
    
    func testRemoteDesktopIntegration() {
        // Given
        let rdpInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser"
        )
        
        // When
        do {
            // 检查Remote Desktop可用性
            let isAvailable = remoteDesktopIntegrator.checkRemoteDesktopAvailability()
            print("Microsoft Remote Desktop 可用性: \(isAvailable)")
            
            // 创建优化的RDP文件
            let displaySettings = try remoteDesktopIntegrator.detectAndOptimizeDisplay()
            let rdpFileURL = try remoteDesktopIntegrator.createOptimizedRDPFile(
                with: rdpInfo,
                displaySettings: displaySettings
            )
            
            // Then - 验证文件内容
            let fileContent = try String(contentsOf: rdpFileURL)
            
            // 验证基本RDP参数
            XCTAssertTrue(fileContent.contains("full address:s:test.example.com:3389"), "应包含服务器地址")
            XCTAssertTrue(fileContent.contains("username:s:testuser"), "应包含用户名")
            
            // 验证显示优化参数
            XCTAssertTrue(fileContent.contains("desktopwidth:i:"), "应包含桌面宽度")
            XCTAssertTrue(fileContent.contains("desktopheight:i:"), "应包含桌面高度")
            XCTAssertTrue(fileContent.contains("desktopscalefactor:i:"), "应包含缩放因子")
            XCTAssertTrue(fileContent.contains("session bpp:i:"), "应包含颜色深度")
            
            // 验证连接优化参数
            XCTAssertTrue(fileContent.contains("connection type:i:6"), "应包含连接类型")
            XCTAssertTrue(fileContent.contains("networkautodetect:i:1"), "应包含网络自动检测")
            XCTAssertTrue(fileContent.contains("bandwidthautodetect:i:1"), "应包含带宽自动检测")
            
            // 验证音频和重定向设置
            XCTAssertTrue(fileContent.contains("audiomode:i:0"), "应包含音频模式")
            XCTAssertTrue(fileContent.contains("redirectclipboard:i:1"), "应包含剪贴板重定向")
            
            // 清理测试文件
            remoteDesktopIntegrator.cleanupTemporaryFile(at: rdpFileURL)
            
            print("✅ Microsoft Remote Desktop 集成测试通过")
            
        } catch {
            XCTFail("Remote Desktop集成测试失败: \(error)")
        }
    }
    
    // MARK: - Performance Impact Tests
    
    func testDisplayOptimizationPerformanceImpact() {
        // Given
        let rdpInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser"
        )
        
        let iterations = 10
        var totalTime: Double = 0
        
        // When - 多次执行显示优化流程
        for i in 1...iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                let displaySettings = try remoteDesktopIntegrator.detectAndOptimizeDisplay()
                let rdpFileURL = try remoteDesktopIntegrator.createOptimizedRDPFile(
                    with: rdpInfo,
                    displaySettings: displaySettings
                )
                
                let iterationTime = CFAbsoluteTimeGetCurrent() - startTime
                totalTime += iterationTime
                
                // 清理
                remoteDesktopIntegrator.cleanupTemporaryFile(at: rdpFileURL)
                
                print("迭代 \(i): \(String(format: "%.3f", iterationTime * 1000))ms")
                
            } catch {
                XCTFail("性能测试迭代 \(i) 失败: \(error)")
            }
        }
        
        // Then - 验证性能指标
        let averageTime = totalTime / Double(iterations)
        let maxAcceptableTime = 0.5 // 500ms
        
        XCTAssertLessThan(averageTime, maxAcceptableTime, "平均处理时间应小于500ms")
        
        print("✅ 性能测试通过:")
        print("   - 总时间: \(String(format: "%.3f", totalTime * 1000))ms")
        print("   - 平均时间: \(String(format: "%.3f", averageTime * 1000))ms")
        print("   - 最大可接受时间: \(String(format: "%.3f", maxAcceptableTime * 1000))ms")
    }
    
    // MARK: - Error Recovery Tests
    
    func testDisplayDetectionFailureRecovery() {
        // Given - 模拟显示检测失败的情况
        let rdpInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser"
        )
        
        // When & Then - 验证错误恢复机制
        do {
            // 正常情况下应该成功
            let displaySettings = try remoteDesktopIntegrator.detectAndOptimizeDisplay()
            XCTAssertNotNil(displaySettings, "显示器检测应该成功")
            
            // 验证备用配置
            let defaultSettings = RDPDisplaySettings(
                desktopWidth: 1920, desktopHeight: 1080,
                sessionBpp: 24, desktopScaleFactor: 100,
                smartSizing: true, compression: 1,
                bitmapCachePersistEnable: true, disableWallpaper: false,
                allowFontSmoothing: false, screenModeId: 2
            )
            
            let rdpFileURL = try remoteDesktopIntegrator.createOptimizedRDPFile(
                with: rdpInfo,
                displaySettings: defaultSettings
            )
            
            XCTAssertTrue(FileManager.default.fileExists(atPath: rdpFileURL.path), "备用配置应该能创建RDP文件")
            
            // 清理
            remoteDesktopIntegrator.cleanupTemporaryFile(at: rdpFileURL)
            
            print("✅ 错误恢复测试通过")
            
        } catch {
            XCTFail("错误恢复测试失败: \(error)")
        }
    }
    
    // MARK: - Multi-Display Environment Tests
    
    func testMultiDisplayEnvironment() {
        // Given - 模拟多显示器环境
        do {
            let allDisplays = try displayDetector.detectAllDisplays()
            let primaryDisplay = try displayDetector.detectPrimaryDisplay()
            
            // When & Then
            XCTAssertGreaterThan(allDisplays.count, 0, "应该检测到至少一个显示器")
            XCTAssertNotNil(primaryDisplay, "应该检测到主显示器")
            
            // 验证主显示器在所有显示器列表中
            let primaryFound = allDisplays.contains { display in
                display.width == primaryDisplay.width &&
                display.height == primaryDisplay.height &&
                display.scaleFactor == primaryDisplay.scaleFactor
            }
            
            XCTAssertTrue(primaryFound, "主显示器应该在所有显示器列表中")
            
            // 为每个显示器生成优化配置
            for (index, display) in allDisplays.enumerated() {
                let optimizedSettings = configOptimizer.optimizeForDisplay(display)
                XCTAssertTrue(configOptimizer.validateRDPSettings(optimizedSettings), "显示器 \(index) 的优化设置应该有效")
            }
            
            print("✅ 多显示器环境测试通过，检测到 \(allDisplays.count) 个显示器")
            
        } catch {
            XCTFail("多显示器环境测试失败: \(error)")
        }
    }
    
    // MARK: - SSH Workflow Preservation Tests
    
    func testSSHWorkflowPreservation() {
        // Given - SSH连接信息
        let sshInfo = SSHConnectionInfo(
            ip: "192.168.1.100",
            port: "22",
            username: "testuser",
            password: "testpass",
            filename: "test_ssh"
        )
        
        let sshIntegrator = SSHTerminalIntegrator()
        
        // When & Then - 验证SSH流程不受显示优化影响
        do {
            // 执行显示优化（这不应该影响SSH）
            _ = try remoteDesktopIntegrator.detectAndOptimizeDisplay()
            
            // SSH功能应该正常工作
            let availableTerminal = sshIntegrator.detectAvailableTerminal()
            XCTAssertNotEqual(availableTerminal, .unavailable, "应该检测到可用终端")
            
            let sshCommand = sshIntegrator.buildSSHCommand(from: sshInfo)
            XCTAssertTrue(sshCommand.contains("ssh"), "SSH命令应该包含ssh")
            XCTAssertTrue(sshCommand.contains("192.168.1.100"), "SSH命令应该包含IP地址")
            XCTAssertTrue(sshCommand.contains("22"), "SSH命令应该包含端口")
            
            print("✅ SSH工作流程保持测试通过")
            
        } catch {
            XCTFail("SSH工作流程保持测试失败: \(error)")
        }
    }
    
    // MARK: - End-to-End Integration Test
    
    func testCompleteEndToEndFlow() {
        // Given - 完整的端到端测试场景
        let rdpConfig = """
        full address:s:test.example.com:3389
        username:s:testuser
        session bpp:i:32
        audiomode:i:0
        smart sizing:i:1
        screen mode id:i:2
        """
        
        let jmsConfigDict: [String: Any] = [
            "protocol": "rdp",
            "config": rdpConfig
        ]
        
        do {
            // 创建完整的JMS URL
            let jsonData = try JSONSerialization.data(withJSONObject: jmsConfigDict)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            let base64Payload = Data(jsonString.utf8).base64EncodedString()
            let testURL = URL(string: "jms://\(base64Payload)")!
            
            print("🔄 开始端到端完整流程测试")
            
            // 模拟AppDelegate的完整处理流程
            let urlParser = URLParser()
            let payloadDecoder = PayloadDecoder()
            let connectionInfoExtractor = ConnectionInfoExtractor()
            
            // 步骤1-3: URL处理
            let urlComponents = try urlParser.parseJMSURL(testURL)
            let jmsConfig = try payloadDecoder.decodePayload(urlComponents.payload)
            let connectionInfo = try connectionInfoExtractor.extractConnectionInfo(from: jmsConfig)
            
            // 步骤4: RDP处理（包含显示优化）
            guard case .rdp(let rdpInfo) = connectionInfo else {
                XCTFail("应该提取到RDP连接信息")
                return
            }
            
            // 步骤5: 显示优化和文件创建
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let displaySettings = try remoteDesktopIntegrator.detectAndOptimizeDisplay()
            let rdpFileURL = try remoteDesktopIntegrator.createOptimizedRDPFile(
                with: rdpInfo,
                displaySettings: displaySettings
            )
            
            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            
            // 验证结果
            XCTAssertTrue(FileManager.default.fileExists(atPath: rdpFileURL.path), "RDP文件应该被创建")
            XCTAssertLessThan(totalTime, 1.0, "端到端流程应在1秒内完成")
            
            // 验证文件内容
            let fileContent = try String(contentsOf: rdpFileURL)
            XCTAssertTrue(fileContent.contains("test.example.com:3389"), "应包含服务器地址")
            XCTAssertTrue(fileContent.contains("testuser"), "应包含用户名")
            XCTAssertTrue(fileContent.contains("desktopwidth:i:"), "应包含显示优化参数")
            
            // 清理
            remoteDesktopIntegrator.cleanupTemporaryFile(at: rdpFileURL)
            
            print("🎉 端到端完整流程测试成功")
            print("   - 总处理时间: \(String(format: "%.3f", totalTime * 1000))ms")
            
        } catch {
            XCTFail("端到端完整流程测试失败: \(error)")
        }
    }
}
