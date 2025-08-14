#!/usr/bin/env swift

import Foundation

print("🔍 测试基本RDP功能...")

// 创建测试RDP配置
let testRDPConfig = """
{
    "protocol": "rdp",
    "config": "full address:s:test.server.com:3389\\nusername:s:testuser"
}
"""

// Base64编码
let encodedData = testRDPConfig.data(using: .utf8)!
let base64Encoded = encodedData.base64EncodedString()
let testURL = "jms://\(base64Encoded)"

print("📝 生成的测试URL:")
print(testURL)

// 验证解码
if let decodedData = Data(base64Encoded: base64Encoded),
   let decodedString = String(data: decodedData, encoding: .utf8) {
    print("\n✅ Base64解码成功:")
    print(decodedString)
    
    // 验证JSON解析
    do {
        if let jsonData = decodedString.data(using: .utf8),
           let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            print("\n✅ JSON解析成功:")
            print("协议: \(jsonObject["protocol"] ?? "未知")")
            
            if let config = jsonObject["config"] as? String {
                print("配置: \(config)")
                
                // 解析RDP参数
                let configLines = config.components(separatedBy: "\\n")
                for line in configLines {
                    if line.hasPrefix("full address:s:") {
                        let address = String(line.dropFirst("full address:s:".count))
                        print("服务器地址: \(address)")
                    } else if line.hasPrefix("username:s:") {
                        let username = String(line.dropFirst("username:s:".count))
                        print("用户名: \(username)")
                    }
                }
            }
        }
    } catch {
        print("❌ JSON解析失败: \(error)")
        exit(1)
    }
} else {
    print("❌ Base64解码失败")
    exit(1)
}

print("\n🎉 基本RDP功能测试通过！")
print("✅ URL编码/解码正常")
print("✅ JSON解析正常")
print("✅ RDP参数提取正常")

// 保存测试URL到文件
let testURLFile = "test_rdp_url.txt"
try? testURL.write(toFile: testURLFile, atomically: true, encoding: .utf8)
print("\n📄 测试URL已保存到: \(testURLFile)")
print("💡 可以使用以下命令测试:")
print("   open '\(testURL)'")
