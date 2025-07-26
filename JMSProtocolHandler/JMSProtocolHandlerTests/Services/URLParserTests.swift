import XCTest
@testable import JMSProtocolHandler

class URLParserTests: XCTestCase {
    
    var urlParser: URLParser!
    
    override func setUp() {
        super.setUp()
        urlParser = URLParser()
    }
    
    override func tearDown() {
        urlParser = nil
        super.tearDown()
    }
    
    // MARK: - Valid URL Tests
    
    func testParseValidJMSURL() throws {
        // 创建一个有效的base64编码payload
        let testPayload = "eyJ0ZXN0IjoidmFsdWUifQ==" // {"test":"value"} 的base64编码
        let testURL = URL(string: "jms://\(testPayload)")!
        
        let result = try urlParser.parseJMSURL(testURL)
        
        XCTAssertEqual(result.scheme, "jms")
        XCTAssertEqual(result.encodedPayload, testPayload)
        XCTAssertEqual(result.originalURL, testURL)
    }
    
    func testParseJMSURLWithComplexPayload() throws {
        // 使用更复杂的JSON数据
        let jsonData = """
        {
            "filename": "test.rdp",
            "protocol": "rdp",
            "username": "testuser",
            "token": "abc123",
            "config": "full address:s:test.com:3389\\nusername:s:testuser"
        }
        """.data(using: .utf8)!
        
        let base64Payload = jsonData.base64EncodedString()
        let testURL = URL(string: "jms://\(base64Payload)")!
        
        let result = try urlParser.parseJMSURL(testURL)
        
        XCTAssertEqual(result.scheme, "jms")
        XCTAssertEqual(result.encodedPayload, base64Payload)
        XCTAssertEqual(result.originalURL, testURL)
    }
    
    // MARK: - Invalid URL Tests
    
