//
//  UIComponentTreeGenerator.swift
//  JMSProtocolHandler
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import Cocoa
import Foundation

/// GUI组件信息结构
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

/// GUI验证报告结构
struct GUIValidationReport: Codable {
    let timestamp: Date
    let testName: String
    let status: ValidationStatus
    let componentTree: UIComponentInfo?
    let validationResults: [ValidationResult]
    let summary: ValidationSummary
    
    enum ValidationStatus: String, Codable {
        case passed = "PASSED"
        case failed = "FAILED"
        case warning = "WARNING"
    }
    
    struct ValidationResult: Codable {
        let componentId: String
        let testType: String
        let status: ValidationStatus
        let message: String
        let expected: String?
        let actual: String?
        let suggestion: String?
    }
    
    struct ValidationSummary: Codable {
        let totalComponents: Int
        let passedTests: Int
        let failedTests: Int
        let warningTests: Int
        let executionTime: TimeInterval
    }
}

/// GUI组件层级树生成器
class UIComponentTreeGenerator {
    
    // MARK: - Properties
    
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var componentCounter: Int = 0
    
    // MARK: - Initialization
    
    init() {
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Public Methods
    
    /// 生成视图层级树
    /// - Parameter rootView: 根视图
    /// - Returns: 组件信息树
    func generateComponentTree(from rootView: NSView) -> UIComponentInfo {
        componentCounter = 0
        return generateComponentInfo(from: rootView, depth: 0)
    }
    
    /// 将组件树导出为JSON字符串
    /// - Parameter componentTree: 组件树
    /// - Returns: JSON字符串
    func exportToJSON(_ componentTree: UIComponentInfo) throws -> String {
        let data = try encoder.encode(componentTree)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    /// 将组件树保存到临时文件
    /// - Parameters:
    ///   - componentTree: 组件树
    ///   - fileName: 文件名（可选）
    /// - Returns: 文件URL
    @discardableResult
    func saveToTempFile(_ componentTree: UIComponentInfo, fileName: String? = nil) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = fileName ?? "gui_component_tree_\(Date().timeIntervalSince1970).json"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        let jsonString = try exportToJSON(componentTree)
        try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
        
        print("📄 GUI组件树已保存到: \(fileURL.path)")
        return fileURL
    }
    
    /// 从JSON字符串导入组件树
    /// - Parameter jsonString: JSON字符串
    /// - Returns: 组件信息树
    func importFromJSON(_ jsonString: String) throws -> UIComponentInfo {
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "UIComponentTreeGenerator", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string"])
        }
        return try decoder.decode(UIComponentInfo.self, from: data)
    }
    
    /// 比较两个组件树的差异
    /// - Parameters:
    ///   - oldTree: 旧的组件树
    ///   - newTree: 新的组件树
    /// - Returns: 差异报告
    func compareComponentTrees(_ oldTree: UIComponentInfo, _ newTree: UIComponentInfo) -> [String] {
        var differences: [String] = []
        compareComponents(oldTree, newTree, path: "root", differences: &differences)
        return differences
    }
    
    // MARK: - Private Methods
    
