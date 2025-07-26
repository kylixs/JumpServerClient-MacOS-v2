import XCTest
@testable import JMSProtocolHandler

class PayloadDecoderTests: XCTestCase {
    
    var payloadDecoder: PayloadDecoder!
    
    override func setUp() {
        super.setUp()
        payloadDecoder = PayloadDecoder()
    }
    
    override func tearDown() {
        payloadDecoder = nil
        super.tearDown()
    }
    
    // MARK: - Base64解码测试
    
    func testDecodeBase64Payload_ValidBase64_ShouldReturnData() throws {
        // Given
        let originalString = "Hello, World!"
        let base64String = Data(originalString.utf8).base64EncodedString()
        
        // When
        let decodedData = try payloadDecoder.decodeBase64Payload(base64String)
        
        // Then
        let decodedString = String(data: decodedData, encoding: .utf8)
        XCTAssertEqual(decodedString, originalString)
    }
    
    func testDecodeBase64Payload_ValidJSONBase64_ShouldReturnData() throws {
        // Given
        let jsonString = """
        {
            "filename": "test.rdp",
            "protocol": "rdp",
            "username": "testuser",
            "token": "testtoken",
            "config": "full address:s:test.com:3389\\nusername:s:testuser"
        }
        """
        let base64String = Data(jsonString.utf8).base64EncodedString()
        
        // When
        let decodedData = try payloadDecoder.decodeBase64Payload(base64String)
        
        // Then
        let decodedString = String(data: decodedData, encoding: .utf8)
        XCTAssertEqual(decodedString, jsonString)
    }
    
    func testDecodeBase64Payload_WithWhitespace_ShouldReturnData() throws {
        // Given
        let originalString = "Test with whitespace"
        let base64String = "  " + Data(originalString.utf8).base64EncodedString() + "  \n"
        
        // When
        let decodedData = try payloadDecoder.decodeBase64Payload(base64String)
        
        // Then
        let decodedString = String(data: decodedData, encoding: .utf8)
        XCTAssertEqual(decodedString, originalString)
    }
    
