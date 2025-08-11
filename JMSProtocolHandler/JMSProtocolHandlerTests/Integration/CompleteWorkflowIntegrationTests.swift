//
//  CompleteWorkflowIntegrationTests.swift
//  JMSProtocolHandlerTests
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import XCTest
@testable import JMSProtocolHandler

class CompleteWorkflowIntegrationTests: XCTestCase {
    
    var urlParser: URLParser!
    var payloadDecoder: PayloadDecoder!
    var connectionInfoExtractor: ConnectionInfoExtractor!
    var remoteDesktopIntegrator: RemoteDesktopIntegrator!
    var sshTerminalIntegrator: SSHTerminalIntegrator!
    var errorHandler: ErrorHandler!
    var notificationManager: NotificationManager!
    
    override func setUp() {
        super.setUp()
        urlParser = URLParser()
        payloadDecoder = PayloadDecoder()
        connectionInfoExtractor = ConnectionInfoExtractor()
        remoteDesktopIntegrator = RemoteDesktopIntegrator()
        sshTerminalIntegrator = SSHTerminalIntegrator()
        errorHandler = ErrorHandler()
        notificationManager = NotificationManager()
    }
    
    override func tearDown() {
        // 清理临时文件
        remoteDesktopIntegrator.cleanupAllTemporaryFiles()
        
        urlParser = nil
        payloadDecoder = nil
        connectionInfoExtractor = nil
        remoteDesktopIntegrator = nil
        sshTerminalIntegrator = nil
        errorHandler = nil
        notificationManager = nil
        super.tearDown()
    }
    
    // MARK: - RDP Complete Workflow Tests (with Display Optimization)
    
