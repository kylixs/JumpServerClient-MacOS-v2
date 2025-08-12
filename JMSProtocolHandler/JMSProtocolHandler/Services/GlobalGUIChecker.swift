//
//  GlobalGUIChecker.swift
//  JMSProtocolHandler
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import Cocoa
import Foundation

/// 全局GUI检查器 - 检查所有界面的完整性和正确性
class GlobalGUIChecker {
    
    // MARK: - Data Structures
    
    struct InterfaceDefinition {
        let name: String
        let identifier: String
        let expectedComponents: [ExpectedComponent]
        let layoutRules: [LayoutRule]
        let loadingRequirements: LoadingRequirement
        let creator: () -> NSViewController?
        
        struct ExpectedComponent {
            let type: String
            let identifier: String?
            let isRequired: Bool
            let expectedContent: ExpectedContent?
            let expectedState: ExpectedState?
            
            struct ExpectedContent {
                let text: String?
                let title: String?
                let placeholder: String?
                let options: [String]?
                let valueRange: (min: Double, max: Double)?
            }
            
            struct ExpectedState {
                let isEnabled: Bool?
                let isVisible: Bool?
                let selectedIndex: Int?
                let checkState: Bool?
            }
        }
        
        struct LayoutRule {
            let type: LayoutRuleType
            let description: String
            let validator: (UIComponentInfo) -> Bool
            
            enum LayoutRuleType {
                case minimumSize
                case componentAlignment
                case noOverlap
                case properSpacing
                case responsiveLayout
            }
        }
        
        struct LoadingRequirement {
            let maxLoadTime: TimeInterval
            let requiredResources: [String]
            let criticalComponents: [String]
        }
    }
    
    struct GlobalCheckReport: Codable {
        let timestamp: Date
        let totalInterfaces: Int
        let checkedInterfaces: Int
        let passedInterfaces: Int
        let failedInterfaces: Int
        let interfaceReports: [InterfaceCheckReport]
        let summary: CheckSummary
        
        struct InterfaceCheckReport: Codable {
            let interfaceName: String
            let status: CheckStatus
            let loadingTime: TimeInterval
            let componentIssues: [ComponentIssue]
            let layoutIssues: [LayoutIssue]
            let loadingIssues: [LoadingIssue]
            let componentTree: UIComponentInfo?
            
            enum CheckStatus: String, Codable {
                case passed = "PASSED"
                case failed = "FAILED"
                case warning = "WARNING"
                case loadFailed = "LOAD_FAILED"
            }
        }
        
        struct ComponentIssue: Codable {
            let componentId: String
            let issueType: IssueType
            let severity: Severity
            let description: String
            let expected: String
            let actual: String
            let suggestion: String
            
            enum IssueType: String, Codable {
                case missing = "MISSING"
                case wrongType = "WRONG_TYPE"
                case wrongContent = "WRONG_CONTENT"
                case wrongState = "WRONG_STATE"
                case disabled = "DISABLED"
                case hidden = "HIDDEN"
            }
            
            enum Severity: String, Codable {
                case critical = "CRITICAL"
                case major = "MAJOR"
                case minor = "MINOR"
                case warning = "WARNING"
            }
        }
        
        struct LayoutIssue: Codable {
            let issueType: LayoutIssueType
            let severity: ComponentIssue.Severity
            let description: String
            let affectedComponents: [String]
            let suggestion: String
            
            enum LayoutIssueType: String, Codable {
                case overlap = "OVERLAP"
                case misalignment = "MISALIGNMENT"
                case wrongSize = "WRONG_SIZE"
                case badSpacing = "BAD_SPACING"
                case outOfBounds = "OUT_OF_BOUNDS"
            }
        }
        
        struct LoadingIssue: Codable {
            let issueType: LoadingIssueType
            let severity: ComponentIssue.Severity
            let description: String
            let suggestion: String
            
            enum LoadingIssueType: String, Codable {
                case timeout = "TIMEOUT"
                case resourceMissing = "RESOURCE_MISSING"
                case initializationFailed = "INITIALIZATION_FAILED"
                case dependencyMissing = "DEPENDENCY_MISSING"
            }
        }
        
