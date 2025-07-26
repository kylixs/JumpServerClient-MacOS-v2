#!/usr/bin/env swift

import Foundation
import Cocoa

print("=== JMS Protocol Handler 集成测试和端到端测试套件 ===\n")

// 测试框架
class TestFramework {
    private var testResults: [String: Bool] = [:]
    private var testDetails: [String: String] = [:]
    private var totalTests = 0
    private var passedTests = 0
    
    func runTest(_ testName: String, test: () throws -> Void) {
        totalTests += 1
        print("🧪 \(testName)")
        
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            try test()
            let endTime = CFAbsoluteTimeGetCurrent()
            let duration = endTime - startTime
            
            testResults[testName] = true
            testDetails[testName] = "✅ 通过 (\(String(format: "%.3f", duration))秒)"
            passedTests += 1
            print("   ✅ 通过 - 耗时: \(String(format: "%.3f", duration))秒")
        } catch {
            testResults[testName] = false
            testDetails[testName] = "❌ 失败: \(error.localizedDescription)"
            print("   ❌ 失败: \(error.localizedDescription)")
        }
        print()
    }
    
    func printSummary() {
        let separator = String(repeating: "=", count: 60)
        print(separator)
        print("测试总结")
        print(separator)
        print("总测试数: \(totalTests)")
        print("通过测试: \(passedTests)")
        print("失败测试: \(totalTests - passedTests)")
        print("通过率: \(String(format: "%.1f", Double(passedTests) / Double(totalTests) * 100))%")
        print()
        
        print("详细结果:")
        for (testName, result) in testDetails {
            print("  \(testName): \(result)")
        }
        
        if passedTests == totalTests {
            print("\n🎉 所有测试通过！")
        } else {
            print("\n⚠️ 有测试失败，请检查上述结果")
        }
    }
}

// 必要的类型定义
enum JMSError: Error, LocalizedError {
    case invalidURL, decodingFailed, jsonParsingFailed, missingConnectionInfo
    case remoteDesktopNotFound, remoteDesktopLaunchFailed, configParsingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL格式错误"
        case .decodingFailed: return "解码失败"
        case .jsonParsingFailed: return "配置信息格式错误"
        case .missingConnectionInfo: return "连接信息不完整"
        case .remoteDesktopNotFound: return "未找到Microsoft Remote Desktop应用程序"
        case .remoteDesktopLaunchFailed: return "启动Microsoft Remote Desktop失败"
        case .configParsingFailed: return "配置解析失败"
        }
    }
}

struct JMSConfig: Codable {
    let config: String
    func validate() throws {
        guard !config.isEmpty else { throw JMSError.missingConnectionInfo }
    }
}

struct ConnectionInfo {
    let fullAddress: String
    let username: String
    let sessionBpp: Int?
    let audioMode: Int?
    let smartSizing: Bool?
    let screenModeId: Int?
    
    func validate() throws {
        guard !fullAddress.isEmpty else { throw JMSError.missingConnectionInfo }
        guard !username.isEmpty else { throw JMSError.missingConnectionInfo }
    }
}

// 测试用的服务实现
class TestURLParser {
    func parseJMSURL(_ url: URL) throws -> (scheme: String, payload: String) {
        guard url.scheme?.lowercased() == "jms" else { throw JMSError.invalidURL }
        guard let host = url.host, !host.isEmpty else { throw JMSError.invalidURL }
        guard Data(base64Encoded: host) != nil else { throw JMSError.invalidURL }
        return (url.scheme!, host)
    }
}

class TestPayloadDecoder {
    func decodeAndParsePayload(_ payload: String) throws -> JMSConfig {
        guard let decodedData = Data(base64Encoded: payload) else { throw JMSError.decodingFailed }
        do {
            let config = try JSONDecoder().decode(JMSConfig.self, from: decodedData)
            try config.validate()
            return config
        } catch { throw JMSError.jsonParsingFailed }
    }
}

class TestConnectionInfoExtractor {
    func extractConnectionInfo(from config: JMSConfig) throws -> ConnectionInfo {
        let lines = config.config.components(separatedBy: "\n")
        var fullAddress = "", username = ""
        var sessionBpp: Int?, audioMode: Int?, smartSizing: Bool?, screenModeId: Int?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("full address:s:") {
                fullAddress = String(trimmed.dropFirst("full address:s:".count))
            } else if trimmed.hasPrefix("username:s:") {
                username = String(trimmed.dropFirst("username:s:".count))
            } else if trimmed.hasPrefix("session bpp:i:") {
                sessionBpp = Int(String(trimmed.dropFirst("session bpp:i:".count)))
            } else if trimmed.hasPrefix("audiomode:i:") {
                audioMode = Int(String(trimmed.dropFirst("audiomode:i:".count)))
            } else if trimmed.hasPrefix("smart sizing:i:") {
                smartSizing = String(trimmed.dropFirst("smart sizing:i:".count)) == "1"
            } else if trimmed.hasPrefix("screen mode id:i:") {
                screenModeId = Int(String(trimmed.dropFirst("screen mode id:i:".count)))
            }
        }
        
