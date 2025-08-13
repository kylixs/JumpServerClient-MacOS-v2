import XCTest
@testable import JMSSSHModule
@testable import JMSCore

final class JMSSSHModuleTests: XCTestCase {
    
    var sshIntegrator: SSHTerminalIntegrator!
    
    override func setUp() {
        super.setUp()
        sshIntegrator = SSHTerminalIntegrator()
    }
    
    override func tearDown() {
        sshIntegrator = nil
        super.tearDown()
    }
    
    // MARK: - SSHTerminalIntegrator Tests
    
    func testSSHTerminalIntegratorInitialization() {
        XCTAssertNotNil(sshIntegrator)
    }
    
    func testBuildSSHCommandBasic() {
        let connectionInfo = SSHConnectionInfo(
            ip: "192.168.1.100",
            port: 22,
            username: "testuser"
        )
        
        let command = sshIntegrator.buildSSHCommand(connectionInfo)
        
        XCTAssertTrue(command.contains("ssh"))
        XCTAssertTrue(command.contains("testuser@192.168.1.100"))
        XCTAssertTrue(command.contains("-o StrictHostKeyChecking=no"))
        XCTAssertTrue(command.contains("-o UserKnownHostsFile=/dev/null"))
        XCTAssertFalse(command.contains("-p 22")) // 默认端口不应该显式指定
    }
    
    func testBuildSSHCommandWithCustomPort() {
        let connectionInfo = SSHConnectionInfo(
            ip: "192.168.1.100",
            port: 2222,
            username: "testuser"
        )
        
        let command = sshIntegrator.buildSSHCommand(connectionInfo)
        
        XCTAssertTrue(command.contains("ssh"))
        XCTAssertTrue(command.contains("-p 2222"))
        XCTAssertTrue(command.contains("testuser@192.168.1.100"))
    }
    
    func testBuildSSHCommandWithPassword() throws {
        let connectionInfo = SSHConnectionInfo(
            ip: "192.168.1.100",
            port: 22,
            username: "testuser",
            password: "testpass"
        )
        
        let command = try sshIntegrator.buildSSHCommandWithPassword(connectionInfo)
        
        // 如果expect可用，应该返回expect脚本路径
        // 如果expect不可用，应该返回普通SSH命令
        XCTAssertTrue(command.contains("ssh") || command.contains("expect"))
    }
    
    func testBuildSSHCommandWithoutPassword() throws {
        let connectionInfo = SSHConnectionInfo(
            ip: "192.168.1.100",
            port: 22,
            username: "testuser",
            password: nil
        )
        
        let command = try sshIntegrator.buildSSHCommandWithPassword(connectionInfo)
        
        // 没有密码时应该返回普通SSH命令
        XCTAssertTrue(command.contains("ssh"))
        XCTAssertTrue(command.contains("testuser@192.168.1.100"))
        XCTAssertFalse(command.contains("expect"))
    }
    
    func testBuildSSHCommandWithEmptyPassword() throws {
        let connectionInfo = SSHConnectionInfo(
            ip: "192.168.1.100",
            port: 22,
            username: "testuser",
            password: ""
        )
        
        let command = try sshIntegrator.buildSSHCommandWithPassword(connectionInfo)
        
        // 空密码时应该返回普通SSH命令
        XCTAssertTrue(command.contains("ssh"))
        XCTAssertTrue(command.contains("testuser@192.168.1.100"))
        XCTAssertFalse(command.contains("expect"))
    }
    
    // MARK: - TerminalApp Tests
    
    func testTerminalAppDisplayNames() {
        XCTAssertEqual(TerminalApp.iTerm2.displayName, "iTerm2")
        XCTAssertEqual(TerminalApp.terminal.displayName, "Terminal")
    }
    
    func testTerminalAppBundleIdentifiers() {
        XCTAssertEqual(TerminalApp.iTerm2.bundleIdentifier, "com.googlecode.iterm2")
        XCTAssertEqual(TerminalApp.terminal.bundleIdentifier, "com.apple.Terminal")
    }
    
    // MARK: - Terminal Detection Tests
    
    func testDetectAvailableTerminal() {
        // 这个测试依赖于系统环境，至少应该有Terminal可用
        do {
            let terminalApp = try sshIntegrator.detectAvailableTerminal()
            XCTAssertTrue(terminalApp == .iTerm2 || terminalApp == .terminal)
        } catch {
            // 在某些测试环境中可能没有终端应用程序
            if case JMSError.terminalNotFound = error {
                print("未检测到终端应用程序（可能在无头环境中）")
            } else {
                XCTFail("意外的错误: \(error)")
            }
        }
    }
    
    // MARK: - SSH Connection Info Tests
    
    func testSSHConnectionInfoBasic() {
        let connectionInfo = SSHConnectionInfo(
            ip: "192.168.1.100",
            username: "testuser"
        )
        
        XCTAssertEqual(connectionInfo.ip, "192.168.1.100")
        XCTAssertEqual(connectionInfo.port, 22) // 默认端口
        XCTAssertEqual(connectionInfo.username, "testuser")
        XCTAssertNil(connectionInfo.password)
        XCTAssertEqual(connectionInfo.connectionString, "testuser@192.168.1.100")
    }
    
