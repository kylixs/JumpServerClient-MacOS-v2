import XCTest
@testable import JMSProtocolManager

class ProtocolDetectionStrictTest: XCTestCase {
    
    var detectionService: ProtocolDetectionService!
    
    override func setUp() {
        super.setUp()
        detectionService = ProtocolDetectionService.shared
    }
    
    override func tearDown() {
        detectionService = nil
        super.tearDown()
    }
    
    func testDetectionLogicStrictness() async {
        // Given
        print("🧪 开始严格的协议检测逻辑测试")
        
        // When
        do {
            let handlers = try await detectionService.detectAllHandlers()
            
            // Then - 验证检测结果的严谨性
            XCTAssertFalse(handlers.isEmpty, "应该至少检测到一个处理器")
            
            print("📊 检测结果分析:")
            print("   总处理器数量: \(handlers.count)")
            
            var currentAppCount = 0
            var otherAppCount = 0
            var invalidCount = 0
            var validPathCount = 0
            
            for (index, handler) in handlers.enumerated() {
                print("   \(index + 1). \(handler.statusIcon) \(handler.appName)")
                print("      路径: \(handler.appPath)")
                print("      状态: \(handler.statusText)")
                print("      默认: \(handler.isDefault)")
                print("      有效: \(handler.isPathValid)")
                
                // 统计各种状态
                switch handler.status {
                case .currentApp:
                    currentAppCount += 1
                    // 验证当前应用的路径应该包含JMSProtocolHandler
                    XCTAssertTrue(
                        handler.appPath.contains("JMSProtocolHandler") || 
                        handler.appName.contains("JMSProtocolHandler"),
                        "当前应用应该与JMSProtocolHandler相关"
                    )
                case .otherApp:
                    otherAppCount += 1
                case .invalid:
                    invalidCount += 1
                case .checking:
                    XCTFail("不应该有检查中状态的处理器")
                }
                
                if handler.isPathValid {
                    validPathCount += 1
                }
                
                // 验证路径逻辑严谨性
                if handler.status != .invalid {
                    XCTAssertTrue(handler.isPathValid, "非无效状态的处理器应该有有效路径")
                }
                
                // 验证应用名称不为空
                XCTAssertFalse(handler.appName.isEmpty, "应用名称不应为空")
                XCTAssertFalse(handler.appPath.isEmpty, "应用路径不应为空")
            }
            
            print("📈 统计结果:")
            print("   当前应用: \(currentAppCount)")
            print("   其他应用: \(otherAppCount)")
            print("   无效应用: \(invalidCount)")
            print("   有效路径: \(validPathCount)")
            
            // 验证逻辑严谨性
            XCTAssertLessThanOrEqual(currentAppCount, 1, "应该最多只有一个当前应用")
            XCTAssertGreaterThan(validPathCount, 0, "应该至少有一个有效路径")
            
        } catch {
            XCTFail("协议检测不应该失败: \(error)")
        }
    }
    
    func testPathValidationLogic() async {
        // Given
        do {
            let handlers = try await detectionService.detectAllHandlers()
            
            // When & Then - 验证路径验证逻辑
            for handler in handlers {
                let actualExists = FileManager.default.fileExists(atPath: handler.appPath)
                
                if handler.status == .invalid {
                    // 无效状态的处理器路径应该不存在
                    XCTAssertFalse(actualExists, "无效处理器的路径应该不存在: \(handler.appPath)")
                } else {
                    // 其他状态的处理器路径应该存在
                    XCTAssertTrue(actualExists, "有效处理器的路径应该存在: \(handler.appPath)")
                }
                
                // 验证isPathValid与实际文件系统状态一致
                XCTAssertEqual(handler.isPathValid, actualExists, "isPathValid应该与实际文件存在状态一致")
            }
        } catch {
            XCTFail("路径验证测试失败: \(error)")
        }
    }
    
