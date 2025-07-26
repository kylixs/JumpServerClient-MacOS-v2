import XCTest
@testable import JMSProtocolHandler

class ConnectionInfoTests: XCTestCase {
    
    func testConnectionInfoInitialization() {
        // Given
        let fullAddress = "develop-jumpserver.jlcops.com:3389"
        let username = "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53"
        let sessionBpp = 32
        let audioMode = 0
        let smartSizing = true
        let screenModeId = 2
        let additionalConfig = ["test": "value"]
        
        // When
        let connectionInfo = ConnectionInfo(
            fullAddress: fullAddress,
            username: username,
            sessionBpp: sessionBpp,
            audioMode: audioMode,
            smartSizing: smartSizing,
            screenModeId: screenModeId,
            additionalConfig: additionalConfig
        )
        
        // Then
        XCTAssertEqual(connectionInfo.fullAddress, fullAddress)
        XCTAssertEqual(connectionInfo.username, username)
        XCTAssertEqual(connectionInfo.sessionBpp, sessionBpp)
        XCTAssertEqual(connectionInfo.audioMode, audioMode)
        XCTAssertEqual(connectionInfo.smartSizing, smartSizing)
        XCTAssertEqual(connectionInfo.screenModeId, screenModeId)
        XCTAssertEqual(connectionInfo.additionalConfig, additionalConfig)
    }
    
    func testConnectionInfoInitializationWithDefaults() {
        // Given
        let fullAddress = "test.com:3389"
        let username = "testuser"
        
        // When
        let connectionInfo = ConnectionInfo(
            fullAddress: fullAddress,
            username: username
        )
        
        // Then
        XCTAssertEqual(connectionInfo.fullAddress, fullAddress)
        XCTAssertEqual(connectionInfo.username, username)
        XCTAssertNil(connectionInfo.sessionBpp)
        XCTAssertNil(connectionInfo.audioMode)
        XCTAssertNil(connectionInfo.smartSizing)
        XCTAssertNil(connectionInfo.screenModeId)
        XCTAssertTrue(connectionInfo.additionalConfig.isEmpty)
    }
    
    func testConnectionInfoValidation_Success() {
        // Given
        let validConnectionInfo = ConnectionInfo(
            fullAddress: "test.com:3389",
            username: "testuser"
        )
        
        // When & Then
        XCTAssertNoThrow(try validConnectionInfo.validate())
    }
    
    func testConnectionInfoValidation_EmptyAddress() {
        // Given
        let invalidConnectionInfo = ConnectionInfo(
            fullAddress: "",
            username: "testuser"
        )
        
        // When & Then
        XCTAssertThrowsError(try invalidConnectionInfo.validate()) { error in
            XCTAssertEqual(error as? JMSError, JMSError.missingConnectionInfo)
        }
    }
    
    func testConnectionInfoValidation_EmptyUsername() {
        // Given
        let invalidConnectionInfo = ConnectionInfo(
            fullAddress: "test.com:3389",
            username: ""
        )
        
        // When & Then
        XCTAssertThrowsError(try invalidConnectionInfo.validate()) { error in
            XCTAssertEqual(error as? JMSError, JMSError.missingConnectionInfo)
        }
    }
    
    func testHostnameExtraction_WithPort() {
        // Given
        let connectionInfo = ConnectionInfo(
            fullAddress: "develop-jumpserver.jlcops.com:3389",
            username: "testuser"
        )
        
        // When
        let hostname = connectionInfo.hostname
        
        // Then
        XCTAssertEqual(hostname, "develop-jumpserver.jlcops.com")
    }
    
    func testHostnameExtraction_WithoutPort() {
        // Given
        let connectionInfo = ConnectionInfo(
            fullAddress: "develop-jumpserver.jlcops.com",
            username: "testuser"
        )
        
        // When
        let hostname = connectionInfo.hostname
        
        // Then
        XCTAssertEqual(hostname, "develop-jumpserver.jlcops.com")
    }
    
    func testPortExtraction_WithPort() {
        // Given
        let connectionInfo = ConnectionInfo(
            fullAddress: "test.com:3390",
            username: "testuser"
        )
        
        // When
        let port = connectionInfo.port
        
        // Then
        XCTAssertEqual(port, 3390)
    }
    
    func testPortExtraction_WithoutPort() {
        // Given
        let connectionInfo = ConnectionInfo(
            fullAddress: "test.com",
            username: "testuser"
        )
        
        // When
        let port = connectionInfo.port
        
        // Then
        XCTAssertEqual(port, 3389) // 默认RDP端口
    }
    
    func testPortExtraction_InvalidPort() {
        // Given
        let connectionInfo = ConnectionInfo(
            fullAddress: "test.com:invalid",
            username: "testuser"
        )
        
        // When
        let port = connectionInfo.port
        
        // Then
        XCTAssertEqual(port, 3389) // 默认RDP端口
    }
    
    func testGenerateRDPContent_BasicInfo() {
        // Given
        let connectionInfo = ConnectionInfo(
            fullAddress: "test.com:3389",
            username: "testuser"
        )
        
        // When
        let rdpContent = connectionInfo.generateRDPContent()
        
        // Then
        let expectedContent = [
            "full address:s:test.com:3389",
            "username:s:testuser"
        ].joined(separator: "\n")
        
        XCTAssertEqual(rdpContent, expectedContent)
    }
    
    func testGenerateRDPContent_WithAllOptions() {
        // Given
        let connectionInfo = ConnectionInfo(
            fullAddress: "test.com:3389",
            username: "testuser",
            sessionBpp: 32,
            audioMode: 0,
            smartSizing: true,
            screenModeId: 2,
            additionalConfig: ["custom param:s": "custom value"]
        )
        
        // When
        let rdpContent = connectionInfo.generateRDPContent()
        
        // Then
        XCTAssertTrue(rdpContent.contains("full address:s:test.com:3389"))
        XCTAssertTrue(rdpContent.contains("username:s:testuser"))
        XCTAssertTrue(rdpContent.contains("session bpp:i:32"))
        XCTAssertTrue(rdpContent.contains("audiomode:i:0"))
        XCTAssertTrue(rdpContent.contains("smart sizing:i:1"))
        XCTAssertTrue(rdpContent.contains("screen mode id:i:2"))
        XCTAssertTrue(rdpContent.contains("custom param:s:custom value"))
    }
    
    func testGenerateRDPContent_SmartSizingFalse() {
        // Given
        let connectionInfo = ConnectionInfo(
            fullAddress: "test.com:3389",
            username: "testuser",
            smartSizing: false
        )
        
        // When
        let rdpContent = connectionInfo.generateRDPContent()
        
        // Then
        XCTAssertTrue(rdpContent.contains("smart sizing:i:0"))
    }
}