    func testCompleteRDPWorkflowWithDisplayOptimization() {
        // Given - 创建一个完整的RDP URL
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
            let jsonData = try JSONSerialization.data(withJSONObject: jmsConfigDict)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            let base64Payload = Data(jsonString.utf8).base64EncodedString()
            let testURL = URL(string: "jms://\(base64Payload)")!
            
            // When - 执行完整的工作流程
            print("🔄 开始RDP完整工作流程测试（包含显示优化）")
            
            // 步骤1: URL解析
            print("Step 1: 解析JMS URL...")
            let urlComponents = try urlParser.parseJMSURL(testURL)
            XCTAssertEqual(urlComponents.scheme, "jms", "URL scheme应为jms")
            XCTAssertFalse(urlComponents.payload.isEmpty, "Payload不应为空")
            print("✅ URL解析成功")
            
            // 步骤2: Payload解码
            print("Step 2: 解码payload...")
            let jmsConfig = try payloadDecoder.decodePayload(urlComponents.payload)
            XCTAssertEqual(jmsConfig.protocol, "rdp", "协议类型应为rdp")
            print("✅ Payload解码成功")
            
            // 步骤3: 连接信息提取
            print("Step 3: 提取连接信息...")
            let connectionInfo = try connectionInfoExtractor.extractConnectionInfo(from: jmsConfig)
            
            guard case .rdp(let rdpInfo) = connectionInfo else {
                XCTFail("应该提取到RDP连接信息")
                return
            }
            
            XCTAssertEqual(rdpInfo.fullAddress, "test.example.com:3389", "服务器地址应正确")
            XCTAssertEqual(rdpInfo.username, "testuser", "用户名应正确")
            print("✅ 连接信息提取成功")
            
            // 步骤4: 显示器检测和优化
            print("Step 4: 显示器检测和优化...")
            let displaySettings = try remoteDesktopIntegrator.detectAndOptimizeDisplay()
            
            XCTAssertGreaterThan(displaySettings.desktopWidth, 0, "桌面宽度应大于0")
            XCTAssertGreaterThan(displaySettings.desktopHeight, 0, "桌面高度应大于0")
            XCTAssertTrue([16, 24, 32].contains(displaySettings.sessionBpp), "颜色深度应为有效值")
            print("✅ 显示器检测和优化成功")
            
            // 步骤5: 创建优化的RDP文件
            print("Step 5: 创建优化的RDP文件...")
            let rdpFileURL = try remoteDesktopIntegrator.createOptimizedRDPFile(
                with: rdpInfo,
                displaySettings: displaySettings
            )
            
            XCTAssertTrue(FileManager.default.fileExists(atPath: rdpFileURL.path), "RDP文件应被创建")
            
            // 验证文件内容包含显示优化参数
            let fileContent = try String(contentsOf: rdpFileURL)
            XCTAssertTrue(fileContent.contains("desktopwidth:i:"), "应包含桌面宽度")
            XCTAssertTrue(fileContent.contains("desktopheight:i:"), "应包含桌面高度")
            XCTAssertTrue(fileContent.contains("desktopscalefactor:i:"), "应包含缩放因子")
            print("✅ 优化的RDP文件创建成功")
            
            // 清理测试文件
            remoteDesktopIntegrator.cleanupTemporaryFile(at: rdpFileURL)
            
            print("🎉 RDP完整工作流程测试成功（包含显示优化）")
            
        } catch {
            XCTFail("RDP完整工作流程测试失败: \(error)")
        }
    }
    
    // MARK: - SSH Complete Workflow Tests
    
    func testCompleteSSHWorkflow() {
        // Given - 创建一个完整的SSH URL
        let sshToken = """
        {
            "ip": "192.168.1.100",
            "port": "22",
            "username": "testuser",
            "password": "testpass"
        }
        """
        
        let jmsConfigDict: [String: Any] = [
            "protocol": "ssh",
            "token": sshToken
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jmsConfigDict)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            let base64Payload = Data(jsonString.utf8).base64EncodedString()
            let testURL = URL(string: "jms://\(base64Payload)")!
            
            // When - 执行完整的工作流程
            print("🔄 开始SSH完整工作流程测试")
            
            // 步骤1: URL解析
            print("Step 1: 解析JMS URL...")
            let urlComponents = try urlParser.parseJMSURL(testURL)
            XCTAssertEqual(urlComponents.scheme, "jms", "URL scheme应为jms")
            print("✅ URL解析成功")
            
            // 步骤2: Payload解码
            print("Step 2: 解码payload...")
            let jmsConfig = try payloadDecoder.decodePayload(urlComponents.payload)
            XCTAssertEqual(jmsConfig.protocol, "ssh", "协议类型应为ssh")
            print("✅ Payload解码成功")
            
            // 步骤3: 连接信息提取
            print("Step 3: 提取连接信息...")
            let connectionInfo = try connectionInfoExtractor.extractConnectionInfo(from: jmsConfig)
            
            guard case .ssh(let sshInfo) = connectionInfo else {
                XCTFail("应该提取到SSH连接信息")
                return
            }
            
            XCTAssertEqual(sshInfo.ip, "192.168.1.100", "IP地址应正确")
            XCTAssertEqual(sshInfo.port, "22", "端口应正确")
            XCTAssertEqual(sshInfo.username, "testuser", "用户名应正确")
            XCTAssertEqual(sshInfo.password, "testpass", "密码应正确")
            print("✅ 连接信息提取成功")
            
            // 步骤4: 终端检测
            print("Step 4: 检测可用终端...")
            let availableTerminal = sshTerminalIntegrator.detectAvailableTerminal()
            XCTAssertNotEqual(availableTerminal, .unavailable, "应该检测到可用的终端")
            print("✅ 终端检测成功: \(availableTerminal)")
            
            print("🎉 SSH完整工作流程测试成功")
            
        } catch {
            XCTFail("SSH完整工作流程测试失败: \(error)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testCompleteWorkflowErrorHandling() {
        // Given - 创建一个无效的URL
        let invalidURL = URL(string: "jms://invalid-base64")!
        
        // When & Then - 验证错误处理
        do {
            _ = try urlParser.parseJMSURL(invalidURL)
            XCTFail("应该抛出解码错误")
        } catch let error as JMSError {
            let errorMessage = errorHandler.handleError(error)
            XCTAssertFalse(errorMessage.isEmpty, "错误消息不应为空")
            print("✅ 错误处理测试成功: \(errorMessage)")
        } catch {
            XCTFail("应该抛出JMSError类型的错误")
        }
    }
    
    // MARK: - Display Optimization Impact Tests
    
    func testDisplayOptimizationDoesNotAffectSSH() {
        // Given - SSH连接信息
        let sshInfo = SSHConnectionInfo(
            ip: "192.168.1.100",
            port: "22",
            username: "testuser",
            password: "testpass",
            filename: "test_connection"
        )
        
        // When - 检测显示器（这不应该影响SSH处理）
        do {
            _ = try remoteDesktopIntegrator.detectAndOptimizeDisplay()
            
            // SSH处理应该不受影响
            let availableTerminal = sshTerminalIntegrator.detectAvailableTerminal()
            XCTAssertNotEqual(availableTerminal, .unavailable, "SSH终端检测不应受显示优化影响")
            
            print("✅ 显示优化不影响SSH协议处理")
            
        } catch {
            XCTFail("显示优化不应影响SSH处理: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testCompleteWorkflowPerformance() {
        // Given
        let rdpConfig = """
        full address:s:test.example.com:3389
        username:s:testuser
        """
        
        let jmsConfigDict: [String: Any] = [
            "protocol": "rdp",
            "config": rdpConfig
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jmsConfigDict)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            let base64Payload = Data(jsonString.utf8).base64EncodedString()
            let testURL = URL(string: "jms://\(base64Payload)")!
            
            // When - 测试完整工作流程的性能
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let urlComponents = try urlParser.parseJMSURL(testURL)
            let jmsConfig = try payloadDecoder.decodePayload(urlComponents.payload)
            let connectionInfo = try connectionInfoExtractor.extractConnectionInfo(from: jmsConfig)
            
            if case .rdp(let rdpInfo) = connectionInfo {
                let displaySettings = try remoteDesktopIntegrator.detectAndOptimizeDisplay()
                let rdpFileURL = try remoteDesktopIntegrator.createOptimizedRDPFile(
                    with: rdpInfo,
                    displaySettings: displaySettings
                )
                
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                
                // Then - 完整工作流程应在1秒内完成
                XCTAssertLessThan(timeElapsed, 1.0, "完整工作流程应在1秒内完成")
                
                // 清理
                remoteDesktopIntegrator.cleanupTemporaryFile(at: rdpFileURL)
                
                print("✅ 完整工作流程性能测试通过: \(String(format: "%.3f", timeElapsed * 1000))ms")
            }
            
        } catch {
            XCTFail("性能测试失败: \(error)")
        }
    }
    
    // MARK: - Integration Validation Tests
    
    func testAllModulesIntegration() {
        // 验证所有模块都能正常工作
        XCTAssertNotNil(urlParser, "URLParser应该初始化成功")
        XCTAssertNotNil(payloadDecoder, "PayloadDecoder应该初始化成功")
        XCTAssertNotNil(connectionInfoExtractor, "ConnectionInfoExtractor应该初始化成功")
        XCTAssertNotNil(remoteDesktopIntegrator, "RemoteDesktopIntegrator应该初始化成功")
        XCTAssertNotNil(sshTerminalIntegrator, "SSHTerminalIntegrator应该初始化成功")
        XCTAssertNotNil(errorHandler, "ErrorHandler应该初始化成功")
        XCTAssertNotNil(notificationManager, "NotificationManager应该初始化成功")
        
        print("✅ 所有模块集成验证通过")
    }
}
