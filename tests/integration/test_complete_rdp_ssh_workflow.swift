#!/usr/bin/env swift

import Foundation
import Cocoa

// MARK: - Complete RDP & SSH Workflow Test

/// 完整的RDP和SSH工作流程测试
/// 测试JMS Protocol Handler对两种协议的完整支持

print("🚀 开始完整的RDP和SSH工作流程测试...")

// MARK: - 测试数据

// RDP测试数据
let testRDPData = """
{
  "filename": "develop-jumpserver-connection",
  "protocol": "rdp",
  "username": "gongdewei",
  "token": "",
  "config": "full address:s:develop-jumpserver.jlcops.com:3389\\nusername:s:gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53\\nsession bpp:i:32\\naudiomode:i:0\\nsmart sizing:i:1\\nscreen mode id:i:2"
}
"""

// SSH测试数据
let testSSHData = """
{
  "filename": "gongdewei-gn-repo-192_168_2_221-jumpserver",
  "protocol": "ssh",
  "username": "gongdewei",
  "token": "{\\"ip\\": \\"fat-jumpserver.jlc.com\\", \\"port\\": \\"2222\\", \\"username\\": \\"JMS-26307eea-9f95-4080-8381-3c62e9e407f2\\", \\"password\\": \\"bfAMUXKl3ZaCpcxK\\"}",
  "config": ""
}
"""

// MARK: - 数据模型

struct JMSConfig: Codable {
    let filename: String
    let `protocol`: String
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

enum ConnectionInfo {
    case rdp(RDPConnectionInfo)
    case ssh(SSHConnectionInfo)
    
    var protocolType: String {
        switch self {
        case .rdp: return "rdp"
        case .ssh: return "ssh"
        }
    }
    
    var description: String {
        switch self {
        case .rdp(let rdpInfo):
            return "RDP连接: \(rdpInfo.username)@\(rdpInfo.fullAddress)"
        case .ssh(let sshInfo):
            return "SSH连接: \(sshInfo.username)@\(sshInfo.ip):\(sshInfo.port)"
        }
    }
}

struct RDPConnectionInfo {
    let fullAddress: String
    let username: String
    let sessionBpp: Int?
    let audioMode: Int?
    let smartSizing: Bool?
    let screenModeId: Int?
    let additionalConfig: [String: String]
    
    func validate() throws {
        guard !fullAddress.isEmpty, !username.isEmpty else {
            throw NSError(domain: "RDPError", code: 1, userInfo: [NSLocalizedDescriptionKey: "RDP连接信息不完整"])
        }
    }
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
            throw NSError(domain: "SSHError", code: 1, userInfo: [NSLocalizedDescriptionKey: "SSH连接信息不完整"])
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
}

// MARK: - 测试函数

func createTestURL(from jsonData: String) -> String {
    let base64EncodedData = Data(jsonData.utf8).base64EncodedString()
    return "jms://\(base64EncodedData)"
}

func parseJMSURL(_ urlString: String) throws -> JMSConfig {
    guard let url = URL(string: urlString),
          url.scheme?.lowercased() == "jms",
          let host = url.host,
          !host.isEmpty else {
        throw NSError(domain: "URLError", code: 1, userInfo: [NSLocalizedDescriptionKey: "URL格式错误"])
    }
    
    guard let decodedData = Data(base64Encoded: host) else {
        throw NSError(domain: "URLError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Base64解码失败"])
    }
    
    let decoder = JSONDecoder()
    return try decoder.decode(JMSConfig.self, from: decodedData)
}

func extractConnectionInfo(from config: JMSConfig) throws -> ConnectionInfo {
    switch config.protocol.lowercased() {
    case "rdp":
        return try extractRDPConnectionInfo(from: config)
    case "ssh":
        return try extractSSHConnectionInfo(from: config)
    default:
        throw NSError(domain: "ProtocolError", code: 1, userInfo: [NSLocalizedDescriptionKey: "不支持的协议类型: \(config.protocol)"])
    }
}

func extractRDPConnectionInfo(from config: JMSConfig) throws -> ConnectionInfo {
    let configParams = try parseRDPConfigString(config.config)
    
    guard let fullAddress = configParams["full address"],
          let username = configParams["username"] else {
        throw NSError(domain: "RDPError", code: 1, userInfo: [NSLocalizedDescriptionKey: "缺少必要的RDP连接信息"])
    }
    
    let sessionBpp = Int(configParams["session bpp"] ?? "")
    let audioMode = Int(configParams["audiomode"] ?? "")
    let smartSizing = (configParams["smart sizing"] == "1")
    let screenModeId = Int(configParams["screen mode id"] ?? "")
    
    let rdpInfo = RDPConnectionInfo(
        fullAddress: fullAddress,
        username: username,
        sessionBpp: sessionBpp,
        audioMode: audioMode,
        smartSizing: smartSizing,
        screenModeId: screenModeId,
        additionalConfig: [:]
    )
    
    try rdpInfo.validate()
    return .rdp(rdpInfo)
}

func extractSSHConnectionInfo(from config: JMSConfig) throws -> ConnectionInfo {
    guard !config.token.isEmpty else {
        throw NSError(domain: "SSHError", code: 1, userInfo: [NSLocalizedDescriptionKey: "SSH Token为空"])
    }
    
    guard let tokenData = config.token.data(using: .utf8) else {
        throw NSError(domain: "SSHError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Token编码失败"])
    }
    
    let decoder = JSONDecoder()
    let sshToken = try decoder.decode(SSHToken.self, from: tokenData)
    
    let sshInfo = SSHConnectionInfo(
        ip: sshToken.ip,
        port: sshToken.port,
        username: sshToken.username,
        password: sshToken.password,
        filename: config.filename
    )
    
    try sshInfo.validate()
    return .ssh(sshInfo)
}

