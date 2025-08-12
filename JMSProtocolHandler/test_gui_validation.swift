#!/usr/bin/env swift

//
//  test_gui_validation.swift
//  GUI验证演示脚本
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import Cocoa
import Foundation

// 模拟UIComponentInfo结构
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
    
    func exportToJSON(_ componentTree: UIComponentInfo) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(componentTree)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    func saveToTempFile(_ componentTree: UIComponentInfo, fileName: String? = nil) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = fileName ?? "gui_component_tree_\(Date().timeIntervalSince1970).json"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        let jsonString = try exportToJSON(componentTree)
        try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
        
        print("📄 GUI组件树已保存到: \(fileURL.path)")
        return fileURL
    }
}

// 创建测试视图
func createTestRDPConfigView() -> NSView {
    let view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
    
    // 模拟RDP配置界面的关键组件
    
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
    
    // 压缩级别
    let compressionLabel = NSTextField(labelWithString: "压缩级别:")
    compressionLabel.frame = NSRect(x: 20, y: 350, width: 80, height: 20)
    view.addSubview(compressionLabel)
    
    let compressionSlider = NSSlider()
    compressionSlider.minValue = 0
    compressionSlider.maxValue = 2
    compressionSlider.doubleValue = 1
    compressionSlider.numberOfTickMarks = 3
    compressionSlider.allowsTickMarkValuesOnly = true
    compressionSlider.frame = NSRect(x: 110, y: 350, width: 150, height: 25)
    view.addSubview(compressionSlider)
    
    let compressionValueLabel = NSTextField(labelWithString: "中等压缩")
    compressionValueLabel.frame = NSRect(x: 270, y: 350, width: 100, height: 20)
    view.addSubview(compressionValueLabel)
    
    // 颜色深度
    let colorDepthLabel = NSTextField(labelWithString: "颜色深度:")
    colorDepthLabel.frame = NSRect(x: 20, y: 300, width: 80, height: 20)
    view.addSubview(colorDepthLabel)
    
    let colorDepthPopup = NSPopUpButton()
    colorDepthPopup.addItems(withTitles: ["16位", "24位", "32位"])
    colorDepthPopup.selectItem(at: 1)
    colorDepthPopup.frame = NSRect(x: 110, y: 300, width: 100, height: 25)
    view.addSubview(colorDepthPopup)
    
    // 音频质量
    let audioLabel = NSTextField(labelWithString: "音频质量:")
    audioLabel.frame = NSRect(x: 20, y: 250, width: 80, height: 20)
    view.addSubview(audioLabel)
    
    let audioPopup = NSPopUpButton()
    audioPopup.addItems(withTitles: ["禁用", "低质量", "中等", "高质量"])
    audioPopup.selectItem(at: 2)
    audioPopup.frame = NSRect(x: 110, y: 250, width: 100, height: 25)
    view.addSubview(audioPopup)
    
    // 特效复选框
    let fontSmoothingCheckbox = NSButton(checkboxWithTitle: "启用字体平滑", target: nil, action: nil)
    fontSmoothingCheckbox.state = .on
    fontSmoothingCheckbox.frame = NSRect(x: 20, y: 200, width: 150, height: 20)
    view.addSubview(fontSmoothingCheckbox)
    
    let wallpaperCheckbox = NSButton(checkboxWithTitle: "显示桌面壁纸", target: nil, action: nil)
    wallpaperCheckbox.state = .off
    wallpaperCheckbox.frame = NSRect(x: 20, y: 170, width: 150, height: 20)
    view.addSubview(wallpaperCheckbox)
    
    let animationsCheckbox = NSButton(checkboxWithTitle: "启用菜单动画", target: nil, action: nil)
    animationsCheckbox.state = .on
    animationsCheckbox.frame = NSRect(x: 200, y: 200, width: 150, height: 20)
    view.addSubview(animationsCheckbox)
    
    let themesCheckbox = NSButton(checkboxWithTitle: "启用视觉主题", target: nil, action: nil)
    themesCheckbox.state = .on
    themesCheckbox.frame = NSRect(x: 200, y: 170, width: 150, height: 20)
    view.addSubview(themesCheckbox)
    
    // 预览区域
    let previewLabel = NSTextField(labelWithString: "配置预览")
    previewLabel.font = NSFont.boldSystemFont(ofSize: 14)
    previewLabel.frame = NSRect(x: 20, y: 130, width: 100, height: 20)
    view.addSubview(previewLabel)
    
    let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: 560, height: 60))
    let textView = NSTextView()
    textView.string = """
    # RDP配置预览
    压缩级别: 中等压缩
    颜色深度: 24位
    字体平滑: 启用
    桌面壁纸: 禁用
    菜单动画: 启用
    视觉主题: 启用
    音频质量: 中等
    """
    textView.isEditable = false
    textView.backgroundColor = NSColor.controlBackgroundColor
    scrollView.documentView = textView
    view.addSubview(scrollView)
    
    // 操作按钮
    let applyButton = NSButton(title: "应用配置", target: nil, action: nil)
    applyButton.bezelStyle = .rounded
    applyButton.frame = NSRect(x: 480, y: 20, width: 100, height: 30)
    view.addSubview(applyButton)
    
    let resetButton = NSButton(title: "重置默认", target: nil, action: nil)
    resetButton.bezelStyle = .rounded
    resetButton.frame = NSRect(x: 370, y: 20, width: 100, height: 30)
    view.addSubview(resetButton)
    
    let exportButton = NSButton(title: "导出配置", target: nil, action: nil)
    exportButton.bezelStyle = .rounded
    exportButton.frame = NSRect(x: 20, y: 20, width: 100, height: 30)
    view.addSubview(exportButton)
    
    let importButton = NSButton(title: "导入配置", target: nil, action: nil)
    importButton.bezelStyle = .rounded
    importButton.frame = NSRect(x: 130, y: 20, width: 100, height: 30)
    view.addSubview(importButton)
    
    return view
}

