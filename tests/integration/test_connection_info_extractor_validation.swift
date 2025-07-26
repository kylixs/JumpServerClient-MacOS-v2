#!/usr/bin/env swift

import Foundation

// Copy the necessary models and protocols for testing
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
        guard !filename.isEmpty else {
            throw JMSError.missingRequiredField("filename")
        }
        guard !`protocol`.isEmpty else {
            throw JMSError.missingRequiredField("protocol")
        }
        guard !username.isEmpty else {
            throw JMSError.missingRequiredField("username")
        }
        guard !token.isEmpty else {
            throw JMSError.missingRequiredField("token")
        }
        guard !config.isEmpty else {
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
    
    init(fullAddress: String, username: String, sessionBpp: Int? = nil, 
         audioMode: Int? = nil, smartSizing: Bool? = nil, 
         screenModeId: Int? = nil, additionalConfig: [String: String] = [:]) {
        self.fullAddress = fullAddress
        self.username = username
        self.sessionBpp = sessionBpp
        self.audioMode = audioMode
        self.smartSizing = smartSizing
        self.screenModeId = screenModeId
        self.additionalConfig = additionalConfig
    }
    
    func validate() throws {
        guard !fullAddress.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
        
        guard !username.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
        
        guard fullAddress.contains(":") || !fullAddress.isEmpty else {
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

// Test functions
func testBasicExtraction() {
    print("Testing basic connection info extraction...")
    
    let extractor = ConnectionInfoExtractor()
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
    
    do {
        let connectionInfo = try extractor.extractConnectionInfo(from: jmsConfig)
        
        assert(connectionInfo.fullAddress == "develop-jumpserver.jlcops.com:3389", "Full address mismatch")
        assert(connectionInfo.username == "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53", "Username mismatch")
        assert(connectionInfo.sessionBpp == 32, "Session BPP mismatch")
        assert(connectionInfo.audioMode == 0, "Audio mode mismatch")
        assert(connectionInfo.smartSizing == true, "Smart sizing mismatch")
        assert(connectionInfo.screenModeId == 2, "Screen mode ID mismatch")
        assert(connectionInfo.hostname == "develop-jumpserver.jlcops.com", "Hostname mismatch")
        assert(connectionInfo.port == 3389, "Port mismatch")
        
        print("✅ Basic extraction test passed")
    } catch {
        print("❌ Basic extraction test failed: \(error)")
    }
}

func testMissingRequiredFields() {
    print("Testing missing required fields...")
    
    let extractor = ConnectionInfoExtractor()
    
    // Test missing full address
    let configWithoutAddress = """
    username:s:testuser
    session bpp:i:32
    """
    
    let jmsConfig1 = JMSConfig(
        filename: "test.rdp",
        protocol: "rdp",
        username: "testuser",
        token: "testtoken",
        config: configWithoutAddress
    )
    
    do {
        _ = try extractor.extractConnectionInfo(from: jmsConfig1)
        print("❌ Should have thrown error for missing full address")
    } catch JMSError.missingConnectionInfo {
        print("✅ Correctly caught missing full address error")
    } catch {
        print("❌ Wrong error type for missing full address: \(error)")
    }
    
    // Test missing username
    let configWithoutUsername = """
    full address:s:test-server.com:3389
    session bpp:i:32
    """
    
    let jmsConfig2 = JMSConfig(
        filename: "test.rdp",
        protocol: "rdp",
        username: "testuser",
        token: "testtoken",
        config: configWithoutUsername
    )
    
    do {
        _ = try extractor.extractConnectionInfo(from: jmsConfig2)
        print("❌ Should have thrown error for missing username")
    } catch JMSError.missingConnectionInfo {
        print("✅ Correctly caught missing username error")
    } catch {
        print("❌ Wrong error type for missing username: \(error)")
    }
}

func testConfigParsing() {
    print("Testing config string parsing...")
    
    let extractor = ConnectionInfoExtractor()
    let configString = """
    full address:s:develop-jumpserver.jlcops.com:3389
    username:s:gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53
    session bpp:i:32
    audiomode:i:0
    """
    
    do {
        let result = try extractor.parseConfigString(configString)
        
        assert(result["full address"] == "develop-jumpserver.jlcops.com:3389", "Full address parsing failed")
        assert(result["username"] == "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53", "Username parsing failed")
        assert(result["session bpp"] == "32", "Session BPP parsing failed")
        assert(result["audiomode"] == "0", "Audio mode parsing failed")
        
        print("✅ Config parsing test passed")
    } catch {
        print("❌ Config parsing test failed: \(error)")
    }
}

func testAdditionalConfig() {
    print("Testing additional config parameters...")
    
    let extractor = ConnectionInfoExtractor()
    let configString = """
    full address:s:test-server.com:3389
    username:s:testuser
    session bpp:i:24
    custom param:s:custom value
    another setting:i:42
    desktopwidth:i:1920
    desktopheight:i:1080
    """
    
    let jmsConfig = JMSConfig(
        filename: "test.rdp",
        protocol: "rdp",
        username: "testuser",
        token: "testtoken",
        config: configString
    )
    
    do {
        let connectionInfo = try extractor.extractConnectionInfo(from: jmsConfig)
        
        assert(connectionInfo.fullAddress == "test-server.com:3389", "Full address mismatch")
        assert(connectionInfo.username == "testuser", "Username mismatch")
        assert(connectionInfo.sessionBpp == 24, "Session BPP mismatch")
        assert(connectionInfo.additionalConfig["custom param"] == "custom value", "Custom param mismatch")
        assert(connectionInfo.additionalConfig["another setting"] == "42", "Another setting mismatch")
        assert(connectionInfo.additionalConfig["desktopwidth"] == "1920", "Desktop width mismatch")
        assert(connectionInfo.additionalConfig["desktopheight"] == "1080", "Desktop height mismatch")
        
        print("✅ Additional config test passed")
    } catch {
        print("❌ Additional config test failed: \(error)")
    }
}

func testInvalidConfigFormat() {
    print("Testing invalid config format...")
    
    let extractor = ConnectionInfoExtractor()
    let invalidConfigString = "full address:develop-jumpserver.jlcops.com:3389" // Missing type
    
    do {
        let result = try extractor.parseConfigString(invalidConfigString)
        print("❌ Should have thrown error for invalid config format, but got result: \(result)")
    } catch JMSError.configParsingFailed {
        print("✅ Correctly caught invalid config format error")
    } catch {
        print("❌ Wrong error type for invalid config format: \(error)")
    }
}

// Run all tests
print("🧪 Running ConnectionInfoExtractor validation tests...\n")

testBasicExtraction()
testMissingRequiredFields()
testConfigParsing()
testAdditionalConfig()
testInvalidConfigFormat()

print("\n✅ All ConnectionInfoExtractor validation tests completed!")