        struct CheckSummary: Codable {
            let totalIssues: Int
            let criticalIssues: Int
            let majorIssues: Int
            let minorIssues: Int
            let warningIssues: Int
            let executionTime: TimeInterval
            let recommendations: [String]
        }
    }
    
    // MARK: - Properties
    
    private let guiValidator: GUIValidator
    private let treeGenerator: UIComponentTreeGenerator
    private let tempDirectory: URL
    private let interfaceDefinitionManager: InterfaceDefinitionManager
    
    // MARK: - Initialization
    
    init() {
        self.guiValidator = GUIValidator()
        self.treeGenerator = UIComponentTreeGenerator()
        self.tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("JMSProtocolHandler_Global_GUI_Check", isDirectory: true)
        self.interfaceDefinitionManager = InterfaceDefinitionManager.shared
        
        // 确保临时目录存在
        try? FileManager.default.createDirectory(at: tempDirectory, 
                                               withIntermediateDirectories: true, 
                                               attributes: nil)
    }
    
    // MARK: - Public Methods
    
    /// 执行全局GUI检查
    /// - Returns: 全局检查报告
    func performGlobalGUICheck() -> GlobalCheckReport {
        print("🔍 开始全局GUI界面检查...")
        let startTime = Date()
        
        let interfaceDefinitions = interfaceDefinitionManager.getAllInterfaceDefinitions()
        var interfaceReports: [GlobalCheckReport.InterfaceCheckReport] = []
        var passedCount = 0
        var failedCount = 0
        
        for interfaceDefinition in interfaceDefinitions {
            print("📋 检查界面: \(interfaceDefinition.name)")
            
            let report = checkInterface(interfaceDefinition)
            interfaceReports.append(report)
            
            switch report.status {
            case .passed:
                passedCount += 1
            case .failed, .loadFailed:
                failedCount += 1
            case .warning:
                // 警告不计入失败
                break
            }
        }
        
        let executionTime = Date().timeIntervalSince(startTime)
        let summary = createCheckSummary(from: interfaceReports, executionTime: executionTime)
        
        let globalReport = GlobalCheckReport(
            timestamp: Date(),
            totalInterfaces: interfaceDefinitions.count,
            checkedInterfaces: interfaceReports.count,
            passedInterfaces: passedCount,
            failedInterfaces: failedCount,
            interfaceReports: interfaceReports,
            summary: summary
        )
        
        // 保存全局报告
        saveGlobalReport(globalReport)
        
        print("✅ 全局GUI检查完成")
        print("📊 结果: \(passedCount)个通过, \(failedCount)个失败, 共\(summary.totalIssues)个问题")
        
        return globalReport
    }
    
