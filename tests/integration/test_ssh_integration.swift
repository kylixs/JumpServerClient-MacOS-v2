#!/usr/bin/env swift

import Foundation
import Cocoa

// MARK: - SSH Integration Test

/// SSH集成测试
/// 测试SSH协议的完整工作流程，包括URL解析、连接信息提取和终端启动

print("🧪 开始SSH集成测试...")

// 测试数据：基于提供的SSH连接信息
let testSSHData = """
{
  "filename": "gongdewei-gn-repo-192_168_2_221-jumpserver",
  "protocol": "ssh",
  "username": "gongdewei",
  "token": "{\\"ip\\": \\"fat-jumpserver.jlc.com\\", \\"port\\": \\"2222\\", \\"username\\": \\"JMS-26307eea-9f95-4080-8381-3c62e9e407f2\\", \\"password\\": \\"bfAMUXKl3ZaCpcxK\\"}",
  "config": ""
}
"""

// 编码为base64
let base64EncodedData = Data(testSSHData.utf8).base64EncodedString()
let testURL = "jms://\(base64EncodedData)"

print("📋 测试数据准备完成")
print("   协议类型: SSH")
print("   服务器: fat-jumpserver.jlc.com:2222")
print("   用户名: JMS-26307eea-9f95-4080-8381-3c62e9e407f2")
print("   URL长度: \(testURL.count) 字符")

// MARK: - 模拟数据模型

struct JMSConfig: Codable {
    let filename: String
    let `protocol`: String  // 使用反引号转义关键字
    let username: String
    let token: String
    let config: String
}

struct SSHToken: Codable {
    let ip: String
    let port: String
    let username: String
    let password: String
}

struct SSHConnectionInfo {
    let ip: String
    let port: String
    let username: String
    let password: String
    let filename: String
    
    var connectionString: String {
        return "\(username)@\(ip):\(port)"
    }
    
    func validate() throws {
        guard !ip.isEmpty, !port.isEmpty, !username.isEmpty, !password.isEmpty else {
            throw NSError(domain: "SSHError", code: 1, userInfo: [NSLocalizedDescriptionKey: "缺少必要的SSH连接信息"])
        }
        
        guard Int(port) != nil else {
            throw NSError(domain: "SSHError", code: 2, userInfo: [NSLocalizedDescriptionKey: "端口号格式无效"])
        }
    }
}

enum TerminalApp {
    case iterm2, terminal, unavailable
    
    var displayName: String {
        switch self {
        case .iterm2: return "iTerm2"
        case .terminal: return "Terminal"
        case .unavailable: return "无可用终端"
        }
    }
    
    var bundleIdentifier: String? {
        switch self {
        case .iterm2: return "com.googlecode.iterm2"
        case .terminal: return "com.apple.Terminal"
        case .unavailable: return nil
        }
    }
}

// MARK: - 测试函数

func testURLParsing() throws {
    print("\n🔍 测试1: URL解析")
    
    guard let url = URL(string: testURL) else {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "URL创建失败"])
    }
    
    guard url.scheme?.lowercased() == "jms" else {
        throw NSError(domain: "TestError", code: 2, userInfo: [NSLocalizedDescriptionKey: "URL协议错误"])
    }
    
    guard let host = url.host, !host.isEmpty else {
        throw NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "URL payload为空"])
    }
    
    print("   ✅ URL解析成功")
    print("   📊 Scheme: \(url.scheme ?? "nil")")
    print("   📊 Payload长度: \(host.count)")
}

