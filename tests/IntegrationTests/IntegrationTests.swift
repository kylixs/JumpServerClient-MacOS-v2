import XCTest
@testable import JMSCore
@testable import JMSRDPModule
@testable import JMSSSHModule

final class IntegrationTests: XCTestCase {
    
    // 服务组件
    var urlParser: URLParser!
    var payloadDecoder: PayloadDecoder!
    var connectionInfoExtractor: ConnectionInfoExtractor!
    var rdpIntegrator: RemoteDesktopIntegrator!
    var sshIntegrator: SSHTerminalIntegrator!
    
    override func setUp() {
        super.setUp()
        urlParser = URLParser()
        payloadDecoder = PayloadDecoder()
        connectionInfoExtractor = ConnectionInfoExtractor()
        rdpIntegrator = RemoteDesktopIntegrator()
        sshIntegrator = SSHTerminalIntegrator()
    }
    
    override func tearDown() {
        RDPConfigManager.shared.resetToDefaults()
        super.tearDown()
    }
    
    // MARK: - 完整RDP流程测试
    
    func testCompleteRDPFlow() throws {
        // 1. 创建RDP配置JSON
        let rdpConfigJSON = [
            "protocol": "rdp",
            "config": """
                full address:s:test.rdp.server.com:3389
                username:s:rdpuser
                session bpp:i:32
                audiomode:i:0
                redirectclipboard:i:1
                """
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: rdpConfigJSON)
        let base64Payload = jsonData.base64EncodedString()
        let jmsURL = "jms://\(base64Payload)"
        
        // 2. 完整处理流程
        let urlComponents = try urlParser.parseURL(jmsURL)
        XCTAssertEqual(urlComponents.scheme, "jms")
        XCTAssertTrue(urlComponents.isValid)
        
        let config = try payloadDecoder.decodePayload(urlComponents.encodedPayload)
        XCTAssertEqual(config.protocolType, "rdp")
        XCTAssertTrue(config.isValid)
        
        let connectionInfo = try connectionInfoExtractor.extractConnectionInfo(from: config)
        
        // 3. 验证RDP连接信息
        if case .rdp(let rdpInfo) = connectionInfo {
            XCTAssertEqual(rdpInfo.fullAddress, "test.rdp.server.com:3389")
            XCTAssertEqual(rdpInfo.username, "rdpuser")
            XCTAssertEqual(rdpInfo.serverAddress, "test.rdp.server.com")
            XCTAssertEqual(rdpInfo.port, 3389)
            
            // 4. 测试RDP配置管理
            let configManager = RDPConfigManager.shared
            
            // 测试不同质量配置
            for profile in [QualityProfile.performance, .balanced, .quality] {
                configManager.setQualityProfile(profile)
                XCTAssertEqual(configManager.qualityProfile.identifier, profile.identifier)
                
                let settings = configManager.settings
                XCTAssertNotNil(settings)
                
                // 验证质量配置的差异
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
            
            // 5. 测试RDP集成器配置
            XCTAssertEqual(rdpIntegrator.availableQualityProfiles.count, 3)
            
            rdpIntegrator.setQualityProfile(.performance)
            XCTAssertEqual(rdpIntegrator.currentQualityProfile.identifier, "performance")
            
        } else {
            XCTFail("应该返回RDP连接信息")
        }
    }
    
    // MARK: - 完整SSH流程测试
    
    func testCompleteSSHFlow() throws {
        // 1. 创建SSH配置JSON
        let sshToken = [
            "ip": "test.ssh.server.com",
            "port": 2222,
            "username": "sshuser",
            "password": "sshpass123"
        ] as [String : Any]
        
        let tokenData = try JSONSerialization.data(withJSONObject: sshToken)
        let tokenString = String(data: tokenData, encoding: .utf8)!
        
        let sshConfigJSON = [
            "protocol": "ssh",
            "token": tokenString
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: sshConfigJSON)
        let base64Payload = jsonData.base64EncodedString()
        let jmsURL = "jms://\(base64Payload)"
        
        // 2. 完整处理流程
        let urlComponents = try urlParser.parseURL(jmsURL)
        XCTAssertEqual(urlComponents.scheme, "jms")
        XCTAssertTrue(urlComponents.isValid)
        
        let config = try payloadDecoder.decodePayload(urlComponents.encodedPayload)
        XCTAssertEqual(config.protocolType, "ssh")
        XCTAssertTrue(config.isValid)
        
        let connectionInfo = try connectionInfoExtractor.extractConnectionInfo(from: config)
        
        // 3. 验证SSH连接信息
        if case .ssh(let sshInfo) = connectionInfo {
            XCTAssertEqual(sshInfo.ip, "test.ssh.server.com")
            XCTAssertEqual(sshInfo.port, 2222)
            XCTAssertEqual(sshInfo.username, "sshuser")
            XCTAssertEqual(sshInfo.password, "sshpass123")
            
            // 4. 测试SSH命令构建
            let basicCommand = sshIntegrator.buildSSHCommand(sshInfo)
            XCTAssertTrue(basicCommand.contains("ssh"))
            XCTAssertTrue(basicCommand.contains("-p 2222"))
            XCTAssertTrue(basicCommand.contains("sshuser@test.ssh.server.com"))
            XCTAssertTrue(basicCommand.contains("-o StrictHostKeyChecking=no"))
            
            // 5. 测试带密码的SSH命令
            let passwordCommand = try sshIntegrator.buildSSHCommandWithPassword(sshInfo)
            XCTAssertNotNil(passwordCommand)
            XCTAssertFalse(passwordCommand.isEmpty)
            
        } else {
            XCTFail("应该返回SSH连接信息")
        }
    }
    
    // MARK: - 错误处理集成测试
    
    func testErrorHandlingIntegration() {
        let errorHandler = ErrorHandler.shared
        
        // 测试各种错误类型的处理
        let testErrors: [JMSError] = [
            .invalidURL("test://invalid"),
            .decodingFailed("invalid base64"),
            .jsonParsingFailed("malformed json"),
            .missingConnectionInfo("missing field"),
            .unsupportedProtocol("ftp"),
            .remoteDesktopNotFound,
            .terminalNotFound,
            .displayDetectionFailed("no display"),
            .configurationError("config error"),
            .fileOperationFailed("file error"),
            .networkError("network error")
        ]
        
        for error in testErrors {
            // 测试错误处理不会崩溃
            XCTAssertNoThrow(errorHandler.handleJMSError(error, showAlert: false))
            
            // 验证错误描述
            XCTAssertNotNil(error.errorDescription)
            XCTAssertNotNil(error.recoverySuggestion)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - 通知系统集成测试
    
    func testNotificationSystemIntegration() {
        let notificationManager = NotificationManager.shared
        
        // 测试各种通知类型
        XCTAssertNoThrow(notificationManager.showSuccessNotification(title: "测试成功", message: "测试消息"))
        XCTAssertNoThrow(notificationManager.showInfoNotification(title: "测试信息", message: "测试消息"))
        
        // 测试错误通知
        let testError = JMSError.configurationError("测试错误")
        XCTAssertNoThrow(notificationManager.showErrorNotification(testError))
        
        // 测试连接成功通知
        let rdpInfo = RDPConnectionInfo(fullAddress: "test:3389", username: "user", config: "")
        let sshInfo = SSHConnectionInfo(ip: "192.168.1.1", username: "user")
        
        XCTAssertNoThrow(notificationManager.showRDPConnectionSuccess(rdpInfo))
        XCTAssertNoThrow(notificationManager.showSSHConnectionSuccess(sshInfo))
        
        // 测试显示器优化通知
        let displayConfig = DisplayConfiguration(width: 1920, height: 1080)
        XCTAssertNoThrow(notificationManager.showDisplayOptimizationNotification(displayConfig))
    }
    
    // MARK: - 配置持久化集成测试
    
    func testConfigurationPersistenceIntegration() {
        let configManager = RDPConfigManager.shared
        
        // 1. 设置自定义配置
        let customSettings = RDPSettings(
            resolution: .custom(2560, 1440),
            colorDepth: .depth32,
            compressionLevel: .low,
            enableFontSmoothing: true,
            scalingFactor: 2.0
        )
        
        configManager.updateSettings(customSettings)
        XCTAssertEqual(configManager.qualityProfile.identifier, "custom")
        
        // 2. 验证设置已保存
        let currentSettings = configManager.settings
        XCTAssertEqual(currentSettings.resolution.width, 2560)
        XCTAssertEqual(currentSettings.resolution.height, 1440)
        XCTAssertEqual(currentSettings.colorDepth, .depth32)
        XCTAssertEqual(currentSettings.compressionLevel, .low)
        XCTAssertTrue(currentSettings.enableFontSmoothing)
        XCTAssertEqual(currentSettings.scalingFactor, 2.0)
        
        // 3. 测试质量配置切换（不触发通知）
        let originalProfile = configManager.qualityProfile
        configManager.updateSettings(QualityProfile.performance.settings)
        XCTAssertEqual(configManager.settings.colorDepth, .depth16)
        
        // 4. 重置为默认值
        configManager.resetToDefaults()
        XCTAssertEqual(configManager.qualityProfile.identifier, "balanced")
    }
    
    // MARK: - 多协议支持集成测试
    
    func testMultiProtocolSupportIntegration() throws {
        // 测试同时处理多种协议类型
        let protocols = ["rdp", "ssh"]
        
        for protocolType in protocols {
            var configJSON: [String: Any]
            
            if protocolType == "rdp" {
                configJSON = [
                    "protocol": "rdp",
                    "config": "full address:s:server.com:3389\nusername:s:user"
                ]
            } else {
                let sshToken = ["ip": "192.168.1.1", "port": 22, "username": "user"] as [String : Any]
                let tokenData = try JSONSerialization.data(withJSONObject: sshToken)
                let tokenString = String(data: tokenData, encoding: .utf8)!
                
                configJSON = [
                    "protocol": "ssh",
                    "token": tokenString
                ]
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: configJSON)
            let base64Payload = jsonData.base64EncodedString()
            let jmsURL = "jms://\(base64Payload)"
            
            // 处理流程
            let urlComponents = try urlParser.parseURL(jmsURL)
            let config = try payloadDecoder.decodePayload(urlComponents.encodedPayload)
            let connectionInfo = try connectionInfoExtractor.extractConnectionInfo(from: config)
            
            // 验证协议类型
            XCTAssertEqual(connectionInfo.protocolType, protocolType)
            
            switch connectionInfo {
            case .rdp(let rdpInfo):
                XCTAssertEqual(rdpInfo.serverAddress, "server.com")
                XCTAssertEqual(rdpInfo.username, "user")
            case .ssh(let sshInfo):
                XCTAssertEqual(sshInfo.ip, "192.168.1.1")
                XCTAssertEqual(sshInfo.username, "user")
            }
        }
    }
    
    // MARK: - 性能集成测试
    
    func testPerformanceIntegration() throws {
        // 创建测试数据
        let rdpConfigJSON = [
            "protocol": "rdp",
            "config": "full address:s:perf.test.com:3389\nusername:s:perfuser"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: rdpConfigJSON)
        let base64Payload = jsonData.base64EncodedString()
        let jmsURL = "jms://\(base64Payload)"
        
        // 性能测试：完整处理流程
        measure {
            do {
                let urlComponents = try urlParser.parseURL(jmsURL)
                let config = try payloadDecoder.decodePayload(urlComponents.encodedPayload)
                let _ = try connectionInfoExtractor.extractConnectionInfo(from: config)
            } catch {
                XCTFail("处理过程中出现错误: \(error)")
            }
        }
    }
    
    // MARK: - 边界条件集成测试
    
    func testBoundaryConditionsIntegration() throws {
        // 测试各种边界条件
        let testCases = [
            // 最小有效RDP配置
            ["protocol": "rdp", "config": "full address:s:a:1\nusername:s:u"],
            // 最小有效SSH配置
            ["protocol": "ssh", "token": "{\"ip\":\"1\",\"username\":\"u\"}"],
            // 包含特殊字符的配置
            ["protocol": "rdp", "config": "full address:s:测试服务器.com:3389\nusername:s:用户名"],
        ]
        
        for configJSON in testCases {
            let jsonData = try JSONSerialization.data(withJSONObject: configJSON)
            let base64Payload = jsonData.base64EncodedString()
            let jmsURL = "jms://\(base64Payload)"
            
            // 应该能够成功处理
            XCTAssertNoThrow(try urlParser.parseURL(jmsURL))
            
            let urlComponents = try urlParser.parseURL(jmsURL)
            XCTAssertNoThrow(try payloadDecoder.decodePayload(urlComponents.encodedPayload))
            
            let config = try payloadDecoder.decodePayload(urlComponents.encodedPayload)
            XCTAssertNoThrow(try connectionInfoExtractor.extractConnectionInfo(from: config))
        }
    }
    
    // MARK: - 并发安全集成测试
    
    func testConcurrencySafetyIntegration() throws {
        let rdpConfigJSON = [
            "protocol": "rdp",
            "config": "full address:s:concurrent.test.com:3389\nusername:s:concurrentuser"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: rdpConfigJSON)
        let base64Payload = jsonData.base64EncodedString()
        let jmsURL = "jms://\(base64Payload)"
        
        let expectation = XCTestExpectation(description: "并发处理完成")
        expectation.expectedFulfillmentCount = 10
        
        // 并发执行多个处理任务
        for i in 0..<10 {
            DispatchQueue.global(qos: .background).async {
                do {
                    let parser = URLParser()
                    let decoder = PayloadDecoder()
                    let extractor = ConnectionInfoExtractor()
                    
                    let urlComponents = try parser.parseURL(jmsURL)
                    let config = try decoder.decodePayload(urlComponents.encodedPayload)
                    let connectionInfo = try extractor.extractConnectionInfo(from: config)
                    
                    // 验证结果一致性
                    XCTAssertEqual(connectionInfo.protocolType, "rdp")
                    
                    expectation.fulfill()
                } catch {
                    XCTFail("并发处理失败 [\(i)]: \(error)")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}