    /// 生成单个组件的信息
    /// - Parameters:
    ///   - view: NSView实例
    ///   - depth: 层级深度
    /// - Returns: 组件信息
    private func generateComponentInfo(from view: NSView, depth: Int) -> UIComponentInfo {
        componentCounter += 1
        let componentId = "component_\(componentCounter)"
        
        // 收集基本信息
        let type = String(describing: type(of: view))
        let className = view.className
        
        // 收集内容信息
        let content = extractComponentContent(from: view)
        
        // 递归收集子组件
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
            isEnabled: view.isEnabled,
            alphaValue: view.alphaValue,
            tag: view.tag,
            zIndex: depth,
            content: content,
            children: children
        )
    }
    
    /// 提取组件内容信息
    /// - Parameter view: NSView实例
    /// - Returns: 组件内容信息
    private func extractComponentContent(from view: NSView) -> UIComponentInfo.UIComponentContent {
        var text: String?
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
        var accessibilityLabel: String?
        var accessibilityValue: String?
        var accessibilityRole: String?
        
        // 提取不同类型控件的特定信息
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
            intValue = slider.intValue
        }
        
        if let textView = view as? NSTextView {
            text = textView.string
            isEditable = textView.isEditable
            isSelectable = textView.isSelectable
        }
        
        // 通用属性
        toolTip = view.toolTip
        
        // 辅助功能信息
        if let accessibilityElement = view as? NSAccessibilityElement {
            accessibilityLabel = accessibilityElement.accessibilityLabel()
            accessibilityValue = accessibilityElement.accessibilityValue() as? String
            accessibilityRole = accessibilityElement.accessibilityRole()?.rawValue
        }
        
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
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: accessibilityValue,
            accessibilityRole: accessibilityRole
        )
    }
    
    /// 比较两个组件的差异
    /// - Parameters:
    ///   - oldComponent: 旧组件
    ///   - newComponent: 新组件
    ///   - path: 组件路径
    ///   - differences: 差异数组
    private func compareComponents(_ oldComponent: UIComponentInfo, 
                                 _ newComponent: UIComponentInfo, 
                                 path: String, 
                                 differences: inout [String]) {
        
        // 比较基本属性
        if oldComponent.type != newComponent.type {
            differences.append("\(path): Type changed from \(oldComponent.type) to \(newComponent.type)")
        }
        
        if oldComponent.frame != newComponent.frame {
            differences.append("\(path): Frame changed from \(oldComponent.frame) to \(newComponent.frame)")
        }
        
        if oldComponent.isHidden != newComponent.isHidden {
            differences.append("\(path): Hidden state changed from \(oldComponent.isHidden) to \(newComponent.isHidden)")
        }
        
        if oldComponent.isEnabled != newComponent.isEnabled {
            differences.append("\(path): Enabled state changed from \(oldComponent.isEnabled) to \(newComponent.isEnabled)")
        }
        
        // 比较内容
        compareComponentContent(oldComponent.content, newComponent.content, path: path, differences: &differences)
        
        // 比较子组件
        let oldChildrenCount = oldComponent.children.count
        let newChildrenCount = newComponent.children.count
        
        if oldChildrenCount != newChildrenCount {
            differences.append("\(path): Children count changed from \(oldChildrenCount) to \(newChildrenCount)")
        }
        
        let minCount = min(oldChildrenCount, newChildrenCount)
        for i in 0..<minCount {
            compareComponents(oldComponent.children[i], newComponent.children[i], 
                            path: "\(path).child[\(i)]", differences: &differences)
        }
    }
    
    /// 比较组件内容的差异
    /// - Parameters:
    ///   - oldContent: 旧内容
    ///   - newContent: 新内容
    ///   - path: 组件路径
    ///   - differences: 差异数组
    private func compareComponentContent(_ oldContent: UIComponentInfo.UIComponentContent,
                                       _ newContent: UIComponentInfo.UIComponentContent,
                                       path: String,
                                       differences: inout [String]) {
        
        if oldContent.text != newContent.text {
            differences.append("\(path): Text changed from '\(oldContent.text ?? "nil")' to '\(newContent.text ?? "nil")'")
        }
        
        if oldContent.title != newContent.title {
            differences.append("\(path): Title changed from '\(oldContent.title ?? "nil")' to '\(newContent.title ?? "nil")'")
        }
        
        if oldContent.stringValue != newContent.stringValue {
            differences.append("\(path): StringValue changed from '\(oldContent.stringValue ?? "nil")' to '\(newContent.stringValue ?? "nil")'")
        }
        
        if oldContent.state != newContent.state {
            differences.append("\(path): State changed from \(oldContent.state ?? -1) to \(newContent.state ?? -1)")
        }
        
        if oldContent.selectedSegment != newContent.selectedSegment {
            differences.append("\(path): SelectedSegment changed from \(oldContent.selectedSegment ?? -1) to \(newContent.selectedSegment ?? -1)")
        }
        
        if oldContent.doubleValue != newContent.doubleValue {
            differences.append("\(path): DoubleValue changed from \(oldContent.doubleValue ?? 0) to \(newContent.doubleValue ?? 0)")
        }
    }
}

// MARK: - Extensions

extension UIComponentTreeGenerator {
    
    /// 查找指定类型的组件
    /// - Parameters:
    ///   - componentTree: 组件树
    ///   - type: 组件类型
    /// - Returns: 匹配的组件数组
    func findComponents(in componentTree: UIComponentInfo, ofType type: String) -> [UIComponentInfo] {
        var results: [UIComponentInfo] = []
        
        if componentTree.type == type {
            results.append(componentTree)
        }
        
        for child in componentTree.children {
            results.append(contentsOf: findComponents(in: child, ofType: type))
        }
        
        return results
    }
    
    /// 查找包含指定文本的组件
    /// - Parameters:
    ///   - componentTree: 组件树
    ///   - text: 要查找的文本
    /// - Returns: 匹配的组件数组
    func findComponents(in componentTree: UIComponentInfo, containingText text: String) -> [UIComponentInfo] {
        var results: [UIComponentInfo] = []
        
        let content = componentTree.content
        if content.text?.contains(text) == true ||
           content.title?.contains(text) == true ||
           content.stringValue?.contains(text) == true {
            results.append(componentTree)
        }
        
        for child in componentTree.children {
            results.append(contentsOf: findComponents(in: child, containingText: text))
        }
        
        return results
    }
    
    /// 获取组件树的统计信息
    /// - Parameter componentTree: 组件树
    /// - Returns: 统计信息字典
    func getStatistics(for componentTree: UIComponentInfo) -> [String: Any] {
        var stats: [String: Any] = [:]
        var componentTypes: [String: Int] = [:]
        var totalComponents = 0
        var hiddenComponents = 0
        var disabledComponents = 0
        
        func collectStats(_ component: UIComponentInfo) {
            totalComponents += 1
            componentTypes[component.type, default: 0] += 1
            
            if component.isHidden {
                hiddenComponents += 1
            }
            
            if !component.isEnabled {
                disabledComponents += 1
            }
            
            for child in component.children {
                collectStats(child)
            }
        }
        
        collectStats(componentTree)
        
        stats["totalComponents"] = totalComponents
        stats["componentTypes"] = componentTypes
        stats["hiddenComponents"] = hiddenComponents
        stats["disabledComponents"] = disabledComponents
        stats["maxDepth"] = getMaxDepth(componentTree)
        
        return stats
    }
    
    /// 获取组件树的最大深度
    /// - Parameter componentTree: 组件树
    /// - Returns: 最大深度
    private func getMaxDepth(_ componentTree: UIComponentInfo) -> Int {
        if componentTree.children.isEmpty {
            return 1
        }
        
        let childDepths = componentTree.children.map { getMaxDepth($0) }
        return 1 + (childDepths.max() ?? 0)
    }
}
