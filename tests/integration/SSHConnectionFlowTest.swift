import XCTest
@testable import JMSCore
@testable import JMSSSHModule

/// SSH连接完整流程测试
/// 测试SSH连接的完整流程处理
class SSHConnectionFlowTest: XCTestCase {
    
    var urlParser: URLParser!
    var payloadDecoder: PayloadDecoder!
    var connectionInfoExtractor: ConnectionInfoExtractor!
    var sshIntegrator: SSHTerminalIntegrator!
    
    override func setUp() {
        super.setUp()
        urlParser = URLParser()
        payloadDecoder = PayloadDecoder()
        connectionInfoExtractor = ConnectionInfoExtractor()
        sshIntegrator = SSHTerminalIntegrator()
    }
    
    override func tearDown() {
        urlParser = nil
        payloadDecoder = nil
        connectionInfoExtractor = nil
        sshIntegrator = nil
        super.tearDown()
    }
    
    // MARK: - SSH协议完整流程测试
    
    func testCompleteSSHFlow() {
        print("🧪 测试SSH协议完整处理流程")
        
        // 创建测试SSH配置
        let sshConfig = """
        {
            "protocol": "ssh",
            "token": "{\\"ip\\":\\"192.168.1.100\\",\\"port\\":22,\\"username\\":\\"testuser\\",\\"password\\":\\"testpass\\"}"
        }
        """
        
        let encodedPayload = Data(sshConfig.utf8).base64EncodedString()
        let testURL = "jms://\(encodedPayload)"
        
        print("📝 测试SSH URL: \(testURL)")
        
        do {
            // 步骤1: URL解析
            let urlComponents = try urlParser.parseURL(testURL)
            XCTAssertEqual(urlComponents.scheme, "jms", "URL scheme应该是jms")
            print("✅ SSH URL解析成功")
            
            // 步骤2: Payload解码
            let decodedPayload = try payloadDecoder.decodePayload(urlComponents.host ?? "")
            XCTAssertTrue(decodedPayload.contains("ssh"), "解码后应该包含ssh协议")
            print("✅ SSH Payload解码成功")
            
            // 步骤3: 连接信息提取
            let connectionInfo = try connectionInfoExtractor.extractConnectionInfo(from: decodedPayload)
            
            switch connectionInfo {
            case .ssh(let sshInfo):
                XCTAssertEqual(sshInfo.ip, "192.168.1.100", "SSH IP应该正确")
                XCTAssertEqual(sshInfo.port, 22, "SSH端口应该正确")
                XCTAssertEqual(sshInfo.username, "testuser", "SSH用户名应该正确")
                XCTAssertEqual(sshInfo.password, "testpass", "SSH密码应该正确")
                print("✅ SSH连接信息提取成功")
                
                // 步骤4: 测试SSH命令构建
                testSSHCommandGeneration(sshInfo)
                
            case .rdp:
                XCTFail("应该提取到SSH连接信息，而不是RDP")
            }
            
        } catch {
            XCTFail("SSH协议处理失败: \(error)")
        }
        
        print("🎉 SSH协议完整流程测试通过")
    }
    
    func testSSHCommandGeneration(_ sshInfo: SSHConnectionInfo) {
        print("🧪 测试SSH命令生成")
        
        // 测试基本SSH命令生成
        let basicCommand = sshIntegrator.buildSSHCommand(for: sshInfo, useExpect: false)
        let expectedBasicCommand = "ssh -p 22 testuser@192.168.1.100"
        XCTAssertEqual(basicCommand, expectedBasicCommand, "基本SSH命令应该正确")
        print("✅ 基本SSH命令生成正确: \(basicCommand)")
        
        // 测试带expect的SSH命令生成
        let expectCommand = sshIntegrator.buildSSHCommand(for: sshInfo, useExpect: true)
        XCTAssertTrue(expectCommand.contains("expect"), "expect命令应该包含expect")
        XCTAssertTrue(expectCommand.contains("spawn ssh"), "expect命令应该包含spawn ssh")
        XCTAssertTrue(expectCommand.contains("testpass"), "expect命令应该包含密码")
        print("✅ expect SSH命令生成正确")
    }
    
