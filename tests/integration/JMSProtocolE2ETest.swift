import XCTest
@testable import JMSCore
@testable import JMSRDPModule
@testable import JMSSSHModule

/// JMS协议端到端测试
/// 测试完整的jms://协议处理流程（URL接收 → 解析 → 配置应用 → 启动连接）
class JMSProtocolE2ETest: XCTestCase {
    
    var urlParser: URLParser!
    var payloadDecoder: PayloadDecoder!
    var connectionInfoExtractor: ConnectionInfoExtractor!
    var rdpConfigManager: RDPConfigManager!
    var rdpSettingsManager: RDPSettingsManager!
    
    override func setUp() {
        super.setUp()
        urlParser = URLParser()
        payloadDecoder = PayloadDecoder()
        connectionInfoExtractor = ConnectionInfoExtractor()
        rdpConfigManager = RDPConfigManager(forTesting: true)
        rdpSettingsManager = RDPSettingsManager()
    }
    
    override func tearDown() {
        urlParser = nil
        payloadDecoder = nil
        connectionInfoExtractor = nil
        rdpConfigManager = nil
        rdpSettingsManager = nil
        super.tearDown()
    }
    
    // MARK: - RDP协议完整流程测试
    
    func testCompleteRDPProtocolFlow() {
        print("🧪 测试RDP协议完整处理流程")
        
        // 步骤1: 创建测试用的RDP配置
        let testRDPConfig = """
        {
            "protocol": "rdp",
            "config": "full address:s:192.168.1.100:3389\\nusername:s:testuser\\nsession bpp:i:32\\naudiomode:i:0\\ncompression:i:1"
        }
        """
        
        // 步骤2: Base64编码
        let encodedPayload = Data(testRDPConfig.utf8).base64EncodedString()
        let testURL = "jms://\(encodedPayload)"
        
        print("📝 测试URL: \(testURL)")
        
        // 步骤3: URL解析
        do {
            let urlComponents = try urlParser.parseURL(testURL)
            XCTAssertEqual(urlComponents.scheme, "jms", "URL scheme应该是jms")
            XCTAssertNotNil(urlComponents.host, "URL应该有host部分")
            print("✅ URL解析成功")
        } catch {
            XCTFail("URL解析失败: \(error)")
            return
        }
        
        // 步骤4: Payload解码
        do {
            let urlComponents = try urlParser.parseURL(testURL)
            let decodedPayload = try payloadDecoder.decodePayload(urlComponents.host ?? "")
            XCTAssertTrue(decodedPayload.contains("protocol"), "解码后的payload应该包含protocol字段")
            XCTAssertTrue(decodedPayload.contains("rdp"), "解码后的payload应该包含rdp协议")
            print("✅ Payload解码成功")
        } catch {
            XCTFail("Payload解码失败: \(error)")
            return
        }
        
        // 步骤5: 连接信息提取
        do {
            let urlComponents = try urlParser.parseURL(testURL)
            let decodedPayload = try payloadDecoder.decodePayload(urlComponents.host ?? "")
            let connectionInfo = try connectionInfoExtractor.extractConnectionInfo(from: decodedPayload)
            
            switch connectionInfo {
            case .rdp(let rdpInfo):
                XCTAssertEqual(rdpInfo.serverAddress, "192.168.1.100:3389", "RDP服务器地址应该正确")
                XCTAssertEqual(rdpInfo.username, "testuser", "RDP用户名应该正确")
                print("✅ RDP连接信息提取成功")
            case .ssh:
                XCTFail("应该提取到RDP连接信息，而不是SSH")
            }
        } catch {
            XCTFail("连接信息提取失败: \(error)")
            return
        }
        
        // 步骤6: 配置重新加载测试
        do {
            // 创建测试配置
            let testSettings = RDPSettings(
                profileName: "E2E测试配置",
                resolution: ResolutionSettings(width: 2560, height: 1440),
                hiDPI: HiDPISettings(enabled: true, scaleFactor: 2.0),
                colorDepth: 32,
                compressionLevel: 1,
                enableFontSmoothing: true
            )
            
            // 保存配置
            try rdpSettingsManager.saveSettings(testSettings)
            
            // 模拟配置重新加载
            let latestSettings = rdpSettingsManager.currentSettings
            let qualityProfile = RDPConfigManager.convertToQualityProfile(latestSettings)
            rdpConfigManager.setQualityProfile(qualityProfile)
            
            // 验证配置应用
            let appliedSettings = rdpConfigManager.currentSettings
            XCTAssertEqual(appliedSettings.profileName, "E2E测试配置", "配置应该正确应用")
            XCTAssertEqual(appliedSettings.resolution.width, 2560, "分辨率应该正确应用")
            XCTAssertTrue(appliedSettings.hiDPI.enabled, "HiDPI设置应该正确应用")
            
            print("✅ 配置重新加载和应用成功")
        } catch {
            XCTFail("配置重新加载失败: \(error)")
        }
        
        print("🎉 RDP协议完整流程测试通过")
    }
    
