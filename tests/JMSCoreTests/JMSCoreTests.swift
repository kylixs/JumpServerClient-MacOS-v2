import XCTest
@testable import JMSCore

final class JMSCoreTests: XCTestCase {
    
    // MARK: - URLParser Tests
    
    func testURLParserValidJMSURL() throws {
        let parser = URLParser()
        let validURL = "jms://eyJwcm90b2NvbCI6InJkcCIsImNvbmZpZyI6InRlc3QifQ=="
        
        let components = try parser.parseURL(validURL)
        
        XCTAssertEqual(components.scheme, "jms")
        XCTAssertFalse(components.encodedPayload.isEmpty)
        XCTAssertTrue(components.isValid)
    }
    
    func testURLParserInvalidScheme() {
        let parser = URLParser()
        let invalidURL = "http://example.com"
        
        XCTAssertThrowsError(try parser.parseURL(invalidURL)) { error in
            XCTAssertTrue(error is JMSError)
            if case .invalidURL(let message) = error as? JMSError {
                XCTAssertTrue(message.contains("不支持的协议"))
            }
        }
    }
    
    func testURLParserEmptyPayload() {
        let parser = URLParser()
        let emptyURL = "jms://"
        
        XCTAssertThrowsError(try parser.parseURL(emptyURL)) { error in
            XCTAssertTrue(error is JMSError)
            if case .invalidURL(let message) = error as? JMSError {
                XCTAssertTrue(message.contains("缺少编码的payload"))
            }
        }
    }
    
    func testURLParserIsValidJMSURL() {
        let parser = URLParser()
        
        XCTAssertTrue(parser.isValidJMSURL("jms://validpayload"))
        XCTAssertFalse(parser.isValidJMSURL("http://example.com"))
        XCTAssertFalse(parser.isValidJMSURL("invalid-url"))
    }
    
    // MARK: - PayloadDecoder Tests
    
    func testPayloadDecoderValidBase64() throws {
        let decoder = PayloadDecoder()
        let validBase64 = "eyJwcm90b2NvbCI6InJkcCIsImNvbmZpZyI6InRlc3QifQ==" // {"protocol":"rdp","config":"test"}
        
        let config = try decoder.decodePayload(validBase64)
        
        XCTAssertEqual(config.protocolType, "rdp")
        XCTAssertEqual(config.config, "test")
    }
    
    func testPayloadDecoderInvalidBase64() {
        let decoder = PayloadDecoder()
        let invalidBase64 = "invalid-base64!!!"
        
        XCTAssertThrowsError(try decoder.decodePayload(invalidBase64)) { error in
            XCTAssertTrue(error is JMSError)
            if case .decodingFailed = error as? JMSError {
                // 预期的错误类型
            } else {
                XCTFail("应该抛出 decodingFailed 错误")
            }
        }
    }
    
    func testPayloadDecoderInvalidJSON() {
        let decoder = PayloadDecoder()
        let invalidJSON = "aW52YWxpZC1qc29u" // "invalid-json" in base64
        
        XCTAssertThrowsError(try decoder.decodePayload(invalidJSON)) { error in
            XCTAssertTrue(error is JMSError)
            if case .jsonParsingFailed = error as? JMSError {
                // 预期的错误类型
            } else {
                XCTFail("应该抛出 jsonParsingFailed 错误")
            }
        }
    }
    
    func testPayloadDecoderMissingProtocol() {
        let decoder = PayloadDecoder()
        let missingProtocol = "eyJjb25maWciOiJ0ZXN0In0=" // {"config":"test"}
        
        XCTAssertThrowsError(try decoder.decodePayload(missingProtocol)) { error in
            XCTAssertTrue(error is JMSError)
            if case .jsonParsingFailed = error as? JMSError {
                // 预期的错误类型
            } else {
                XCTFail("应该抛出 jsonParsingFailed 错误")
            }
        }
    }
    
    // MARK: - ConnectionInfoExtractor Tests
    
    func testConnectionInfoExtractorRDP() throws {
        let extractor = ConnectionInfoExtractor()
        let rdpConfig = JMSConfig(
            protocolType: "rdp",
            config: "full address:s:server.example.com:3389\nusername:s:testuser\nsession bpp:i:32",
            token: nil
        )
        
        let connectionInfo = try extractor.extractConnectionInfo(from: rdpConfig)
        
        if case .rdp(let rdpInfo) = connectionInfo {
            XCTAssertEqual(rdpInfo.fullAddress, "server.example.com:3389")
            XCTAssertEqual(rdpInfo.username, "testuser")
            XCTAssertEqual(rdpInfo.serverAddress, "server.example.com")
            XCTAssertEqual(rdpInfo.port, 3389)
        } else {
            XCTFail("应该返回RDP连接信息")
        }
    }
    
    func testConnectionInfoExtractorSSH() throws {
        let extractor = ConnectionInfoExtractor()
        let sshToken = """
        {"ip":"192.168.1.100","port":22,"username":"testuser","password":"testpass"}
        """
        let sshConfig = JMSConfig(
            protocolType: "ssh",
            config: nil,
            token: sshToken
        )
        
        let connectionInfo = try extractor.extractConnectionInfo(from: sshConfig)
        
        if case .ssh(let sshInfo) = connectionInfo {
            XCTAssertEqual(sshInfo.ip, "192.168.1.100")
            XCTAssertEqual(sshInfo.port, 22)
            XCTAssertEqual(sshInfo.username, "testuser")
            XCTAssertEqual(sshInfo.password, "testpass")
            XCTAssertEqual(sshInfo.connectionString, "testuser@192.168.1.100")
        } else {
            XCTFail("应该返回SSH连接信息")
        }
    }
    
