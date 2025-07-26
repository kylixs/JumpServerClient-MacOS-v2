import Foundation
import Cocoa

/// RemoteDesktopIntegrator功能测试
class RemoteDesktopIntegratorTests {
    
    private let integrator = RemoteDesktopIntegrator()
    
    func runAllTests() {
        print("=== RemoteDesktopIntegrator 功能测试 ===\n")
        
        testCheckRemoteDesktopAvailability()
        testCreateTemporaryRDPFile()
        testRDPContentGeneration()
        testTemporaryFileCleanup()
        testRemoteDesktopVersion()
        testLaunchRemoteDesktop()
        testConnectionInfoValidation()
        
        print("\n=== 测试完成 ===")
    }
    
    // MARK: - Test Methods
    
    func testCheckRemoteDesktopAvailability() {
        print("1. 测试Microsoft Remote Desktop可用性检查")
        
        let isAvailable = integrator.checkRemoteDesktopAvailability()
        print("   Microsoft Remote Desktop 可用性: \(isAvailable ? "✅ 已安装" : "❌ 未安装")")
        
        if isAvailable {
            if let version = integrator.getRemoteDesktopVersion() {
                print("   版本信息: \(version)")
            }
        } else {
            print("   提示: 请安装Microsoft Remote Desktop以进行完整测试")
        }
        print()
    }
    
    func testCreateTemporaryRDPFile() {
        print("2. 测试临时RDP文件创建")
        
        let connectionInfo = ConnectionInfo(
            fullAddress: "test-server.example.com:3389",
            username: "testuser|test-session-id",
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
            let fileURL = try integrator.createTemporaryRDPFile(with: connectionInfo)
            print("   ✅ 临时RDP文件创建成功")
            print("   文件路径: \(fileURL.path)")
            
            // 验证文件内容
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            print("   文件内容预览:")
            print("   \(content.prefix(200))...")
            
            // 验证必要字段
            let requiredFields = [
                "full address:s:test-server.example.com:3389",
                "username:s:testuser|test-session-id",
                "session bpp:i:32",
                "audiomode:i:0"
            ]
            
            var allFieldsPresent = true
            for field in requiredFields {
                if !content.contains(field) {
                    print("   ❌ 缺少必要字段: \(field)")
                    allFieldsPresent = false
                }
            }
            
            if allFieldsPresent {
                print("   ✅ 所有必要字段都存在")
            }
            
            // 清理测试文件
            integrator.cleanupTemporaryFile(at: fileURL)
            print("   ✅ 测试文件已清理")
            
        } catch {
            print("   ❌ 临时RDP文件创建失败: \(error)")
        }
        print()
    }
    
    func testRDPContentGeneration() {
        print("3. 测试RDP内容生成")
        
        let connectionInfo = ConnectionInfo(
            fullAddress: "server.example.com:3389",
            username: "user123",
            sessionBpp: 24,
            audioMode: 1,
            smartSizing: false,
            screenModeId: 1,
            additionalConfig: [
                "desktopwidth": "1440",
                "desktopheight": "900",
                "compression": "1"
            ]
        )
        
        let rdpContent = connectionInfo.generateRDPContent()
        print("   生成的RDP内容:")
        print("   \(rdpContent)")
        
        // 验证内容格式
        let lines = rdpContent.components(separatedBy: "\n")
        var validFormat = true
        
        for line in lines {
            if !line.contains(":") {
                print("   ❌ 无效的RDP行格式: \(line)")
                validFormat = false
            }
        }
        
        if validFormat {
            print("   ✅ RDP内容格式正确")
        }
        print()
    }
    