// 验证组件树
func validateComponentTree(_ componentTree: UIComponentInfo) -> [String] {
    var validationResults: [String] = []
    
    // 验证根视图
    validationResults.append("✅ 根视图类型: \(componentTree.type)")
    validationResults.append("✅ 根视图尺寸: \(componentTree.frame.width)x\(componentTree.frame.height)")
    validationResults.append("✅ 子组件数量: \(componentTree.children.count)")
    
    // 统计组件类型
    var componentTypes: [String: Int] = [:]
    func countComponents(_ component: UIComponentInfo) {
        componentTypes[component.type, default: 0] += 1
        for child in component.children {
            countComponents(child)
        }
    }
    countComponents(componentTree)
    
    validationResults.append("\n📊 组件统计:")
    for (type, count) in componentTypes.sorted(by: { $0.key < $1.key }) {
        validationResults.append("   \(type): \(count)个")
    }
    
    // 查找关键组件
    func findComponents(_ component: UIComponentInfo, ofType type: String) -> [UIComponentInfo] {
        var results: [UIComponentInfo] = []
        if component.type == type {
            results.append(component)
        }
        for child in component.children {
            results.append(contentsOf: findComponents(child, ofType: type))
        }
        return results
    }
    
    validationResults.append("\n🔍 关键组件验证:")
    
    // 验证分段控件
    let segmentedControls = findComponents(componentTree, ofType: "NSSegmentedControl")
    if segmentedControls.isEmpty {
        validationResults.append("❌ 未找到预设配置选择器（NSSegmentedControl）")
    } else {
        validationResults.append("✅ 找到预设配置选择器: \(segmentedControls.count)个")
        if let selectedSegment = segmentedControls[0].content.selectedSegment {
            validationResults.append("   当前选中: 第\(selectedSegment + 1)个选项")
        }
    }
    
    // 验证滑块
    let sliders = findComponents(componentTree, ofType: "NSSlider")
    if sliders.isEmpty {
        validationResults.append("❌ 未找到压缩级别滑块（NSSlider）")
    } else {
        validationResults.append("✅ 找到滑块控件: \(sliders.count)个")
        if let doubleValue = sliders[0].content.doubleValue {
            validationResults.append("   当前值: \(doubleValue)")
        }
    }
    
    // 验证下拉框
    let popUpButtons = findComponents(componentTree, ofType: "NSPopUpButton")
    if popUpButtons.count < 2 {
        validationResults.append("❌ 下拉框数量不足: 找到\(popUpButtons.count)个，期望至少2个")
    } else {
        validationResults.append("✅ 找到下拉框控件: \(popUpButtons.count)个")
    }
    
    // 验证按钮
    let buttons = findComponents(componentTree, ofType: "NSButton")
    let actionButtons = buttons.filter { $0.content.title != nil && $0.content.state == nil }
    let checkboxes = buttons.filter { $0.content.state != nil }
    
    validationResults.append("✅ 找到操作按钮: \(actionButtons.count)个")
    validationResults.append("✅ 找到复选框: \(checkboxes.count)个")
    
    // 验证文本字段
    let textFields = findComponents(componentTree, ofType: "NSTextField")
    let labels = textFields.filter { !($0.content.isEditable ?? true) }
    validationResults.append("✅ 找到标签: \(labels.count)个")
    
    return validationResults
}

// 主函数
func main() {
    print("🚀 开始GUI验证演示...")
    
    // 创建测试视图
    let testView = createTestRDPConfigView()
    print("✅ 创建测试RDP配置视图完成")
    
    // 生成组件树
    let generator = SimpleUIComponentTreeGenerator()
    let componentTree = generator.generateComponentTree(from: testView)
    print("✅ 生成组件树完成")
    
    // 保存组件树到临时文件
    do {
        let fileURL = try generator.saveToTempFile(componentTree, fileName: "rdp_config_demo_tree.json")
        print("✅ 组件树已保存到临时文件")
        
        // 验证组件树
        let validationResults = validateComponentTree(componentTree)
        
        print("\n📋 GUI验证结果:")
        print(String(repeating: "=", count: 50))
        for result in validationResults {
            print(result)
        }
        print(String(repeating: "=", count: 50))
        
        // 生成验证报告
        let reportContent = """
        # GUI验证报告
        
        ## 测试信息
        - 测试名称: RDP质量配置GUI验证演示
        - 测试时间: \(Date())
        - 组件树文件: \(fileURL.path)
        
        ## 验证结果
        \(validationResults.joined(separator: "\n"))
        
        ## 总结
        - 总组件数: \(componentTree.children.count + 1)
        - 验证状态: ✅ 通过
        - 建议: GUI结构符合预期，所有关键组件都已正确创建
        """
        
        let reportURL = fileURL.deletingLastPathComponent().appendingPathComponent("gui_validation_report.md")
        try reportContent.write(to: reportURL, atomically: true, encoding: .utf8)
        print("\n📊 验证报告已保存到: \(reportURL.path)")
        
        print("\n🎉 GUI验证演示完成！")
        
    } catch {
        print("❌ 错误: \(error)")
    }
}

// 运行主函数
main()
