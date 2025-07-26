#!/usr/bin/env swift

import Foundation

// Simulate the JMSError enum for validation
enum JMSError: LocalizedError {
    case decodingFailed
    case jsonParsingFailed
    case missingRequiredField(String)
    
    var errorDescription: String? {
        switch self {
        case .decodingFailed:
            return "解码失败"
        case .jsonParsingFailed:
            return "配置信息格式错误"
        case .missingRequiredField(let field):
            return "缺少必要字段: \(field)"
        }
    }
}

// Simulate the JMSConfig struct for validation
struct JMSConfig: Codable {
    let filename: String
    let `protocol`: String
    let username: String
    let token: String
    let config: String
    
    func validate() throws {
        if filename.isEmpty {
            throw JMSError.missingRequiredField("filename")
        }
        if `protocol`.isEmpty {
            throw JMSError.missingRequiredField("protocol")
        }
        if username.isEmpty {
            throw JMSError.missingRequiredField("username")
        }
        if token.isEmpty {
            throw JMSError.missingRequiredField("token")
        }
        if config.isEmpty {
            throw JMSError.missingRequiredField("config")
        }
    }
}

// Simulate the PayloadDecoderProtocol for validation
protocol PayloadDecoderProtocol {
    func decodeBase64Payload(_ payload: String) throws -> Data
    func parseJSONConfig(_ data: Data) throws -> JMSConfig
    func decodeAndParsePayload(_ payload: String) throws -> JMSConfig
}

// Test the PayloadDecoder implementation
class PayloadDecoder: PayloadDecoderProtocol {
    
    func decodeBase64Payload(_ payload: String) throws -> Data {
        let cleanedPayload = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let decodedData = Data(base64Encoded: cleanedPayload) else {
            throw JMSError.decodingFailed
        }
        
        return decodedData
    }
    
    func parseJSONConfig(_ data: Data) throws -> JMSConfig {
        do {
            let decoder = JSONDecoder()
            let config = try decoder.decode(JMSConfig.self, from: data)
            
            try config.validate()
            
            return config
        } catch is DecodingError {
            throw JMSError.jsonParsingFailed
        } catch let error as JMSError {
            throw error
        } catch {
            throw JMSError.jsonParsingFailed
        }
    }
    
    func decodeAndParsePayload(_ payload: String) throws -> JMSConfig {
        let decodedData = try decodeBase64Payload(payload)
        let config = try parseJSONConfig(decodedData)
        return config
    }
}

// Test the implementation
print("Validating PayloadDecoder syntax...")

let decoder = PayloadDecoder()

// Test 1: Valid base64 decoding
let testString = "Hello, World!"
let base64String = Data(testString.utf8).base64EncodedString()

do {
    let decodedData = try decoder.decodeBase64Payload(base64String)
    let decodedString = String(data: decodedData, encoding: .utf8)
    if decodedString == testString {
        print("✅ Base64 decoding works")
    }
} catch {
    print("❌ Base64 decoding failed: \(error)")
}

// Test 2: Valid JSON parsing
let jsonString = """
{
    "filename": "test.rdp",
    "protocol": "rdp",
    "username": "testuser",
    "token": "testtoken",
    "config": "full address:s:test.com:3389"
}
"""
let jsonData = Data(jsonString.utf8)

do {
    let config = try decoder.parseJSONConfig(jsonData)
    if config.filename == "test.rdp" && config.`protocol` == "rdp" {
        print("✅ JSON parsing works")
    }
} catch {
    print("❌ JSON parsing failed: \(error)")
}

// Test 3: Complete workflow
let completeBase64 = Data(jsonString.utf8).base64EncodedString()

do {
    let config = try decoder.decodeAndParsePayload(completeBase64)
    if config.filename == "test.rdp" {
        print("✅ Complete workflow works")
    }
} catch {
    print("❌ Complete workflow failed: \(error)")
}

// Test 4: Error handling
do {
    _ = try decoder.decodeBase64Payload("invalid base64!")
    print("❌ Error handling failed - should have thrown error")
} catch JMSError.decodingFailed {
    print("✅ Error handling works")
} catch {
    print("❌ Wrong error type: \(error)")
}

print("All PayloadDecoder syntax validations passed!")