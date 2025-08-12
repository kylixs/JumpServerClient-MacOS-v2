//
//  SimpleGUIValidationTest.swift
//  JMSProtocolHandlerTests
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import XCTest
import Cocoa

class SimpleGUIValidationTest: XCTestCase {
    
    func testBasicViewCreation() throws {
        print("🧪 测试基本视图创建...")
        
        // 创建一个简单的测试视图
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        
        // 添加一个按钮
        let button = NSButton(title: "测试按钮", target: nil, action: nil)
        button.frame = NSRect(x: 50, y: 50, width: 100, height: 30)
        view.addSubview(button)
        
        // 添加一个文本字段
        let textField = NSTextField()
        textField.stringValue = "测试文本"
        textField.frame = NSRect(x: 50, y: 100, width: 200, height: 25)
        view.addSubview(textField)
        
        // 验证视图结构
        XCTAssertEqual(view.subviews.count, 2, "视图应该有2个子视图")
        XCTAssertTrue(view.subviews.contains(button), "视图应该包含按钮")
        XCTAssertTrue(view.subviews.contains(textField), "视图应该包含文本字段")
        
        // 验证组件属性
        XCTAssertEqual(button.title, "测试按钮", "按钮标题应该正确")
        XCTAssertEqual(textField.stringValue, "测试文本", "文本字段内容应该正确")
        
        print("✅ 基本视图创建测试通过")
    }
    
    func testViewControllerCreation() throws {
        print("🧪 测试视图控制器创建...")
        
        // 创建视图控制器
        let viewController = NSViewController()
        
        // 创建视图
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 400))
        
        // 添加一些组件来模拟RDP配置界面
        let titleLabel = NSTextField(labelWithString: "RDP质量配置")
        titleLabel.frame = NSRect(x: 20, y: 350, width: 200, height: 25)
        view.addSubview(titleLabel)
        
        let segmentedControl = NSSegmentedControl()
        segmentedControl.segmentCount = 3
        segmentedControl.setLabel("性能", forSegment: 0)
        segmentedControl.setLabel("平衡", forSegment: 1)
        segmentedControl.setLabel("质量", forSegment: 2)
        segmentedControl.selectedSegment = 1
        segmentedControl.frame = NSRect(x: 20, y: 300, width: 300, height: 30)
        view.addSubview(segmentedControl)
        
        let applyButton = NSButton(title: "应用", target: nil, action: nil)
        applyButton.frame = NSRect(x: 400, y: 20, width: 80, height: 30)
        view.addSubview(applyButton)
        
        // 设置视图控制器的视图
        viewController.view = view
        
        // 验证视图控制器
        XCTAssertNotNil(viewController.view, "视图控制器应该有视图")
        XCTAssertEqual(viewController.view?.subviews.count, 3, "视图应该有3个子视图")
        
        // 验证组件
        XCTAssertEqual(titleLabel.stringValue, "RDP质量配置", "标题标签应该正确")
        XCTAssertEqual(segmentedControl.selectedSegment, 1, "分段控件应该选中第二个选项")
        XCTAssertEqual(applyButton.title, "应用", "应用按钮标题应该正确")
        
        print("✅ 视图控制器创建测试通过")
    }
    
    func testComponentTreeBasics() throws {
        print("🧪 测试组件树基础功能...")
        
        // 创建测试视图
        let rootView = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        
        // 添加子视图
        let containerView = NSView(frame: NSRect(x: 20, y: 20, width: 560, height: 460))
        rootView.addSubview(containerView)
        
        let button = NSButton(title: "测试", target: nil, action: nil)
        button.frame = NSRect(x: 10, y: 10, width: 80, height: 30)
        containerView.addSubview(button)
        
        // 验证视图层级
        XCTAssertEqual(rootView.subviews.count, 1, "根视图应该有1个子视图")
        XCTAssertEqual(containerView.subviews.count, 1, "容器视图应该有1个子视图")
        XCTAssertTrue(rootView.subviews.contains(containerView), "根视图应该包含容器视图")
        XCTAssertTrue(containerView.subviews.contains(button), "容器视图应该包含按钮")
        
        // 验证视图属性
        XCTAssertEqual(rootView.frame.width, 600, "根视图宽度应该正确")
        XCTAssertEqual(rootView.frame.height, 500, "根视图高度应该正确")
        XCTAssertFalse(rootView.isHidden, "根视图应该可见")
        XCTAssertTrue(rootView.isEnabled, "根视图应该启用")
        
        print("✅ 组件树基础功能测试通过")
    }
    
    func testJSONSerialization() throws {
        print("🧪 测试JSON序列化...")
        
        // 创建测试数据结构
        struct TestData: Codable {
            let name: String
            let value: Int
            let isEnabled: Bool
            let frame: CGRect
        }
        
        let testData = TestData(
            name: "测试组件",
            value: 42,
            isEnabled: true,
            frame: CGRect(x: 10, y: 20, width: 100, height: 50)
        )
        
        // 序列化为JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let jsonData = try encoder.encode(testData)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        XCTAssertNotNil(jsonString, "JSON字符串不应该为nil")
        XCTAssertTrue(jsonString!.contains("测试组件"), "JSON应该包含测试数据")
        XCTAssertTrue(jsonString!.contains("42"), "JSON应该包含数值")
        XCTAssertTrue(jsonString!.contains("true"), "JSON应该包含布尔值")
        
        // 反序列化
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(TestData.self, from: jsonData)
        
        XCTAssertEqual(decodedData.name, testData.name, "反序列化的名称应该一致")
        XCTAssertEqual(decodedData.value, testData.value, "反序列化的数值应该一致")
        XCTAssertEqual(decodedData.isEnabled, testData.isEnabled, "反序列化的布尔值应该一致")
        XCTAssertEqual(decodedData.frame, testData.frame, "反序列化的frame应该一致")
        
        print("✅ JSON序列化测试通过")
    }
    
    func testTempFileOperations() throws {
        print("🧪 测试临时文件操作...")
        
        // 创建临时目录
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("GUIValidationTest", isDirectory: true)
        
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true, attributes: nil)
        
        // 创建测试文件
        let testContent = """
        {
            "testName": "GUI验证测试",
            "timestamp": "\(Date())",
            "components": [
                {
                    "type": "NSButton",
                    "title": "测试按钮"
                }
            ]
        }
        """
        
        let testFile = testDir.appendingPathComponent("test_report.json")
        try testContent.write(to: testFile, atomically: true, encoding: .utf8)
        
        // 验证文件存在
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path), "测试文件应该存在")
        
        // 读取文件内容
        let readContent = try String(contentsOf: testFile, encoding: .utf8)
        XCTAssertEqual(readContent, testContent, "读取的内容应该与写入的内容一致")
        
        // 清理测试文件
        try FileManager.default.removeItem(at: testDir)
        XCTAssertFalse(FileManager.default.fileExists(atPath: testDir.path), "测试目录应该被删除")
        
        print("✅ 临时文件操作测试通过")
    }
}