    /// 检查特定界面
    /// - Parameter interfaceDefinition: 界面定义
    /// - Returns: 界面检查报告
    func checkInterface(_ interfaceDefinition: InterfaceDefinition) -> GlobalCheckReport.InterfaceCheckReport {
        let startTime = Date()
        
        // 尝试创建界面
        guard let viewController = interfaceDefinition.creator() else {
            let loadingTime = Date().timeIntervalSince(startTime)
            return GlobalCheckReport.InterfaceCheckReport(
                interfaceName: interfaceDefinition.name,
                status: .loadFailed,
                loadingTime: loadingTime,
                componentIssues: [],
                layoutIssues: [],
                loadingIssues: [
                    GlobalCheckReport.LoadingIssue(
                        issueType: .initializationFailed,
                        severity: .critical,
                        description: "无法创建界面视图控制器",
                        suggestion: "检查界面初始化代码和依赖项"
                    )
                ],
                componentTree: nil
            )
        }
        
        let loadingTime = Date().timeIntervalSince(startTime)
        
        // 检查加载时间
        var loadingIssues: [GlobalCheckReport.LoadingIssue] = []
        if loadingTime > interfaceDefinition.loadingRequirements.maxLoadTime {
            loadingIssues.append(
                GlobalCheckReport.LoadingIssue(
                    issueType: .timeout,
                    severity: .major,
                    description: "界面加载时间过长: \(String(format: "%.3f", loadingTime))秒",
                    suggestion: "优化界面初始化代码，减少同步操作"
                )
            )
        }
        
        // 生成组件树
        guard let rootView = viewController.view else {
            return GlobalCheckReport.InterfaceCheckReport(
                interfaceName: interfaceDefinition.name,
                status: .loadFailed,
                loadingTime: loadingTime,
                componentIssues: [],
                layoutIssues: [],
                loadingIssues: loadingIssues + [
                    GlobalCheckReport.LoadingIssue(
                        issueType: .initializationFailed,
                        severity: .critical,
                        description: "界面视图为空",
                        suggestion: "确保视图控制器正确设置了view属性"
                    )
                ],
                componentTree: nil
            )
        }
        
        let componentTree = treeGenerator.generateComponentTree(from: rootView)
        
        // 保存组件树
        do {
            let fileName = "\(interfaceDefinition.identifier)_component_tree.json"
            try treeGenerator.saveToTempFile(componentTree, fileName: fileName)
        } catch {
            print("⚠️ 保存组件树失败: \(error)")
        }
        
        // 检查组件问题
        let componentIssues = checkComponents(componentTree, against: interfaceDefinition.expectedComponents)
        
        // 检查布局问题
        let layoutIssues = checkLayout(componentTree, against: interfaceDefinition.layoutRules)
        
        // 确定整体状态
        let status = determineInterfaceStatus(
            componentIssues: componentIssues,
            layoutIssues: layoutIssues,
            loadingIssues: loadingIssues
        )
        
        return GlobalCheckReport.InterfaceCheckReport(
            interfaceName: interfaceDefinition.name,
            status: status,
            loadingTime: loadingTime,
            componentIssues: componentIssues,
            layoutIssues: layoutIssues,
            loadingIssues: loadingIssues,
            componentTree: componentTree
        )
    }
    
    // MARK: - Private Methods
    
    /// 检查组件问题
    private func checkComponents(_ componentTree: UIComponentInfo, 
                               against expectedComponents: [InterfaceDefinition.ExpectedComponent]) -> [GlobalCheckReport.ComponentIssue] {
        var issues: [GlobalCheckReport.ComponentIssue] = []
        
        for expectedComponent in expectedComponents {
            let foundComponents = findComponents(in: componentTree, matching: expectedComponent)
            
            if foundComponents.isEmpty && expectedComponent.isRequired {
                issues.append(
                    GlobalCheckReport.ComponentIssue(
                        componentId: expectedComponent.identifier ?? expectedComponent.type,
                        issueType: .missing,
                        severity: .critical,
                        description: "缺少必需的组件: \(expectedComponent.type)",
                        expected: "存在\(expectedComponent.type)组件",
                        actual: "未找到组件",
                        suggestion: "检查组件创建和添加到视图的代码"
                    )
                )
            } else {
                // 检查找到的组件
                for component in foundComponents {
                    issues.append(contentsOf: validateComponent(component, against: expectedComponent))
                }
            }
        }
        
        return issues
    }
    
    /// 检查布局问题
    private func checkLayout(_ componentTree: UIComponentInfo, 
                           against layoutRules: [InterfaceDefinition.LayoutRule]) -> [GlobalCheckReport.LayoutIssue] {
        var issues: [GlobalCheckReport.LayoutIssue] = []
        
        for rule in layoutRules {
            if !rule.validator(componentTree) {
                let issue = GlobalCheckReport.LayoutIssue(
                    issueType: mapLayoutRuleToIssueType(rule.type),
                    severity: .major,
                    description: rule.description,
                    affectedComponents: [],
                    suggestion: "检查布局约束和组件位置设置"
                )
                issues.append(issue)
            }
        }
        
        // 检查组件重叠
        let allComponents = getAllComponents(componentTree)
        let overlappingPairs = findOverlappingComponents(allComponents)
        
        if !overlappingPairs.isEmpty {
            issues.append(
                GlobalCheckReport.LayoutIssue(
                    issueType: .overlap,
                    severity: .major,
                    description: "发现\(overlappingPairs.count)对重叠的组件",
                    affectedComponents: overlappingPairs.flatMap { [$0.0.id, $0.1.id] },
                    suggestion: "调整组件位置或大小，确保组件不重叠"
                )
            )
        }
        
        return issues
    }
    