func testBase64Decoding() throws -> JMSConfig {
    print("\n🔓 测试2: Base64解码和JSON解析")
    
    guard let url = URL(string: testURL),
          let host = url.host else {
        throw NSError(domain: "TestError", code: 4, userInfo: [NSLocalizedDescriptionKey: "URL解析失败"])
    }
    
    guard let decodedData = Data(base64Encoded: host) else {
        throw NSError(domain: "TestError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Base64解码失败"])
    }
    
    let decoder = JSONDecoder()
    let jmsConfig = try decoder.decode(JMSConfig.self, from: decodedData)
    
    print("   ✅ 解码成功")
    print("   📊 协议类型: \(jmsConfig.protocol)")
    print("   📊 文件名: \(jmsConfig.filename)")
    print("   📊 用户名: \(jmsConfig.username)")
    print("   📊 Token长度: \(jmsConfig.token.count)")
    
    return jmsConfig
}

func testSSHTokenParsing(_ jmsConfig: JMSConfig) throws -> SSHConnectionInfo {
    print("\n🔑 测试3: SSH Token解析")
    
    guard jmsConfig.protocol.lowercased() == "ssh" else {
        throw NSError(domain: "TestError", code: 6, userInfo: [NSLocalizedDescriptionKey: "协议类型不是SSH"])
    }
    
    guard !jmsConfig.token.isEmpty else {
        throw NSError(domain: "TestError", code: 7, userInfo: [NSLocalizedDescriptionKey: "SSH Token为空"])
    }
    
    guard let tokenData = jmsConfig.token.data(using: .utf8) else {
        throw NSError(domain: "TestError", code: 8, userInfo: [NSLocalizedDescriptionKey: "Token编码失败"])
    }
    
    let decoder = JSONDecoder()
    let sshToken = try decoder.decode(SSHToken.self, from: tokenData)
    
    let sshConnectionInfo = SSHConnectionInfo(
        ip: sshToken.ip,
        port: sshToken.port,
        username: sshToken.username,
        password: sshToken.password,
        filename: jmsConfig.filename
    )
    
    try sshConnectionInfo.validate()
    
    print("   ✅ SSH Token解析成功")
    print("   📊 服务器: \(sshConnectionInfo.ip)")
    print("   📊 端口: \(sshConnectionInfo.port)")
    print("   📊 用户名: \(sshConnectionInfo.username)")
    print("   📊 密码长度: \(sshConnectionInfo.password.count)")
    print("   📊 连接字符串: \(sshConnectionInfo.connectionString)")
    
    return sshConnectionInfo
}

func testTerminalDetection() -> TerminalApp {
    print("\n🖥️  测试4: 终端应用程序检测")
    
    // 检测iTerm2
    if let _ = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.googlecode.iterm2") {
        print("   ✅ 检测到iTerm2")
        return .iterm2
    }
    
    // 检测Terminal
    if let _ = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") {
        print("   ✅ 检测到系统Terminal")
        return .terminal
    }
    
    print("   ❌ 未检测到可用终端")
    return .unavailable
}

func testExpectAvailability() -> Bool {
    print("\n⚡ 测试5: Expect工具检测")
    
    let process = Process()
    process.launchPath = "/usr/bin/which"
    process.arguments = ["expect"]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    
    do {
        try process.run()
        process.waitUntilExit()
        
        let available = process.terminationStatus == 0
        if available {
            print("   ✅ Expect工具可用")
        } else {
            print("   ⚠️  Expect工具不可用，需要手动输入密码")
        }
        return available
    } catch {
        print("   ❌ Expect检测失败: \(error)")
        return false
    }
}

