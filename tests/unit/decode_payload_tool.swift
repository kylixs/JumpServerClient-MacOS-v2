#!/usr/bin/env swift

// JMS Payload解码工具
// 用于解码和分析JMS协议的payload内容

import Foundation

func printUsage() {
    print("""
    JMS Payload解码工具
    
    用法:
        swift decode_payload_tool.swift <payload>
        swift decode_payload_tool.swift <jms_url>
    
    示例:
        swift decode_payload_tool.swift eyJwcm90b2NvbCI6InJkcCIsImhvc3QiOiIxOTIuMTY4LjEuMTAwIn0=
        swift decode_payload_tool.swift "jms://eyJwcm90b2NvbCI6InJkcCIsImhvc3QiOiIxOTIuMTY4LjEuMTAwIn0="
    
    功能:
        - Base64解码
        - JSON格式化
        - 字段分析
        - 协议类型识别
    """)
}

func decodePayload(_ input: String) {
    print("🔍 JMS Payload解码工具")
    print(String(repeating: "=", count: 50))
    
    // 提取payload
    var payload = input
    if input.hasPrefix("jms://") {
        payload = String(input.dropFirst(6))
        print("📋 输入类型: JMS URL")
        print("🔗 完整URL: \(input)")
    } else {
        print("📋 输入类型: Base64 Payload")
    }
    
    print("📄 原始Payload: \(payload)")
    print("")
    
    // Base64解码
    print("🔓 Base64解码...")
    guard let decodedData = Data(base64Encoded: payload) else {
        print("❌ Base64解码失败")
        print("💡 请检查payload格式是否正确")
        return
    }
    
    guard let decodedString = String(data: decodedData, encoding: .utf8) else {
        print("❌ 字符串转换失败")
        return
    }
    
    print("✅ 解码成功")
    print("📄 解码后内容: \(decodedString)")
    print("")
    
    // JSON解析
    print("📊 JSON解析...")
    do {
        guard let jsonObject = try JSONSerialization.jsonObject(with: decodedData) as? [String: Any] else {
            print("❌ JSON解析失败：不是字典类型")
            return
        }
        
        print("✅ JSON解析成功")
        print("")
        
        // 格式化输出
        print("📋 字段分析:")
        print(String(repeating: "-", count: 30))
        
        for (key, value) in jsonObject.sorted(by: { $0.key < $1.key }) {
            let valueStr = "\(value)"
            if valueStr.count > 100 {
                print("   \(key): \(valueStr.prefix(100))...")
            } else {
                print("   \(key): \(value)")
            }
        }
        
        print("")
        
        // 协议分析
        print("🔍 协议分析:")
        print(String(repeating: "-", count: 30))
        
        if let protocol_type = jsonObject["protocol"] as? String {
            print("   协议类型: \(protocol_type.uppercased())")
            
            switch protocol_type.lowercased() {
            case "rdp":
                analyzeRDPPayload(jsonObject)
            case "ssh":
                analyzeSSHPayload(jsonObject)
            default:
                print("   ⚠️ 未知协议类型")
            }
        } else {
            print("   ❌ 缺少协议类型字段")
        }
        
        // 格式化JSON输出
        if let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            print("")
            print("📄 格式化JSON:")
            print(String(repeating: "-", count: 30))
            print(prettyString)
        }
        
    } catch {
        print("❌ JSON解析错误: \(error.localizedDescription)")
    }
}

func analyzeRDPPayload(_ json: [String: Any]) {
    print("   📊 RDP协议分析:")
    
    // 检查必需字段
    if let config = json["config"] as? String {
        print("     ✅ 包含RDP配置文件")
        print("     📏 配置长度: \(config.count) 字符")
        
        // 分析配置内容
        let lines = config.components(separatedBy: .newlines)
        print("     📋 配置行数: \(lines.count)")
        
        // 提取关键配置
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("full address:") {
                print("     🖥️ 服务器: \(trimmed)")
            } else if trimmed.hasPrefix("username:") {
                print("     👤 用户名: \(trimmed)")
            } else if trimmed.hasPrefix("desktopwidth:") {
                print("     📐 宽度: \(trimmed)")
            } else if trimmed.hasPrefix("desktopheight:") {
                print("     📐 高度: \(trimmed)")
            }
        }
    } else {
        print("     ❌ 缺少RDP配置文件")
    }
    
    if let username = json["username"] as? String {
        print("     👤 用户名: \(username)")
    }
    
    if let filename = json["filename"] as? String {
        print("     📄 文件名: \(filename)")
    }
}

func analyzeSSHPayload(_ json: [String: Any]) {
    print("   📊 SSH协议分析:")
    
    if let token = json["token"] as? String {
        print("     ✅ 包含SSH token")
        print("     📏 Token长度: \(token.count) 字符")
        
        // 尝试解析token
        if let tokenData = token.data(using: .utf8),
           let tokenJson = try? JSONSerialization.jsonObject(with: tokenData) as? [String: Any] {
            print("     📊 Token内容:")
            for (key, value) in tokenJson {
                print("       \(key): \(value)")
            }
        }
    } else {
        print("     ❌ 缺少SSH token")
    }
}

// 主程序
if CommandLine.arguments.count < 2 {
    printUsage()
    exit(1)
}

let input = CommandLine.arguments[1]
decodePayload(input)
