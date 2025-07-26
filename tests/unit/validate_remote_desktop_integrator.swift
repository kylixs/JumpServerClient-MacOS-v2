#!/usr/bin/env swift

import Foundation
import Cocoa

// 复制必要的模型和协议定义
enum JMSError: Error, LocalizedError {
    case invalidURL
    case invalidPayload
    case decodingFailed
    case missingConnectionInfo
    case remoteDesktopNotFound
    case remoteDesktopLaunchFailed
    case notificationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL格式"
        case .invalidPayload:
            return "无效的payload数据"
        case .decodingFailed:
            return "解码失败"
        case .missingConnectionInfo:
            return "缺少连接信息"
        case .remoteDesktopNotFound:
            return "未找到Microsoft Remote Desktop应用程序"
        case .remoteDesktopLaunchFailed:
            return "启动Remote Desktop失败"
        case .notificationFailed:
            return "通知发送失败"
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

protocol RemoteDesktopIntegratorProtocol {
    func launchRemoteDesktop(with connectionInfo: ConnectionInfo) throws
    func checkRemoteDesktopAvailability() -> Bool
    func createTemporaryRDPFile(with connectionInfo: ConnectionInfo) throws -> URL
    func cleanupTemporaryFile(at fileURL: URL)
}

// RemoteDesktopIntegrator实现
class RemoteDesktopIntegrator: RemoteDesktopIntegratorProtocol {
    
    private static let remoteDesktopBundleID = "com.microsoft.rdc.macos"
    private static let remoteDesktopPaths = [
        "/Applications/Microsoft Remote Desktop.app",
        "/Applications/Microsoft Remote Desktop 10.app",
        "~/Applications/Microsoft Remote Desktop.app",
        "~/Applications/Microsoft Remote Desktop 10.app"
    ]
    
    private let temporaryDirectory: URL
    
    init() {
        self.temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("JMSProtocolHandler", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: temporaryDirectory, 
                                               withIntermediateDirectories: true, 
                                               attributes: nil)
    }
    
    func checkRemoteDesktopAvailability() -> Bool {
        if let _ = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.remoteDesktopBundleID) {
            return true
        }
        
        for path in Self.remoteDesktopPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expandedPath) {
                return true
            }
        }
        
        return false
    }
    
    func createTemporaryRDPFile(with connectionInfo: ConnectionInfo) throws -> URL {
        try connectionInfo.validate()
        
        let fileName = "jms_connection_\(UUID().uuidString).rdp"
        let fileURL = temporaryDirectory.appendingPathComponent(fileName)
        
        let rdpContent = connectionInfo.generateRDPContent()
        
        do {
            try rdpContent.write(to: fileURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], 
                                                ofItemAtPath: fileURL.path)
            return fileURL
        } catch {
            throw JMSError.remoteDesktopLaunchFailed
        }
    }
    
    func launchRemoteDesktop(with connectionInfo: ConnectionInfo) throws {
        guard checkRemoteDesktopAvailability() else {
            throw JMSError.remoteDesktopNotFound
        }
        
        let rdpFileURL = try createTemporaryRDPFile(with: connectionInfo)
        
        do {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.remoteDesktopBundleID) {
                try NSWorkspace.shared.open([rdpFileURL], 
                                          withApplicationAt: appURL, 
                                          configuration: NSWorkspace.OpenConfiguration())
            } else {
                let success = NSWorkspace.shared.open(rdpFileURL)
                if !success {
                    throw JMSError.remoteDesktopLaunchFailed
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.cleanupTemporaryFile(at: rdpFileURL)
            }
            
        } catch {
            cleanupTemporaryFile(at: rdpFileURL)
            throw JMSError.remoteDesktopLaunchFailed
        }
    }
    
    func cleanupTemporaryFile(at fileURL: URL) {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Warning: Failed to cleanup temporary file at \(fileURL.path): \(error)")
        }
    }
    
    func getRemoteDesktopVersion() -> String? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.remoteDesktopBundleID) else {
            return nil
        }
        
        guard let bundle = Bundle(url: appURL) else {
            return nil
        }
        
        return bundle.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    func cleanupAllTemporaryFiles() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: temporaryDirectory, 
                                                                     includingPropertiesForKeys: nil)
            for fileURL in contents where fileURL.pathExtension == "rdp" {
                cleanupTemporaryFile(at: fileURL)
            }
        } catch {
            print("Warning: Failed to cleanup temporary directory: \(error)")
        }
    }
}