    func testConnectionInfoExtractorUnsupportedProtocol() {
        let extractor = ConnectionInfoExtractor()
        let unsupportedConfig = JMSConfig(protocolType: "ftp", config: nil, token: nil)
        
        XCTAssertThrowsError(try extractor.extractConnectionInfo(from: unsupportedConfig)) { error in
            XCTAssertTrue(error is JMSError)
            if case .unsupportedProtocol(let protocolName) = error as? JMSError {
                XCTAssertEqual(protocolName, "ftp")
            } else {
                XCTFail("应该抛出 unsupportedProtocol 错误")
            }
        }
    }
    
    // MARK: - Data Model Tests
    
    func testJMSErrorLocalization() {
        let error = JMSError.invalidURL("test.com")
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.errorDescription!.contains("test.com"))
    }
    
    func testConnectionInfoProtocolType() {
        let rdpInfo = RDPConnectionInfo(fullAddress: "server:3389", username: "user", config: "")
        let sshInfo = SSHConnectionInfo(ip: "192.168.1.1", username: "user")
        
        let rdpConnection = ConnectionInfo.rdp(rdpInfo)
        let sshConnection = ConnectionInfo.ssh(sshInfo)
        
        XCTAssertEqual(rdpConnection.protocolType, "rdp")
        XCTAssertEqual(sshConnection.protocolType, "ssh")
    }
    
    func testDisplayConfigurationProperties() {
        let config = DisplayConfiguration(
            width: 2560,
            height: 1440,
            scaleFactor: 2.0,
            colorDepth: 32,
            isHiDPI: true,
            refreshRate: 60.0
        )
        
        XCTAssertEqual(config.resolutionString, "2560x1440")
        XCTAssertEqual(config.densityType, .retina)
        XCTAssertEqual(config.recommendedColorDepth, 32)
        XCTAssertFalse(config.is4K)
        XCTAssertFalse(config.isUltraWide)
    }
    
    func testDisplayConfiguration4K() {
        let config4K = DisplayConfiguration(
            width: 3840,
            height: 2160,
            scaleFactor: 1.0,
            colorDepth: 32,
            isHiDPI: false
        )
        
        XCTAssertTrue(config4K.is4K)
        XCTAssertFalse(config4K.isUltraWide)
    }
    
    func testDisplayConfigurationUltraWide() {
        let configUltraWide = DisplayConfiguration(
            width: 3440,
            height: 1440,
            scaleFactor: 1.0,
            colorDepth: 32,
            isHiDPI: false
        )
        
        XCTAssertFalse(configUltraWide.is4K)
        XCTAssertTrue(configUltraWide.isUltraWide)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteURLProcessingFlow() throws {
        // 创建一个完整的RDP配置JSON
        let rdpConfigJSON = [
            "protocol": "rdp",
            "config": "full address:s:test.server.com:3389\nusername:s:testuser\nsession bpp:i:32"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: rdpConfigJSON)
        let base64Payload = jsonData.base64EncodedString()
        let jmsURL = "jms://\(base64Payload)"
        
        // 完整流程测试
        let parser = URLParser()
        let decoder = PayloadDecoder()
        let extractor = ConnectionInfoExtractor()
        
        let urlComponents = try parser.parseURL(jmsURL)
        let config = try decoder.decodePayload(urlComponents.encodedPayload)
        let connectionInfo = try extractor.extractConnectionInfo(from: config)
        
        // 验证结果
        XCTAssertEqual(config.protocolType, "rdp")
        if case .rdp(let rdpInfo) = connectionInfo {
            XCTAssertEqual(rdpInfo.serverAddress, "test.server.com")
            XCTAssertEqual(rdpInfo.username, "testuser")
            XCTAssertEqual(rdpInfo.port, 3389)
        } else {
            XCTFail("应该返回RDP连接信息")
        }
    }
    
    func testCompleteSSHProcessingFlow() throws {
        // 创建一个完整的SSH配置JSON
        let sshToken = [
            "ip": "192.168.1.100",
            "port": 2222,
            "username": "sshuser",
            "password": "sshpass"
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
        
        // 完整流程测试
        let parser = URLParser()
        let decoder = PayloadDecoder()
        let extractor = ConnectionInfoExtractor()
        
        let urlComponents = try parser.parseURL(jmsURL)
        let config = try decoder.decodePayload(urlComponents.encodedPayload)
        let connectionInfo = try extractor.extractConnectionInfo(from: config)
        
        // 验证结果
        XCTAssertEqual(config.protocolType, "ssh")
        if case .ssh(let sshInfo) = connectionInfo {
            XCTAssertEqual(sshInfo.ip, "192.168.1.100")
            XCTAssertEqual(sshInfo.port, 2222)
            XCTAssertEqual(sshInfo.username, "sshuser")
            XCTAssertEqual(sshInfo.password, "sshpass")
        } else {
            XCTFail("应该返回SSH连接信息")
        }
    }
}