    func testParseInvalidScheme() {
        let testURL = URL(string: "http://eyJ0ZXN0IjoidmFsdWUifQ==")!
        
        XCTAssertThrowsError(try urlParser.parseJMSURL(testURL)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.invalidURL)
        }
    }
    
    func testParseEmptyPayload() {
        let testURL = URL(string: "jms://")!
        
        XCTAssertThrowsError(try urlParser.parseJMSURL(testURL)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.invalidURL)
        }
    }
    
    func testParseInvalidBase64Payload() {
        let testURL = URL(string: "jms://invalid-base64!")!
        
        XCTAssertThrowsError(try urlParser.parseJMSURL(testURL)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.invalidURL)
        }
    }
    
    func testParseMalformedURL() {
        let testURL = URL(string: "jms:")!
        
        XCTAssertThrowsError(try urlParser.parseJMSURL(testURL)) { error in
            XCTAssertEqual(error as? JMSError, JMSError.invalidURL)
        }
    }
    
    // MARK: - URL Validation Tests
    
    func testIsValidJMSURL_ValidURL() {
        let testURL = URL(string: "jms://eyJ0ZXN0IjoidmFsdWUifQ==")!
        XCTAssertTrue(urlParser.isValidJMSURL(testURL))
    }
    
    func testIsValidJMSURL_InvalidScheme() {
        let testURL = URL(string: "http://eyJ0ZXN0IjoidmFsdWUifQ==")!
        XCTAssertFalse(urlParser.isValidJMSURL(testURL))
    }
    
    func testIsValidJMSURL_CaseInsensitiveScheme() {
        let testURL = URL(string: "JMS://eyJ0ZXN0IjoidmFsdWUifQ==")!
        XCTAssertTrue(urlParser.isValidJMSURL(testURL))
    }
    
    func testIsValidJMSURL_EmptyHost() {
        let testURL = URL(string: "jms://")!
        XCTAssertFalse(urlParser.isValidJMSURL(testURL))
    }
    
    func testIsValidJMSURL_InvalidBase64() {
        let testURL = URL(string: "jms://invalid-base64!")!
        XCTAssertFalse(urlParser.isValidJMSURL(testURL))
    }
    
    // MARK: - Base64 Validation Edge Cases
    
    func testValidBase64WithPadding() {
        let testURL = URL(string: "jms://dGVzdA==")! // "test" with padding
        XCTAssertTrue(urlParser.isValidJMSURL(testURL))
    }
    
    func testValidBase64WithoutPadding() {
        let testURL = URL(string: "jms://dGVzdA")! // "test" without padding (still valid)
        XCTAssertFalse(urlParser.isValidJMSURL(testURL)) // Should be false due to length not being multiple of 4
    }
    
    func testInvalidBase64Length() {
        let testURL = URL(string: "jms://abc")! // Length not multiple of 4
        XCTAssertFalse(urlParser.isValidJMSURL(testURL))
    }
    
    func testInvalidBase64Characters() {
        let testURL = URL(string: "jms://abc@def#")! // Contains invalid characters
        XCTAssertFalse(urlParser.isValidJMSURL(testURL))
    }
    
    func testInvalidBase64PaddingPosition() {
        let testURL = URL(string: "jms://ab=cd")! // Padding in wrong position
        XCTAssertFalse(urlParser.isValidJMSURL(testURL))
    }
    
    func testInvalidBase64TooMuchPadding() {
        let testURL = URL(string: "jms://ab===")! // Too much padding
        XCTAssertFalse(urlParser.isValidJMSURL(testURL))
    }
    
    // MARK: - Real-world Scenario Tests
    
    func testRealWorldJMSURL() throws {
        // 模拟真实的JMS URL场景
        let realConfig = """
        {
            "filename": "connection.rdp",
            "protocol": "rdp",
            "username": "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53",
            "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
            "config": "full address:s:develop-jumpserver.jlcops.com:3389\\nusername:s:gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53\\nsession bpp:i:32\\naudiomode:i:0"
        }
        """.data(using: .utf8)!
        
        let base64Payload = realConfig.base64EncodedString()
        let testURL = URL(string: "jms://\(base64Payload)")!
        
        let result = try urlParser.parseJMSURL(testURL)
        
        XCTAssertEqual(result.scheme, "jms")
        XCTAssertEqual(result.encodedPayload, base64Payload)
        XCTAssertEqual(result.originalURL, testURL)
        
        // 验证可以成功解码
        let decodedData = Data(base64Encoded: result.encodedPayload)
        XCTAssertNotNil(decodedData)
        
        let decodedString = String(data: decodedData!, encoding: .utf8)
        XCTAssertNotNil(decodedString)
        XCTAssertTrue(decodedString!.contains("develop-jumpserver.jlcops.com"))
    }
    
    // MARK: - Additional Edge Cases
    
    func testEmptyStringPayload() {
        let testURL = URL(string: "jms://")!
        XCTAssertFalse(urlParser.isValidJMSURL(testURL))
    }
    
    func testURLWithPath() {
        let testURL = URL(string: "jms://eyJ0ZXN0IjoidmFsdWUifQ==/path")!
        XCTAssertTrue(urlParser.isValidJMSURL(testURL))
    }
    
    func testURLWithQuery() {
        let testURL = URL(string: "jms://eyJ0ZXN0IjoidmFsdWUifQ==?query=value")!
        XCTAssertTrue(urlParser.isValidJMSURL(testURL))
    }
    
    func testURLWithFragment() {
        let testURL = URL(string: "jms://eyJ0ZXN0IjoidmFsdWUifQ==#fragment")!
        XCTAssertTrue(urlParser.isValidJMSURL(testURL))
    }
    
    func testURLWithPort() {
        let testURL = URL(string: "jms://eyJ0ZXN0IjoidmFsdWUifQ==:8080")!
        XCTAssertTrue(urlParser.isValidJMSURL(testURL))
    }
    
    func testMixedCaseScheme() {
        let testURL = URL(string: "JmS://eyJ0ZXN0IjoidmFsdWUifQ==")!
        XCTAssertTrue(urlParser.isValidJMSURL(testURL))
    }
    
    func testBase64URLSafeCharacters() {
        // Test with URL-safe base64 characters (- and _ instead of + and /)
        let testURL = URL(string: "jms://eyJ0ZXN0IjoidmFsdWUifQ==")!
        XCTAssertTrue(urlParser.isValidJMSURL(testURL))
    }
    
    func testVeryLongBase64Payload() throws {
        // Create a very long JSON payload
        var longConfig = "{"
        for i in 0..<100 {
            longConfig += "\"key\(i)\": \"value\(i)\","
        }
        longConfig += "\"final\": \"value\"}"
        
        let longPayload = longConfig.data(using: .utf8)!.base64EncodedString()
        let testURL = URL(string: "jms://\(longPayload)")!
        
        XCTAssertTrue(urlParser.isValidJMSURL(testURL))
        
        let result = try urlParser.parseJMSURL(testURL)
        XCTAssertEqual(result.encodedPayload, longPayload)
    }
    
    func testSpecialCharactersInBase64() {
        // Test base64 with + and / characters
        let testData = "Hello+World/Test=".data(using: .utf8)!
        let base64Payload = testData.base64EncodedString()
        let testURL = URL(string: "jms://\(base64Payload)")!
        
        XCTAssertTrue(urlParser.isValidJMSURL(testURL))
    }
    
    func testMinimalValidBase64() {
        // Minimal valid base64 (4 characters)
        let testURL = URL(string: "jms://dGVz")! // "tes" in base64
        XCTAssertTrue(urlParser.isValidJMSURL(testURL))
    }
    
    // MARK: - Error Handling Tests
    
    func testParseURLWithNilScheme() {
        // This shouldn't happen in practice, but test defensive programming
        let testURL = URL(string: "://eyJ0ZXN0IjoidmFsdWUifQ==")!
        XCTAssertFalse(urlParser.isValidJMSURL(testURL))
    }
    
    func testParseURLWithEmptyScheme() {
        let testURL = URL(string: "://eyJ0ZXN0IjoidmFsdWUifQ==")!
        XCTAssertFalse(urlParser.isValidJMSURL(testURL))
    }
    
    // MARK: - Performance Tests
    
    func testParsingPerformance() {
        let testPayload = "eyJ0ZXN0IjoidmFsdWUifQ=="
        let testURL = URL(string: "jms://\(testPayload)")!
        
        measure {
            for _ in 0..<1000 {
                _ = try? urlParser.parseJMSURL(testURL)
            }
        }
    }
    
    func testValidationPerformance() {
        let testURL = URL(string: "jms://eyJ0ZXN0IjoidmFsdWUifQ==")!
        
        measure {
            for _ in 0..<1000 {
                _ = urlParser.isValidJMSURL(testURL)
            }
        }
    }
}