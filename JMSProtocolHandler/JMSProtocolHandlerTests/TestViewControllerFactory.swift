//
//  TestViewControllerFactory.swift
//  JMSProtocolHandlerTests
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import Cocoa

/// 测试视图控制器工厂 - 专门用于创建测试用的视图控制器
class TestViewControllerFactory {
    
    // MARK: - RDP Quality Config View Controllers
    
    /// 创建标准的RDP质量配置视图控制器
    static func createStandardRDPQualityConfigViewController() -> NSViewController {
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
        
        // 颜色深度下拉框
        let colorDepthLabel = NSTextField(labelWithString: "颜色深度:")
        colorDepthLabel.frame = NSRect(x: 20, y: 300, width: 80, height: 20)
        view.addSubview(colorDepthLabel)
        
        let colorDepthPopup = NSPopUpButton()
        colorDepthPopup.addItems(withTitles: ["16位", "24位", "32位"])
        colorDepthPopup.selectItem(at: 1)
        colorDepthPopup.frame = NSRect(x: 110, y: 300, width: 100, height: 25)
        view.addSubview(colorDepthPopup)
        
        // 音频质量下拉框
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
        
        viewController.view = view
        return viewController
    }
    
    /// 创建有问题的RDP质量配置视图控制器（用于测试问题检测）
    static func createProblematicRDPQualityConfigViewController() -> NSViewController {
        let viewController = NSViewController()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300)) // 尺寸过小
        
        // 缺少标题标签
        
        // 添加一个禁用的分段控件
        let segmentedControl = NSSegmentedControl()
        segmentedControl.segmentCount = 3
        segmentedControl.setLabel("性能", forSegment: 0)
        segmentedControl.setLabel("平衡", forSegment: 1)
        segmentedControl.setLabel("质量", forSegment: 2)
        segmentedControl.selectedSegment = 1
        segmentedControl.isEnabled = false // 问题：禁用状态
        segmentedControl.frame = NSRect(x: 20, y: 250, width: 300, height: 30)
        view.addSubview(segmentedControl)
        
        // 添加一个隐藏的滑块
        let slider = NSSlider()
        slider.minValue = 0
        slider.maxValue = 2
        slider.doubleValue = 1
        slider.isHidden = true // 问题：隐藏状态
        slider.frame = NSRect(x: 20, y: 200, width: 150, height: 25)
        view.addSubview(slider)
        
        // 缺少下拉框组件
        
        // 添加重叠的按钮
        let button1 = NSButton(title: "按钮1", target: nil, action: nil)
        button1.frame = NSRect(x: 50, y: 50, width: 100, height: 30)
        view.addSubview(button1)
        
        let button2 = NSButton(title: "按钮2", target: nil, action: nil)
        button2.frame = NSRect(x: 75, y: 65, width: 100, height: 30) // 问题：与button1重叠
        view.addSubview(button2)
        
        viewController.view = view
        return viewController
    }
    
    // MARK: - Other Test View Controllers
    
    /// 创建简单的测试视图控制器
    static func createSimpleTestViewController() -> NSViewController {
        let viewController = NSViewController()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        
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
        
        viewController.view = view
        return viewController
    }
    
    /// 创建有重叠组件的视图控制器
    static func createOverlappingComponentsViewController() -> NSViewController {
        let viewController = NSViewController()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        
        // 创建两个重叠的按钮
        let button1 = NSButton(title: "按钮1", target: nil, action: nil)
        button1.frame = NSRect(x: 50, y: 50, width: 100, height: 30)
        view.addSubview(button1)
        
        let button2 = NSButton(title: "按钮2", target: nil, action: nil)
        button2.frame = NSRect(x: 75, y: 65, width: 100, height: 30) // 与button1重叠
        view.addSubview(button2)
        
        // 创建两个重叠的文本字段
        let textField1 = NSTextField()
        textField1.stringValue = "文本1"
        textField1.frame = NSRect(x: 200, y: 100, width: 150, height: 25)
        view.addSubview(textField1)
        
        let textField2 = NSTextField()
        textField2.stringValue = "文本2"
        textField2.frame = NSRect(x: 220, y: 110, width: 150, height: 25) // 与textField1重叠
        view.addSubview(textField2)
        
        viewController.view = view
        return viewController
    }
    
    /// 创建有问题的视图控制器（用于测试各种问题检测）
    static func createProblematicViewController() -> NSViewController {
        let viewController = NSViewController()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300)) // 尺寸过小
        
        // 添加一个禁用的按钮
        let disabledButton = NSButton(title: "禁用按钮", target: nil, action: nil)
        disabledButton.isEnabled = false
        disabledButton.frame = NSRect(x: 20, y: 20, width: 100, height: 30)
        view.addSubview(disabledButton)
        
        // 添加一个隐藏的文本字段
        let hiddenTextField = NSTextField()
        hiddenTextField.isHidden = true
        hiddenTextField.frame = NSRect(x: 20, y: 60, width: 200, height: 25)
        view.addSubview(hiddenTextField)
        
        // 添加一个空标签
        let emptyLabel = NSTextField(labelWithString: "")
        emptyLabel.frame = NSRect(x: 20, y: 100, width: 100, height: 20)
        view.addSubview(emptyLabel)
        
        viewController.view = view
        return viewController
    }
    
    /// 创建复杂的测试视图（用于性能测试）
    static func createComplexTestViewController() -> NSViewController {
        let viewController = NSViewController()
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
            
            let slider = NSSlider()
            slider.minValue = 0
            slider.maxValue = 100
            slider.doubleValue = Double(i * 10)
            slider.frame = NSRect(x: 10, y: 90, width: 150, height: 25)
            containerView.addSubview(slider)
            
            view.addSubview(containerView)
        }
        
        viewController.view = view
        return viewController
    }
}
