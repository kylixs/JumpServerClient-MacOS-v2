import XCTest
@testable import JMSProtocolHandler

class JMSConfigTests: XCTestCase {
    
    func testJMSConfigInitialization() {
        // Given
        let filename = "test.rdp"
        let protocol = "rdp"
        let username = "testuser"
        let token = "testtoken"
        let config = "full address:s:test.com:3389\nusername:s:testuser"
        
        // When
        let jmsConfig = JMSConfig(
            filename: filename,
            protocol: protocol,
            username: username,
            token: token,
            config: config
        )
        
        // Then
        XCTAssertEqual(jmsConfig.filename, filename)
        XCTAssertEqual(jmsConfig.`protocol`, protocol)
        XCTAssertEqual(jmsConfig.username, username)
        XCTAssertEqual(jmsConfig.token, token)
        XCTAssertEqual(jmsConfig.config, config)
    }
    
    func testJMSConfigValidation_Success() {
        // Given
        let validConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: "full address:s:test.com:3389"
        )
        
        // When & Then
        XCTAssertNoThrow(try validConfig.validate())
    }
    
    func testJMSConfigValidation_MissingFilename() {
        // Given
        let invalidConfig = JMSConfig(
            filename: "",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: "full address:s:test.com:3389"
        )
        
        // When & Then
        XCTAssertThrowsError(try invalidConfig.validate()) { error in
            if case JMSError.missingRequiredField(let field) = error {
                XCTAssertEqual(field, "filename")
            } else {
                XCTFail("Expected missingRequiredField error")
            }
        }
    }
    
    func testJMSConfigValidation_MissingProtocol() {
        // Given
        let invalidConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "",
            username: "testuser",
            token: "testtoken",
            config: "full address:s:test.com:3389"
        )
        
        // When & Then
        XCTAssertThrowsError(try invalidConfig.validate()) { error in
            if case JMSError.missingRequiredField(let field) = error {
                XCTAssertEqual(field, "protocol")
            } else {
                XCTFail("Expected missingRequiredField error")
            }
        }
    }
    
    func testJMSConfigValidation_MissingUsername() {
        // Given
        let invalidConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "",
            token: "testtoken",
            config: "full address:s:test.com:3389"
        )
        
        // When & Then
        XCTAssertThrowsError(try invalidConfig.validate()) { error in
            if case JMSError.missingRequiredField(let field) = error {
                XCTAssertEqual(field, "username")
            } else {
                XCTFail("Expected missingRequiredField error")
            }
        }
    }
    
    func testJMSConfigValidation_MissingToken() {
        // Given
        let invalidConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "",
            config: "full address:s:test.com:3389"
        )
        
        // When & Then
        XCTAssertThrowsError(try invalidConfig.validate()) { error in
            if case JMSError.missingRequiredField(let field) = error {
                XCTAssertEqual(field, "token")
            } else {
                XCTFail("Expected missingRequiredField error")
            }
        }
    }
    
    func testJMSConfigValidation_MissingConfig() {
        // Given
        let invalidConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: ""
        )
        
        // When & Then
        XCTAssertThrowsError(try invalidConfig.validate()) { error in
            if case JMSError.missingRequiredField(let field) = error {
                XCTAssertEqual(field, "config")
            } else {
                XCTFail("Expected missingRequiredField error")
            }
        }
    }
    
    func testIsRDPProtocol_True() {
        // Given
        let rdpConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: "full address:s:test.com:3389"
        )
        
        // When & Then
        XCTAssertTrue(rdpConfig.isRDPProtocol)
    }
    
    func testIsRDPProtocol_TrueCaseInsensitive() {
        // Given
        let rdpConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "RDP",
            username: "testuser",
            token: "testtoken",
            config: "full address:s:test.com:3389"
        )
        
        // When & Then
        XCTAssertTrue(rdpConfig.isRDPProtocol)
    }
    
    func testIsRDPProtocol_False() {
        // Given
        let sshConfig = JMSConfig(
            filename: "test.ssh",
            protocol: "ssh",
            username: "testuser",
            token: "testtoken",
            config: "host:test.com"
        )
        
        // When & Then
        XCTAssertFalse(sshConfig.isRDPProtocol)
    }
    
    func testJMSConfigCodable() throws {
        // Given
        let originalConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: "full address:s:test.com:3389"
        )
        
        // When
        let jsonData = try JSONEncoder().encode(originalConfig)
        let decodedConfig = try JSONDecoder().decode(JMSConfig.self, from: jsonData)
        
        // Then
        XCTAssertEqual(decodedConfig.filename, originalConfig.filename)
        XCTAssertEqual(decodedConfig.`protocol`, originalConfig.`protocol`)
        XCTAssertEqual(decodedConfig.username, originalConfig.username)
        XCTAssertEqual(decodedConfig.token, originalConfig.token)
        XCTAssertEqual(decodedConfig.config, originalConfig.config)
    }
}