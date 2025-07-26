#!/usr/bin/env swift

import Foundation

// Copy the data models here for testing
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

// Test the models
print("Testing JMS Data Models...")

// Test JMSConfig
let config = JMSConfig(
    filename: "test.rdp",
    protocol: "rdp",
    username: "testuser",
    token: "testtoken",
    config: "full address:s:test.com:3389"
)

do {
    try config.validate()
    print("✅ JMSConfig validation passed")
} catch {
    print("❌ JMSConfig validation failed: \(error)")
}

print("✅ JMSConfig isRDPProtocol: \(config.isRDPProtocol)")

// Test ConnectionInfo
let connectionInfo = ConnectionInfo(
    fullAddress: "develop-jumpserver.jlcops.com:3389",
    username: "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53",
    sessionBpp: 32,
    audioMode: 0
)

do {
    try connectionInfo.validate()
    print("✅ ConnectionInfo validation passed")
} catch {
    print("❌ ConnectionInfo validation failed: \(error)")
}

print("✅ ConnectionInfo hostname: \(connectionInfo.hostname)")
print("✅ ConnectionInfo port: \(connectionInfo.port)")

// Test JSON encoding/decoding
do {
    let jsonData = try JSONEncoder().encode(config)
    let decodedConfig = try JSONDecoder().decode(JMSConfig.self, from: jsonData)
    print("✅ JMSConfig JSON encoding/decoding passed")
} catch {
    print("❌ JMSConfig JSON encoding/decoding failed: \(error)")
}

print("All data model tests completed!")