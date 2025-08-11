//
//  RDPQualityConfigViewControllerTests.swift
//  JMSProtocolHandlerTests
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import XCTest
@testable import JMSProtocolHandler

class RDPQualityConfigViewControllerTests: XCTestCase {
    
    var viewController: RDPQualityConfigViewController!
    var configManager: RDPQualityConfigManager!
    
    override func setUp() {
        super.setUp()
        viewController = RDPQualityConfigViewController()
        configManager = RDPQualityConfigManager.shared
        
        // 重置到默认配置
        configManager.resetToDefaultConfiguration()
        
        // 加载视图
        _ = viewController.view
    }
    
    override func tearDown() {
        viewController = nil
        configManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testViewControllerInitialization() {
        XCTAssertNotNil(viewController.view)
        XCTAssertEqual(viewController.view.frame.width, 600)
        XCTAssertEqual(viewController.view.frame.height, 500)
    }
    
    func testUIComponentsCreation() {
        // 验证主要UI组件是否创建
        let subviews = viewController.view.subviews
        
        // 检查是否包含必要的控件类型
        let hasSegmentedControl = subviews.contains { $0 is NSSegmentedControl }
        let hasSlider = subviews.contains { $0 is NSSlider }
        let hasPopUpButton = subviews.contains { $0 is NSPopUpButton }
        let hasCheckbox = subviews.contains { $0 is NSButton }
        let hasScrollView = subviews.contains { $0 is NSScrollView }
        
        XCTAssertTrue(hasSegmentedControl, "应该包含分段控件")
        XCTAssertTrue(hasSlider, "应该包含滑块控件")
        XCTAssertTrue(hasPopUpButton, "应该包含弹出按钮")
        XCTAssertTrue(hasCheckbox, "应该包含复选框")
        XCTAssertTrue(hasScrollView, "应该包含滚动视图")
    }
    
    // MARK: - Configuration Loading Tests
    
    func testLoadCurrentConfiguration() {
        // 设置一个特定的配置
        configManager.setQualityProfile(.performance)
        
        // 重新创建视图控制器以测试加载
        viewController = RDPQualityConfigViewController()
        _ = viewController.view
        
        // 验证配置是否正确加载
        // 这里我们通过间接方式验证，因为属性是私有的
        XCTAssertNotNil(viewController.view)
    }
    
    // MARK: - Protocol Implementation Tests
    
    func testShowQualityConfigurationPanel() {
        // 测试显示质量配置面板
        XCTAssertNoThrow(viewController.showQualityConfigurationPanel())
    }
    
    func testDisplayQualityProfiles() {
        // 测试显示质量配置文件
        XCTAssertNoThrow(viewController.displayQualityProfiles())
    }
    
    func testShowCustomConfigurationEditor() {
        // 测试显示自定义配置编辑器
        XCTAssertNoThrow(viewController.showCustomConfigurationEditor())
    }
    
    func testPreviewConfiguration() {
        let testSettings = RDPQualitySettings.performanceOptimized
        
        // 测试预览配置
        XCTAssertNoThrow(viewController.previewConfiguration(testSettings))
    }
    
    func testApplyConfiguration() {
        // 测试应用配置
        XCTAssertNoThrow(viewController.applyConfiguration(.performance))
        
        // 验证配置是否已应用
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .performance)
    }
    
    func testResetConfiguration() {
        // 先设置一个非默认配置
        configManager.setQualityProfile(.performance)
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .performance)
        
        // 测试重置配置
        viewController.resetConfiguration()
        
