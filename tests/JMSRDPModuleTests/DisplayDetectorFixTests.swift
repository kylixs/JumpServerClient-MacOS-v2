import XCTest
import CoreGraphics
@testable import JMSRDPModule
@testable import JMSCore

/// HiDPI修复验证测试
final class DisplayDetectorFixTests: XCTestCase {
    
    var displayDetector: DisplayDetector!
    
    override func setUp() {
        super.setUp()
        displayDetector = DisplayDetector()
    }
    
    override func tearDown() {
        displayDetector = nil
        super.tearDown()
    }
    
    // MARK: - HiDPI修复验证测试
    
    func testPhysicalResolutionDetection() {
        // 测试物理分辨率检测是否正确
        do {
            let config = try displayDetector.detectPrimaryDisplay()
            
            // 验证分辨率不为零
            XCTAssertGreaterThan(config.width, 0, "物理宽度应该大于0")
            XCTAssertGreaterThan(config.height, 0, "物理高度应该大于0")
            
            // 获取逻辑分辨率进行对比
            let mainDisplayID = CGMainDisplayID()
            let logicalBounds = CGDisplayBounds(mainDisplayID)
            let logicalWidth = Int(logicalBounds.width)
            let logicalHeight = Int(logicalBounds.height)
            
            print("📏 检测结果:")
            print("   物理分辨率: \(config.width) × \(config.height)")
            print("   逻辑分辨率: \(logicalWidth) × \(logicalHeight)")
            print("   缩放因子: \(String(format: "%.2f", config.scaleFactor))")
            print("   HiDPI: \(config.isHiDPI)")
            
            // 如果是HiDPI显示器，物理分辨率应该大于逻辑分辨率
            if config.isHiDPI {
                XCTAssertGreaterThanOrEqual(config.width, logicalWidth, "HiDPI显示器的物理宽度应该大于等于逻辑宽度")
                XCTAssertGreaterThanOrEqual(config.height, logicalHeight, "HiDPI显示器的物理高度应该大于等于逻辑高度")
                XCTAssertGreaterThan(config.scaleFactor, 1.0, "HiDPI显示器的缩放因子应该大于1.0")
            } else {
                // 非HiDPI显示器，物理分辨率应该等于逻辑分辨率
                XCTAssertEqual(config.scaleFactor, 1.0, accuracy: 0.1, "非HiDPI显示器的缩放因子应该接近1.0")
            }
            
        } catch {
            XCTFail("显示器检测失败: \(error.localizedDescription)")
        }
    }
    
    func testScaleFactorAccuracy() {
        // 测试缩放因子计算的准确性
        do {
            let config = try displayDetector.detectPrimaryDisplay()
            
            // 缩放因子应该在合理范围内
            XCTAssertGreaterThan(config.scaleFactor, 0.5, "缩放因子不应该小于0.5")
            XCTAssertLessThan(config.scaleFactor, 5.0, "缩放因子不应该大于5.0")
            
            // 对于HiDPI显示器，缩放因子通常是1.5, 2.0, 2.5, 3.0等
            if config.isHiDPI {
                XCTAssertGreaterThan(config.scaleFactor, 1.2, "HiDPI显示器的缩放因子应该大于1.2")
                
                // 验证缩放因子的合理性
                let commonScaleFactors: [Double] = [1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0]
                let tolerance = 0.3
                
                let isReasonableScale = commonScaleFactors.contains { factor in
                    abs(config.scaleFactor - factor) < tolerance
                }
                
                XCTAssertTrue(isReasonableScale, "缩放因子 \(config.scaleFactor) 应该接近常见的HiDPI缩放值")
            }
            
        } catch {
            XCTFail("显示器检测失败: \(error.localizedDescription)")
        }
    }
    
    func testHiDPIDetectionConsistency() {
        // 测试HiDPI检测的一致性
        do {
            let config = try displayDetector.detectPrimaryDisplay()
            
            // HiDPI检测应该与缩放因子一致
            if config.scaleFactor > 1.5 {
                XCTAssertTrue(config.isHiDPI, "缩放因子 > 1.5 时应该检测为HiDPI")
            } else {
                XCTAssertFalse(config.isHiDPI, "缩放因子 <= 1.5 时应该检测为非HiDPI")
            }
            
        } catch {
            XCTFail("显示器检测失败: \(error.localizedDescription)")
        }
    }
    
    func testMultipleDisplayDetection() {
        // 测试多显示器检测
        do {
            let configs = try displayDetector.detectAllDisplays()
            
            XCTAssertGreaterThan(configs.count, 0, "应该检测到至少一个显示器")
            
            for (index, config) in configs.enumerated() {
                print("🖥️ 显示器 \(index + 1):")
                print("   分辨率: \(config.width) × \(config.height)")
                print("   缩放因子: \(String(format: "%.2f", config.scaleFactor))")
                print("   HiDPI: \(config.isHiDPI)")
                print("   刷新率: \(config.refreshRate)Hz")
                print("   颜色深度: \(config.colorDepth)位")
                
                // 验证每个显示器的基本属性
                XCTAssertGreaterThan(config.width, 0)
                XCTAssertGreaterThan(config.height, 0)
                XCTAssertGreaterThan(config.scaleFactor, 0)
                XCTAssertGreaterThan(config.colorDepth, 0)
                XCTAssertGreaterThanOrEqual(config.refreshRate, 0)
            }
            
        } catch {
            XCTFail("多显示器检测失败: \(error.localizedDescription)")
        }
    }
    
    func testDisplayConfigurationProperties() {
        // 测试显示器配置属性的完整性
        do {
            let config = try displayDetector.detectPrimaryDisplay()
            
            // 验证所有属性都有合理的值
            XCTAssertGreaterThan(config.width, 800, "宽度应该大于800")
            XCTAssertGreaterThan(config.height, 600, "高度应该大于600")
            XCTAssertLessThan(config.width, 8000, "宽度应该小于8000")
            XCTAssertLessThan(config.height, 5000, "高度应该小于5000")
            
            XCTAssertGreaterThan(config.scaleFactor, 0.5)
            XCTAssertLessThan(config.scaleFactor, 5.0)
            
            XCTAssertTrue([8, 16, 24, 32].contains(config.colorDepth), "颜色深度应该是8, 16, 24或32位")
            
            XCTAssertGreaterThanOrEqual(config.refreshRate, 0)
            XCTAssertLessThan(config.refreshRate, 300, "刷新率应该小于300Hz")
            
            XCTAssertGreaterThan(config.displayID, 0, "显示器ID应该大于0")
            
        } catch {
            XCTFail("显示器配置属性验证失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 性能测试
    
    func testDisplayDetectionPerformance() {
        // 测试显示器检测性能
        measure {
            do {
                _ = try displayDetector.detectPrimaryDisplay()
            } catch {
                XCTFail("性能测试中显示器检测失败: \(error.localizedDescription)")
            }
        }
    }
    
    func testMultipleDetectionPerformance() {
        // 测试多次检测的性能
        measure {
            for _ in 0..<10 {
                do {
                    _ = try displayDetector.detectPrimaryDisplay()
                } catch {
                    XCTFail("多次检测性能测试失败: \(error.localizedDescription)")
                }
            }
        }
    }
}