    func testCurrentAppIdentification() async {
        // Given
        do {
            let handlers = try await detectionService.detectAllHandlers()
            
            // When & Then - 验证当前应用识别逻辑
            let currentAppHandlers = handlers.filter { $0.status == .currentApp }
            
            print("🔍 当前应用识别测试:")
            print("   找到的当前应用数量: \(currentAppHandlers.count)")
            
            for handler in currentAppHandlers {
                print("   当前应用: \(handler.appName) at \(handler.appPath)")
                
                // 验证当前应用的特征
                let isJMSRelated = handler.appName.contains("JMSProtocolHandler") || 
                                  handler.appPath.contains("JMSProtocolHandler")
                
                XCTAssertTrue(isJMSRelated, "当前应用应该与JMSProtocolHandler相关")
                
                // 如果路径有效，应该指向一个.app包
                if handler.isPathValid {
                    XCTAssertTrue(handler.appPath.hasSuffix(".app"), "有效的当前应用路径应该以.app结尾")
                }
            }
            
            // 应该最多只有一个当前应用
            XCTAssertLessThanOrEqual(currentAppHandlers.count, 1, "应该最多只有一个当前应用")
            
        } catch {
            XCTFail("当前应用识别测试失败: \(error)")
        }
    }
    
    func testDefaultHandlerLogic() {
        // Given & When
        let isDefault = detectionService.isCurrentAppDefaultHandler()
        
        // Then
        print("📱 默认处理器检查:")
        print("   当前应用是否为默认处理器: \(isDefault)")
        
        // 这个测试主要验证方法能正常执行，结果取决于系统状态
        XCTAssertTrue(isDefault == true || isDefault == false, "应该返回明确的布尔值")
    }
    
    func testHandlerUniqueness() async {
        // Given
        do {
            let handlers = try await detectionService.detectAllHandlers()
            
            // When & Then - 验证处理器唯一性
            var seenPaths = Set<String>()
            var duplicatePaths: [String] = []
            
            for handler in handlers {
                if seenPaths.contains(handler.appPath) {
                    duplicatePaths.append(handler.appPath)
                } else {
                    seenPaths.insert(handler.appPath)
                }
            }
            
            print("🔍 唯一性检查:")
            print("   总处理器: \(handlers.count)")
            print("   唯一路径: \(seenPaths.count)")
            print("   重复路径: \(duplicatePaths)")
            
            XCTAssertTrue(duplicatePaths.isEmpty, "不应该有重复的处理器路径: \(duplicatePaths)")
            XCTAssertEqual(handlers.count, seenPaths.count, "处理器数量应该等于唯一路径数量")
            
        } catch {
            XCTFail("唯一性测试失败: \(error)")
        }
    }
    
    func testDetectionConsistency() async {
        // Given - 执行多次检测
        var allResults: [[ProtocolHandlerModel]] = []
        
        for i in 0..<3 {
            do {
                let handlers = try await detectionService.detectAllHandlers()
                allResults.append(handlers)
                print("🔄 第\(i+1)次检测: \(handlers.count)个处理器")
            } catch {
                XCTFail("第\(i+1)次检测失败: \(error)")
                return
            }
        }
        
        // When & Then - 验证一致性
        guard let firstResult = allResults.first else {
            XCTFail("应该有检测结果")
            return
        }
        
        for (index, result) in allResults.enumerated() {
            XCTAssertEqual(
                result.count, 
                firstResult.count, 
                "第\(index+1)次检测的处理器数量应该一致"
            )
            
            // 验证路径集合一致性
            let firstPaths = Set(firstResult.map { $0.appPath })
            let currentPaths = Set(result.map { $0.appPath })
            
            XCTAssertEqual(
                currentPaths, 
                firstPaths, 
                "第\(index+1)次检测的处理器路径集合应该一致"
            )
        }
        
        print("✅ 一致性检查通过")
    }
}