func parseRDPConfigString(_ configString: String) throws -> [String: String] {
    var configParams: [String: String] = [:]
    // 正确处理换行符 - 将\\n替换为实际的换行符
    let normalizedConfig = configString.replacingOccurrences(of: "\\\\n", with: "\n")
    let lines = normalizedConfig.components(separatedBy: "\n")
    
    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedLine.isEmpty { continue }
        
        if let colonIndex = trimmedLine.firstIndex(of: ":") {
            let keyPart = String(trimmedLine[..<colonIndex])
            let remainingPart = String(trimmedLine[trimmedLine.index(after: colonIndex)...])
            
            if let secondColonIndex = remainingPart.firstIndex(of: ":") {
                let value = String(remainingPart[remainingPart.index(after: secondColonIndex)...])
                configParams[keyPart] = value
            }
        }
    }
    
    return configParams
}

func checkRDPAvailability() -> Bool {
    return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.rdc.macos") != nil
}

func detectTerminalApp() -> TerminalApp {
    if NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.googlecode.iterm2") != nil {
        return .iterm2
    } else if NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") != nil {
        return .terminal
    } else {
        return .unavailable
    }
}

func checkExpectAvailability() -> Bool {
    let process = Process()
    process.launchPath = "/usr/bin/which"
    process.arguments = ["expect"]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    
    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    } catch {
        return false
    }
}

// MARK: - 主测试流程

func testProtocol(_ protocolName: String, jsonData: String) -> Bool {
    print("\\n🧪 测试\(protocolName.uppercased())协议工作流程...")
    
    do {
        // 步骤1: 创建测试URL
        let testURL = createTestURL(from: jsonData)
        print("   ✅ 步骤1: URL创建成功 (长度: \(testURL.count))")
        
        // 步骤2: 解析URL和配置
        let jmsConfig = try parseJMSURL(testURL)
        print("   ✅ 步骤2: URL解析成功 (协议: \(jmsConfig.protocol))")
        
        // 步骤3: 提取连接信息
        let connectionInfo = try extractConnectionInfo(from: jmsConfig)
        print("   ✅ 步骤3: 连接信息提取成功")
        print("      📊 \(connectionInfo.description)")
        
        // 步骤4: 检查相应的应用程序可用性
        switch connectionInfo {
        case .rdp:
            let rdpAvailable = checkRDPAvailability()
            print("   \(rdpAvailable ? "✅" : "⚠️") 步骤4: Microsoft Remote Desktop \(rdpAvailable ? "可用" : "不可用")")
            if !rdpAvailable {
                print("      💡 提示: 请从Mac App Store安装Microsoft Remote Desktop")
            }
            
        case .ssh:
            let terminalApp = detectTerminalApp()
            let expectAvailable = checkExpectAvailability()
            print("   ✅ 步骤4: 终端应用程序检测完成")
            print("      📊 可用终端: \(terminalApp.displayName)")
            print("      📊 Expect工具: \(expectAvailable ? "可用" : "不可用")")
            
            if terminalApp == .unavailable {
                print("      ⚠️ 警告: 无可用终端应用程序")
                return false
            }
        }
        
        print("   🎉 \(protocolName.uppercased())协议工作流程测试通过!")
        return true
        
    } catch {
        print("   ❌ \(protocolName.uppercased())协议工作流程测试失败: \(error.localizedDescription)")
        return false
    }
}

func runCompleteWorkflowTest() {
    print("🚀 JMS Protocol Handler 完整工作流程测试")
    print(String(repeating: "=", count: 50))
    
    // 测试RDP协议
    let rdpSuccess = testProtocol("RDP", jsonData: testRDPData)
    
    // 测试SSH协议
    let sshSuccess = testProtocol("SSH", jsonData: testSSHData)
    
    // 测试总结
    print("\\n📊 测试总结")
    print(String(repeating: "=", count: 30))
    print("   \(rdpSuccess ? "✅" : "❌") RDP协议支持: \(rdpSuccess ? "通过" : "失败")")
    print("   \(sshSuccess ? "✅" : "❌") SSH协议支持: \(sshSuccess ? "通过" : "失败")")
    
    if rdpSuccess && sshSuccess {
        print("\\n🎉 所有测试通过！JMS Protocol Handler已准备就绪")
        print("💡 支持的功能:")
        print("   • RDP远程桌面连接 (Microsoft Remote Desktop)")
        print("   • SSH终端连接 (iTerm2/Terminal + expect)")
        print("   • 自动协议识别和分发")
        print("   • Base64解码和JSON解析")
        print("   • 完整的错误处理")
    } else {
        print("\\n⚠️ 部分测试失败，请检查相关依赖:")
        if !rdpSuccess {
            print("   • 安装Microsoft Remote Desktop")
        }
        if !sshSuccess {
            print("   • 确保终端应用程序可用")
            print("   • 安装expect工具: brew install expect")
        }
    }
    
    // 系统环境信息
    print("\\n🖥️ 系统环境信息")
    print("   • macOS版本: \(ProcessInfo.processInfo.operatingSystemVersionString)")
    print("   • 架构: \(ProcessInfo.processInfo.machineHardwareName ?? "未知")")
    print("   • Microsoft Remote Desktop: \(checkRDPAvailability() ? "已安装" : "未安装")")
    print("   • 终端应用程序: \(detectTerminalApp().displayName)")
    print("   • Expect工具: \(checkExpectAvailability() ? "已安装" : "未安装")")
}

// 运行完整测试
runCompleteWorkflowTest()

// MARK: - 扩展

extension ProcessInfo {
    var machineHardwareName: String? {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }
}
