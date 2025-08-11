//
//  PerformanceOptimizationTests.swift
//  JMSProtocolHandlerTests
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import XCTest
@testable import JMSProtocolHandler

class PerformanceOptimizationTests: XCTestCase {
    
    var displayDetector: DisplayDetector!
    var configOptimizer: RDPConfigOptimizer!
    var remoteDesktopIntegrator: RemoteDesktopIntegrator!
    
    override func setUp() {
        super.setUp()
        displayDetector = DisplayDetector()
        configOptimizer = RDPConfigOptimizer()
        remoteDesktopIntegrator = RemoteDesktopIntegrator()
    }
    
    override func tearDown() {
        remoteDesktopIntegrator.cleanupAllTemporaryFiles()
        displayDetector = nil
        configOptimizer = nil
        remoteDesktopIntegrator = nil
        super.tearDown()
    }
    
    // MARK: - Display Detection Performance Tests
    
    func testDisplayDetectionPerformance() {
        // Given
        let iterations = 100
        var totalTime: Double = 0
        var results: [Double] = []
        
        // When - 多次执行显示器检测
        for i in 1...iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                _ = try displayDetector.detectPrimaryDisplay()
                let iterationTime = CFAbsoluteTimeGetCurrent() - startTime
                totalTime += iterationTime
                results.append(iterationTime)
                
                if i <= 5 || i % 20 == 0 {
                    print("显示器检测迭代 \(i): \(String(format: "%.3f", iterationTime * 1000))ms")
                }
                
            } catch {
                XCTFail("显示器检测迭代 \(i) 失败: \(error)")
            }
        }
        
        // Then - 分析性能指标
        let averageTime = totalTime / Double(iterations)
        let minTime = results.min() ?? 0
        let maxTime = results.max() ?? 0
        
        // 性能要求
        let maxAcceptableAverage = 0.010 // 10ms
        let maxAcceptableSingle = 0.050 // 50ms
        
        XCTAssertLessThan(averageTime, maxAcceptableAverage, "平均检测时间应小于10ms")
        XCTAssertLessThan(maxTime, maxAcceptableSingle, "单次检测时间应小于50ms")
        
        print("✅ 显示器检测性能测试通过:")
        print("   - 总时间: \(String(format: "%.3f", totalTime * 1000))ms")
        print("   - 平均时间: \(String(format: "%.3f", averageTime * 1000))ms")
        print("   - 最小时间: \(String(format: "%.3f", minTime * 1000))ms")
        print("   - 最大时间: \(String(format: "%.3f", maxTime * 1000))ms")
        print("   - 检测频率: \(String(format: "%.0f", Double(iterations) / totalTime)) 次/秒")
    }
    
    func testRDPConfigGenerationPerformance() {
        // Given
        let testDisplay = DisplayConfiguration(
            width: 1920, height: 1080, scaleFactor: 1.0,
            colorDepth: 24, isRetina: false
        )
        
        let rdpInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser"
        )
        
        let iterations = 1000
        var totalTime: Double = 0
        
        // When - 多次执行RDP配置生成
        for i in 1...iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let displaySettings = configOptimizer.optimizeForDisplay(testDisplay)
            let configString = configOptimizer.generateRDPConfigString(displaySettings, connectionInfo: rdpInfo)
            
            let iterationTime = CFAbsoluteTimeGetCurrent() - startTime
            totalTime += iterationTime
            
            // 验证生成的配置不为空
            XCTAssertFalse(configString.isEmpty, "生成的RDP配置不应为空")
            
            if i <= 5 || i % 200 == 0 {
                print("RDP配置生成迭代 \(i): \(String(format: "%.3f", iterationTime * 1000))ms")
            }
        }
        
        // Then - 验证性能指标
        let averageTime = totalTime / Double(iterations)
        let maxAcceptableAverage = 0.001 // 1ms
        let throughput = Double(iterations) / totalTime
        
        XCTAssertLessThan(averageTime, maxAcceptableAverage, "平均配置生成时间应小于1ms")
        XCTAssertGreaterThan(throughput, 1000, "吞吐量应大于1000次/秒")
        
        print("✅ RDP配置生成性能测试通过:")
        print("   - 总时间: \(String(format: "%.3f", totalTime * 1000))ms")
        print("   - 平均时间: \(String(format: "%.6f", averageTime * 1000))ms")
        print("   - 吞吐量: \(String(format: "%.0f", throughput)) 次/秒")
    }
    
    // MARK: - HiDPI Display Configuration Tests
    
    func testHiDPIDisplayConfiguration() {
        // Given - 模拟各种HiDPI显示器
        let hiDPIConfigurations = [
            // MacBook Pro 13" Retina
            DisplayConfiguration(width: 2560, height: 1600, scaleFactor: 2.0, colorDepth: 32, isRetina: true),
            // MacBook Pro 14" Retina
            DisplayConfiguration(width: 3024, height: 1964, scaleFactor: 2.0, colorDepth: 32, isRetina: true),
            // MacBook Pro 16" Retina
            DisplayConfiguration(width: 3456, height: 2234, scaleFactor: 2.0, colorDepth: 32, isRetina: true),
            // iMac 24" Retina
            DisplayConfiguration(width: 4480, height: 2520, scaleFactor: 2.0, colorDepth: 32, isRetina: true),
            // Studio Display
            DisplayConfiguration(width: 5120, height: 2880, scaleFactor: 2.0, colorDepth: 32, isRetina: true)
        ]
        
        // When & Then - 测试每种HiDPI配置
        for (index, config) in hiDPIConfigurations.enumerated() {
            print("🔄 测试HiDPI配置 \(index + 1): \(config.width)x\(config.height) @\(config.scaleFactor)x")
            
            let optimizedSettings = configOptimizer.optimizeForDisplay(config)
            
            // HiDPI特定验证
            XCTAssertTrue(config.isRetina, "配置应标记为Retina")
            XCTAssertEqual(config.scaleFactor, 2.0, "HiDPI缩放因子应为2.0")
            
            // 优化设置验证
            XCTAssertGreaterThan(optimizedSettings.desktopScaleFactor, 100, "HiDPI应有缩放因子")
            XCTAssertLessThanOrEqual(optimizedSettings.desktopScaleFactor, 300, "缩放因子应在合理范围内")
            XCTAssertEqual(optimizedSettings.compression, 0, "HiDPI应使用无压缩")
            XCTAssertTrue(optimizedSettings.allowFontSmoothing, "HiDPI应启用字体平滑")
            XCTAssertEqual(optimizedSettings.sessionBpp, 32, "HiDPI应使用32位颜色")
            
            // 分辨率优化验证
            XCTAssertLessThanOrEqual(optimizedSettings.desktopWidth, 3840, "宽度不应超过4K")
            XCTAssertLessThanOrEqual(optimizedSettings.desktopHeight, 2160, "高度不应超过4K")
            
            // 验证设置有效性
            XCTAssertTrue(configOptimizer.validateRDPSettings(optimizedSettings), "HiDPI优化设置应有效")
            
            print("✅ HiDPI配置 \(index + 1) 优化成功")
        }
    }
    
    // MARK: - Multi-Display Performance Tests
    
    func testMultiDisplayPerformance() {
        // Given
        let iterations = 50
        var totalTime: Double = 0
        
        // When - 多次执行多显示器检测
        for i in 1...iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                let allDisplays = try displayDetector.detectAllDisplays()
                let primaryDisplay = try displayDetector.detectPrimaryDisplay()
                
                let iterationTime = CFAbsoluteTimeGetCurrent() - startTime
                totalTime += iterationTime
                
                // 验证检测结果
                XCTAssertGreaterThan(allDisplays.count, 0, "应检测到至少一个显示器")
                XCTAssertNotNil(primaryDisplay, "应检测到主显示器")
                
                if i <= 5 || i % 10 == 0 {
                    print("多显示器检测迭代 \(i): \(String(format: "%.3f", iterationTime * 1000))ms, 检测到 \(allDisplays.count) 个显示器")
                }
                
            } catch {
                XCTFail("多显示器检测迭代 \(i) 失败: \(error)")
            }
        }
        
        // Then - 验证性能
        let averageTime = totalTime / Double(iterations)
        let maxAcceptableTime = 0.020 // 20ms
        
        XCTAssertLessThan(averageTime, maxAcceptableTime, "多显示器检测平均时间应小于20ms")
        
        print("✅ 多显示器性能测试通过:")
        print("   - 平均时间: \(String(format: "%.3f", averageTime * 1000))ms")
        print("   - 总时间: \(String(format: "%.3f", totalTime * 1000))ms")
    }
    
    // MARK: - Memory Usage Tests
    
    func testMemoryUsageOptimization() {
        // Given
        let iterations = 1000
        let rdpInfo = RDPConnectionInfo(fullAddress: "test.example.com:3389", username: "testuser")
        
        // 记录初始内存使用
        let initialMemory = getMemoryUsage()
        
        // When - 执行大量操作
        for i in 1...iterations {
            do {
                let displaySettings = try remoteDesktopIntegrator.detectAndOptimizeDisplay()
                let rdpFileURL = try remoteDesktopIntegrator.createOptimizedRDPFile(
                    with: rdpInfo,
                    displaySettings: displaySettings
                )
                
                // 立即清理以测试内存管理
                remoteDesktopIntegrator.cleanupTemporaryFile(at: rdpFileURL)
                
                // 每100次迭代检查一次内存
                if i % 100 == 0 {
                    let currentMemory = getMemoryUsage()
                    let memoryIncrease = currentMemory - initialMemory
                    print("迭代 \(i): 内存使用 \(String(format: "%.2f", currentMemory))MB (+\(String(format: "%.2f", memoryIncrease))MB)")
                    
                    // 内存增长不应超过50MB
                    XCTAssertLessThan(memoryIncrease, 50.0, "内存增长应控制在50MB以内")
                }
                
            } catch {
                XCTFail("内存测试迭代 \(i) 失败: \(error)")
            }
        }
        
        // Then - 验证最终内存使用
        let finalMemory = getMemoryUsage()
        let totalIncrease = finalMemory - initialMemory
        
        XCTAssertLessThan(totalIncrease, 100.0, "总内存增长应小于100MB")
        
        print("✅ 内存使用优化测试通过:")
        print("   - 初始内存: \(String(format: "%.2f", initialMemory))MB")
        print("   - 最终内存: \(String(format: "%.2f", finalMemory))MB")
        print("   - 内存增长: \(String(format: "%.2f", totalIncrease))MB")
    }
    
    // MARK: - Apple Silicon Optimization Tests
    
    func testAppleSiliconOptimization() {
        // Given - 检测当前架构
        let architecture = getCurrentArchitecture()
        print("当前架构: \(architecture)")
        
        // When - 执行性能测试
        let iterations = 100
        var totalTime: Double = 0
        
        for i in 1...iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                let displaySettings = try remoteDesktopIntegrator.detectAndOptimizeDisplay()
                let rdpInfo = RDPConnectionInfo(fullAddress: "test.example.com:3389", username: "testuser")
                let rdpFileURL = try remoteDesktopIntegrator.createOptimizedRDPFile(
                    with: rdpInfo,
                    displaySettings: displaySettings
                )
                
                let iterationTime = CFAbsoluteTimeGetCurrent() - startTime
                totalTime += iterationTime
                
                // 清理
                remoteDesktopIntegrator.cleanupTemporaryFile(at: rdpFileURL)
                
            } catch {
                XCTFail("Apple Silicon优化测试迭代 \(i) 失败: \(error)")
            }
        }
        
        // Then - 验证性能（Apple Silicon应该更快）
        let averageTime = totalTime / Double(iterations)
        let expectedMaxTime = architecture.contains("arm64") ? 0.005 : 0.010 // Apple Silicon更严格的要求
        
        XCTAssertLessThan(averageTime, expectedMaxTime, "在\(architecture)上的性能应满足要求")
        
        print("✅ \(architecture) 优化测试通过:")
        print("   - 平均时间: \(String(format: "%.3f", averageTime * 1000))ms")
        print("   - 性能要求: < \(String(format: "%.3f", expectedMaxTime * 1000))ms")
    }
    
    // MARK: - Configuration Quality Tests
    
    func testRDPConfigurationQuality() {
        // Given - 不同的显示器配置
        let testConfigurations = [
            ("1080p Standard", DisplayConfiguration(width: 1920, height: 1080, scaleFactor: 1.0, colorDepth: 24, isRetina: false)),
            ("4K Standard", DisplayConfiguration(width: 3840, height: 2160, scaleFactor: 1.0, colorDepth: 32, isRetina: false)),
            ("MacBook Retina", DisplayConfiguration(width: 2880, height: 1800, scaleFactor: 2.0, colorDepth: 32, isRetina: true)),
            ("Ultrawide", DisplayConfiguration(width: 3440, height: 1440, scaleFactor: 1.0, colorDepth: 24, isRetina: false))
        ]
        
        let rdpInfo = RDPConnectionInfo(fullAddress: "test.example.com:3389", username: "testuser")
        
        // When & Then - 测试每种配置的质量
        for (name, config) in testConfigurations {
            print("🔄 测试配置质量: \(name)")
            
            let optimizedSettings = configOptimizer.optimizeForDisplay(config)
            let configString = configOptimizer.generateRDPConfigString(optimizedSettings, connectionInfo: rdpInfo)
            
            // 验证配置质量
            XCTAssertTrue(configOptimizer.validateRDPSettings(optimizedSettings), "\(name) 配置应有效")
            XCTAssertFalse(configString.isEmpty, "\(name) 配置字符串不应为空")
            
            // 验证关键参数存在
            XCTAssertTrue(configString.contains("desktopwidth:i:"), "\(name) 应包含桌面宽度")
            XCTAssertTrue(configString.contains("desktopheight:i:"), "\(name) 应包含桌面高度")
            XCTAssertTrue(configString.contains("session bpp:i:"), "\(name) 应包含颜色深度")
            
            // 特殊配置验证
            if config.isRetina {
                XCTAssertTrue(configString.contains("allow font smoothing:i:1"), "Retina配置应启用字体平滑")
                XCTAssertTrue(configString.contains("compression:i:0"), "Retina配置应使用无压缩")
            }
            
            print("✅ \(name) 配置质量验证通过")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0.0
        }
    }
    
    private func getCurrentArchitecture() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }
        return machine ?? "unknown"
    }
}
