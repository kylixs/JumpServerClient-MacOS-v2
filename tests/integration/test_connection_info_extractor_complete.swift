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

struct JMSConfig: Codable {
    let filename: String
    let `protocol`: String
    let username: String
    let token: String
    let config: String
    
    enum CodingKeys: String, CodingKey {
        case filename, `protocol`, username, token, config
    }
    
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
    
    var isRDPProtocol: Bool {
        return `protocol`.lowercased() == "rdp"
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

// Test the implementation
func runTests() {
    let extractor = ConnectionInfoExtractor()
    
    print("🧪 Testing ConnectionInfoExtractor...")
    
    // Test 1: Valid configuration
    do {
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
        
        let connectionInfo = try extractor.extractConnectionInfo(from: jmsConfig)
        
        print("✅ Test 1 - Valid configuration:")
        print("   Full Address: \(connectionInfo.fullAddress)")
        print("   Username: \(connectionInfo.username)")
        print("   Session BPP: \(connectionInfo.sessionBpp ?? -1)")
        print("   Audio Mode: \(connectionInfo.audioMode ?? -1)")
        print("   Smart Sizing: \(connectionInfo.smartSizing ?? false)")
        print("   Screen Mode ID: \(connectionInfo.screenModeId ?? -1)")
        print("   Hostname: \(connectionInfo.hostname)")
        print("   Port: \(connectionInfo.port)")
        print("   Additional Config: \(connectionInfo.additionalConfig)")
        
        assert(connectionInfo.fullAddress == "develop-jumpserver.jlcops.com:3389")
        assert(connectionInfo.username == "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53")
        assert(connectionInfo.sessionBpp == 32)
        assert(connectionInfo.audioMode == 0)
        assert(connectionInfo.smartSizing == true)
        assert(connectionInfo.screenModeId == 2)
        assert(connectionInfo.hostname == "develop-jumpserver.jlcops.com")
        assert(connectionInfo.port == 3389)
        assert(connectionInfo.additionalConfig["desktopwidth"] == "1920")
        assert(connectionInfo.additionalConfig["desktopheight"] == "1080")
        
    } catch {
        print("❌ Test 1 failed: \(error)")
        return
    }
    
    // Test 2: Missing full address
    do {
        let configString = """
        username:s:testuser
        session bpp:i:32
        """
        
        let jmsConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: configString
        )
        
        _ = try extractor.extractConnectionInfo(from: jmsConfig)
        print("❌ Test 2 should have failed")
        return
    } catch JMSError.missingConnectionInfo {
        print("✅ Test 2 - Missing full address correctly throws error")
    } catch {
        print("❌ Test 2 failed with unexpected error: \(error)")
        return
    }
    
    // Test 3: Parse config string
    do {
        let configString = """
        full address:s:test-server.com:3389
        username:s:testuser
        session bpp:i:24
        custom param:s:custom value
        """
        
        let result = try extractor.parseConfigString(configString)
        
        print("✅ Test 3 - Parse config string:")
        print("   Parsed parameters: \(result)")
        
        assert(result["full address"] == "test-server.com:3389")
        assert(result["username"] == "testuser")
        assert(result["session bpp"] == "24")
        assert(result["custom param"] == "custom value")
        
    } catch {
        print("❌ Test 3 failed: \(error)")
        return
    }
    
    // Test 4: Extract value
    let configParams = [
        "full address": "test-server.com:3389",
        "username": "testuser"
    ]
    
    let fullAddress = extractor.extractValue(for: "full address", from: configParams)
    let nonExistent = extractor.extractValue(for: "nonexistent", from: configParams)
    
    print("✅ Test 4 - Extract value:")
    print("   Full address: \(fullAddress ?? "nil")")
    print("   Non-existent: \(nonExistent ?? "nil")")
    
    assert(fullAddress == "test-server.com:3389")
    assert(nonExistent == nil)
    
    print("\n🎉 All tests passed! ConnectionInfoExtractor implementation is working correctly.")
}

runTests()