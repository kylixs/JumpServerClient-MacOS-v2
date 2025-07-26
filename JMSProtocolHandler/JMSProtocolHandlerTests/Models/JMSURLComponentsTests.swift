import XCTest
@testable import JMSProtocolHandler

class JMSURLComponentsTests: XCTestCase {
    
    func testJMSURLComponentsInitialization() {
        // Given
        let scheme = "jms"
        let encodedPayload = "eyJ0ZXN0IjoidmFsdWUifQ=="
        let originalURL = URL(string: "jms://\(encodedPayload)")
        
        // When
        let urlComponents = JMSURLComponents(scheme: scheme, encodedPayload: encodedPayload, originalURL: originalURL)
        
        // Then
        XCTAssertEqual(urlComponents.scheme, scheme)
        XCTAssertEqual(urlComponents.encodedPayload, encodedPayload)
        XCTAssertEqual(urlComponents.originalURL, originalURL)
    }
    
    func testJMSURLComponentsInitializationWithoutURL() {
        // Given
        let scheme = "jms"
        let encodedPayload = "eyJ0ZXN0IjoidmFsdWUifQ=="
        
        // When
        let urlComponents = JMSURLComponents(scheme: scheme, encodedPayload: encodedPayload)
        
        // Then
        XCTAssertEqual(urlComponents.scheme, scheme)
        XCTAssertEqual(urlComponents.encodedPayload, encodedPayload)
        XCTAssertNil(urlComponents.originalURL)
    }
    
    func testJMSURLComponentsValidation_Success() {
        // Given
        let validComponents = JMSURLComponents(
            scheme: "jms",
            encodedPayload: "eyJ0ZXN0IjoidmFsdWUifQ=="
        )
        
        // When & Then
        XCTAssertNoThrow(try validComponents.validate())
    }
    
    func testJMSURLComponentsValidation_SuccessCaseInsensitive() {
        // Given
        let validComponents = JMSURLComponents(
            scheme: "JMS",
            encodedPayload: "eyJ0ZXN0IjoidmFsdWUifQ=="
        )
        
        // When & Then
        XCTAssertNoThrow(try validComponents.validate())
    }
    
    func testJMSURLComponentsValidation_InvalidScheme() {
        // Given
        let invalidComponents = JMSURLComponents(
            scheme: "http",
            encodedPayload: "eyJ0ZXN0IjoidmFsdWUifQ=="
        )
        
        // When & Then
        XCTAssertThrowsError(try invalidComponents.validate()) { error in
            XCTAssertEqual(error as? JMSError, JMSError.invalidURL)
        }
    }
    
    func testJMSURLComponentsValidation_EmptyPayload() {
        // Given
        let invalidComponents = JMSURLComponents(
            scheme: "jms",
            encodedPayload: ""
        )
        
        // When & Then
        XCTAssertThrowsError(try invalidComponents.validate()) { error in
            XCTAssertEqual(error as? JMSError, JMSError.invalidURL)
        }
    }
}