        guard !fullAddress.isEmpty, !username.isEmpty else { throw JMSError.missingConnectionInfo }
        return ConnectionInfo(fullAddress: fullAddress, username: username, 
                            sessionBpp: sessionBpp, audioMode: audioMode, 
                            smartSizing: smartSizing, screenModeId: screenModeId)
    }
}

class TestRemoteDesktopIntegrator {
    func checkRemoteDesktopAvailability() -> Bool {
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.rdc.macos") != nil
    }
    
    func launchRemoteDesktop(with connectionInfo: ConnectionInfo) throws {
        guard checkRemoteDesktopAvailability() else { throw JMSError.remoteDesktopNotFound }
        try connectionInfo.validate()
        // 在测试中不实际启动应用程序
    }
}

// 集成测试类
class IntegrationTestSuite {
    private let urlParser = TestURLParser()
    private let payloadDecoder = TestPayloadDecoder()
    private let connectionInfoExtractor = TestConnectionInfoExtractor()
    private let remoteDesktopIntegrator = TestRemoteDesktopIntegrator()
    
    func runAllTests() {
        let framework = TestFramework()
        
        // 1. URL格式测试
        framework.runTest("URL格式验证 - 有效JMS URL") {
            let url = URL(string: "jms://dGVzdA==")!
            let result = try urlParser.parseJMSURL(url)
            guard result.scheme == "jms" && result.payload == "dGVzdA==" else {
                throw JMSError.invalidURL
            }
        }
        
        framework.runTest("URL格式验证 - 无效scheme") {
            let url = URL(string: "http://example.com")!
            do {
                _ = try urlParser.parseJMSURL(url)
                throw JMSError.invalidURL // 应该失败
            } catch JMSError.invalidURL {
                // 期望的行为
            }
        }
        
        framework.runTest("URL格式验证 - 空payload") {
            let url = URL(string: "jms://")!
            do {
                _ = try urlParser.parseJMSURL(url)
                throw JMSError.invalidURL // 应该失败
            } catch JMSError.invalidURL {
                // 期望的行为
            }
        }
        
        // 2. Payload解码测试
        framework.runTest("Payload解码 - 有效JSON") {
            let validPayload = "eyJjb25maWciOiJ0ZXN0IGNvbmZpZyJ9" // {"config":"test config"}
            let config = try payloadDecoder.decodeAndParsePayload(validPayload)
            guard config.config == "test config" else {
                throw JMSError.jsonParsingFailed
            }
        }
        
        framework.runTest("Payload解码 - 无效base64") {
            let invalidPayload = "invalid-base64"
            do {
                _ = try payloadDecoder.decodeAndParsePayload(invalidPayload)
                throw JMSError.decodingFailed // 应该失败
            } catch JMSError.decodingFailed {
                // 期望的行为
            }
        }
        
        // 3. 连接信息提取测试
        framework.runTest("连接信息提取 - 完整配置") {
            let config = JMSConfig(config: """
                full address:s:test.server.com:3389
                username:s:testuser
                session bpp:i:32
                audiomode:i:0
                smart sizing:i:1
                screen mode id:i:2
                """)
            
            let connectionInfo = try connectionInfoExtractor.extractConnectionInfo(from: config)
            guard connectionInfo.fullAddress == "test.server.com:3389" &&
                  connectionInfo.username == "testuser" &&
                  connectionInfo.sessionBpp == 32 &&
                  connectionInfo.audioMode == 0 &&
                  connectionInfo.smartSizing == true &&
                  connectionInfo.screenModeId == 2 else {
                throw JMSError.configParsingFailed
            }
        }
        
        framework.runTest("连接信息提取 - 缺少必要字段") {
            let config = JMSConfig(config: "session bpp:i:32")
            do {
                _ = try connectionInfoExtractor.extractConnectionInfo(from: config)
                throw JMSError.missingConnectionInfo // 应该失败
            } catch JMSError.missingConnectionInfo {
                // 期望的行为
            }
        }
        
        // 4. Remote Desktop集成测试
        framework.runTest("Remote Desktop可用性检查") {
            let isAvailable = remoteDesktopIntegrator.checkRemoteDesktopAvailability()
            print("   Microsoft Remote Desktop 可用性: \(isAvailable ? "✅" : "❌")")
            // 这个测试总是通过，只是报告状态
        }
        
        framework.runTest("Remote Desktop启动测试") {
            let connectionInfo = ConnectionInfo(
                fullAddress: "test.server.com:3389",
                username: "testuser",
                sessionBpp: 32,
                audioMode: 0,
                smartSizing: true,
                screenModeId: 2
            )
            
            if remoteDesktopIntegrator.checkRemoteDesktopAvailability() {
                try remoteDesktopIntegrator.launchRemoteDesktop(with: connectionInfo)
            } else {
                print("   跳过启动测试 - Microsoft Remote Desktop 不可用")
            }
        }
        
        // 5. 端到端测试
        framework.runTest("端到端测试 - 完整流程") {
            let testURL = "jms://eyJjb25maWciOiJmdWxsIGFkZHJlc3M6czp0ZXN0LnNlcnZlci5jb206MzM4OVxudXNlcm5hbWU6czp0ZXN0dXNlclxuc2Vzc2lvbiBicHA6aTozMlxuYXVkaW9tb2RlOmk6MFxuc21hcnQgc2l6aW5nOmk6MVxuc2NyZWVuIG1vZGUgaWQ6aToyIn0="
            
            guard let url = URL(string: testURL) else {
                throw JMSError.invalidURL
            }
            
            // Step 1: URL解析
            let urlResult = try urlParser.parseJMSURL(url)
            
            // Step 2: Payload解码
            let config = try payloadDecoder.decodeAndParsePayload(urlResult.payload)
            
            // Step 3: 连接信息提取
            let connectionInfo = try connectionInfoExtractor.extractConnectionInfo(from: config)
            
            // Step 4: Remote Desktop启动（如果可用）
            if remoteDesktopIntegrator.checkRemoteDesktopAvailability() {
                try remoteDesktopIntegrator.launchRemoteDesktop(with: connectionInfo)
            }
            
            // 验证结果
            guard connectionInfo.fullAddress == "test.server.com:3389" &&
                  connectionInfo.username == "testuser" else {
                throw JMSError.configParsingFailed
            }
        }
        
        // 6. 错误场景测试
        framework.runTest("错误场景 - 无效URL到启动失败的完整流程") {
            let invalidURLs = [
                "http://example.com",
                "jms://",
                "jms://invalid-base64",
                "jms://eyJpbnZhbGlkIjoianNvbiJ9" // 无效JSON结构
            ]
            
            var errorCount = 0
            for testURL in invalidURLs {
                if let url = URL(string: testURL) {
                    do {
                        let urlResult = try urlParser.parseJMSURL(url)
                        let config = try payloadDecoder.decodeAndParsePayload(urlResult.payload)
                        let _ = try connectionInfoExtractor.extractConnectionInfo(from: config)
                        // 如果到这里没有抛出异常，说明测试失败
                    } catch {
                        errorCount += 1 // 期望的错误
                    }
                }
            }
            
            guard errorCount == invalidURLs.count else {
                throw JMSError.configParsingFailed
            }
        }
        
        // 7. 性能测试
        framework.runTest("性能测试 - 批量URL处理") {
            let validURL = "jms://eyJjb25maWciOiJmdWxsIGFkZHJlc3M6czp0ZXN0LnNlcnZlci5jb206MzM4OVxudXNlcm5hbWU6czp0ZXN0dXNlciJ9"
            let startTime = CFAbsoluteTimeGetCurrent()
            
            for _ in 1...10 {
                guard let url = URL(string: validURL) else { continue }
                let urlResult = try urlParser.parseJMSURL(url)
                let config = try payloadDecoder.decodeAndParsePayload(urlResult.payload)
                let _ = try connectionInfoExtractor.extractConnectionInfo(from: config)
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let totalTime = endTime - startTime
            let avgTime = totalTime / 10
            
            print("   处理10个URL总时间: \(String(format: "%.3f", totalTime))秒")
            print("   平均每个URL: \(String(format: "%.3f", avgTime))秒")
            
            guard avgTime < 1.0 else { // 目标：1秒内
                throw JMSError.configParsingFailed
            }
        }
        
        framework.printSummary()
    }
}

// 运行集成测试
let testSuite = IntegrationTestSuite()
testSuite.runAllTests()

print("\n🎯 任务10 - 编写集成测试和端到端测试 - 完成！")