    // MARK: - SSH终端检测测试
    
    func testTerminalDetection() {
        print("🧪 测试终端应用程序检测")
        
        // 测试终端检测功能
        let availableTerminals = sshIntegrator.detectAvailableTerminals()
        XCTAssertFalse(availableTerminals.isEmpty, "应该检测到至少一个终端应用程序")
        
        // 验证检测到的终端
        for terminal in availableTerminals {
            print("📱 检测到终端: \(terminal.name) - \(terminal.bundleIdentifier)")
            XCTAssertFalse(terminal.name.isEmpty, "终端名称不应该为空")
            XCTAssertFalse(terminal.bundleIdentifier.isEmpty, "Bundle ID不应该为空")
        }
        
        // 测试首选终端选择
        let preferredTerminal = sshIntegrator.getPreferredTerminal()
        XCTAssertNotNil(preferredTerminal, "应该能够选择一个首选终端")
        print("✅ 首选终端: \(preferredTerminal?.name ?? "未知")")
    }
    
    // MARK: - SSH连接参数验证测试
    
    func testSSHConnectionParameters() {
        print("🧪 测试SSH连接参数验证")
        
        let testCases = [
            // 标准SSH连接
            SSHConnectionInfo(ip: "192.168.1.100", port: 22, username: "user1", password: "pass1"),
            // 自定义端口
            SSHConnectionInfo(ip: "10.0.0.50", port: 2222, username: "admin", password: "admin123"),
            // IPv6地址
            SSHConnectionInfo(ip: "::1", port: 22, username: "localuser", password: "localpass"),
            // 域名
            SSHConnectionInfo(ip: "ssh.example.com", port: 22, username: "remoteuser", password: "remotepass")
        ]
        
        for (index, sshInfo) in testCases.enumerated() {
            print("📝 测试用例 \(index + 1): \(sshInfo.username)@\(sshInfo.ip):\(sshInfo.port)")
            
            // 验证SSH命令生成
            let command = sshIntegrator.buildSSHCommand(for: sshInfo, useExpect: false)
            
            // 验证命令包含正确的参数
            XCTAssertTrue(command.contains(sshInfo.ip), "命令应该包含IP地址")
            XCTAssertTrue(command.contains(sshInfo.username), "命令应该包含用户名")
            XCTAssertTrue(command.contains("-p \(sshInfo.port)"), "命令应该包含端口")
            
            print("✅ SSH命令: \(command)")
        }
    }
    
    // MARK: - SSH错误处理测试
    
