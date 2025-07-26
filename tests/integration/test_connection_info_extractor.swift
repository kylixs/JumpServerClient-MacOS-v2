#!/usr/bin/env swift

import Foundation

// Copy the necessary models and classes for testing
enum JMSError: LocalizedError {
    case invalidURL
    case decodingFailed
    case jsonParsingFailed
    case missingConnectionInfo
    case remoteDesktopNotFound
    case remoteDesktopLaunchFailed
    case configParsingFailed
    case missingRequiredField(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL格式错误"
        case .decodingFailed:
            return "解码失败"
        case .jsonParsingFailed:
            return "配置信息格式错误"
        case .missingConnectionInfo:
            return "连接信息不完整"
        case .remoteDesktopNotFound:
            return "未找到Microsoft Remote Desktop应用程序"
        case .remoteDesktopLaunchFailed:
            return "启动Microsoft Remote Desktop失败"
        case .configParsingFailed:
            return "配置解析失败"
        case .missingRequiredField(let field):
            return "缺少必要字段: \(field)"
        }
    }
}

struct JMSConfig {
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

struct ConnectionInfo {
    let fullAddress: String
    let username: String
    let sessionBpp: Int?
    let audioMode: Int?
    let smartSizing: Bool?
    let screenModeId: Int?
    let additionalConfig: [String: String]
    
    func validate() throws {
        guard !fullAddress.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
        
        guard !username.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
    }
    
    var hostname: String {
        return fullAddress.components(separatedBy: ":").first ?? fullAddress
    }
    
    var port: Int {
        let components = fullAddress.components(separatedBy: ":")
        if components.count > 1, let port = Int(components[1]) {
            return port
        }
        return 3389
    }
}

protocol ConnectionInfoExtractorProtocol {
    func extractConnectionInfo(from config: JMSConfig) throws -> ConnectionInfo
    func parseConfigString(_ configString: String) throws -> [String: String]
    func extractValue(for key: String, from configParams: [String: String]) -> String?
}

class ConnectionInfoExtractor: ConnectionInfoExtractorProtocol {
    
    func extractConnectionInfo(from config: JMSConfig) throws -> ConnectionInfo {
        try config.validate()
        
        let configParams = try parseConfigString(config.config)
        
        guard let fullAddress = extractValue(for: "full address", from: configParams),
              !fullAddress.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
        
        guard let username = extractValue(for: "username", from: configParams),
              !username.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
        
        let sessionBpp = extractIntValue(for: "session bpp", from: configParams)
        let audioMode = extractIntValue(for: "audiomode", from: configParams)
        let smartSizing = extractBoolValue(for: "smart sizing", from: configParams)
        let screenModeId = extractIntValue(for: "screen mode id", from: configParams)
        
        var additionalConfig: [String: String] = [:]
        let knownKeys = Set(["full address", "username", "session bpp", "audiomode", "smart sizing", "screen mode id"])
        
        for (key, value) in configParams {
            if !knownKeys.contains(key) {
                additionalConfig[key] = value
            }
        }
        
        let connectionInfo = ConnectionInfo(
            fullAddress: fullAddress,
            username: username,
            sessionBpp: sessionBpp,
            audioMode: audioMode,
            smartSizing: smartSizing,
            screenModeId: screenModeId,
            additionalConfig: additionalConfig
        )
        
        try connectionInfo.validate()
        
        return connectionInfo
    }
    
    func parseConfigString(_ configString: String) throws -> [String: String] {
        var configParams: [String: String] = [:]
        
        let lines = configString.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.isEmpty {
                continue
            }
            
            if let colonIndex = trimmedLine.firstIndex(of: ":") {
                let keyPart = String(trimmedLine[..<colonIndex])
                let remainingPart = String(trimmedLine[trimmedLine.index(after: colonIndex)...])
                
                if let secondColonIndex = remainingPart.firstIndex(of: ":") {
                    let type = String(remainingPart[..<secondColonIndex])
                    let value = String(remainingPart[remainingPart.index(after: secondColonIndex)...])
                    
                    if isValidConfigType(type) {
                        configParams[keyPart] = value
                    }
                } else {
                    throw JMSError.configParsingFailed
                }
            }
        }
        
