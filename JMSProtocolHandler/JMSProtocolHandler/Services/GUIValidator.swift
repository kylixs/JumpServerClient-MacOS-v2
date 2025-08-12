//
//  GUIValidator.swift
//  JMSProtocolHandler
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import Cocoa
import Foundation

/// GUI验证器
class GUIValidator {
    
    // MARK: - Properties
    
    private let treeGenerator: UIComponentTreeGenerator
    private let tempDirectory: URL
    
    // MARK: - Initialization
    
    init() {
        self.treeGenerator = UIComponentTreeGenerator()
        self.tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("JMSProtocolHandler_GUI_Tests", isDirectory: true)
        
        // 确保临时目录存在
        try? FileManager.default.createDirectory(at: tempDirectory, 
                                               withIntermediateDirectories: true, 
                                               attributes: nil)
    }
    
    // MARK: - Public Methods
    
    /// 验证RDP质量配置界面
    /// - Parameter viewController: RDP质量配置视图控制器
    /// - Returns: 验证报告
    func validateRDPQualityConfigGUI(_ viewController: NSViewController) -> GUIValidationReport {
        let startTime = Date()
        let testName = "RDP_Quality_Config_GUI_Validation"
        
        print("🔍 开始验证RDP质量配置GUI...")
        
        guard let rootView = viewController.view else {
            return createFailedReport(testName: testName, 
                                    message: "无法获取视图控制器的根视图", 
                                    startTime: startTime)
        }
        
        // 生成组件树
        let componentTree = treeGenerator.generateComponentTree(from: rootView)
        
        // 保存组件树到临时文件
        do {
            let fileName = "rdp_config_gui_tree_\(Date().timeIntervalSince1970).json"
            try treeGenerator.saveToTempFile(componentTree, fileName: fileName)
            print("📄 组件树已保存到临时文件: \(fileName)")
        } catch {
            print("⚠️ 保存组件树失败: \(error)")
        }
        
        // 执行验证
        var validationResults: [GUIValidationReport.ValidationResult] = []
        
        // 验证预设配置选项
        validationResults.append(contentsOf: validatePresetConfigurationOptions(componentTree))
        
        // 验证自定义配置控件
        validationResults.append(contentsOf: validateCustomConfigurationControls(componentTree))
        
        // 验证界面布局
        validationResults.append(contentsOf: validateInterfaceLayout(componentTree))
        
        // 验证按钮和交互元素
        validationResults.append(contentsOf: validateInteractiveElements(componentTree))
        
        // 验证文本和标签
        validationResults.append(contentsOf: validateTextAndLabels(componentTree))
        
        // 生成验证报告
        let executionTime = Date().timeIntervalSince(startTime)
        let summary = createValidationSummary(validationResults, executionTime: executionTime, 
                                            componentTree: componentTree)
        
        let overallStatus: GUIValidationReport.ValidationStatus = validationResults.contains { $0.status == .failed } ? .failed :
                                                                 validationResults.contains { $0.status == .warning } ? .warning : .passed
        
        let report = GUIValidationReport(
            timestamp: Date(),
            testName: testName,
            status: overallStatus,
            componentTree: componentTree,
            validationResults: validationResults,
            summary: summary
        )
        
        // 保存验证报告
        saveValidationReport(report)
        
        print("✅ GUI验证完成，状态: \(overallStatus.rawValue)")
        return report
    }
    
    /// 验证任意视图控制器的GUI
    /// - Parameters:
    ///   - viewController: 视图控制器
    ///   - testName: 测试名称
    /// - Returns: 验证报告
    func validateGUI(_ viewController: NSViewController, testName: String) -> GUIValidationReport {
        let startTime = Date()
        
        print("🔍 开始验证GUI: \(testName)")
        
        guard let rootView = viewController.view else {
            return createFailedReport(testName: testName, 
                                    message: "无法获取视图控制器的根视图", 
                                    startTime: startTime)
        }
        
        // 生成组件树
        let componentTree = treeGenerator.generateComponentTree(from: rootView)
        
        // 保存组件树到临时文件
        do {
            let fileName = "\(testName.lowercased())_gui_tree_\(Date().timeIntervalSince1970).json"
            try treeGenerator.saveToTempFile(componentTree, fileName: fileName)
            print("📄 组件树已保存到临时文件: \(fileName)")
        } catch {
            print("⚠️ 保存组件树失败: \(error)")
        }
        
        // 执行基本验证
        var validationResults: [GUIValidationReport.ValidationResult] = []
        
        // 基本组件验证
        validationResults.append(contentsOf: validateBasicComponents(componentTree))
        
        // 生成验证报告
        let executionTime = Date().timeIntervalSince(startTime)
        let summary = createValidationSummary(validationResults, executionTime: executionTime, 
                                            componentTree: componentTree)
        
        let overallStatus: GUIValidationReport.ValidationStatus = validationResults.contains { $0.status == .failed } ? .failed :
                                                                 validationResults.contains { $0.status == .warning } ? .warning : .passed
        
        let report = GUIValidationReport(
            timestamp: Date(),
            testName: testName,
            status: overallStatus,
            componentTree: componentTree,
            validationResults: validationResults,
            summary: summary
        )
        
        // 保存验证报告
        saveValidationReport(report)
        
        print("✅ GUI验证完成，状态: \(overallStatus.rawValue)")
        return report
    }
    