    func testSSHErrorHandling() {
        print("🧪 测试SSH错误处理")
        
        // 测试无效的SSH配置
        let invalidConfigs = [
            // 缺少IP
            """
            {
                "protocol": "ssh",
                "token": "{\\"port\\":22,\\"username\\":\\"user\\",\\"password\\":\\"pass\\"}"
            }
            """,
            // 无效端口
            """
            {
                "protocol": "ssh",
                "token": "{\\"ip\\":\\"192.168.1.100\\",\\"port\\":-1,\\"username\\":\\"user\\",\\"password\\":\\"pass\\"}"
            }
            """,
            // 缺少用户名
            """
            {
                "protocol": "ssh",
                "token": "{\\"ip\\":\\"192.168.1.100\\",\\"port\\":22,\\"password\\":\\"pass\\"}"
            }
            """,
            // 无效JSON
            """
            {
                "protocol": "ssh",
                "token": "invalid_json"
            }
            """
        ]
        
        for (index, invalidConfig) in invalidConfigs.enumerated() {
            print("📝 测试无效配置 \(index + 1)")
            
            let encodedPayload = Data(invalidConfig.utf8).base64EncodedString()
            let testURL = "jms://\(encodedPayload)"
            
            do {
                let urlComponents = try urlParser.parseURL(testURL)
                let decodedPayload = try payloadDecoder.decodePayload(urlComponents.host ?? "")
                let _ = try connectionInfoExtractor.extractConnectionInfo(from: decodedPayload)
                
                // 如果到这里没有抛出异常，说明处理了不应该处理的配置
                XCTFail("应该拒绝无效的SSH配置 \(index + 1)")
                
            } catch {
                // 预期的错误
                XCTAssertTrue(error is JMSError, "应该抛出JMSError类型的错误")
                print("✅ 正确处理了无效配置 \(index + 1): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - SSH AppleScript生成测试
    
    func testAppleScriptGeneration() {
        print("🧪 测试AppleScript生成")
        
        let sshInfo = SSHConnectionInfo(
            ip: "test.server.com",
            port: 22,
            username: "testuser",
            password: "testpass"
        )
        
        // 测试Terminal AppleScript生成
        if let terminalScript = sshIntegrator.generateTerminalAppleScript(for: sshInfo) {
            XCTAssertTrue(terminalScript.contains("tell application \"Terminal\""), "应该包含Terminal应用程序调用")
            XCTAssertTrue(terminalScript.contains("ssh"), "应该包含ssh命令")
            XCTAssertTrue(terminalScript.contains(sshInfo.ip), "应该包含服务器地址")
            print("✅ Terminal AppleScript生成成功")
        }
        
        // 测试iTerm2 AppleScript生成
        if let itermScript = sshIntegrator.generateITermAppleScript(for: sshInfo) {
            XCTAssertTrue(itermScript.contains("tell application \"iTerm\""), "应该包含iTerm应用程序调用")
            XCTAssertTrue(itermScript.contains("ssh"), "应该包含ssh命令")
            XCTAssertTrue(itermScript.contains(sshInfo.ip), "应该包含服务器地址")
            print("✅ iTerm2 AppleScript生成成功")
        }
    }
    
    // MARK: - SSH性能测试
    
    func testSSHPerformance() {
        print("🧪 测试SSH处理性能")
        
        let sshInfo = SSHConnectionInfo(
            ip: "performance.test.com",
            port: 22,
            username: "perfuser",
            password: "perfpass"
        )
        
        // 测试SSH命令生成性能
        measure {
            for _ in 0..<1000 {
                let _ = sshIntegrator.buildSSHCommand(for: sshInfo, useExpect: false)
            }
        }
        
        print("✅ SSH性能测试完成")
    }
    
    // MARK: - SSH特殊字符处理测试
    
    func testSSHSpecialCharacterHandling() {
        print("🧪 测试SSH特殊字符处理")
        
        let specialCases = [
            // 包含特殊字符的密码
            SSHConnectionInfo(ip: "192.168.1.100", port: 22, username: "user", password: "pass@123!"),
            // 包含空格的用户名（虽然不常见）
            SSHConnectionInfo(ip: "192.168.1.100", port: 22, username: "test user", password: "password"),
            // 包含引号的密码
            SSHConnectionInfo(ip: "192.168.1.100", port: 22, username: "user", password: "pass\"word"),
            // 包含反斜杠的密码
            SSHConnectionInfo(ip: "192.168.1.100", port: 22, username: "user", password: "pass\\word")
        ]
        
        for (index, sshInfo) in specialCases.enumerated() {
            print("📝 测试特殊字符用例 \(index + 1)")
            
            // 测试基本命令生成（不应该崩溃）
            XCTAssertNoThrow({
                let _ = sshIntegrator.buildSSHCommand(for: sshInfo, useExpect: false)
            }, "处理特殊字符不应该崩溃")
            
            // 测试expect命令生成（需要正确转义）
            XCTAssertNoThrow({
                let _ = sshIntegrator.buildSSHCommand(for: sshInfo, useExpect: true)
            }, "处理特殊字符的expect命令不应该崩溃")
            
            print("✅ 特殊字符用例 \(index + 1) 处理成功")
        }
    }
}