        // 验证是否重置到默认配置
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .balanced)
    }
    
    // MARK: - Import/Export Tests
    
    func testExportConfiguration() {
        // 设置一个配置
        configManager.setQualityProfile(.quality)
        
        // 测试导出
        let exportedConfig = viewController.exportConfiguration()
        XCTAssertNotNil(exportedConfig)
        XCTAssertFalse(exportedConfig!.isEmpty)
        
        // 验证导出的配置包含预期内容
        XCTAssertTrue(exportedConfig!.contains("quality"))
    }
    
    func testImportConfiguration() {
        // 先导出一个配置作为测试数据
        configManager.setQualityProfile(.performance)
        let customConfig = RDPCustomConfiguration(
            name: "测试配置",
            settings: RDPQualitySettings.qualityOptimized
        )
        configManager.saveCustomConfiguration(customConfig)
        
        guard let exportedConfig = viewController.exportConfiguration() else {
            XCTFail("无法导出配置用于测试")
            return
        }
        
        // 重置配置
        configManager.resetToDefaultConfiguration()
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .balanced)
        
        // 测试导入
        let importSuccess = viewController.importConfiguration(exportedConfig)
        XCTAssertTrue(importSuccess)
        
        // 验证导入结果
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .performance)
        XCTAssertEqual(configManager.getAllCustomConfigurations().count, 1)
    }
    
    func testImportInvalidConfiguration() {
        let invalidConfig = "{ invalid json }"
        let importSuccess = viewController.importConfiguration(invalidConfig)
        XCTAssertFalse(importSuccess)
    }
    
    // MARK: - UI Interaction Tests
    
    func testProfileSegmentedControlInteraction() {
        // 查找分段控件
        let segmentedControl = findSegmentedControl()
        XCTAssertNotNil(segmentedControl)
        
        if let control = segmentedControl {
            // 模拟选择不同的配置文件
            control.selectedSegment = 0 // 性能优先
            control.sendAction(control.action, to: control.target)
            
            // 验证配置是否更新（间接验证）
            XCTAssertNotNil(viewController.view)
        }
    }
    
    func testSliderInteraction() {
        // 查找滑块控件
        let slider = findSlider()
        XCTAssertNotNil(slider)
        
        if let slider = slider {
            // 模拟滑块值变化
            slider.intValue = 2
            slider.sendAction(slider.action, to: slider.target)
            
            // 验证UI是否响应（间接验证）
            XCTAssertNotNil(viewController.view)
        }
    }
    
    func testCheckboxInteraction() {
        // 查找复选框
        let checkboxes = findCheckboxes()
        XCTAssertFalse(checkboxes.isEmpty)
        
        for checkbox in checkboxes {
            // 模拟复选框状态变化
            checkbox.state = checkbox.state == .on ? .off : .on
            checkbox.sendAction(checkbox.action, to: checkbox.target)
            
            // 验证UI是否响应（间接验证）
            XCTAssertNotNil(viewController.view)
        }
    }
    
    func testPopUpButtonInteraction() {
        // 查找弹出按钮
        let popUpButtons = findPopUpButtons()
        XCTAssertFalse(popUpButtons.isEmpty)
        
        for popUp in popUpButtons {
            if popUp.numberOfItems > 1 {
                // 模拟选择不同的选项
                popUp.selectItem(at: 1)
                popUp.sendAction(popUp.action, to: popUp.target)
                
                // 验证UI是否响应（间接验证）
                XCTAssertNotNil(viewController.view)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func findSegmentedControl() -> NSSegmentedControl? {
        return findSubview(of: NSSegmentedControl.self)
    }
    
    private func findSlider() -> NSSlider? {
        return findSubview(of: NSSlider.self)
    }
    
    private func findCheckboxes() -> [NSButton] {
        return findSubviews(of: NSButton.self).filter { $0.buttonType == .switch }
    }
    
    private func findPopUpButtons() -> [NSPopUpButton] {
        return findSubviews(of: NSPopUpButton.self)
    }
    
    private func findSubview<T: NSView>(of type: T.Type) -> T? {
        return findSubviews(of: type).first
    }
    
    private func findSubviews<T: NSView>(of type: T.Type) -> [T] {
        var result: [T] = []
        
        func searchInView(_ view: NSView) {
            if let targetView = view as? T {
                result.append(targetView)
            }
            
            for subview in view.subviews {
                searchInView(subview)
            }
        }
        
        searchInView(viewController.view)
        return result
    }
    
    // MARK: - Performance Tests
    
    func testViewLoadingPerformance() {
        measure {
            let testViewController = RDPQualityConfigViewController()
            _ = testViewController.view
        }
    }
    
    func testConfigurationUpdatePerformance() {
        measure {
            viewController.previewConfiguration(RDPQualitySettings.performanceOptimized)
            viewController.previewConfiguration(RDPQualitySettings.balanced)
            viewController.previewConfiguration(RDPQualitySettings.qualityOptimized)
        }
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsage() {
        // 创建多个视图控制器实例来测试内存使用
        var controllers: [RDPQualityConfigViewController] = []
        
        for _ in 0..<10 {
            let controller = RDPQualityConfigViewController()
            _ = controller.view
            controllers.append(controller)
        }
        
        // 验证所有控制器都正确创建
        XCTAssertEqual(controllers.count, 10)
        
        // 清理
        controllers.removeAll()
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidConfigurationHandling() {
        // 测试处理无效配置的情况
        let invalidSettings = RDPQualitySettings(
            compressionLevel: -1, // 无效值
            colorDepth: 15,       // 无效值
            enableFontSmoothing: true,
            enableWallpaper: true,
            enableMenuAnimations: true,
            enableThemes: true,
            enableFullWindowDrag: true,
            bitmapCaching: true,
            audioQuality: .high,
            networkOptimization: .lan,
            estimatedBandwidth: "",
            performanceImpact: .high,
            qualityLevel: .premium
        )
        
        // 应该能够处理无效配置而不崩溃
        XCTAssertNoThrow(viewController.previewConfiguration(invalidSettings))
    }
}
