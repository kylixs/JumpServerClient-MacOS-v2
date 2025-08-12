//
//  GUIValidationTests.swift
//  JMSProtocolHandlerTests
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import XCTest
import Cocoa
@testable import JMSProtocolHandler

class GUIValidationTests: XCTestCase {
    
    // MARK: - Properties
    
    private var guiValidator: GUIValidator!
    private var treeGenerator: UIComponentTreeGenerator!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        guiValidator = GUIValidator()
        treeGenerator = UIComponentTreeGenerator()
        
        print("🧪 设置GUI验证测试环境")
    }
    
    override func tearDownWithError() throws {
        guiValidator = nil
        treeGenerator = nil
        try super.tearDownWithError()
        
        print("🧹 清理GUI验证测试环境")
    }
    
    // MARK: - Component Tree Generation Tests
    
    func testUIComponentTreeGeneration() throws {
        print("🔍 测试UI组件树生成...")
        
        // 创建测试视图
        let testView = createTestView()
        
        // 生成组件树
        let componentTree = treeGenerator.generateComponentTree(from: testView)
        
        // 验证组件树结构
        XCTAssertEqual(componentTree.type, "NSView", "根组件类型应该是NSView")
        XCTAssertFalse(componentTree.children.isEmpty, "根组件应该有子组件")
        XCTAssertEqual(componentTree.frame, testView.frame, "组件树应该记录正确的frame")
        
        // 验证子组件
        XCTAssertGreaterThanOrEqual(componentTree.children.count, 3, "应该至少有3个子组件")
        
        print("✅ UI组件树生成测试通过")
    }
    
    func testComponentTreeJSONExport() throws {
        print("🔍 测试组件树JSON导出...")
        
        let testView = createTestView()
        let componentTree = treeGenerator.generateComponentTree(from: testView)
        
        // 导出为JSON
        let jsonString = try treeGenerator.exportToJSON(componentTree)
        
        // 验证JSON格式
        XCTAssertFalse(jsonString.isEmpty, "JSON字符串不应该为空")
        XCTAssertTrue(jsonString.contains("\"type\""), "JSON应该包含type字段")
        XCTAssertTrue(jsonString.contains("\"frame\""), "JSON应该包含frame字段")
        XCTAssertTrue(jsonString.contains("\"children\""), "JSON应该包含children字段")
        
        // 验证可以重新解析
        let parsedTree = try treeGenerator.importFromJSON(jsonString)
        XCTAssertEqual(parsedTree.type, componentTree.type, "解析后的组件树类型应该一致")
        
        print("✅ 组件树JSON导出测试通过")
    }
    
    func testComponentTreeSaveToTempFile() throws {
        print("🔍 测试组件树保存到临时文件...")
        
        let testView = createTestView()
        let componentTree = treeGenerator.generateComponentTree(from: testView)
        
        // 保存到临时文件
        let fileURL = try treeGenerator.saveToTempFile(componentTree, fileName: "test_component_tree.json")
        
        // 验证文件存在
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "临时文件应该存在")
        
        // 验证文件内容
        let fileContent = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertFalse(fileContent.isEmpty, "文件内容不应该为空")
        XCTAssertTrue(fileContent.contains("\"type\""), "文件应该包含JSON格式的组件树")
        
        // 清理临时文件
        try? FileManager.default.removeItem(at: fileURL)
        
        print("✅ 组件树保存到临时文件测试通过")
    }
    
    // MARK: - GUI Validation Tests
    
    func testBasicGUIValidation() throws {
        print("🔍 测试基本GUI验证...")
        
        // 创建测试视图控制器
        let testViewController = createTestViewController()
        
        // 执行GUI验证
        let report = guiValidator.validateGUI(testViewController, testName: "BasicGUITest")
        
        // 验证报告结构
        XCTAssertEqual(report.testName, "BasicGUITest", "测试名称应该正确")
        XCTAssertNotNil(report.componentTree, "应该生成组件树")
        XCTAssertFalse(report.validationResults.isEmpty, "应该有验证结果")
        
        // 验证基本验证通过
        let passedResults = report.validationResults.filter { $0.status == .passed }
        XCTAssertFalse(passedResults.isEmpty, "应该有通过的验证项")
        
        // 验证摘要信息
        XCTAssertGreaterThan(report.summary.totalComponents, 0, "应该统计到组件数量")
        XCTAssertGreaterThan(report.summary.executionTime, 0, "应该记录执行时间")
        
        print("✅ 基本GUI验证测试通过")
    }
    
    func testRDPQualityConfigGUIValidation() throws {
        print("🔍 测试RDP质量配置GUI验证...")
        
        // 创建RDP质量配置视图控制器的模拟
        let rdpConfigViewController = createMockRDPQualityConfigViewController()
        
        // 执行RDP GUI验证
        let report = guiValidator.validateRDPQualityConfigGUI(rdpConfigViewController)
        
        // 验证报告
        XCTAssertEqual(report.testName, "RDP_Quality_Config_GUI_Validation", "测试名称应该正确")
        XCTAssertNotNil(report.componentTree, "应该生成组件树")
        
        // 验证特定的RDP配置验证项
        let validationTypes = Set(report.validationResults.map { $0.testType })
        XCTAssertTrue(validationTypes.contains("界面尺寸"), "应该验证界面尺寸")
        XCTAssertTrue(validationTypes.contains("根视图存在性"), "应该验证根视图存在性")
        
        // 验证至少有一些验证通过
        let passedCount = report.validationResults.filter { $0.status == .passed }.count
        XCTAssertGreaterThan(passedCount, 0, "应该有通过的验证项")
        
        print("✅ RDP质量配置GUI验证测试通过")
    }
    
    func testGUIValidationReportGeneration() throws {
        print("🔍 测试GUI验证报告生成...")
        
        let testViewController = createTestViewController()
        let report = guiValidator.validateGUI(testViewController, testName: "ReportGenerationTest")
        
        // 验证报告完整性
        XCTAssertNotNil(report.timestamp, "应该有时间戳")
        XCTAssertEqual(report.testName, "ReportGenerationTest", "测试名称应该正确")
        XCTAssertNotNil(report.componentTree, "应该有组件树")
        XCTAssertFalse(report.validationResults.isEmpty, "应该有验证结果")
        
        // 验证摘要统计
        let summary = report.summary
        let totalTests = summary.passedTests + summary.failedTests + summary.warningTests
        XCTAssertEqual(totalTests, report.validationResults.count, "摘要统计应该与验证结果数量一致")
        
        // 验证状态计算
        let hasFailures = report.validationResults.contains { $0.status == .failed }
        let hasWarnings = report.validationResults.contains { $0.status == .warning }
        
        if hasFailures {
            XCTAssertEqual(report.status, .failed, "有失败项时整体状态应该是失败")
        } else if hasWarnings {
            XCTAssertEqual(report.status, .warning, "有警告项时整体状态应该是警告")
        } else {
            XCTAssertEqual(report.status, .passed, "无失败和警告时整体状态应该是通过")
        }
        
        print("✅ GUI验证报告生成测试通过")
    }
    
    // MARK: - Component Search Tests
    
    func testComponentSearch() throws {
        print("🔍 测试组件搜索功能...")
        
        let testView = createTestView()
        let componentTree = treeGenerator.generateComponentTree(from: testView)
        
        // 测试按类型搜索
        let buttons = treeGenerator.findComponents(in: componentTree, ofType: "NSButton")
        XCTAssertFalse(buttons.isEmpty, "应该找到按钮组件")
        
        let textFields = treeGenerator.findComponents(in: componentTree, ofType: "NSTextField")
        XCTAssertFalse(textFields.isEmpty, "应该找到文本字段组件")
        
        // 测试按文本搜索
        let componentsWithTestText = treeGenerator.findComponents(in: componentTree, containingText: "测试")
        XCTAssertFalse(componentsWithTestText.isEmpty, "应该找到包含'测试'文本的组件")
        
        print("✅ 组件搜索功能测试通过")
    }
    
    func testComponentStatistics() throws {
        print("🔍 测试组件统计功能...")
        
        let testView = createTestView()
        let componentTree = treeGenerator.generateComponentTree(from: testView)
        
        // 获取统计信息
        let stats = treeGenerator.getStatistics(for: componentTree)
        
        // 验证统计信息
        XCTAssertNotNil(stats["totalComponents"], "应该有总组件数统计")
        XCTAssertNotNil(stats["componentTypes"], "应该有组件类型统计")
        XCTAssertNotNil(stats["maxDepth"], "应该有最大深度统计")
        
        let totalComponents = stats["totalComponents"] as? Int ?? 0
        XCTAssertGreaterThan(totalComponents, 0, "总组件数应该大于0")
        
        let maxDepth = stats["maxDepth"] as? Int ?? 0
        XCTAssertGreaterThan(maxDepth, 0, "最大深度应该大于0")
        
        print("✅ 组件统计功能测试通过")
    }
    
    // MARK: - Performance Tests
    
    func testGUIValidationPerformance() throws {
        print("🔍 测试GUI验证性能...")
        
        let testViewController = createTestViewController()
        
        // 测量验证性能
        measure {
            let _ = guiValidator.validateGUI(testViewController, testName: "PerformanceTest")
        }
        
        print("✅ GUI验证性能测试完成")
    }
    
    func testComponentTreeGenerationPerformance() throws {
        print("🔍 测试组件树生成性能...")
        
        let testView = createComplexTestView()
        
        // 测量生成性能
        measure {
            let _ = treeGenerator.generateComponentTree(from: testView)
        }
        
        print("✅ 组件树生成性能测试完成")
    }
    
    // MARK: - Helper Methods
    
    /// 创建测试视图
    private func createTestView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        
        // 添加一些测试组件
        let button = NSButton(title: "测试按钮", target: nil, action: nil)
        button.frame = NSRect(x: 20, y: 20, width: 100, height: 30)
        view.addSubview(button)
        
        let textField = NSTextField()
        textField.stringValue = "测试文本"
        textField.frame = NSRect(x: 20, y: 60, width: 200, height: 25)
        view.addSubview(textField)
        
        let label = NSTextField(labelWithString: "测试标签")
        label.frame = NSRect(x: 20, y: 100, width: 100, height: 20)
        view.addSubview(label)
        
        return view
    }
    
    /// 创建复杂测试视图
    private func createComplexTestView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        
        // 添加多个层级的组件
        for i in 0..<10 {
            let containerView = NSView(frame: NSRect(x: i * 50, y: i * 40, width: 200, height: 150))
            
            let button = NSButton(title: "按钮\(i)", target: nil, action: nil)
            button.frame = NSRect(x: 10, y: 10, width: 80, height: 30)
            containerView.addSubview(button)
            
            let textField = NSTextField()
            textField.stringValue = "文本\(i)"
            textField.frame = NSRect(x: 10, y: 50, width: 150, height: 25)
            containerView.addSubview(textField)
            
            view.addSubview(containerView)
        }
        
        return view
    }
    
    /// 创建测试视图控制器
    private func createTestViewController() -> NSViewController {
        let viewController = NSViewController()
        viewController.view = createTestView()
        return viewController
    }
    
    /// 创建模拟的RDP质量配置视图控制器
    private func createMockRDPQualityConfigViewController() -> NSViewController {
        let viewController = NSViewController()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        
        // 模拟RDP配置界面的关键组件
        
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
        let slider = NSSlider()
        slider.minValue = 0
        slider.maxValue = 2
        slider.doubleValue = 1
        slider.frame = NSRect(x: 100, y: 350, width: 150, height: 25)
        view.addSubview(slider)
        
        // 颜色深度下拉框
        let colorDepthPopup = NSPopUpButton()
        colorDepthPopup.addItems(withTitles: ["16位", "24位", "32位"])
        colorDepthPopup.selectItem(at: 1)
        colorDepthPopup.frame = NSRect(x: 100, y: 300, width: 100, height: 25)
        view.addSubview(colorDepthPopup)
        
        // 音频质量下拉框
        let audioPopup = NSPopUpButton()
        audioPopup.addItems(withTitles: ["禁用", "低质量", "中等", "高质量"])
        audioPopup.selectItem(at: 2)
        audioPopup.frame = NSRect(x: 100, y: 250, width: 100, height: 25)
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
        
        // 操作按钮
        let applyButton = NSButton(title: "应用配置", target: nil, action: nil)
        applyButton.frame = NSRect(x: 480, y: 20, width: 100, height: 30)
        view.addSubview(applyButton)
        
        let resetButton = NSButton(title: "重置默认", target: nil, action: nil)
        resetButton.frame = NSRect(x: 370, y: 20, width: 100, height: 30)
        view.addSubview(resetButton)
        
        let exportButton = NSButton(title: "导出配置", target: nil, action: nil)
        exportButton.frame = NSRect(x: 20, y: 20, width: 100, height: 30)
        view.addSubview(exportButton)
        
        let importButton = NSButton(title: "导入配置", target: nil, action: nil)
        importButton.frame = NSRect(x: 130, y: 20, width: 100, height: 30)
        view.addSubview(importButton)
        
        // 预览文本视图
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: 560, height: 100))
        let textView = NSTextView()
        textView.string = "配置预览内容..."
        textView.isEditable = false
        scrollView.documentView = textView
        view.addSubview(scrollView)
        
        // 添加一些标签
        let labels = [
            ("预设配置文件", NSRect(x: 20, y: 440, width: 100, height: 20)),
            ("压缩级别", NSRect(x: 20, y: 350, width: 70, height: 20)),
            ("颜色深度", NSRect(x: 20, y: 300, width: 70, height: 20)),
            ("音频质量", NSRect(x: 20, y: 250, width: 70, height: 20)),
            ("配置预览", NSRect(x: 20, y: 180, width: 70, height: 20))
        ]
        
        for (text, frame) in labels {
            let label = NSTextField(labelWithString: text)
            label.frame = frame
            view.addSubview(label)
        }
        
        viewController.view = view
        return viewController
    }
}