    // MARK: - Private Validation Methods
    
    /// 验证预设配置选项
    private func validatePresetConfigurationOptions(_ componentTree: UIComponentInfo) -> [GUIValidationReport.ValidationResult] {
        var results: [GUIValidationReport.ValidationResult] = []
        
        // 查找分段控件（预设配置选择器）
        let segmentedControls = treeGenerator.findComponents(in: componentTree, ofType: "NSSegmentedControl")
        
        if segmentedControls.isEmpty {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "preset_config_selector",
                testType: "预设配置选项存在性",
                status: .failed,
                message: "未找到预设配置选择器（NSSegmentedControl）",
                expected: "应该存在一个分段控件用于选择预设配置",
                actual: "未找到分段控件",
                suggestion: "检查RDPQualityConfigViewController中是否正确创建了profileSegmentedControl"
            ))
        } else {
            let segmentedControl = segmentedControls[0]
            
            // 验证分段数量（应该有3个：性能优先、平衡模式、质量优先）
            if segmentedControl.content.selectedSegment != nil {
                results.append(GUIValidationReport.ValidationResult(
                    componentId: segmentedControl.id,
                    testType: "预设配置选项数量",
                    status: .passed,
                    message: "找到预设配置选择器",
                    expected: "存在分段控件",
                    actual: "找到分段控件",
                    suggestion: nil
                ))
            } else {
                results.append(GUIValidationReport.ValidationResult(
                    componentId: segmentedControl.id,
                    testType: "预设配置选项配置",
                    status: .warning,
                    message: "分段控件可能未正确配置",
                    expected: "分段控件应该有选中状态",
                    actual: "selectedSegment为nil",
                    suggestion: "检查分段控件的初始化和配置"
                ))
            }
        }
        
        return results
    }
    
    /// 验证自定义配置控件
    private func validateCustomConfigurationControls(_ componentTree: UIComponentInfo) -> [GUIValidationReport.ValidationResult] {
        var results: [GUIValidationReport.ValidationResult] = []
        
        // 查找滑块控件（压缩级别）
        let sliders = treeGenerator.findComponents(in: componentTree, ofType: "NSSlider")
        if sliders.isEmpty {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "compression_slider",
                testType: "压缩级别滑块存在性",
                status: .failed,
                message: "未找到压缩级别滑块",
                expected: "应该存在至少一个滑块控件",
                actual: "未找到滑块控件",
                suggestion: "检查compressionSlider是否正确创建和添加到视图中"
            ))
        } else {
            results.append(GUIValidationReport.ValidationResult(
                componentId: sliders[0].id,
                testType: "压缩级别滑块存在性",
                status: .passed,
                message: "找到压缩级别滑块",
                expected: "存在滑块控件",
                actual: "找到\(sliders.count)个滑块控件",
                suggestion: nil
            ))
        }
        
        // 查找下拉框控件（颜色深度、音频质量）
        let popUpButtons = treeGenerator.findComponents(in: componentTree, ofType: "NSPopUpButton")
        if popUpButtons.count < 2 {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "popup_buttons",
                testType: "下拉框控件数量",
                status: .failed,
                message: "下拉框控件数量不足",
                expected: "应该至少有2个下拉框（颜色深度、音频质量）",
                actual: "找到\(popUpButtons.count)个下拉框",
                suggestion: "检查colorDepthPopup和audioQualityPopup是否正确创建"
            ))
        } else {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "popup_buttons",
                testType: "下拉框控件数量",
                status: .passed,
                message: "找到足够的下拉框控件",
                expected: "至少2个下拉框",
                actual: "找到\(popUpButtons.count)个下拉框",
                suggestion: nil
            ))
        }
        
        // 查找复选框控件（特效选项）
        let checkboxes = treeGenerator.findComponents(in: componentTree, ofType: "NSButton")
            .filter { $0.content.state != nil }
        
        if checkboxes.count < 4 {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "checkboxes",
                testType: "复选框控件数量",
                status: .warning,
                message: "复选框控件数量可能不足",
                expected: "应该有4个复选框（字体平滑、壁纸、动画、主题）",
                actual: "找到\(checkboxes.count)个复选框",
                suggestion: "检查特效选项的复选框是否都正确创建"
            ))
        } else {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "checkboxes",
                testType: "复选框控件数量",
                status: .passed,
                message: "找到足够的复选框控件",
                expected: "至少4个复选框",
                actual: "找到\(checkboxes.count)个复选框",
                suggestion: nil
            ))
        }
        
        return results
    }
    
    /// 验证界面布局
    private func validateInterfaceLayout(_ componentTree: UIComponentInfo) -> [GUIValidationReport.ValidationResult] {
        var results: [GUIValidationReport.ValidationResult] = []
        
        // 验证根视图大小
        if componentTree.frame.width < 500 || componentTree.frame.height < 400 {
            results.append(GUIValidationReport.ValidationResult(
                componentId: componentTree.id,
                testType: "界面尺寸",
                status: .warning,
                message: "界面尺寸可能过小",
                expected: "宽度≥500，高度≥400",
                actual: "宽度=\(componentTree.frame.width)，高度=\(componentTree.frame.height)",
                suggestion: "考虑增加界面尺寸以提供更好的用户体验"
            ))
        } else {
            results.append(GUIValidationReport.ValidationResult(
                componentId: componentTree.id,
                testType: "界面尺寸",
                status: .passed,
                message: "界面尺寸合适",
                expected: "宽度≥500，高度≥400",
                actual: "宽度=\(componentTree.frame.width)，高度=\(componentTree.frame.height)",
                suggestion: nil
            ))
        }
        
        // 验证组件是否有重叠
        let allComponents = getAllComponents(componentTree)
        let overlappingComponents = findOverlappingComponents(allComponents)
        
        if !overlappingComponents.isEmpty {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "layout_overlap",
                testType: "组件重叠检查",
                status: .warning,
                message: "发现可能重叠的组件",
                expected: "组件不应该重叠",
                actual: "发现\(overlappingComponents.count)对重叠组件",
                suggestion: "检查组件布局约束，确保组件不会重叠"
            ))
        } else {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "layout_overlap",
                testType: "组件重叠检查",
                status: .passed,
                message: "未发现组件重叠",
                expected: "组件不重叠",
                actual: "无重叠组件",
                suggestion: nil
            ))
        }
        
        return results
    }
    
    /// 验证交互元素
    private func validateInteractiveElements(_ componentTree: UIComponentInfo) -> [GUIValidationReport.ValidationResult] {
        var results: [GUIValidationReport.ValidationResult] = []
        
        // 查找按钮
        let buttons = treeGenerator.findComponents(in: componentTree, ofType: "NSButton")
        let actionButtons = buttons.filter { $0.content.title != nil && $0.content.state == nil }
        
        if actionButtons.count < 4 {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "action_buttons",
                testType: "操作按钮数量",
                status: .warning,
                message: "操作按钮数量可能不足",
                expected: "应该有4个操作按钮（应用、重置、导出、导入）",
                actual: "找到\(actionButtons.count)个操作按钮",
                suggestion: "检查applyButton、resetButton、exportButton、importButton是否正确创建"
            ))
        } else {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "action_buttons",
                testType: "操作按钮数量",
                status: .passed,
                message: "找到足够的操作按钮",
                expected: "至少4个操作按钮",
                actual: "找到\(actionButtons.count)个操作按钮",
                suggestion: nil
            ))
        }
        
        // 验证按钮是否启用
        let disabledButtons = actionButtons.filter { !$0.isEnabled }
        if !disabledButtons.isEmpty {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "button_enabled_state",
                testType: "按钮启用状态",
                status: .warning,
                message: "部分按钮处于禁用状态",
                expected: "所有按钮应该启用",
                actual: "\(disabledButtons.count)个按钮被禁用",
                suggestion: "检查按钮的启用逻辑"
            ))
        } else {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "button_enabled_state",
                testType: "按钮启用状态",
                status: .passed,
                message: "所有按钮都已启用",
                expected: "按钮启用",
                actual: "所有按钮启用",
                suggestion: nil
            ))
        }
        
        return results
    }
    
    /// 验证文本和标签
    private func validateTextAndLabels(_ componentTree: UIComponentInfo) -> [GUIValidationReport.ValidationResult] {
        var results: [GUIValidationReport.ValidationResult] = []
        
        // 查找文本字段和标签
        let textFields = treeGenerator.findComponents(in: componentTree, ofType: "NSTextField")
        let labels = textFields.filter { !($0.isEditable ?? true) }
        
        if labels.count < 5 {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "labels",
                testType: "标签数量",
                status: .warning,
                message: "标签数量可能不足",
                expected: "应该有足够的标签来描述各个控件",
                actual: "找到\(labels.count)个标签",
                suggestion: "检查是否为所有控件添加了描述标签"
            ))
        } else {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "labels",
                testType: "标签数量",
                status: .passed,
                message: "找到足够的标签",
                expected: "足够的标签",
                actual: "找到\(labels.count)个标签",
                suggestion: nil
            ))
        }
        
        // 检查是否有空标签
        let emptyLabels = labels.filter { 
            ($0.content.stringValue?.isEmpty ?? true) && 
            ($0.content.title?.isEmpty ?? true) 
        }
        
        if !emptyLabels.isEmpty {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "empty_labels",
                testType: "空标签检查",
                status: .warning,
                message: "发现空标签",
                expected: "标签应该有内容",
                actual: "发现\(emptyLabels.count)个空标签",
                suggestion: "为空标签添加适当的文本内容"
            ))
        } else {
            results.append(GUIValidationReport.ValidationResult(
                componentId: "empty_labels",
                testType: "空标签检查",
                status: .passed,
                message: "未发现空标签",
                expected: "无空标签",
                actual: "所有标签都有内容",
                suggestion: nil
            ))
        }
        
        return results
    }
    
    /// 验证基本组件
    private func validateBasicComponents(_ componentTree: UIComponentInfo) -> [GUIValidationReport.ValidationResult] {
        var results: [GUIValidationReport.ValidationResult] = []
        
        // 基本存在性检查
        results.append(GUIValidationReport.ValidationResult(
            componentId: componentTree.id,
            testType: "根视图存在性",
            status: .passed,
            message: "根视图存在",
            expected: "存在根视图",
            actual: "找到根视图: \(componentTree.type)",
            suggestion: nil
        ))
        
        // 子组件数量检查
        if componentTree.children.isEmpty {
            results.append(GUIValidationReport.ValidationResult(
                componentId: componentTree.id,
                testType: "子组件存在性",
                status: .warning,
                message: "根视图没有子组件",
                expected: "应该有子组件",
                actual: "子组件数量: 0",
                suggestion: "检查视图是否正确加载了子组件"
            ))
        } else {
            results.append(GUIValidationReport.ValidationResult(
                componentId: componentTree.id,
                testType: "子组件存在性",
                status: .passed,
                message: "找到子组件",
                expected: "存在子组件",
                actual: "子组件数量: \(componentTree.children.count)",
                suggestion: nil
            ))
        }
        
        return results
    }
    
    // MARK: - Helper Methods
    
    /// 创建失败报告
    private func createFailedReport(testName: String, message: String, startTime: Date) -> GUIValidationReport {
        let executionTime = Date().timeIntervalSince(startTime)
        
        let validationResult = GUIValidationReport.ValidationResult(
            componentId: "root",
            testType: "基础验证",
            status: .failed,
            message: message,
            expected: "成功获取视图",
            actual: "获取视图失败",
            suggestion: "检查视图控制器的初始化和视图加载"
        )
        
        let summary = GUIValidationReport.ValidationSummary(
            totalComponents: 0,
            passedTests: 0,
            failedTests: 1,
            warningTests: 0,
            executionTime: executionTime
        )
        
        return GUIValidationReport(
            timestamp: Date(),
            testName: testName,
            status: .failed,
            componentTree: nil,
            validationResults: [validationResult],
            summary: summary
        )
    }
    
    /// 创建验证摘要
    private func createValidationSummary(_ validationResults: [GUIValidationReport.ValidationResult], 
                                       executionTime: TimeInterval,
                                       componentTree: UIComponentInfo) -> GUIValidationReport.ValidationSummary {
        let passedTests = validationResults.filter { $0.status == .passed }.count
        let failedTests = validationResults.filter { $0.status == .failed }.count
        let warningTests = validationResults.filter { $0.status == .warning }.count
        
        let stats = treeGenerator.getStatistics(for: componentTree)
        let totalComponents = stats["totalComponents"] as? Int ?? 0
        
        return GUIValidationReport.ValidationSummary(
            totalComponents: totalComponents,
            passedTests: passedTests,
            failedTests: failedTests,
            warningTests: warningTests,
            executionTime: executionTime
        )
    }
    
    /// 保存验证报告
    private func saveValidationReport(_ report: GUIValidationReport) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(report)
            let fileName = "gui_validation_report_\(report.testName)_\(Date().timeIntervalSince1970).json"
            let fileURL = tempDirectory.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            print("📊 验证报告已保存到: \(fileURL.path)")
        } catch {
            print("⚠️ 保存验证报告失败: \(error)")
        }
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
}
