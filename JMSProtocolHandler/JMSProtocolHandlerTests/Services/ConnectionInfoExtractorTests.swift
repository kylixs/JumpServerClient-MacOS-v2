import XCTest
@testable import JMSProtocolHandler

class ConnectionInfoExtractorTests: XCTestCase {
    
    var extractor: ConnectionInfoExtractor!
    
    override func setUp() {
        super.setUp()
        extractor = ConnectionInfoExtractor()
    }
    
    override func tearDown() {
        extractor = nil
        super.tearDown()
    }
    
    // MARK: - extractConnectionInfo Tests
    
    func testExtractConnectionInfo_ValidConfig_Success() throws {
        // Given
        let configString = """
        full address:s:develop-jumpserver.jlcops.com:3389
        username:s:gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53
        session bpp:i:32
        audiomode:i:0
        smart sizing:i:1
        screen mode id:i:2
        """
        
        let jmsConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: configString
        )
        
        // When
        let connectionInfo = try extractor.extractConnectionInfo(from: jmsConfig)
        
        // Then
        XCTAssertEqual(connectionInfo.fullAddress, "develop-jumpserver.jlcops.com:3389")
        XCTAssertEqual(connectionInfo.username, "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53")
        XCTAssertEqual(connectionInfo.sessionBpp, 32)
        XCTAssertEqual(connectionInfo.audioMode, 0)
        XCTAssertEqual(connectionInfo.smartSizing, true)
        XCTAssertEqual(connectionInfo.screenModeId, 2)
    }
    
    func testExtractConnectionInfo_MissingFullAddress_ThrowsError() {
        // Given
        let configString = """
        username:s:gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53
        session bpp:i:32
        """
        
        let jmsConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: configString
        )
        
        // When & Then
        XCTAssertThrowsError(try extractor.extractConnectionInfo(from: jmsConfig)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.missingConnectionInfo)
        }
    }
    
    func testExtractConnectionInfo_MissingUsername_ThrowsError() {
        // Given
        let configString = """
        full address:s:develop-jumpserver.jlcops.com:3389
        session bpp:i:32
        """
        
        let jmsConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: configString
        )
        
        // When & Then
        XCTAssertThrowsError(try extractor.extractConnectionInfo(from: jmsConfig)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.missingConnectionInfo)
        }
    }
    
    func testExtractConnectionInfo_EmptyFullAddress_ThrowsError() {
        // Given
        let configString = """
        full address:s:
        username:s:gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53
        """
        
        let jmsConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: configString
        )
        
        // When & Then
        XCTAssertThrowsError(try extractor.extractConnectionInfo(from: jmsConfig)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.missingConnectionInfo)
        }
    }
    
    func testExtractConnectionInfo_EmptyUsername_ThrowsError() {
        // Given
        let configString = """
        full address:s:develop-jumpserver.jlcops.com:3389
        username:s:
        """
        
        let jmsConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: configString
        )
        
        // When & Then
        XCTAssertThrowsError(try extractor.extractConnectionInfo(from: jmsConfig)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.missingConnectionInfo)
        }
    }
    
    func testExtractConnectionInfo_WithAdditionalConfig_Success() throws {
        // Given
        let configString = """
        full address:s:test-server.com:3389
        username:s:testuser
        session bpp:i:24
        custom param:s:custom value
        another setting:i:42
        """
        
        let jmsConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: configString
        )
        
        // When
        let connectionInfo = try extractor.extractConnectionInfo(from: jmsConfig)
        
        // Then
        XCTAssertEqual(connectionInfo.fullAddress, "test-server.com:3389")
        XCTAssertEqual(connectionInfo.username, "testuser")
        XCTAssertEqual(connectionInfo.sessionBpp, 24)
        XCTAssertEqual(connectionInfo.additionalConfig["custom param"], "custom value")
        XCTAssertEqual(connectionInfo.additionalConfig["another setting"], "42")
    }
    
    // MARK: - parseConfigString Tests
    
    func testParseConfigString_ValidFormat_Success() throws {
        // Given
        let configString = """
        full address:s:develop-jumpserver.jlcops.com:3389
        username:s:gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53
        session bpp:i:32
        audiomode:i:0
        """
        
        // When
        let result = try extractor.parseConfigString(configString)
        
        // Then
        XCTAssertEqual(result["full address"], "develop-jumpserver.jlcops.com:3389")
        XCTAssertEqual(result["username"], "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53")
        XCTAssertEqual(result["session bpp"], "32")
        XCTAssertEqual(result["audiomode"], "0")
    }
    
    func testParseConfigString_WithEmptyLines_Success() throws {
        // Given
        let configString = """
        full address:s:test-server.com:3389
        
        username:s:testuser
        
        session bpp:i:32
        """
        
        // When
        let result = try extractor.parseConfigString(configString)
        
        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result["full address"], "test-server.com:3389")
        XCTAssertEqual(result["username"], "testuser")
        XCTAssertEqual(result["session bpp"], "32")
    }
    
    func testParseConfigString_WithWhitespace_Success() throws {
        // Given
        let configString = """
          full address:s:test-server.com:3389  
          username:s:testuser  
        """
        
        // When
        let result = try extractor.parseConfigString(configString)
        
        // Then
        XCTAssertEqual(result["full address"], "test-server.com:3389")
        XCTAssertEqual(result["username"], "testuser")
    }
    
    func testParseConfigString_InvalidFormat_ThrowsError() {
        // Given - Missing second colon
        let configString = "full address:develop-jumpserver.jlcops.com:3389"
        
        // When & Then
        XCTAssertThrowsError(try extractor.parseConfigString(configString)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.configParsingFailed)
        }
    }
    
    func testParseConfigString_InvalidType_ThrowsError() {
        // Given
        let configString = """
        full address:s:test-server.com:3389
        invalid line:x:should throw error
        username:s:testuser
        """
        
        // When & Then
        XCTAssertThrowsError(try extractor.parseConfigString(configString)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.configParsingFailed)
        }
    }
    
    func testParseConfigString_EmptyString_ReturnsEmptyDictionary() throws {
        // Given
        let configString = ""
        
        // When
        let result = try extractor.parseConfigString(configString)
        
        // Then
        XCTAssertTrue(result.isEmpty)
    }
    
    func testParseConfigString_OnlyWhitespace_ReturnsEmptyDictionary() throws {
        // Given
        let configString = "   \n  \n  "
        
        // When
        let result = try extractor.parseConfigString(configString)
        
        // Then
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - extractValue Tests
    
    func testExtractValue_ExistingKey_ReturnsValue() {
        // Given
        let configParams = [
            "full address": "test-server.com:3389",
            "username": "testuser"
        ]
        
        // When
        let result = extractor.extractValue(for: "full address", from: configParams)
        
        // Then
        XCTAssertEqual(result, "test-server.com:3389")
    }
    
    func testExtractValue_NonExistingKey_ReturnsNil() {
        // Given
        let configParams = [
            "full address": "test-server.com:3389"
        ]
        
        // When
        let result = extractor.extractValue(for: "username", from: configParams)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testExtractValue_EmptyDictionary_ReturnsNil() {
        // Given
        let configParams: [String: String] = [:]
        
        // When
        let result = extractor.extractValue(for: "full address", from: configParams)
        
        // Then
        XCTAssertNil(result)
    }
    
    // MARK: - Additional RDP Parameter Tests
    
    func testExtractConnectionInfo_AllRDPParameters_Success() throws {
        // Given
        let configString = """
        full address:s:test-server.com:3389
        username:s:testuser
        session bpp:i:32
        audiomode:i:2
        smart sizing:i:1
        screen mode id:i:1
        desktopwidth:i:1920
        desktopheight:i:1080
        compression:i:1
        keyboardhook:i:2
        """
        
        let jmsConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: configString
        )
        
        // When
        let connectionInfo = try extractor.extractConnectionInfo(from: jmsConfig)
        
        // Then
        XCTAssertEqual(connectionInfo.fullAddress, "test-server.com:3389")
        XCTAssertEqual(connectionInfo.username, "testuser")
        XCTAssertEqual(connectionInfo.sessionBpp, 32)
        XCTAssertEqual(connectionInfo.audioMode, 2)
        XCTAssertEqual(connectionInfo.smartSizing, true)
        XCTAssertEqual(connectionInfo.screenModeId, 1)
        XCTAssertEqual(connectionInfo.additionalConfig["desktopwidth"], "1920")
        XCTAssertEqual(connectionInfo.additionalConfig["desktopheight"], "1080")
        XCTAssertEqual(connectionInfo.additionalConfig["compression"], "1")
        XCTAssertEqual(connectionInfo.additionalConfig["keyboardhook"], "2")
    }
    
    func testExtractConnectionInfo_BooleanParameterVariations_Success() throws {
        // Given
        let configString = """
        full address:s:test-server.com:3389
        username:s:testuser
        smart sizing:i:0
        compression:i:1
        """
        
        let jmsConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: configString
        )
        
        // When
        let connectionInfo = try extractor.extractConnectionInfo(from: jmsConfig)
        
        // Then
        XCTAssertEqual(connectionInfo.smartSizing, false) // 0 = false
        XCTAssertEqual(connectionInfo.additionalConfig["compression"], "1")
    }
    
    func testExtractConnectionInfo_DefaultPortHandling_Success() throws {
        // Given - Address without port
        let configString = """
        full address:s:test-server.com
        username:s:testuser
        """
        
        let jmsConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: configString
        )
        
        // When
        let connectionInfo = try extractor.extractConnectionInfo(from: jmsConfig)
        
        // Then
        XCTAssertEqual(connectionInfo.fullAddress, "test-server.com")
        XCTAssertEqual(connectionInfo.hostname, "test-server.com")
        XCTAssertEqual(connectionInfo.port, 3389) // Default RDP port
    }
    
    func testExtractConnectionInfo_CustomPortHandling_Success() throws {
        // Given - Address with custom port
        let configString = """
        full address:s:test-server.com:3390
        username:s:testuser
        """
        
        let jmsConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: configString
        )
        
        // When
        let connectionInfo = try extractor.extractConnectionInfo(from: jmsConfig)
        
        // Then
        XCTAssertEqual(connectionInfo.fullAddress, "test-server.com:3390")
        XCTAssertEqual(connectionInfo.hostname, "test-server.com")
        XCTAssertEqual(connectionInfo.port, 3390)
    }
    
    func testExtractConnectionInfo_ComplexUsernameFormat_Success() throws {
        // Given - Username with pipe separator and UUID
        let configString = """
        full address:s:test-server.com:3389
        username:s:gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53
        """
        
        let jmsConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: configString
        )
        
        // When
        let connectionInfo = try extractor.extractConnectionInfo(from: jmsConfig)
        
        // Then
        XCTAssertEqual(connectionInfo.username, "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53")
    }
    
    func testParseConfigString_MixedValidAndInvalidTypes_ThrowsError() {
        // Given - Mix of valid and invalid types
        let configString = """
        full address:s:test-server.com:3389
        session bpp:i:32
        invalid param:z:invalid
        username:s:testuser
        """
        
        // When & Then
        XCTAssertThrowsError(try extractor.parseConfigString(configString)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.configParsingFailed)
        }
    }
    
    func testParseConfigString_EmptyValues_Success() throws {
        // Given - Config with empty values
        let configString = """
        full address:s:test-server.com:3389
        username:s:testuser
        empty param:s:
        session bpp:i:32
        """
        
        // When
        let result = try extractor.parseConfigString(configString)
        
        // Then
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result["full address"], "test-server.com:3389")
        XCTAssertEqual(result["username"], "testuser")
        XCTAssertEqual(result["empty param"], "")
        XCTAssertEqual(result["session bpp"], "32")
    }
    
    // MARK: - Integration Tests
    
    func testExtractConnectionInfo_RealWorldExample_Success() throws {
        // Given - Real world example from the requirements
        let configString = """
        full address:s:develop-jumpserver.jlcops.com:3389
        username:s:gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53
        session bpp:i:32
        audiomode:i:0
        smart sizing:i:1
        screen mode id:i:2
        desktopwidth:i:1920
        desktopheight:i:1080
        """
        
        let jmsConfig = JMSConfig(
            filename: "connection.rdp",
            protocol: "rdp",
            username: "gongdewei",
            token: "auth-token-123",
            config: configString
        )
        
        // When
        let connectionInfo = try extractor.extractConnectionInfo(from: jmsConfig)
        
        // Then
        XCTAssertEqual(connectionInfo.fullAddress, "develop-jumpserver.jlcops.com:3389")
        XCTAssertEqual(connectionInfo.username, "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53")
        XCTAssertEqual(connectionInfo.sessionBpp, 32)
        XCTAssertEqual(connectionInfo.audioMode, 0)
        XCTAssertEqual(connectionInfo.smartSizing, true)
        XCTAssertEqual(connectionInfo.screenModeId, 2)
        XCTAssertEqual(connectionInfo.additionalConfig["desktopwidth"], "1920")
        XCTAssertEqual(connectionInfo.additionalConfig["desktopheight"], "1080")
        
        // Verify hostname and port extraction
        XCTAssertEqual(connectionInfo.hostname, "develop-jumpserver.jlcops.com")
        XCTAssertEqual(connectionInfo.port, 3389)
    }
    

}