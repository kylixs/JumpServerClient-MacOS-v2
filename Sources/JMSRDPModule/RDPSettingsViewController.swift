//
//  RDPSettingsViewController.swift
//  RDP设置视图控制器模块
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import Cocoa

// MARK: - RDP设置视图控制器协议
public protocol RDPSettingsViewControllerDelegate: AnyObject {
    func settingsDidChange(_ settings: RDPSettings)
    func settingsDidSave(_ settings: RDPSettings)
    func settingsDidReset()
}

// MARK: - RDP设置视图控制器
public class RDPSettingsViewController: NSViewController {
    
    // MARK: - 属性
    public weak var delegate: RDPSettingsViewControllerDelegate?
    private let settingsManager = RDPSettingsManager.shared
    
    // UI组件
    private var profileSegmentedControl: NSSegmentedControl!
    private var compressionSlider: NSSlider!
    private var compressionValueLabel: NSTextField!
    private var colorDepthPopup: NSPopUpButton!
    private var audioQualityPopup: NSPopUpButton!
    private var fontSmoothingCheckbox: NSButton!
    private var wallpaperCheckbox: NSButton!
    private var animationsCheckbox: NSButton!
    private var themesCheckbox: NSButton!
    private var statusLabel: NSTextField!
    
    // MARK: - 初始化
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - 生命周期
    public override func loadView() {
        print("📱 加载RDP设置界面...")
        view = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 400))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        setupUI()
        loadCurrentSettings()
        
        print("✅ RDP设置界面加载完成")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        updateStatusLabel("就绪")
    }
    
    // MARK: - UI设置
    private func setupUI() {
        setupTitleAndProfile()
        setupCompressionControls()
        setupQualityControls()
        setupEffectControls()
        setupActionButtons()
        setupStatusLabel()
    }
    
    private func setupTitleAndProfile() {
        // 标题
        let titleLabel = NSTextField(labelWithString: "RDP质量设置")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        titleLabel.frame = NSRect(x: 20, y: 360, width: 200, height: 25)
        view.addSubview(titleLabel)
        
        // 预设配置选择器
        let profileLabel = NSTextField(labelWithString: "预设配置:")
        profileLabel.frame = NSRect(x: 20, y: 320, width: 80, height: 20)
        view.addSubview(profileLabel)
        
        profileSegmentedControl = NSSegmentedControl()
        profileSegmentedControl.segmentCount = 3
        profileSegmentedControl.setLabel("性能", forSegment: 0)
        profileSegmentedControl.setLabel("平衡", forSegment: 1)
        profileSegmentedControl.setLabel("质量", forSegment: 2)
        profileSegmentedControl.selectedSegment = 1
        profileSegmentedControl.target = self
        profileSegmentedControl.action = #selector(profileChanged(_:))
        profileSegmentedControl.frame = NSRect(x: 110, y: 320, width: 200, height: 25)
        view.addSubview(profileSegmentedControl)
    }
    
    private func setupCompressionControls() {
        // 压缩级别
        let compressionLabel = NSTextField(labelWithString: "压缩级别:")
        compressionLabel.frame = NSRect(x: 20, y: 280, width: 80, height: 20)
        view.addSubview(compressionLabel)
        
        compressionSlider = NSSlider()
        compressionSlider.minValue = 0
        compressionSlider.maxValue = 2
        compressionSlider.doubleValue = 1
        compressionSlider.numberOfTickMarks = 3
        compressionSlider.allowsTickMarkValuesOnly = true
        compressionSlider.target = self
        compressionSlider.action = #selector(compressionChanged(_:))
        compressionSlider.frame = NSRect(x: 110, y: 280, width: 150, height: 25)
        view.addSubview(compressionSlider)
        
        compressionValueLabel = NSTextField(labelWithString: "中等")
        compressionValueLabel.frame = NSRect(x: 270, y: 280, width: 80, height: 20)
        view.addSubview(compressionValueLabel)
    }
    
    private func setupQualityControls() {
        // 颜色深度
        let colorDepthLabel = NSTextField(labelWithString: "颜色深度:")
        colorDepthLabel.frame = NSRect(x: 20, y: 240, width: 80, height: 20)
        view.addSubview(colorDepthLabel)
        
        colorDepthPopup = NSPopUpButton()
        colorDepthPopup.addItems(withTitles: ["16位", "24位", "32位"])
        colorDepthPopup.selectItem(at: 1)
        colorDepthPopup.target = self
        colorDepthPopup.action = #selector(qualityControlChanged(_:))
        colorDepthPopup.frame = NSRect(x: 110, y: 240, width: 100, height: 25)
        view.addSubview(colorDepthPopup)
        
        // 音频质量
        let audioLabel = NSTextField(labelWithString: "音频质量:")
        audioLabel.frame = NSRect(x: 220, y: 240, width: 80, height: 20)
        view.addSubview(audioLabel)
        
        audioQualityPopup = NSPopUpButton()
        audioQualityPopup.addItems(withTitles: ["禁用", "低质量", "中等", "高质量"])
        audioQualityPopup.selectItem(at: 2)
        audioQualityPopup.target = self
        audioQualityPopup.action = #selector(qualityControlChanged(_:))
        audioQualityPopup.frame = NSRect(x: 310, y: 240, width: 100, height: 25)
        view.addSubview(audioQualityPopup)
    }
    
    private func setupEffectControls() {
        // 特效选项
        fontSmoothingCheckbox = NSButton(checkboxWithTitle: "字体平滑", target: self, action: #selector(effectControlChanged(_:)))
        fontSmoothingCheckbox.frame = NSRect(x: 20, y: 200, width: 100, height: 20)
        fontSmoothingCheckbox.state = .on
        view.addSubview(fontSmoothingCheckbox)
        
        wallpaperCheckbox = NSButton(checkboxWithTitle: "桌面壁纸", target: self, action: #selector(effectControlChanged(_:)))
        wallpaperCheckbox.frame = NSRect(x: 130, y: 200, width: 100, height: 20)
        wallpaperCheckbox.state = .on
        view.addSubview(wallpaperCheckbox)
        
        animationsCheckbox = NSButton(checkboxWithTitle: "菜单动画", target: self, action: #selector(effectControlChanged(_:)))
        animationsCheckbox.frame = NSRect(x: 20, y: 170, width: 100, height: 20)
        animationsCheckbox.state = .off
        view.addSubview(animationsCheckbox)
        
        themesCheckbox = NSButton(checkboxWithTitle: "视觉主题", target: self, action: #selector(effectControlChanged(_:)))
        themesCheckbox.frame = NSRect(x: 130, y: 170, width: 100, height: 20)
        themesCheckbox.state = .on
        view.addSubview(themesCheckbox)
    }
    
    private func setupActionButtons() {
        // 操作按钮
        let saveButton = NSButton(title: "保存设置", target: self, action: #selector(saveSettings(_:)))
        saveButton.bezelStyle = .rounded
        saveButton.frame = NSRect(x: 20, y: 20, width: 100, height: 30)
        view.addSubview(saveButton)
        
        let resetButton = NSButton(title: "重置默认", target: self, action: #selector(resetSettings(_:)))
        resetButton.bezelStyle = .rounded
        resetButton.frame = NSRect(x: 130, y: 20, width: 100, height: 30)
        view.addSubview(resetButton)
        
        let exportButton = NSButton(title: "导出设置", target: self, action: #selector(exportSettings(_:)))
        exportButton.bezelStyle = .rounded
        exportButton.frame = NSRect(x: 240, y: 20, width: 100, height: 30)
        view.addSubview(exportButton)
        
        let importButton = NSButton(title: "导入设置", target: self, action: #selector(importSettings(_:)))
        importButton.bezelStyle = .rounded
        importButton.frame = NSRect(x: 350, y: 20, width: 100, height: 30)
        view.addSubview(importButton)
    }
    
    private func setupStatusLabel() {
        statusLabel = NSTextField(labelWithString: "状态: 就绪")
        statusLabel.frame = NSRect(x: 20, y: 80, width: 440, height: 20)
        statusLabel.textColor = NSColor.secondaryLabelColor
        view.addSubview(statusLabel)
    }
    
    // MARK: - 数据管理
    private func loadCurrentSettings() {
        let settings = settingsManager.currentSettings
        updateUIWithSettings(settings)
        
        // 更新设置管理器中的当前设置
        settingsManager.updateSettings(settings)
        
        // 通知代理设置已更改
        delegate?.settingsDidChange(settings)
    }
    
    private func getCurrentSettingsFromUI() -> RDPSettings {
        let profiles = ["性能优先", "平衡模式", "质量优先"]
        let profileName = profiles[profileSegmentedControl.selectedSegment]
        
        let colorDepths = [16, 24, 32]
        let colorDepth = colorDepths[colorDepthPopup.indexOfSelectedItem]
        
        let audioQualities = ["禁用", "低质量", "中等", "高质量"]
        let audioQuality = audioQualities[audioQualityPopup.indexOfSelectedItem]
        
        return RDPSettings(
            profileName: profileName,
            compressionLevel: Int(compressionSlider.doubleValue),
            colorDepth: colorDepth,
            audioQuality: audioQuality,
            enableFontSmoothing: fontSmoothingCheckbox.state == .on,
            enableWallpaper: wallpaperCheckbox.state == .on,
            enableMenuAnimations: animationsCheckbox.state == .on,
            enableThemes: themesCheckbox.state == .on
        )
    }
    
    private func updateUIWithSettings(_ settings: RDPSettings) {
        // 更新预设配置选择器
        let profiles = ["性能优先", "平衡模式", "质量优先"]
        if let index = profiles.firstIndex(of: settings.profileName) {
            profileSegmentedControl.selectedSegment = index
        }
        
        // 更新压缩级别
        compressionSlider.doubleValue = Double(settings.compressionLevel)
        updateCompressionLabel()
        
        // 更新颜色深度
        let colorDepths = [16, 24, 32]
        if let index = colorDepths.firstIndex(of: settings.colorDepth) {
            colorDepthPopup.selectItem(at: index)
        }
        
        // 更新音频质量
        let audioQualities = ["禁用", "低质量", "中等", "高质量"]
        if let index = audioQualities.firstIndex(of: settings.audioQuality) {
            audioQualityPopup.selectItem(at: index)
        }
        
        // 更新特效选项
        fontSmoothingCheckbox.state = settings.enableFontSmoothing ? .on : .off
        wallpaperCheckbox.state = settings.enableWallpaper ? .on : .off
        animationsCheckbox.state = settings.enableMenuAnimations ? .on : .off
        themesCheckbox.state = settings.enableThemes ? .on : .off
    }
    
    private func updateCompressionLabel() {
        let level = Int(compressionSlider.doubleValue)
        let labels = ["无压缩", "中等", "高压缩"]
        compressionValueLabel.stringValue = labels[level]
    }
    
    private func updateStatusLabel(_ message: String) {
        statusLabel.stringValue = "状态: \(message)"
    }
    
    // MARK: - 事件处理
    @objc private func profileChanged(_ sender: NSSegmentedControl) {
        let presets = RDPSettings.allPresets
        let selectedPreset = presets[sender.selectedSegment]
        
        updateUIWithSettings(selectedPreset)
        
        // 更新设置管理器中的当前设置
        settingsManager.updateSettings(selectedPreset)
        
        // 通知代理设置已更改
        delegate?.settingsDidChange(selectedPreset)
        
        updateStatusLabel("已切换到预设配置: \(selectedPreset.profileName)")
        print("📊 切换到预设配置: \(selectedPreset.profileName)")
    }
    
    @objc private func compressionChanged(_ sender: NSSlider) {
        updateCompressionLabel()
        
        // 更新设置管理器中的当前设置
        let currentSettings = getCurrentSettingsFromUI()
        settingsManager.updateSettings(currentSettings)
        
        // 通知代理设置已更改
        delegate?.settingsDidChange(currentSettings)
        
        updateStatusLabel("压缩级别已更改")
    }
    
    @objc private func qualityControlChanged(_ sender: NSControl) {
        // 更新设置管理器中的当前设置
        let currentSettings = getCurrentSettingsFromUI()
        settingsManager.updateSettings(currentSettings)
        
        // 通知代理设置已更改
        delegate?.settingsDidChange(currentSettings)
        
        updateStatusLabel("质量设置已更改")
    }
    
    @objc private func effectControlChanged(_ sender: NSButton) {
        // 更新设置管理器中的当前设置
        let currentSettings = getCurrentSettingsFromUI()
        settingsManager.updateSettings(currentSettings)
        
        // 通知代理设置已更改
        delegate?.settingsDidChange(currentSettings)
        
        updateStatusLabel("特效设置已更改")
    }
    
    @objc private func saveSettings(_ sender: NSButton) {
        let currentSettings = getCurrentSettingsFromUI()
        
        do {
            try settingsManager.saveSettings(currentSettings)
            delegate?.settingsDidSave(currentSettings)
            updateStatusLabel("设置保存成功")
            showAlert("保存成功", message: "RDP设置已保存到本地文件")
        } catch {
            updateStatusLabel("设置保存失败")
            showAlert("保存失败", message: error.localizedDescription)
        }
    }
    
    @objc private func resetSettings(_ sender: NSButton) {
        let alert = NSAlert()
        alert.messageText = "重置设置"
        alert.informativeText = "确定要重置为默认配置吗？"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            do {
                try settingsManager.resetToDefault()
                loadCurrentSettings()
                delegate?.settingsDidReset()
                updateStatusLabel("已重置为默认设置")
                showAlert("重置成功", message: "已重置为默认RDP配置")
            } catch {
                updateStatusLabel("重置失败")
                showAlert("重置失败", message: error.localizedDescription)
            }
        }
    }
    
    @objc private func exportSettings(_ sender: NSButton) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "RDP设置_\(settingsManager.getCurrentDateString()).json"
        savePanel.title = "导出RDP设置"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try settingsManager.exportSettings(to: url)
                updateStatusLabel("设置导出成功")
                showAlert("导出成功", message: "RDP设置已导出到:\n\(url.path)")
            } catch {
                updateStatusLabel("设置导出失败")
                showAlert("导出失败", message: error.localizedDescription)
            }
        }
    }
    
    @objc private func importSettings(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.title = "导入RDP设置"
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            do {
                try settingsManager.importSettings(from: url)
                loadCurrentSettings()
                updateStatusLabel("设置导入成功")
                showAlert("导入成功", message: "RDP设置已导入:\n配置: \(settingsManager.currentSettings.profileName)")
            } catch {
                updateStatusLabel("设置导入失败")
                showAlert("导入失败", message: "无法导入设置文件:\n\(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 辅助方法
    private func showAlert(_ title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        
        if let window = view.window {
            alert.beginSheetModal(for: window) { _ in }
        } else {
            alert.runModal()
        }
    }
    
    // MARK: - 公共接口
    
    /// 刷新界面显示
    public func refreshUI() {
        loadCurrentSettings()
    }
    
    /// 应用指定设置
    public func applySettings(_ settings: RDPSettings) {
        settingsManager.updateSettings(settings)
        updateUIWithSettings(settings)
        
        // 通知代理设置已更改
        delegate?.settingsDidChange(settings)
    }
}