    func testDecodeBase64Payload_InvalidBase64_ShouldThrowDecodingFailed() {
        // Given
        let invalidBase64 = "This is not base64!"
        
        // When & Then
        XCTAssertThrowsError(try payloadDecoder.decodeBase64Payload(invalidBase64)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.decodingFailed)
        }
    }
    
    func testDecodeBase64Payload_EmptyString_ShouldThrowDecodingFailed() {
        // Given
        let emptyString = ""
        
        // When & Then
        XCTAssertThrowsError(try payloadDecoder.decodeBase64Payload(emptyString)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.decodingFailed)
        }
    }
    
    // MARK: - JSON解析测试
    
    func testParseJSONConfig_ValidJSON_ShouldReturnJMSConfig() throws {
        // Given
        let jsonString = """
        {
            "filename": "test.rdp",
            "protocol": "rdp",
            "username": "testuser",
            "token": "testtoken",
            "config": "full address:s:test.com:3389\\nusername:s:testuser"
        }
        """
        let jsonData = Data(jsonString.utf8)
        
        // When
        let config = try payloadDecoder.parseJSONConfig(jsonData)
        
        // Then
        XCTAssertEqual(config.filename, "test.rdp")
        XCTAssertEqual(config.protocol, "rdp")
        XCTAssertEqual(config.username, "testuser")
        XCTAssertEqual(config.token, "testtoken")
        XCTAssertEqual(config.config, "full address:s:test.com:3389\\nusername:s:testuser")
    }
    
    func testParseJSONConfig_ComplexConfig_ShouldReturnJMSConfig() throws {
        // Given
        let jsonString = """
        {
            "filename": "complex.rdp",
            "protocol": "RDP",
            "username": "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53",
            "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
            "config": "full address:s:develop-jumpserver.jlcops.com:3389\\nusername:s:gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53\\nsession bpp:i:32\\naudiomode:i:0\\nsmartSizing:i:1\\nscreen mode id:i:2"
        }
        """
        let jsonData = Data(jsonString.utf8)
        
        // When
        let config = try payloadDecoder.parseJSONConfig(jsonData)
        
        // Then
        XCTAssertEqual(config.filename, "complex.rdp")
        XCTAssertEqual(config.protocol, "RDP")
        XCTAssertEqual(config.username, "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53")
        XCTAssertEqual(config.token, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
        XCTAssertTrue(config.config.contains("develop-jumpserver.jlcops.com:3389"))
    }
    
    func testParseJSONConfig_InvalidJSON_ShouldThrowJSONParsingFailed() {
        // Given
        let invalidJSON = "{ invalid json }"
        let jsonData = Data(invalidJSON.utf8)
        
        // When & Then
        XCTAssertThrowsError(try payloadDecoder.parseJSONConfig(jsonData)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.jsonParsingFailed)
        }
    }
    
    func testParseJSONConfig_MissingRequiredField_ShouldThrowMissingRequiredField() {
        // Given
        let jsonString = """
        {
            "filename": "test.rdp",
            "protocol": "rdp",
            "username": "",
            "token": "testtoken",
            "config": "full address:s:test.com:3389"
        }
        """
        let jsonData = Data(jsonString.utf8)
        
        // When & Then
        XCTAssertThrowsError(try payloadDecoder.parseJSONConfig(jsonData)) { error in
            if case JMSError.missingRequiredField(let field) = error {
                XCTAssertEqual(field, "username")
            } else {
                XCTFail("Expected missingRequiredField error")
            }
        }
    }
    
    func testParseJSONConfig_EmptyData_ShouldThrowJSONParsingFailed() {
        // Given
        let emptyData = Data()
        
        // When & Then
        XCTAssertThrowsError(try payloadDecoder.parseJSONConfig(emptyData)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.jsonParsingFailed)
        }
    }
    
    // MARK: - 完整流程测试
    
    func testDecodeAndParsePayload_ValidPayload_ShouldReturnJMSConfig() throws {
        // Given
        let jsonString = """
        {
            "filename": "integration.rdp",
            "protocol": "rdp",
            "username": "integrationuser",
            "token": "integrationtoken",
            "config": "full address:s:integration.com:3389\\nusername:s:integrationuser"
        }
        """
        let base64Payload = Data(jsonString.utf8).base64EncodedString()
        
        // When
        let config = try payloadDecoder.decodeAndParsePayload(base64Payload)
        
        // Then
        XCTAssertEqual(config.filename, "integration.rdp")
        XCTAssertEqual(config.protocol, "rdp")
        XCTAssertEqual(config.username, "integrationuser")
        XCTAssertEqual(config.token, "integrationtoken")
        XCTAssertEqual(config.config, "full address:s:integration.com:3389\\nusername:s:integrationuser")
    }
    
    func testDecodeAndParsePayload_RealWorldExample_ShouldReturnJMSConfig() throws {
        // Given - 基于设计文档中的真实示例
        let jsonString = """
        {
            "filename": "jumpserver.rdp",
            "protocol": "rdp",
            "username": "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53",
            "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
            "config": "full address:s:develop-jumpserver.jlcops.com:3389\\nusername:s:gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53\\nsession bpp:i:32\\naudiomode:i:0\\nsmartSizing:i:1\\nscreen mode id:i:2"
        }
        """
        let base64Payload = Data(jsonString.utf8).base64EncodedString()
        
        // When
        let config = try payloadDecoder.decodeAndParsePayload(base64Payload)
        
        // Then
        XCTAssertEqual(config.filename, "jumpserver.rdp")
        XCTAssertEqual(config.protocol, "rdp")
        XCTAssertEqual(config.username, "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53")
        XCTAssertTrue(config.token.starts(with: "eyJhbGciOiJIUzI1NiI"))
        XCTAssertTrue(config.config.contains("develop-jumpserver.jlcops.com:3389"))
        XCTAssertTrue(config.config.contains("session bpp:i:32"))
        XCTAssertTrue(config.config.contains("audiomode:i:0"))
    }
    
    func testDecodeAndParsePayload_InvalidBase64_ShouldThrowDecodingFailed() {
        // Given
        let invalidBase64 = "Invalid base64 content!"
        
        // When & Then
        XCTAssertThrowsError(try payloadDecoder.decodeAndParsePayload(invalidBase64)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.decodingFailed)
        }
    }
    
    func testDecodeAndParsePayload_ValidBase64InvalidJSON_ShouldThrowJSONParsingFailed() {
        // Given
        let invalidJSON = "{ this is not valid json }"
        let base64Payload = Data(invalidJSON.utf8).base64EncodedString()
        
        // When & Then
        XCTAssertThrowsError(try payloadDecoder.decodeAndParsePayload(base64Payload)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.jsonParsingFailed)
        }
    }
    
    // MARK: - 边界情况测试
    
    func testDecodeAndParsePayload_LargePayload_ShouldWork() throws {
        // Given - 创建一个较大的配置
        let largeConfig = String(repeating: "test parameter:s:value\\n", count: 100)
        let jsonString = """
        {
            "filename": "large.rdp",
            "protocol": "rdp",
            "username": "largeuser",
            "token": "largetoken",
            "config": "\(largeConfig)"
        }
        """
        let base64Payload = Data(jsonString.utf8).base64EncodedString()
        
        // When
        let config = try payloadDecoder.decodeAndParsePayload(base64Payload)
        
        // Then
        XCTAssertEqual(config.filename, "large.rdp")
        XCTAssertEqual(config.protocol, "rdp")
        XCTAssertEqual(config.username, "largeuser")
        XCTAssertEqual(config.token, "largetoken")
        XCTAssertTrue(config.config.contains("test parameter:s:value"))
    }
    
    func testDecodeAndParsePayload_SpecialCharacters_ShouldWork() throws {
        // Given - 包含特殊字符的配置
        let jsonString = """
        {
            "filename": "special-chars.rdp",
            "protocol": "rdp",
            "username": "user@domain.com",
            "token": "token-with-special-chars_123!@#",
            "config": "full address:s:server.domain.com:3389\\nusername:s:user@domain.com\\npassword:s:P@ssw0rd!"
        }
        """
        let base64Payload = Data(jsonString.utf8).base64EncodedString()
        
        // When
        let config = try payloadDecoder.decodeAndParsePayload(base64Payload)
        
        // Then
        XCTAssertEqual(config.filename, "special-chars.rdp")
        XCTAssertEqual(config.protocol, "rdp")
        XCTAssertEqual(config.username, "user@domain.com")
        XCTAssertEqual(config.token, "token-with-special-chars_123!@#")
        XCTAssertTrue(config.config.contains("user@domain.com"))
        XCTAssertTrue(config.config.contains("P@ssw0rd!"))
    }
}