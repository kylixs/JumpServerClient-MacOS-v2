#!/usr/bin/env swift

//
//  test_global_gui_check.swift
//  全局GUI检查演示脚本
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import Cocoa
import Foundation

// 模拟必要的数据结构（简化版本）
struct UIComponentInfo: Codable {
    let id: String
    let type: String
    let className: String
    let frame: CGRect
    let bounds: CGRect
    let isHidden: Bool
    let isEnabled: Bool
    let alphaValue: Double
    let tag: Int
    let zIndex: Int
    let content: UIComponentContent
    let children: [UIComponentInfo]
    
    struct UIComponentContent: Codable {
        let text: String?
        let title: String?
        let stringValue: String?
        let placeholderString: String?
        let toolTip: String?
        let state: Int?
        let selectedSegment: Int?
        let numberOfItems: Int?
        let selectedItemIndex: Int?
        let minValue: Double?
        let maxValue: Double?
        let doubleValue: Double?
        let intValue: Int?
        let isEditable: Bool?
        let isSelectable: Bool?
        let accessibilityLabel: String?
        let accessibilityValue: String?
        let accessibilityRole: String?
    }
}

// 简化的组件树生成器
class SimpleUIComponentTreeGenerator {
    private var componentCounter: Int = 0
    
    func generateComponentTree(from view: NSView) -> UIComponentInfo {
        componentCounter = 0
        return generateComponentInfo(from: view, depth: 0)
    }
    
    private func generateComponentInfo(from view: NSView, depth: Int) -> UIComponentInfo {
        componentCounter += 1
        let componentId = "component_\(componentCounter)"
        
        let type = String(describing: type(of: view))
        let className = view.className
        
        let content = extractComponentContent(from: view)
        
        let children = view.subviews.map { subview in
            generateComponentInfo(from: subview, depth: depth + 1)
        }
        
        return UIComponentInfo(
            id: componentId,
            type: type,
            className: className,
            frame: view.frame,
            bounds: view.bounds,
            isHidden: view.isHidden,
            isEnabled: true, // NSView没有isEnabled属性，默认为true
            alphaValue: view.alphaValue,
            tag: view.tag,
            zIndex: depth,
            content: content,
            children: children
        )
    }
    
    private func extractComponentContent(from view: NSView) -> UIComponentInfo.UIComponentContent {
        let text: String? = nil
        var title: String?
        var stringValue: String?
        var placeholderString: String?
        var toolTip: String?
        var state: Int?
        var selectedSegment: Int?
        var numberOfItems: Int?
        var selectedItemIndex: Int?
        var minValue: Double?
        var maxValue: Double?
        var doubleValue: Double?
        var intValue: Int?
        var isEditable: Bool?
        var isSelectable: Bool?
        
        if let textField = view as? NSTextField {
            stringValue = textField.stringValue
            placeholderString = textField.placeholderString
            isEditable = textField.isEditable
            isSelectable = textField.isSelectable
        }
        
        if let button = view as? NSButton {
            title = button.title
            state = button.state.rawValue
        }
        
        if let segmentedControl = view as? NSSegmentedControl {
            selectedSegment = segmentedControl.selectedSegment
        }
        
        if let popUpButton = view as? NSPopUpButton {
            numberOfItems = popUpButton.numberOfItems
            selectedItemIndex = popUpButton.indexOfSelectedItem
            title = popUpButton.titleOfSelectedItem
        }
        
        if let slider = view as? NSSlider {
            minValue = slider.minValue
            maxValue = slider.maxValue
            doubleValue = slider.doubleValue
            intValue = Int(slider.intValue)
        }
        
        toolTip = view.toolTip
        
        return UIComponentInfo.UIComponentContent(
            text: text,
            title: title,
            stringValue: stringValue,
            placeholderString: placeholderString,
            toolTip: toolTip,
            state: state,
            selectedSegment: selectedSegment,
            numberOfItems: numberOfItems,
            selectedItemIndex: selectedItemIndex,
            minValue: minValue,
            maxValue: maxValue,
            doubleValue: doubleValue,
            intValue: intValue,
            isEditable: isEditable,
            isSelectable: isSelectable,
            accessibilityLabel: nil,
            accessibilityValue: nil,
            accessibilityRole: nil
        )
    }
}

// 全局GUI检查器（简化版本）
class SimpleGlobalGUIChecker {
    