    // MARK: - SSH协议完整流程测试
    
    func testCompleteSSHProtocolFlow() {
        print("🧪 测试SSH协议完整处理流程")
        
        // 步骤1: 创建测试用的SSH配置
        let testSSHConfig = """
        {
            "protocol": "ssh",
            "token": "{\\"ip\\":\\"192.168.1.200\\",\\"port\\":22,\\"username\\":\\"sshuser\\",\\"password\\":\\"sshpass\\"}"
        }
        """
        
        // 步骤2: Base64编码
        let encodedPayload = Data(testSSHConfig.utf8).base64EncodedString()
        let testURL = "jms://\(encodedPayload)"
        
        print("📝 测试URL: \(testURL)")
        
        // 步骤3: 完整流程处理
        do {
            // URL解析
            let urlComponents = try urlParser.parseURL(testURL)
            XCTAssertEqual(urlComponents.scheme, "jms", "URL scheme应该是jms")
            
            // Payload解码
            let decodedPayload = try payloadDecoder.decodePayload(urlComponents.host ?? "")
            XCTAssertTrue(decodedPayload.contains("ssh"), "解码后的payload应该包含ssh协议")
            
            // 连接信息提取
            let connectionInfo = try connectionInfoExtractor.extractConnectionInfo(from: decodedPayload)
            
            switch connectionInfo {
            case .ssh(let sshInfo):
                XCTAssertEqual(sshInfo.ip, "192.168.1.200", "SSH IP地址应该正确")
                XCTAssertEqual(sshInfo.port, 22, "SSH端口应该正确")
                XCTAssertEqual(sshInfo.username, "sshuser", "SSH用户名应该正确")
                XCTAssertEqual(sshInfo.password, "sshpass", "SSH密码应该正确")
                print("✅ SSH连接信息提取成功")
            case .rdp:
                XCTFail("应该提取到SSH连接信息，而不是RDP")
            }
            
        } catch {
            XCTFail("SSH协议处理失败: \(error)")
        }
        
        print("🎉 SSH协议完整流程测试通过")
    }
    
    // MARK: - 错误处理流程测试
    
    func testProtocolErrorHandling() {
        print("🧪 测试协议错误处理流程")
        
        // 测试无效URL
        let invalidURLs = [
            "invalid://test",
            "jms://",
            "jms://invalid_base64!@#",
            "jms://dGVzdA==", // "test" - 无效JSON
        ]
        
        for invalidURL in invalidURLs {
            print("📝 测试无效URL: \(invalidURL)")
            
            do {
                let urlComponents = try urlParser.parseURL(invalidURL)
                let _ = try payloadDecoder.decodePayload(urlComponents.host ?? "")
                // 如果到这里没有抛出异常，说明处理了不应该处理的URL
                if !invalidURL.hasPrefix("jms://") {
                    XCTFail("应该拒绝非jms协议的URL: \(invalidURL)")
                }
            } catch {
                // 预期的错误，验证错误类型
                XCTAssertTrue(error is JMSError, "应该抛出JMSError类型的错误")
                print("✅ 正确处理了无效URL: \(invalidURL)")
            }
        }
        
        print("✅ 协议错误处理测试通过")
    }
    
    // MARK: - 性能测试
    
    func testProtocolProcessingPerformance() {
        print("🧪 测试协议处理性能")
        
        let testRDPConfig = """
        {
            "protocol": "rdp",
            "config": "full address:s:test.server.com:3389\\nusername:s:testuser"
        }
        """
        
        let encodedPayload = Data(testRDPConfig.utf8).base64EncodedString()
        let testURL = "jms://\(encodedPayload)"
        
        // 性能测试：处理100次URL
        measure {
            for _ in 0..<100 {
                do {
                    let urlComponents = try urlParser.parseURL(testURL)
                    let decodedPayload = try payloadDecoder.decodePayload(urlComponents.host ?? "")
                    let _ = try connectionInfoExtractor.extractConnectionInfo(from: decodedPayload)
                } catch {
                    XCTFail("性能测试中出现错误: \(error)")
                }
            }
        }
        
        print("✅ 协议处理性能测试完成")
    }
    