// 测试函数
func testRemoteDesktopIntegrator() {
    print("=== RemoteDesktopIntegrator 验证测试 ===\n")
    
    let integrator = RemoteDesktopIntegrator()
    
    // 1. 测试可用性检查
    print("1. 检查Microsoft Remote Desktop可用性")
    let isAvailable = integrator.checkRemoteDesktopAvailability()
    print("   结果: \(isAvailable ? "✅ 已安装" : "❌ 未安装")")
    
    if isAvailable {
        if let version = integrator.getRemoteDesktopVersion() {
            print("   版本: \(version)")
        }
    }
    print()
    
    // 2. 测试RDP文件创建
    print("2. 测试RDP文件创建")
    let testConnectionInfo = ConnectionInfo(
        fullAddress: "test-server.example.com:3389",
        username: "testuser|session-123",
        sessionBpp: 32,
        audioMode: 0,
        smartSizing: true,
        screenModeId: 2,
        additionalConfig: [
            "desktopwidth": "1920",
            "desktopheight": "1080"
        ]
    )
    
    do {
        let fileURL = try integrator.createTemporaryRDPFile(with: testConnectionInfo)
        print("   ✅ RDP文件创建成功")
        print("   路径: \(fileURL.path)")
        
        // 验证文件内容
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        print("   内容预览:")
        let lines = content.components(separatedBy: "\n")
        for line in lines.prefix(5) {
            print("     \(line)")
        }
        if lines.count > 5 {
            print("     ... (共\(lines.count)行)")
        }
        
        // 清理测试文件
        integrator.cleanupTemporaryFile(at: fileURL)
        print("   ✅ 测试文件已清理")
        
    } catch {
        print("   ❌ RDP文件创建失败: \(error)")
    }
    print()
    
    // 3. 测试连接信息验证
    print("3. 测试连接信息验证")
    
    let validInfo = ConnectionInfo(fullAddress: "valid.server.com:3389", username: "validuser")
    do {
        try validInfo.validate()
        print("   ✅ 有效连接信息验证通过")
    } catch {
        print("   ❌ 有效连接信息验证失败: \(error)")
    }
    
    let invalidInfo = ConnectionInfo(fullAddress: "", username: "user")
    do {
        try invalidInfo.validate()
        print("   ❌ 无效连接信息应该验证失败")
    } catch {
        print("   ✅ 无效连接信息正确被拒绝: \(error)")
    }
    print()
    
    // 4. 测试RDP内容生成
    print("4. 测试RDP内容生成")
    let rdpContent = testConnectionInfo.generateRDPContent()
    print("   生成的RDP内容:")
    let contentLines = rdpContent.components(separatedBy: "\n")
    for line in contentLines {
        print("     \(line)")
    }
    
    // 验证必要字段
    let requiredFields = ["full address:s:", "username:s:"]
    var allPresent = true
    for field in requiredFields {
        if !rdpContent.contains(field) {
            print("   ❌ 缺少必要字段: \(field)")
            allPresent = false
        }
    }
    if allPresent {
        print("   ✅ 所有必要字段都存在")
    }
    print()
    
    print("=== 验证测试完成 ===")
    print("任务7 - Microsoft Remote Desktop集成模块实现完成！")
}

// 运行测试
testRemoteDesktopIntegrator()