    private let treeGenerator = SimpleUIComponentTreeGenerator()
    
    struct InterfaceCheckResult {
        let interfaceName: String
        let status: CheckStatus
        let componentTree: UIComponentInfo
        let issues: [Issue]
        let loadingTime: TimeInterval
        
        enum CheckStatus {
            case passed
            case warning
            case failed
        }
        
        struct Issue {
            let type: IssueType
            let severity: Severity
            let description: String
            let suggestion: String
            
            enum IssueType {
                case missingComponent
                case wrongSize
                case componentOverlap
                case disabledComponent
                case hiddenComponent
                case emptyContent
            }
            
            enum Severity {
                case critical
                case major
                case minor
                case warning
            }
        }
    }
    
    func checkInterface(name: String, viewController: NSViewController) -> InterfaceCheckResult {
        let startTime = Date()
        
        let rootView = viewController.view
        if rootView == nil {
            return InterfaceCheckResult(
                interfaceName: name,
                status: .failed,
                componentTree: createEmptyComponentTree(),
                issues: [InterfaceCheckResult.Issue(
                    type: .missingComponent,
                    severity: .critical,
                    description: "界面视图为空",
                    suggestion: "确保视图控制器正确设置了view属性"
                )],
                loadingTime: Date().timeIntervalSince(startTime)
            )
        }
        
        let componentTree = treeGenerator.generateComponentTree(from: rootView)
        var issues: [InterfaceCheckResult.Issue] = []
        
        // 检查界面尺寸
        if componentTree.frame.width < 500 || componentTree.frame.height < 400 {
            issues.append(InterfaceCheckResult.Issue(
                type: .wrongSize,
                severity: .major,
                description: "界面尺寸过小: \(componentTree.frame.width)x\(componentTree.frame.height)",
                suggestion: "建议最小尺寸为500x400"
            ))
        }
        
        // 检查组件重叠
        let allComponents = getAllComponents(componentTree)
        let overlappingPairs = findOverlappingComponents(allComponents)
        if !overlappingPairs.isEmpty {
            issues.append(InterfaceCheckResult.Issue(
                type: .componentOverlap,
                severity: .major,
                description: "发现\(overlappingPairs.count)对重叠的组件",
                suggestion: "调整组件位置避免重叠"
            ))
        }
        
        // 检查禁用和隐藏的组件
        for component in allComponents {
            if component.isHidden && component.type != "NSView" {
                issues.append(InterfaceCheckResult.Issue(
                    type: .hiddenComponent,
                    severity: .warning,
                    description: "组件\(component.type)被隐藏",
                    suggestion: "检查组件是否应该可见"
                ))
            }
            
            if let stringValue = component.content.stringValue, stringValue.isEmpty,
               component.type == "NSTextField" {
                issues.append(InterfaceCheckResult.Issue(
                    type: .emptyContent,
                    severity: .minor,
                    description: "文本字段内容为空",
                    suggestion: "为文本字段添加适当的内容或占位符"
                ))
            }
        }
        
        // 确定整体状态
        let status: InterfaceCheckResult.CheckStatus
        if issues.contains(where: { $0.severity == .critical }) {
            status = .failed
        } else if issues.contains(where: { $0.severity == .major }) {
            status = .warning
        } else {
            status = .passed
        }
        
        return InterfaceCheckResult(
            interfaceName: name,
            status: status,
            componentTree: componentTree,
            issues: issues,
            loadingTime: Date().timeIntervalSince(startTime)
        )
    }
    
    private func createEmptyComponentTree() -> UIComponentInfo {
        return UIComponentInfo(
            id: "empty",
            type: "Empty",
            className: "Empty",
            frame: CGRect.zero,
            bounds: CGRect.zero,
            isHidden: true,
            isEnabled: false,
            alphaValue: 0,
            tag: 0,
            zIndex: 0,
            content: UIComponentInfo.UIComponentContent(
                text: nil, title: nil, stringValue: nil, placeholderString: nil,
                toolTip: nil, state: nil, selectedSegment: nil, numberOfItems: nil,
                selectedItemIndex: nil, minValue: nil, maxValue: nil, doubleValue: nil,
                intValue: nil, isEditable: nil, isSelectable: nil, accessibilityLabel: nil,
                accessibilityValue: nil, accessibilityRole: nil
            ),
            children: []
        )
    }
    