        return configParams
    }
    
    func extractValue(for key: String, from configParams: [String: String]) -> String? {
        return configParams[key]
    }
    
    private func extractIntValue(for key: String, from configParams: [String: String]) -> Int? {
        guard let stringValue = configParams[key] else { return nil }
        return Int(stringValue)
    }
    
    private func extractBoolValue(for key: String, from configParams: [String: String]) -> Bool? {
        guard let stringValue = configParams[key] else { return nil }
        
        if let intValue = Int(stringValue) {
            return intValue != 0
        }
        
        switch stringValue.lowercased() {
        case "true", "yes", "1":
            return true
        case "false", "no", "0":
            return false
        default:
            return nil
        }
    }
    
    private func isValidConfigType(_ type: String) -> Bool {
        let validTypes = ["s", "i", "b"]
        return validTypes.contains(type)
    }
}

// Test the implementation
func testConnectionInfoExtractor() {
    let extractor = ConnectionInfoExtractor()
    
    print("Testing ConnectionInfoExtractor...")
    
    // Test 1: Valid configuration
    let configString1 = """
    full address:s:develop-jumpserver.jlcops.com:3389
    username:s:gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53
    session bpp:i:32
    audiomode:i:0
    smart sizing:i:1
    screen mode id:i:2
    desktopwidth:i:1920
    desktopheight:i:1080
    """
    
    let jmsConfig1 = JMSConfig(
        filename: "test.rdp",
        protocol: "rdp",
        username: "testuser",
        token: "testtoken",
        config: configString1
    )
    
    do {
        let connectionInfo = try extractor.extractConnectionInfo(from: jmsConfig1)
        print("✅ Test 1 passed:")
        print("  Full Address: \(connectionInfo.fullAddress)")
        print("  Username: \(connectionInfo.username)")
        print("  Session BPP: \(connectionInfo.sessionBpp ?? -1)")
        print("  Audio Mode: \(connectionInfo.audioMode ?? -1)")
        print("  Smart Sizing: \(connectionInfo.smartSizing ?? false)")
        print("  Screen Mode ID: \(connectionInfo.screenModeId ?? -1)")
        print("  Hostname: \(connectionInfo.hostname)")
        print("  Port: \(connectionInfo.port)")
        print("  Additional Config: \(connectionInfo.additionalConfig)")
    } catch {
        print("❌ Test 1 failed: \(error)")
    }
    
    // Test 2: Missing required field
    let configString2 = """
    username:s:testuser
    session bpp:i:32
    """
    
    let jmsConfig2 = JMSConfig(
        filename: "test.rdp",
        protocol: "rdp",
        username: "testuser",
        token: "testtoken",
        config: configString2
    )
    
    do {
        let _ = try extractor.extractConnectionInfo(from: jmsConfig2)
        print("❌ Test 2 failed: Should have thrown error for missing full address")
    } catch JMSError.missingConnectionInfo {
        print("✅ Test 2 passed: Correctly detected missing connection info")
    } catch {
        print("❌ Test 2 failed with unexpected error: \(error)")
    }
    
    // Test 3: Parse config string
    do {
        let configParams = try extractor.parseConfigString(configString1)
        print("✅ Test 3 passed: Config parsing successful")
        print("  Parsed parameters: \(configParams)")
    } catch {
        print("❌ Test 3 failed: \(error)")
    }
    
    // Test 4: Extract specific values
    let testParams = [
        "full address": "test-server.com:3389",
        "username": "testuser"
    ]
    
    if let address = extractor.extractValue(for: "full address", from: testParams) {
        print("✅ Test 4 passed: Successfully extracted value: \(address)")
    } else {
        print("❌ Test 4 failed: Could not extract value")
    }
    
    print("\nAll tests completed!")
}

testConnectionInfoExtractor()