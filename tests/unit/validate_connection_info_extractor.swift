#!/usr/bin/env swift

import Foundation

// Copy the necessary models and protocols
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
    
    func generateRDPContent() -> String {
        var rdpContent = [
            "full address:s:\(fullAddress)",
            "username:s:\(username)"
        ]
        
        if let sessionBpp = sessionBpp {
            rdpContent.append("session bpp:i:\(sessionBpp)")
        }
        
        if let audioMode = audioMode {
            rdpContent.append("audiomode:i:\(audioMode)")
        }
        
        if let smartSizing = smartSizing {
            rdpContent.append("smart sizing:i:\(smartSizing ? 1 : 0)")
        }
        
        if let screenModeId = screenModeId {
            rdpContent.append("screen mode id:i:\(screenModeId)")
        }
        
        for (key, value) in additionalConfig {
            rdpContent.append("\(key):\(value)")
        }
        
        return rdpContent.joined(separator: "\n")
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
                    } else {
                        throw JMSError.configParsingFailed
                    }
                } else {
                    throw JMSError.configParsingFailed
                }
            } else {
                throw JMSError.configParsingFailed
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

// Comprehensive validation tests
func runValidationTests() {
    let extractor = ConnectionInfoExtractor()
    var testsPassed = 0
    var testsTotal = 0
    
    func test(_ name: String, _ testBlock: () throws -> Void) {
        testsTotal += 1
        do {
            try testBlock()
            print("✅ \(name)")
            testsPassed += 1
        } catch {
            print("❌ \(name): \(error)")
        }
    }
    
    print("🧪 Running Connection Info Extractor Validation Tests")
    print(String(repeating: "=", count: 60))
    
    // Test 1: Real-world example from requirements
    test("Real-world example extraction") {
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
        
        // Verify required fields
        guard connectionInfo.fullAddress == "develop-jumpserver.jlcops.com:3389" else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Full address mismatch"])
        }
        guard connectionInfo.username == "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53" else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Username mismatch"])
        }
        
        // Verify RDP parameters
        guard connectionInfo.sessionBpp == 32 else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Session BPP mismatch"])
        }
        guard connectionInfo.audioMode == 0 else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Audio mode mismatch"])
        }
        guard connectionInfo.smartSizing == true else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Smart sizing mismatch"])
        }
        guard connectionInfo.screenModeId == 2 else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Screen mode ID mismatch"])
        }
        
        // Verify additional config
        guard connectionInfo.additionalConfig["desktopwidth"] == "1920" else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Desktop width mismatch"])
        }
        guard connectionInfo.additionalConfig["desktopheight"] == "1080" else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Desktop height mismatch"])
        }
        
        // Verify hostname and port extraction
        guard connectionInfo.hostname == "develop-jumpserver.jlcops.com" else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Hostname extraction failed"])
        }
        guard connectionInfo.port == 3389 else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Port extraction failed"])
        }
    }
    
    // Test 2: All RDP parameters
    test("All RDP parameters extraction") {
        let configString = """
        full address:s:test-server.com:3390
        username:s:testuser
        session bpp:i:24
        audiomode:i:2
        smart sizing:i:0
        screen mode id:i:1
        compression:i:1
        keyboardhook:i:2
        redirectclipboard:i:1
        """
        
        let jmsConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: configString
        )
        
        let connectionInfo = try extractor.extractConnectionInfo(from: jmsConfig)
        
        guard connectionInfo.sessionBpp == 24 else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Session BPP mismatch"])
        }
        guard connectionInfo.audioMode == 2 else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Audio mode mismatch"])
        }
        guard connectionInfo.smartSizing == false else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Smart sizing mismatch"])
        }
        guard connectionInfo.screenModeId == 1 else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Screen mode ID mismatch"])
        }
        guard connectionInfo.additionalConfig["compression"] == "1" else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Compression mismatch"])
        }
        guard connectionInfo.additionalConfig["keyboardhook"] == "2" else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Keyboard hook mismatch"])
        }
        guard connectionInfo.additionalConfig["redirectclipboard"] == "1" else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Redirect clipboard mismatch"])
        }
        
        // Test port extraction
        guard connectionInfo.port == 3390 else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Custom port extraction failed"])
        }
    }
    
    // Test 3: Error handling - missing full address
    test("Missing full address error handling") {
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
        
        do {
            _ = try extractor.extractConnectionInfo(from: jmsConfig)
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Should have thrown error"])
        } catch JMSError.missingConnectionInfo {
            // Expected error
        } catch {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Wrong error type: \(error)"])
        }
    }
    
    // Test 4: Error handling - missing username
    test("Missing username error handling") {
        let configString = """
        full address:s:test-server.com:3389
        session bpp:i:32
        """
        
        let jmsConfig = JMSConfig(
            filename: "test.rdp",
            protocol: "rdp",
            username: "testuser",
            token: "testtoken",
            config: configString
        )
        
        do {
            _ = try extractor.extractConnectionInfo(from: jmsConfig)
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Should have thrown error"])
        } catch JMSError.missingConnectionInfo {
            // Expected error
        } catch {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Wrong error type: \(error)"])
        }
    }
    
    // Test 5: Error handling - invalid config format
    test("Invalid config format error handling") {
        let configString = "full address:develop-jumpserver.jlcops.com:3389"
        
        do {
            _ = try extractor.parseConfigString(configString)
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Should have thrown error"])
        } catch JMSError.configParsingFailed {
            // Expected error
        } catch {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Wrong error type: \(error)"])
        }
    }
    
    // Test 6: Error handling - invalid type
    test("Invalid type error handling") {
        let configString = """
        full address:s:test-server.com:3389
        invalid param:x:should fail
        username:s:testuser
        """
        
        do {
            _ = try extractor.parseConfigString(configString)
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Should have thrown error"])
        } catch JMSError.configParsingFailed {
            // Expected error
        } catch {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Wrong error type: \(error)"])
        }
    }
    
    // Test 7: RDP content generation
    test("RDP content generation") {
        let connectionInfo = ConnectionInfo(
            fullAddress: "test-server.com:3389",
            username: "testuser",
            sessionBpp: 32,
            audioMode: 0,
            smartSizing: true,
            screenModeId: 2,
            additionalConfig: ["desktopwidth": "1920", "desktopheight": "1080"]
        )
        
        let rdpContent = connectionInfo.generateRDPContent()
        
        guard rdpContent.contains("full address:s:test-server.com:3389") else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "RDP content missing full address"])
        }
        guard rdpContent.contains("username:s:testuser") else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "RDP content missing username"])
        }
        guard rdpContent.contains("session bpp:i:32") else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "RDP content missing session bpp"])
        }
        guard rdpContent.contains("smart sizing:i:1") else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "RDP content missing smart sizing"])
        }
        guard rdpContent.contains("desktopwidth:1920") else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "RDP content missing additional config"])
        }
    }
    
    print(String(repeating: "=", count: 60))
    print("📊 Validation Results: \(testsPassed)/\(testsTotal) tests passed")
    
    if testsPassed == testsTotal {
        print("🎉 All validation tests passed!")
        print("✨ Connection Info Extractor implementation is complete and working correctly")
    } else {
        print("⚠️  Some validation tests failed")
    }
}

runValidationTests()