    private func getAllComponents(_ componentTree: UIComponentInfo) -> [UIComponentInfo] {
        var components = [componentTree]
        for child in componentTree.children {
            components.append(contentsOf: getAllComponents(child))
        }
        return components
    }
    
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
}

// 测试界面工厂
class TestInterfaceFactory {
    
    static func createStandardRDPConfigInterface() -> NSViewController {
        let viewController = NSViewController()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        
        // 标题
        let titleLabel = NSTextField(labelWithString: "RDP质量配置")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.frame = NSRect(x: 20, y: 450, width: 200, height: 25)
        view.addSubview(titleLabel)
        
        // 预设配置分段控件
        let segmentedControl = NSSegmentedControl()
        segmentedControl.segmentCount = 3
        segmentedControl.setLabel("性能优先", forSegment: 0)
        segmentedControl.setLabel("平衡模式", forSegment: 1)
        segmentedControl.setLabel("质量优先", forSegment: 2)
        segmentedControl.selectedSegment = 1
        segmentedControl.frame = NSRect(x: 20, y: 400, width: 300, height: 30)
        view.addSubview(segmentedControl)
        
        // 压缩级别滑块
        let compressionSlider = NSSlider()
        compressionSlider.minValue = 0
        compressionSlider.maxValue = 2
        compressionSlider.doubleValue = 1
        compressionSlider.frame = NSRect(x: 110, y: 350, width: 150, height: 25)
        view.addSubview(compressionSlider)
        
        // 下拉框
        let colorDepthPopup = NSPopUpButton()
        colorDepthPopup.addItems(withTitles: ["16位", "24位", "32位"])
        colorDepthPopup.selectItem(at: 1)
        colorDepthPopup.frame = NSRect(x: 110, y: 300, width: 100, height: 25)
        view.addSubview(colorDepthPopup)
        
        // 复选框
        let fontSmoothingCheckbox = NSButton(checkboxWithTitle: "启用字体平滑", target: nil, action: nil)
        fontSmoothingCheckbox.state = .on
        fontSmoothingCheckbox.frame = NSRect(x: 20, y: 200, width: 150, height: 20)
        view.addSubview(fontSmoothingCheckbox)
        
        // 操作按钮
        let applyButton = NSButton(title: "应用配置", target: nil, action: nil)
        applyButton.frame = NSRect(x: 480, y: 20, width: 100, height: 30)
        view.addSubview(applyButton)
        
        viewController.view = view
        return viewController
    }
    
    static func createProblematicInterface() -> NSViewController {
        let viewController = NSViewController()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300)) // 尺寸过小
        
        // 缺少标题
        
        // 禁用的分段控件
        let segmentedControl = NSSegmentedControl()
        segmentedControl.segmentCount = 3
        segmentedControl.setLabel("选项1", forSegment: 0)
        segmentedControl.setLabel("选项2", forSegment: 1)
        segmentedControl.setLabel("选项3", forSegment: 2)
        segmentedControl.selectedSegment = 1
        segmentedControl.isEnabled = false // 问题：禁用状态
        segmentedControl.frame = NSRect(x: 20, y: 200, width: 300, height: 30)
        view.addSubview(segmentedControl)
        
        // 隐藏的滑块
        let slider = NSSlider()
        slider.minValue = 0
        slider.maxValue = 100
        slider.doubleValue = 50
        slider.isHidden = true // 问题：隐藏状态
        slider.frame = NSRect(x: 20, y: 150, width: 200, height: 25)
        view.addSubview(slider)
        
        // 重叠的按钮
        let button1 = NSButton(title: "按钮1", target: nil, action: nil)
        button1.frame = NSRect(x: 50, y: 50, width: 100, height: 30)
        view.addSubview(button1)
        
        let button2 = NSButton(title: "按钮2", target: nil, action: nil)
        button2.frame = NSRect(x: 75, y: 65, width: 100, height: 30) // 重叠
        view.addSubview(button2)
        
        // 空文本字段
        let emptyTextField = NSTextField()
        emptyTextField.stringValue = "" // 问题：空内容
        emptyTextField.frame = NSRect(x: 20, y: 100, width: 200, height: 25)
        view.addSubview(emptyTextField)
        
        viewController.view = view
        return viewController
    }
}