    /// 验证单个组件
    private func validateComponent(_ component: UIComponentInfo, 
                                 against expected: InterfaceDefinition.ExpectedComponent) -> [GlobalCheckReport.ComponentIssue] {
        var issues: [GlobalCheckReport.ComponentIssue] = []
        
        // 检查组件状态
        if let expectedState = expected.expectedState {
            if let expectedEnabled = expectedState.isEnabled, component.isEnabled != expectedEnabled {
                issues.append(
                    GlobalCheckReport.ComponentIssue(
                        componentId: component.id,
                        issueType: expectedEnabled ? .disabled : .wrongState,
                        severity: .major,
                        description: "组件启用状态不正确",
                        expected: "isEnabled = \(expectedEnabled)",
                        actual: "isEnabled = \(component.isEnabled)",
                        suggestion: "检查组件的启用状态设置"
                    )
                )
            }
            
            if let expectedVisible = expectedState.isVisible, component.isHidden == expectedVisible {
                issues.append(
                    GlobalCheckReport.ComponentIssue(
                        componentId: component.id,
                        issueType: expectedVisible ? .hidden : .wrongState,
                        severity: .major,
                        description: "组件可见性不正确",
                        expected: "isHidden = \(!expectedVisible)",
                        actual: "isHidden = \(component.isHidden)",
                        suggestion: "检查组件的可见性设置"
                    )
                )
            }
        }
        
        // 检查组件内容
        if let expectedContent = expected.expectedContent {
            if let expectedText = expectedContent.text, 
               component.content.stringValue != expectedText && component.content.title != expectedText {
                issues.append(
                    GlobalCheckReport.ComponentIssue(
                        componentId: component.id,
                        issueType: .wrongContent,
                        severity: .minor,
                        description: "组件文本内容不匹配",
                        expected: expectedText,
                        actual: component.content.stringValue ?? component.content.title ?? "空",
                        suggestion: "检查组件的文本设置"
                    )
                )
            }
        }
        
        return issues
    }
    
    /// 查找匹配的组件
    private func findComponents(in componentTree: UIComponentInfo, 
                              matching expected: InterfaceDefinition.ExpectedComponent) -> [UIComponentInfo] {
        var results: [UIComponentInfo] = []
        
        func searchComponents(_ component: UIComponentInfo) {
            if component.type == expected.type {
                if let expectedId = expected.identifier {
                    // 如果指定了标识符，需要精确匹配
                    if component.id == expectedId || 
                       component.content.title == expectedId ||
                       component.content.stringValue == expectedId {
                        results.append(component)
                    }
                } else {
                    // 没有指定标识符，类型匹配即可
                    results.append(component)
                }
            }
            
            for child in component.children {
                searchComponents(child)
            }
        }
        
        searchComponents(componentTree)
        return results
    }
    
    /// 获取所有组件（扁平化）
    private func getAllComponents(_ componentTree: UIComponentInfo) -> [UIComponentInfo] {
        var components = [componentTree]
        for child in componentTree.children {
            components.append(contentsOf: getAllComponents(child))
        }
        return components
    }
    
    /// 查找重叠的组件
    private func findOverlappingComponents(_ components: [UIComponentInfo]) -> [(UIComponentInfo, UIComponentInfo)] {
        var overlapping: [(UIComponentInfo, UIComponentInfo)] = []
        
        for i in 0..<components.count {
            for j in (i+1)..<components.count {
                let comp1 = components[i]
                let comp2 = components[j]
                
                if comp1.frame.intersects(comp2.frame) && 
                   !comp1.frame.isEmpty && !comp2.frame.isEmpty &&
                   !comp1.isHidden && !comp2.isHidden {
                    overlapping.append((comp1, comp2))
                }
            }
        }
        
        return overlapping
    }
    