func testSSHCommandBuilding(_ sshInfo: SSHConnectionInfo, expectAvailable: Bool) -> String {
    print("\n🔨 测试6: SSH命令构建")
    
    let sshCommand: String
    
    if expectAvailable {
        // 构建expect脚本
        let escapedPassword = sshInfo.password.replacingOccurrences(of: "\"", with: "\\\"")
        sshCommand = """
        expect -c "
        set timeout 30
        spawn ssh -p \(sshInfo.port) \(sshInfo.username)@\(sshInfo.ip)
        expect {
            \\"*password*\\" {
                send \\"\(escapedPassword)\\r\\"
                exp_continue
            }
            \\"*yes/no*\\" {
                send \\"yes\\r\\"
                exp_continue
            }
            \\"*$\\" {
                interact
            }
            timeout {
                puts \\"连接超时\\"
                exit 1
            }
            eof {
                puts \\"连接已断开\\"
                exit 0
            }
        }
        "
        """
        print("   ✅ 构建expect自动化SSH命令")
    } else {
        // 构建基本SSH命令
        sshCommand = "ssh -p \(sshInfo.port) \(sshInfo.username)@\(sshInfo.ip)"
        print("   ✅ 构建基本SSH命令")
    }
    
    print("   📊 命令长度: \(sshCommand.count) 字符")
    return sshCommand
}

func testAppleScriptGeneration(_ terminalApp: TerminalApp, sshCommand: String) -> String {
    print("\n📜 测试7: AppleScript生成")
    
    let escapedCommand = sshCommand.replacingOccurrences(of: "\"", with: "\\\"")
    let appleScript: String
    
    switch terminalApp {
    case .iterm2:
        appleScript = """
        tell application "iTerm"
            activate
            create window with default profile
            tell current session of current window
                write text "\(escapedCommand)"
            end tell
        end tell
        """
        print("   ✅ 生成iTerm2 AppleScript")
        
    case .terminal:
        appleScript = """
        tell application "Terminal"
            activate
            do script "\(escapedCommand)"
        end tell
        """
        print("   ✅ 生成Terminal AppleScript")
        
    case .unavailable:
        appleScript = ""
        print("   ❌ 无可用终端，无法生成AppleScript")
    }
    
    print("   📊 脚本长度: \(appleScript.count) 字符")
    return appleScript
}

// MARK: - 主测试流程

func runSSHIntegrationTest() {
    do {
        // 测试1: URL解析
        try testURLParsing()
        
        // 测试2: Base64解码和JSON解析
        let jmsConfig = try testBase64Decoding()
        
        // 测试3: SSH Token解析
        let sshConnectionInfo = try testSSHTokenParsing(jmsConfig)
        
        // 测试4: 终端应用程序检测
        let terminalApp = testTerminalDetection()
        
        // 测试5: Expect工具检测
        let expectAvailable = testExpectAvailability()
        
        // 测试6: SSH命令构建
        let sshCommand = testSSHCommandBuilding(sshConnectionInfo, expectAvailable: expectAvailable)
        
        // 测试7: AppleScript生成
        let appleScript = testAppleScriptGeneration(terminalApp, sshCommand: sshCommand)
        
        // 测试总结
        print("\n📊 SSH集成测试总结")
        print("   ✅ URL解析: 通过")
        print("   ✅ Base64解码: 通过")
        print("   ✅ SSH Token解析: 通过")
        print("   ✅ 终端检测: \(terminalApp.displayName)")
        print("   \(expectAvailable ? "✅" : "⚠️") Expect工具: \(expectAvailable ? "可用" : "不可用")")
        print("   ✅ SSH命令构建: 通过")
        print("   \(appleScript.isEmpty ? "❌" : "✅") AppleScript生成: \(appleScript.isEmpty ? "失败" : "通过")")
        
        if terminalApp != .unavailable {
            print("\n🎉 SSH集成测试全部通过！")
            print("💡 提示：实际使用时会自动启动\(terminalApp.displayName)并建立SSH连接")
            
            if !expectAvailable {
                print("⚠️  注意：由于expect工具不可用，需要手动输入SSH密码")
                print("💡 建议安装expect工具：brew install expect")
            }
        } else {
            print("\n❌ SSH集成测试部分失败：无可用终端应用程序")
            print("💡 建议：安装iTerm2或确保系统Terminal可用")
        }
        
    } catch {
        print("\n❌ SSH集成测试失败: \(error.localizedDescription)")
        exit(1)
    }
}

// 运行测试
runSSHIntegrationTest()