    func testTemporaryFileCleanup() {
        print("4. 测试临时文件清理功能")
        
        let connectionInfo = ConnectionInfo(
            fullAddress: "cleanup-test.example.com:3389",
            username: "cleanup-user"
        )
        
        do {
            // 创建多个临时文件
            var fileURLs: [URL] = []
            for i in 1...3 {
                let info = ConnectionInfo(
                    fullAddress: "test\(i).example.com:3389",
                    username: "user\(i)"
                )
                let fileURL = try integrator.createTemporaryRDPFile(with: info)
                fileURLs.append(fileURL)
            }
            
            print("   ✅ 创建了 \(fileURLs.count) 个临时文件")
            
            // 验证文件存在
            for fileURL in fileURLs {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    print("   ✅ 文件存在: \(fileURL.lastPathComponent)")
                } else {
                    print("   ❌ 文件不存在: \(fileURL.lastPathComponent)")
                }
            }
            
            // 清理所有临时文件
            integrator.cleanupAllTemporaryFiles()
            print("   ✅ 执行了批量清理")
            
            // 验证文件已被清理
            var cleanedCount = 0
            for fileURL in fileURLs {
                if !FileManager.default.fileExists(atPath: fileURL.path) {
                    cleanedCount += 1
                }
            }
            
            print("   ✅ 已清理 \(cleanedCount)/\(fileURLs.count) 个文件")
            
        } catch {
            print("   ❌ 临时文件清理测试失败: \(error)")
        }
        print()
    }
    
    func testRemoteDesktopVersion() {
        print("5. 测试获取Remote Desktop版本信息")
        
        if let version = integrator.getRemoteDesktopVersion() {
            print("   ✅ 获取到版本信息: \(version)")
        } else {
            print("   ❌ 无法获取版本信息（可能未安装Microsoft Remote Desktop）")
        }
        print()
    }
    
    func testLaunchRemoteDesktop() {
        print("6. 测试启动Remote Desktop（模拟测试）")
        
        let connectionInfo = ConnectionInfo(
            fullAddress: "demo.example.com:3389",
            username: "demo-user",
            sessionBpp: 32,
            audioMode: 0
        )
        
        // 首先检查可用性
        let isAvailable = integrator.checkRemoteDesktopAvailability()
        
        if isAvailable {
            print("   ✅ Microsoft Remote Desktop 可用")
            print("   ⚠️  跳过实际启动测试（避免打开应用程序）")
            
            // 只测试RDP文件创建部分
            do {
                let fileURL = try integrator.createTemporaryRDPFile(with: connectionInfo)
                print("   ✅ RDP文件创建成功，可以用于启动")
                
                // 立即清理
                integrator.cleanupTemporaryFile(at: fileURL)
                print("   ✅ 测试文件已清理")
                
            } catch {
                print("   ❌ RDP文件创建失败: \(error)")
            }
        } else {
            print("   ❌ Microsoft Remote Desktop 不可用")
            print("   测试启动功能需要先安装Microsoft Remote Desktop")
        }
        print()
    }
    
    // MARK: - Validation Tests
    
    func testConnectionInfoValidation() {
        print("7. 测试连接信息验证")
        
        // 测试有效的连接信息
        let validInfo = ConnectionInfo(
            fullAddress: "valid.server.com:3389",
            username: "validuser"
        )
        
        do {
            try validInfo.validate()
            print("   ✅ 有效连接信息验证通过")
        } catch {
            print("   ❌ 有效连接信息验证失败: \(error)")
        }
        
        // 测试无效的连接信息
        let invalidInfos = [
            ConnectionInfo(fullAddress: "", username: "user"),
            ConnectionInfo(fullAddress: "server.com", username: ""),
        ]
        
        for (index, invalidInfo) in invalidInfos.enumerated() {
            do {
                try invalidInfo.validate()
                print("   ❌ 无效连接信息 \(index + 1) 应该验证失败但通过了")
            } catch {
                print("   ✅ 无效连接信息 \(index + 1) 正确被拒绝: \(error)")
            }
        }
        print()
    }
}

// MARK: - 运行测试

let tests = RemoteDesktopIntegratorTests()
tests.runAllTests()
tests.testConnectionInfoValidation()