    /// 确定界面状态
    private func determineInterfaceStatus(componentIssues: [GlobalCheckReport.ComponentIssue],
                                        layoutIssues: [GlobalCheckReport.LayoutIssue],
                                        loadingIssues: [GlobalCheckReport.LoadingIssue]) -> GlobalCheckReport.InterfaceCheckReport.CheckStatus {
        
        let hasCriticalIssues = componentIssues.contains { $0.severity == .critical } ||
                               layoutIssues.contains { $0.severity == .critical } ||
                               loadingIssues.contains { $0.severity == .critical }
        
        let hasMajorIssues = componentIssues.contains { $0.severity == .major } ||
                            layoutIssues.contains { $0.severity == .major } ||
                            loadingIssues.contains { $0.severity == .major }
        
        if hasCriticalIssues {
            return .failed
        } else if hasMajorIssues {
            return .warning
        } else {
            return .passed
        }
    }
    
    /// 映射布局规则到问题类型
    private func mapLayoutRuleToIssueType(_ ruleType: InterfaceDefinition.LayoutRule.LayoutRuleType) -> GlobalCheckReport.LayoutIssue.LayoutIssueType {
        switch ruleType {
        case .minimumSize:
            return .wrongSize
        case .componentAlignment:
            return .misalignment
        case .noOverlap:
            return .overlap
        case .properSpacing:
            return .badSpacing
        case .responsiveLayout:
            return .outOfBounds
        }
    }
    
    /// 创建检查摘要
    private func createCheckSummary(from reports: [GlobalCheckReport.InterfaceCheckReport], 
                                  executionTime: TimeInterval) -> GlobalCheckReport.CheckSummary {
        var totalIssues = 0
        var criticalIssues = 0
        var majorIssues = 0
        var minorIssues = 0
        var warningIssues = 0
        
        for report in reports {
            totalIssues += report.componentIssues.count + report.layoutIssues.count + report.loadingIssues.count
            
            for issue in report.componentIssues {
                switch issue.severity {
                case .critical: criticalIssues += 1
                case .major: majorIssues += 1
                case .minor: minorIssues += 1
                case .warning: warningIssues += 1
                }
            }
            
            for issue in report.layoutIssues {
                switch issue.severity {
                case .critical: criticalIssues += 1
                case .major: majorIssues += 1
                case .minor: minorIssues += 1
                case .warning: warningIssues += 1
                }
            }
            
            for issue in report.loadingIssues {
                switch issue.severity {
                case .critical: criticalIssues += 1
                case .major: majorIssues += 1
                case .minor: minorIssues += 1
                case .warning: warningIssues += 1
                }
            }
        }
        
        var recommendations: [String] = []
        
        if criticalIssues > 0 {
            recommendations.append("立即修复\(criticalIssues)个严重问题，这些问题会影响应用程序的基本功能")
        }
        
        if majorIssues > 0 {
            recommendations.append("优先修复\(majorIssues)个主要问题，这些问题会影响用户体验")
        }
        
        if minorIssues > 0 {
            recommendations.append("考虑修复\(minorIssues)个次要问题，以提高界面质量")
        }
        
        if totalIssues == 0 {
            recommendations.append("所有界面检查通过，GUI质量优秀")
        }
        
        return GlobalCheckReport.CheckSummary(
            totalIssues: totalIssues,
            criticalIssues: criticalIssues,
            majorIssues: majorIssues,
            minorIssues: minorIssues,
            warningIssues: warningIssues,
            executionTime: executionTime,
            recommendations: recommendations
        )
    }
    
    /// 保存全局报告
    private func saveGlobalReport(_ report: GlobalCheckReport) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(report)
            let fileName = "global_gui_check_report_\(Date().timeIntervalSince1970).json"
            let fileURL = tempDirectory.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            print("📊 全局GUI检查报告已保存到: \(fileURL.path)")
        } catch {
            print("⚠️ 保存全局报告失败: \(error)")
        }
    }
}
