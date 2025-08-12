//
//  GlobalGUICheckerTests.swift
//  JMSProtocolHandlerTests
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import XCTest
import Cocoa

class GlobalGUICheckerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var globalChecker: GlobalGUIChecker!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        globalChecker = GlobalGUIChecker()
        
        print("🧪 设置全局GUI检查测试环境")
    }
    
    override func tearDownWithError() throws {
        globalChecker = nil
        try super.tearDownWithError()
        
        print("🧹 清理全局GUI检查测试环境")
    }
    
    // MARK: - Global GUI Check Tests
    
    func testPerformGlobalGUICheck() throws {
        print("🔍 测试全局GUI检查...")
        
        // 执行全局GUI检查
        let report = globalChecker.performGlobalGUICheck()
        
        // 验证报告结构
        XCTAssertGreaterThan(report.totalInterfaces, 0, "应该检查至少一个界面")
        XCTAssertEqual(report.checkedInterfaces, report.interfaceReports.count, "检查的界面数量应该与报告数量一致")
        XCTAssertNotNil(report.timestamp, "应该有时间戳")
        XCTAssertGreaterThan(report.summary.executionTime, 0, "应该记录执行时间")
        
        // 验证摘要信息
        let summary = report.summary
        let totalCalculated = summary.criticalIssues + summary.majorIssues + summary.minorIssues + summary.warningIssues
        XCTAssertEqual(summary.totalIssues, totalCalculated, "总问题数应该等于各级别问题数之和")
        
        // 验证建议
        XCTAssertFalse(summary.recommendations.isEmpty, "应该有建议信息")
        
        print("✅ 全局GUI检查测试通过")
        print("📊 检查结果: \(report.passedInterfaces)个通过, \(report.failedInterfaces)个失败")
        print("🔍 发现问题: \(summary.totalIssues)个 (严重:\(summary.criticalIssues), 主要:\(summary.majorIssues), 次要:\(summary.minorIssues))")
    }
    
    func testRDPQualityConfigInterfaceCheck() throws {
        print("🔍 测试RDP质量配置界面检查...")
        
        // 获取RDP配置界面定义
        let interfaceDefinitionManager = InterfaceDefinitionManager.shared
        let rdpConfigDefinition = interfaceDefinitionManager.getInterfaceDefinition(by: "rdp_quality_config")
        
        XCTAssertNotNil(rdpConfigDefinition, "应该找到RDP配置界面定义")
        
        guard var definition = rdpConfigDefinition else { return }
        
        // 为测试设置视图控制器创建器
        definition = GlobalGUIChecker.InterfaceDefinition(
            name: definition.name,
            identifier: definition.identifier,
            expectedComponents: definition.expectedComponents,
            layoutRules: definition.layoutRules,
            loadingRequirements: definition.loadingRequirements,
            creator: {
                return TestViewControllerFactory.createStandardRDPQualityConfigViewController()
            }
        )
        
        // 检查RDP配置界面
        let report = globalChecker.checkInterface(definition)
        
        // 验证报告
        XCTAssertEqual(report.interfaceName, "RDP质量配置界面", "界面名称应该正确")
        XCTAssertNotEqual(report.status, .loadFailed, "界面应该能够加载")
        XCTAssertNotNil(report.componentTree, "应该生成组件树")
        XCTAssertLessThan(report.loadingTime, 2.0, "加载时间应该在合理范围内")
        
        // 验证组件检查
        print("📋 组件问题: \(report.componentIssues.count)个")
        for issue in report.componentIssues {
            print("   - \(issue.issueType.rawValue): \(issue.description)")
        }
        
        // 验证布局检查
        print("📐 布局问题: \(report.layoutIssues.count)个")
        for issue in report.layoutIssues {
            print("   - \(issue.issueType.rawValue): \(issue.description)")
        }
        
        // 验证加载检查
        print("⏱️ 加载问题: \(report.loadingIssues.count)个")
        for issue in report.loadingIssues {
            print("   - \(issue.issueType.rawValue): \(issue.description)")
        }
        
        print("✅ RDP质量配置界面检查测试通过")
    }
    
    func testInterfaceDefinitionValidation() throws {
        print("🔍 测试界面定义验证...")
        
        let interfaceDefinitionManager = InterfaceDefinitionManager.shared
        let interfaceDefinitions = interfaceDefinitionManager.getAllInterfaceDefinitions()
        
        XCTAssertFalse(interfaceDefinitions.isEmpty, "应该有界面定义")
        
        for definition in interfaceDefinitions {
            // 验证基本信息
            XCTAssertFalse(definition.name.isEmpty, "界面名称不应该为空")
            XCTAssertFalse(definition.identifier.isEmpty, "界面标识符不应该为空")
            
            // 验证期望组件
            XCTAssertFalse(definition.expectedComponents.isEmpty, "应该有期望的组件定义")
            
            for component in definition.expectedComponents {
                XCTAssertFalse(component.type.isEmpty, "组件类型不应该为空")
                
                if component.isRequired {
                    print("   必需组件: \(component.type) (\(component.identifier ?? "无标识符"))")
                }
            }
            
            // 验证布局规则
            print("   布局规则: \(definition.layoutRules.count)个")
            
            // 验证加载要求
            XCTAssertGreaterThan(definition.loadingRequirements.maxLoadTime, 0, "最大加载时间应该大于0")
            
            print("✅ 界面定义验证通过: \(definition.name)")
        }
        
        print("✅ 所有界面定义验证通过")
    }
    
    func testComponentIssueDetection() throws {
        print("🔍 测试组件问题检测...")
        
        // 创建简化的界面定义
        let definition = createSimpleInterfaceDefinition(
            viewController: TestViewControllerFactory.createProblematicViewController()
        )
        
        // 检查界面
        let report = globalChecker.checkInterface(definition)
        
        // 应该检测到问题
        XCTAssertGreaterThan(report.componentIssues.count + report.layoutIssues.count + report.loadingIssues.count, 0, 
                           "应该检测到至少一个问题")
        
        // 验证问题类型
        let issueTypes = Set(report.componentIssues.map { $0.issueType })
        print("📋 检测到的问题类型: \(issueTypes)")
        
        // 验证严重程度分布
        let severities = report.componentIssues.map { $0.severity }
        let severityCount = Dictionary(grouping: severities, by: { $0 }).mapValues { $0.count }
        print("📊 问题严重程度分布: \(severityCount)")
        
        print("✅ 组件问题检测测试通过")
    }
    
    func testLayoutIssueDetection() throws {
        print("🔍 测试布局问题检测...")
        
        // 创建简化的界面定义
        let definition = createSimpleInterfaceDefinition(
            viewController: TestViewControllerFactory.createOverlappingComponentsViewController()
        )
        
        // 检查界面
        let report = globalChecker.checkInterface(definition)
        
        // 应该检测到布局问题
        XCTAssertGreaterThan(report.layoutIssues.count, 0, "应该检测到布局问题")
        
        // 验证重叠问题
        let hasOverlapIssue = report.layoutIssues.contains { $0.issueType == .overlap }
        XCTAssertTrue(hasOverlapIssue, "应该检测到组件重叠问题")
        
        print("📐 检测到的布局问题: \(report.layoutIssues.count)个")
        for issue in report.layoutIssues {
            print("   - \(issue.issueType.rawValue): \(issue.description)")
        }
        
        print("✅ 布局问题检测测试通过")
    }
    
    func testLoadingIssueDetection() throws {
        print("🔍 测试加载问题检测...")
        
        // 创建一个加载缓慢的界面定义
        let slowLoadingDefinition = createSlowLoadingInterfaceDefinition()
        
        // 检查界面
        let report = globalChecker.checkInterface(slowLoadingDefinition)
        
        // 验证加载时间记录
        XCTAssertGreaterThan(report.loadingTime, 0, "应该记录加载时间")
        
        print("⏱️ 界面加载时间: \(String(format: "%.3f", report.loadingTime))秒")
        print("📋 加载问题: \(report.loadingIssues.count)个")
        
        print("✅ 加载问题检测测试通过")
    }
    
    func testReportGeneration() throws {
        print("🔍 测试报告生成...")
        
        // 执行全局检查
        let report = globalChecker.performGlobalGUICheck()
        
        // 验证报告可以序列化
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(report)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        XCTAssertNotNil(jsonString, "报告应该可以序列化为JSON")
        XCTAssertTrue(jsonString!.contains("timestamp"), "JSON应该包含时间戳")
        XCTAssertTrue(jsonString!.contains("totalInterfaces"), "JSON应该包含界面总数")
        XCTAssertTrue(jsonString!.contains("summary"), "JSON应该包含摘要信息")
        
        print("📄 报告JSON长度: \(jsonString!.count)字符")
        print("✅ 报告生成测试通过")
    }
    
    // MARK: - Performance Tests
    
    func testGlobalCheckPerformance() throws {
        print("🔍 测试全局检查性能...")
        
        measure {
            let _ = globalChecker.performGlobalGUICheck()
        }
        
        print("✅ 全局检查性能测试完成")
    }
    
    // MARK: - Helper Methods
    
    /// 创建简化的界面定义
    private func createSimpleInterfaceDefinition(viewController: NSViewController) -> GlobalGUIChecker.InterfaceDefinition {
        let expectedComponents: [GlobalGUIChecker.InterfaceDefinition.ExpectedComponent] = [
            GlobalGUIChecker.InterfaceDefinition.ExpectedComponent(
                type: "NSButton",
                identifier: "test_button",
                isRequired: true,
                expectedContent: nil,
                expectedState: GlobalGUIChecker.InterfaceDefinition.ExpectedComponent.ExpectedState(
                    isEnabled: true,
                    isVisible: true,
                    selectedIndex: nil,
                    checkState: nil
                )
            )
        ]
        
        let layoutRules: [GlobalGUIChecker.InterfaceDefinition.LayoutRule] = [
            GlobalGUIChecker.InterfaceDefinition.LayoutRule(
                type: .minimumSize,
                description: "界面尺寸应该至少为500x400",
                validator: { componentTree in
                    return componentTree.frame.width >= 500 && componentTree.frame.height >= 400
                }
            )
        ]
        
        let loadingRequirements = GlobalGUIChecker.InterfaceDefinition.LoadingRequirement(
            maxLoadTime: 1.0,
            requiredResources: ["NSButton"],
            criticalComponents: ["test_button"]
        )
        
        return GlobalGUIChecker.InterfaceDefinition(
            name: "测试界面",
            identifier: "test_interface",
            expectedComponents: expectedComponents,
            layoutRules: layoutRules,
            loadingRequirements: loadingRequirements,
            creator: { return viewController }
        )
    }
    
    /// 创建加载缓慢的界面定义
    private func createSlowLoadingInterfaceDefinition() -> GlobalGUIChecker.InterfaceDefinition {
        let expectedComponents: [GlobalGUIChecker.InterfaceDefinition.ExpectedComponent] = []
        let layoutRules: [GlobalGUIChecker.InterfaceDefinition.LayoutRule] = []
        
        let loadingRequirements = GlobalGUIChecker.InterfaceDefinition.LoadingRequirement(
            maxLoadTime: 0.001, // 非常短的时间限制，容易触发超时
            requiredResources: [],
            criticalComponents: []
        )
        
        return GlobalGUIChecker.InterfaceDefinition(
            name: "缓慢加载界面",
            identifier: "slow_loading_interface",
            expectedComponents: expectedComponents,
            layoutRules: layoutRules,
            loadingRequirements: loadingRequirements,
            creator: {
                // 模拟缓慢加载
                Thread.sleep(forTimeInterval: 0.1)
                return TestViewControllerFactory.createSimpleTestViewController()
            }
        )
    }
}