    // MARK: - 配置参数验证测试
    
    func testRDPParameterApplication() {
        print("🧪 测试RDP参数正确应用")
        
        // 创建包含各种参数的RDP配置
        let complexRDPConfig = """
        {
            "protocol": "rdp",
            "config": "full address:s:complex.server.com:3389\\nusername:s:complexuser\\nsession bpp:i:32\\naudiomode:i:0\\ncompression:i:1\\ndesktopwidth:i:2560\\ndesktopheight:i:1440\\nfont smoothing:i:1"
        }
        """
        
        let encodedPayload = Data(complexRDPConfig.utf8).base64EncodedString()
        let testURL = "jms://\(encodedPayload)"
        
        do {
            // 处理URL
            let urlComponents = try urlParser.parseURL(testURL)
            let decodedPayload = try payloadDecoder.decodePayload(urlComponents.host ?? "")
            let connectionInfo = try connectionInfoExtractor.extractConnectionInfo(from: decodedPayload)
            
            switch connectionInfo {
            case .rdp(let rdpInfo):
                XCTAssertEqual(rdpInfo.serverAddress, "complex.server.com:3389", "服务器地址应该正确")
                XCTAssertEqual(rdpInfo.username, "complexuser", "用户名应该正确")
                
                // 验证其他RDP参数是否被正确解析
                XCTAssertNotNil(rdpInfo.additionalConfig, "应该有额外的配置参数")
                
                print("✅ 复杂RDP参数解析成功")
            case .ssh:
                XCTFail("应该是RDP连接信息")
            }
            
        } catch {
            XCTFail("复杂RDP配置处理失败: \(error)")
        }
        
        print("✅ RDP参数应用测试通过")
    }
}

// MARK: - 集成测试辅助方法

extension JMSProtocolE2ETest {
    
    /// 创建测试用的RDP URL
    private func createTestRDPURL(serverAddress: String, username: String, additionalConfig: String = "") -> String {
        let config = "full address:s:\(serverAddress)\\nusername:s:\(username)\(additionalConfig.isEmpty ? "" : "\\n\(additionalConfig)")"
        let jsonConfig = """
        {
            "protocol": "rdp",
            "config": "\(config)"
        }
        """
        let encodedPayload = Data(jsonConfig.utf8).base64EncodedString()
        return "jms://\(encodedPayload)"
    }
    
    /// 创建测试用的SSH URL
    private func createTestSSHURL(ip: String, port: Int, username: String, password: String) -> String {
        let tokenConfig = """
        {"ip":"\(ip)","port":\(port),"username":"\(username)","password":"\(password)"}
        """
        let jsonConfig = """
        {
            "protocol": "ssh",
            "token": "\(tokenConfig)"
        }
        """
        let encodedPayload = Data(jsonConfig.utf8).base64EncodedString()
        return "jms://\(encodedPayload)"
    }
    
    /// 验证RDP配置生成
    private func verifyRDPConfigGeneration(connectionInfo: RDPConnectionInfo) throws {
        // 创建测试配置
        let testSettings = RDPSettings(
            profileName: "验证测试配置",
            resolution: ResolutionSettings(width: 1920, height: 1080),
            hiDPI: HiDPISettings(enabled: false, scaleFactor: 1.0),
            colorDepth: 24,
            compressionLevel: 2
        )
        
        // 应用配置
        let qualityProfile = RDPConfigManager.convertToQualityProfile(testSettings)
        rdpConfigManager.setQualityProfile(qualityProfile)
        
        // 生成RDP配置文件内容
        let configContent = try rdpConfigManager.generateOptimizedConfig(for: connectionInfo)
        
        // 验证配置文件内容
        XCTAssertTrue(configContent.contains("full address:s:\(connectionInfo.serverAddress)"), "配置应该包含服务器地址")
        XCTAssertTrue(configContent.contains("username:s:\(connectionInfo.username)"), "配置应该包含用户名")
        XCTAssertTrue(configContent.contains("desktopwidth:i:1920"), "配置应该包含正确的分辨率宽度")
        XCTAssertTrue(configContent.contains("desktopheight:i:1080"), "配置应该包含正确的分辨率高度")
        XCTAssertTrue(configContent.contains("session bpp:i:24"), "配置应该包含正确的颜色深度")
        XCTAssertTrue(configContent.contains("compression:i:2"), "配置应该包含正确的压缩级别")
        
        print("✅ RDP配置文件生成验证通过")
    }
}