    func testSSHConnectionInfoWithCustomPort() {
        let connectionInfo = SSHConnectionInfo(
            ip: "192.168.1.100",
            port: 2222,
            username: "testuser"
        )
        
        XCTAssertEqual(connectionInfo.port, 2222)
        XCTAssertEqual(connectionInfo.connectionString, "testuser@192.168.1.100 -p 2222")
    }
    
    func testSSHConnectionInfoWithPassword() {
        let connectionInfo = SSHConnectionInfo(
            ip: "192.168.1.100",
            username: "testuser",
            password: "testpass"
        )
        
        XCTAssertEqual(connectionInfo.password, "testpass")
    }
    
    func testSSHConnectionInfoWithAdditionalParams() {
        let additionalParams = [
            "key1": "value1",
            "key2": "value2"
        ]
        
        let connectionInfo = SSHConnectionInfo(
            ip: "192.168.1.100",
            username: "testuser",
            additionalParams: additionalParams
        )
        
        XCTAssertEqual(connectionInfo.additionalParams.count, 2)
        XCTAssertEqual(connectionInfo.additionalParams["key1"], "value1")
        XCTAssertEqual(connectionInfo.additionalParams["key2"], "value2")
    }
    
    // MARK: - Integration Tests
    
    func testSSHConnectionFlow() throws {
        let connectionInfo = SSHConnectionInfo(
            ip: "test.server.com",
            port: 2222,
            username: "testuser",
            password: "testpass"
        )
        
        // 测试SSH命令构建
        let basicCommand = sshIntegrator.buildSSHCommand(connectionInfo)
        XCTAssertTrue(basicCommand.contains("ssh"))
        XCTAssertTrue(basicCommand.contains("-p 2222"))
        XCTAssertTrue(basicCommand.contains("testuser@test.server.com"))
        
        // 测试带密码的SSH命令构建
        let passwordCommand = try sshIntegrator.buildSSHCommandWithPassword(connectionInfo)
        XCTAssertNotNil(passwordCommand)
        XCTAssertFalse(passwordCommand.isEmpty)
    }
    
    func testSSHCommandSecurity() {
        let connectionInfo = SSHConnectionInfo(
            ip: "192.168.1.100",
            username: "testuser"
        )
        
        let command = sshIntegrator.buildSSHCommand(connectionInfo)
        
        // 验证安全选项
        XCTAssertTrue(command.contains("-o StrictHostKeyChecking=no"))
        XCTAssertTrue(command.contains("-o UserKnownHostsFile=/dev/null"))
    }
    
    func testSSHCommandValidation() {
        // 测试各种边界情况
        let testCases = [
            SSHConnectionInfo(ip: "127.0.0.1", username: "root"),
            SSHConnectionInfo(ip: "::1", username: "admin"), // IPv6
            SSHConnectionInfo(ip: "example.com", port: 443, username: "user"),
            SSHConnectionInfo(ip: "192.168.1.1", port: 65535, username: "test")
        ]
        
        for connectionInfo in testCases {
            let command = sshIntegrator.buildSSHCommand(connectionInfo)
            
            // 基本验证
            XCTAssertTrue(command.contains("ssh"))
            XCTAssertTrue(command.contains(connectionInfo.username))
            XCTAssertTrue(command.contains(connectionInfo.ip))
            
            if connectionInfo.port != 22 {
                XCTAssertTrue(command.contains("-p \(connectionInfo.port)"))
            }
        }
    }
    
    func testSSHConnectionStringGeneration() {
        let testCases = [
            (SSHConnectionInfo(ip: "192.168.1.1", username: "user"), "user@192.168.1.1"),
            (SSHConnectionInfo(ip: "example.com", port: 2222, username: "admin"), "admin@example.com -p 2222"),
            (SSHConnectionInfo(ip: "::1", port: 22, username: "root"), "root@::1"),
            (SSHConnectionInfo(ip: "test.local", port: 443, username: "test"), "test@test.local -p 443")
        ]
        
        for (connectionInfo, expectedString) in testCases {
            XCTAssertEqual(connectionInfo.connectionString, expectedString)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testSSHErrorHandling() {
        // 测试无效的连接信息处理
        // 注意：这些测试主要验证代码不会崩溃，而不是验证特定的错误类型
        
        let invalidConnectionInfo = SSHConnectionInfo(
            ip: "",
            username: ""
        )
        
        // 即使是无效的连接信息，buildSSHCommand也应该能够处理
        let command = sshIntegrator.buildSSHCommand(invalidConnectionInfo)
        XCTAssertTrue(command.contains("ssh"))
    }
    
    // MARK: - Performance Tests
    
    func testSSHCommandBuildingPerformance() {
        let connectionInfo = SSHConnectionInfo(
            ip: "192.168.1.100",
            port: 2222,
            username: "testuser",
            password: "testpass"
        )
        
        measure {
            for _ in 0..<1000 {
                _ = sshIntegrator.buildSSHCommand(connectionInfo)
            }
        }
    }
    
    func testSSHConnectionInfoCreationPerformance() {
        measure {
            for i in 0..<1000 {
                _ = SSHConnectionInfo(
                    ip: "192.168.1.\(i % 255)",
                    port: 22 + (i % 1000),
                    username: "user\(i)",
                    password: "pass\(i)"
                )
            }
        }
    }
}