// 主函数
func main() {
    print("🚀 开始全局GUI检查演示...")
    
    let checker = SimpleGlobalGUIChecker()
    var allResults: [SimpleGlobalGUIChecker.InterfaceCheckResult] = []
    
    // 测试界面列表
    let testInterfaces: [(String, NSViewController)] = [
        ("标准RDP配置界面", TestInterfaceFactory.createStandardRDPConfigInterface()),
        ("有问题的界面", TestInterfaceFactory.createProblematicInterface())
    ]
    
    print("\n📋 开始检查所有界面...")
    print(String(repeating: "=", count: 60))
    
    for (name, viewController) in testInterfaces {
        print("\n🔍 检查界面: \(name)")
        
        let result = checker.checkInterface(name: name, viewController: viewController)
        allResults.append(result)
        
        // 显示检查结果
        let statusIcon = result.status == .passed ? "✅" : result.status == .warning ? "⚠️" : "❌"
        print("\(statusIcon) 状态: \(result.status)")
        print("⏱️ 加载时间: \(String(format: "%.3f", result.loadingTime))秒")
        print("📊 组件总数: \(countAllComponents(result.componentTree))")
        print("🔍 发现问题: \(result.issues.count)个")
        
        if !result.issues.isEmpty {
            print("\n📋 问题详情:")
            for (index, issue) in result.issues.enumerated() {
                let severityIcon = issue.severity == .critical ? "🔴" : 
                                 issue.severity == .major ? "🟠" : 
                                 issue.severity == .minor ? "🟡" : "🔵"
                print("   \(index + 1). \(severityIcon) \(issue.description)")
                print("      💡 建议: \(issue.suggestion)")
            }
        }
        
        // 保存组件树到临时文件
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(result.componentTree)
            
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "\(name.replacingOccurrences(of: " ", with: "_"))_component_tree.json"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            print("📄 组件树已保存: \(fileURL.path)")
        } catch {
            print("⚠️ 保存组件树失败: \(error)")
        }
    }
    
    // 生成全局摘要
    print("\n" + String(repeating: "=", count: 60))
    print("📊 全局检查摘要")
    print(String(repeating: "=", count: 60))
    
    let passedCount = allResults.filter { $0.status == .passed }.count
    let warningCount = allResults.filter { $0.status == .warning }.count
    let failedCount = allResults.filter { $0.status == .failed }.count
    let totalIssues = allResults.reduce(0) { $0 + $1.issues.count }
    
    print("✅ 通过: \(passedCount)个界面")
    print("⚠️ 警告: \(warningCount)个界面")
    print("❌ 失败: \(failedCount)个界面")
    print("🔍 总问题数: \(totalIssues)个")
    
    // 问题分类统计
    var issueTypeCount: [String: Int] = [:]
    var severityCount: [String: Int] = [:]
    
    for result in allResults {
        for issue in result.issues {
            let typeKey = String(describing: issue.type)
            let severityKey = String(describing: issue.severity)
            
            issueTypeCount[typeKey, default: 0] += 1
            severityCount[severityKey, default: 0] += 1
        }
    }
    
    if !issueTypeCount.isEmpty {
        print("\n📋 问题类型分布:")
        for (type, count) in issueTypeCount.sorted(by: { $0.value > $1.value }) {
            print("   • \(type): \(count)个")
        }
        
        print("\n📊 严重程度分布:")
        for (severity, count) in severityCount.sorted(by: { $0.value > $1.value }) {
            let icon = severity == "critical" ? "🔴" : 
                      severity == "major" ? "🟠" : 
                      severity == "minor" ? "🟡" : "🔵"
            print("   \(icon) \(severity): \(count)个")
        }
    }
    
    // 生成建议
    print("\n💡 改进建议:")
    if failedCount > 0 {
        print("   🔴 立即修复\(failedCount)个失败的界面，这些问题会严重影响用户体验")
    }
    if warningCount > 0 {
        print("   🟠 优先处理\(warningCount)个有警告的界面，提升界面质量")
    }
    if totalIssues == 0 {
        print("   🎉 所有界面检查通过，GUI质量优秀！")
    }
    
    print("\n🎉 全局GUI检查演示完成！")
}

// 辅助函数
func countAllComponents(_ componentTree: UIComponentInfo) -> Int {
    return 1 + componentTree.children.reduce(0) { $0 + countAllComponents($1) }
}

// 运行主函数
main()
