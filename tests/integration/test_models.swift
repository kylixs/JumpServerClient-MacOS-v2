#!/usr/bin/env swift

import Foundation

// Copy the models here for testing
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
print("Testing JMS data models...")

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

print("✅ RDP protocol check: \(config.isRDPProtocol)")

// Test JSON encoding/decoding
do {
    let jsonData = try JSONEncoder().encode(config)
    let _ = try JSONDecoder().decode(JMSConfig.self, from: jsonData)
    print("✅ JSON encoding/decoding works")
} catch {
    print("❌ JSON encoding/decoding failed: \(error)")
}

print("All tests completed!")