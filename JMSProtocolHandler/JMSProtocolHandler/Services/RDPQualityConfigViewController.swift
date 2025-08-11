//
//  RDPQualityConfigViewController.swift
//  JMSProtocolHandler
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import Cocoa

/// RDP质量配置视图控制器
class RDPQualityConfigViewController: NSViewController, ConfigurationViewControllerProtocol {
    
    // MARK: - Properties
    
    private let configManager = RDPQualityConfigManager.shared
    private var currentProfile: DisplayQualityProfile = .balanced
    private var customSettings: RDPQualitySettings = .balanced
    
    // MARK: - UI Components
    
    private var profileSegmentedControl: NSSegmentedControl!
    private var profileDescriptionLabel: NSTextField!
    private var bandwidthLabel: NSTextField!
    private var performanceLabel: NSTextField!
    private var qualityLabel: NSTextField!
    
    private var compressionSlider: NSSlider!
    private var compressionValueLabel: NSTextField!
    private var colorDepthPopup: NSPopUpButton!
    private var fontSmoothingCheckbox: NSButton!
    private var wallpaperCheckbox: NSButton!
    private var animationsCheckbox: NSButton!
    private var themesCheckbox: NSButton!
    private var audioQualityPopup: NSPopUpButton!
    
    private var configPreviewTextView: NSTextView!
    private var applyButton: NSButton!
    private var resetButton: NSButton!
    private var exportButton: NSButton!
    private var importButton: NSButton!
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        setupUI()
        loadCurrentConfiguration()
        updateUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        setupProfileSection()
        setupCustomSection()
        setupPreviewSection()
        setupButtons()
        setupConstraints()
    }
    
    private func setupProfileSection() {
        // 预设配置标题
        let profileTitleLabel = NSTextField(labelWithString: "预设配置文件")
        profileTitleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        profileTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileTitleLabel)
        
        // 配置文件选择
        profileSegmentedControl = NSSegmentedControl()
        profileSegmentedControl.segmentCount = 3
        profileSegmentedControl.setLabel("性能优先", forSegment: 0)
        profileSegmentedControl.setLabel("平衡模式", forSegment: 1)
        profileSegmentedControl.setLabel("质量优先", forSegment: 2)
        profileSegmentedControl.selectedSegment = 1
        profileSegmentedControl.target = self
        profileSegmentedControl.action = #selector(profileChanged(_:))
        profileSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileSegmentedControl)
        
        // 配置描述
        profileDescriptionLabel = NSTextField(labelWithString: "")
        profileDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileDescriptionLabel)
        
        // 性能信息
        bandwidthLabel = NSTextField(labelWithString: "预估带宽: 1-3 Mbps")
        performanceLabel = NSTextField(labelWithString: "性能影响: 中等")
        qualityLabel = NSTextField(labelWithString: "质量级别: 标准")
        
        [bandwidthLabel, performanceLabel, qualityLabel].forEach { label in
            label?.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label!)
        }
        
        // 约束设置
        NSLayoutConstraint.activate([
            profileTitleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            profileTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            profileSegmentedControl.topAnchor.constraint(equalTo: profileTitleLabel.bottomAnchor, constant: 10),
            profileSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            profileSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            profileDescriptionLabel.topAnchor.constraint(equalTo: profileSegmentedControl.bottomAnchor, constant: 10),
            profileDescriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            profileDescriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            bandwidthLabel.topAnchor.constraint(equalTo: profileDescriptionLabel.bottomAnchor, constant: 10),
            bandwidthLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            performanceLabel.topAnchor.constraint(equalTo: bandwidthLabel.bottomAnchor, constant: 5),
            performanceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            qualityLabel.topAnchor.constraint(equalTo: performanceLabel.bottomAnchor, constant: 5),
            qualityLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }
    
    private func setupCustomSection() {
        // 自定义配置标题
        let customTitleLabel = NSTextField(labelWithString: "自定义配置")
        customTitleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        customTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customTitleLabel)
        
        // 压缩级别
        let compressionLabel = NSTextField(labelWithString: "压缩级别:")
        compressionSlider = NSSlider()
        compressionSlider.minValue = 0
        compressionSlider.maxValue = 2
        compressionSlider.numberOfTickMarks = 3
        compressionSlider.allowsTickMarkValuesOnly = true
        compressionSlider.target = self
        compressionSlider.action = #selector(compressionChanged(_:))
        
        compressionValueLabel = NSTextField(labelWithString: "中等压缩")
        
        // 颜色深度
        let colorDepthLabel = NSTextField(labelWithString: "颜色深度:")
        colorDepthPopup = NSPopUpButton()
        colorDepthPopup.addItems(withTitles: ["16位", "24位", "32位"])
        colorDepthPopup.target = self
        colorDepthPopup.action = #selector(popupChanged(_:))
        
        // 特效选项
        fontSmoothingCheckbox = NSButton(checkboxWithTitle: "启用字体平滑", target: self, action: #selector(checkboxChanged(_:)))
        wallpaperCheckbox = NSButton(checkboxWithTitle: "显示桌面壁纸", target: self, action: #selector(checkboxChanged(_:)))
        animationsCheckbox = NSButton(checkboxWithTitle: "启用菜单动画", target: self, action: #selector(checkboxChanged(_:)))
        themesCheckbox = NSButton(checkboxWithTitle: "启用视觉主题", target: self, action: #selector(checkboxChanged(_:)))
        
        // 音频质量
        let audioLabel = NSTextField(labelWithString: "音频质量:")
        audioQualityPopup = NSPopUpButton()
        audioQualityPopup.addItems(withTitles: ["禁用", "低质量", "中等", "高质量"])
        audioQualityPopup.target = self
        audioQualityPopup.action = #selector(popupChanged(_:))
        
        // 添加到视图并设置约束
        let customControls = [
            customTitleLabel, compressionLabel, compressionSlider, compressionValueLabel,
            colorDepthLabel, colorDepthPopup, fontSmoothingCheckbox, wallpaperCheckbox,
            animationsCheckbox, themesCheckbox, audioLabel, audioQualityPopup
        ]
        
        customControls.forEach { control in
            control?.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(control!)
        }
        
        // 设置约束
        NSLayoutConstraint.activate([
            customTitleLabel.topAnchor.constraint(equalTo: qualityLabel.bottomAnchor, constant: 30),
            customTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            compressionLabel.topAnchor.constraint(equalTo: customTitleLabel.bottomAnchor, constant: 15),
            compressionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            compressionLabel.widthAnchor.constraint(equalToConstant: 80),
            
            compressionSlider.centerYAnchor.constraint(equalTo: compressionLabel.centerYAnchor),
            compressionSlider.leadingAnchor.constraint(equalTo: compressionLabel.trailingAnchor, constant: 10),
            compressionSlider.widthAnchor.constraint(equalToConstant: 150),
            
            compressionValueLabel.centerYAnchor.constraint(equalTo: compressionLabel.centerYAnchor),
            compressionValueLabel.leadingAnchor.constraint(equalTo: compressionSlider.trailingAnchor, constant: 10),
            
            colorDepthLabel.topAnchor.constraint(equalTo: compressionLabel.bottomAnchor, constant: 15),
            colorDepthLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            colorDepthLabel.widthAnchor.constraint(equalToConstant: 80),
            
            colorDepthPopup.centerYAnchor.constraint(equalTo: colorDepthLabel.centerYAnchor),
            colorDepthPopup.leadingAnchor.constraint(equalTo: colorDepthLabel.trailingAnchor, constant: 10),
            
            fontSmoothingCheckbox.topAnchor.constraint(equalTo: colorDepthLabel.bottomAnchor, constant: 15),
            fontSmoothingCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            wallpaperCheckbox.topAnchor.constraint(equalTo: fontSmoothingCheckbox.bottomAnchor, constant: 8),
            wallpaperCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            animationsCheckbox.centerYAnchor.constraint(equalTo: fontSmoothingCheckbox.centerYAnchor),
            animationsCheckbox.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            
            themesCheckbox.centerYAnchor.constraint(equalTo: wallpaperCheckbox.centerYAnchor),
            themesCheckbox.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            
            audioLabel.topAnchor.constraint(equalTo: wallpaperCheckbox.bottomAnchor, constant: 15),
            audioLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            audioLabel.widthAnchor.constraint(equalToConstant: 80),
            
            audioQualityPopup.centerYAnchor.constraint(equalTo: audioLabel.centerYAnchor),
            audioQualityPopup.leadingAnchor.constraint(equalTo: audioLabel.trailingAnchor, constant: 10)
        ])
    }
    
    private func setupPreviewSection() {
        // 预览标题
        let previewTitleLabel = NSTextField(labelWithString: "配置预览")
        previewTitleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        previewTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewTitleLabel)
        
        // 预览文本视图
        let scrollView = NSScrollView()
        configPreviewTextView = NSTextView()
        configPreviewTextView.isEditable = false
        configPreviewTextView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        configPreviewTextView.backgroundColor = NSColor.controlBackgroundColor
        
        scrollView.documentView = configPreviewTextView
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            previewTitleLabel.topAnchor.constraint(equalTo: audioQualityPopup.bottomAnchor, constant: 20),
            previewTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            scrollView.topAnchor.constraint(equalTo: previewTitleLabel.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func setupButtons() {
        applyButton = NSButton(title: "应用配置", target: self, action: #selector(applyConfiguration(_:)))
        resetButton = NSButton(title: "重置默认", target: self, action: #selector(resetToDefault(_:)))
        exportButton = NSButton(title: "导出配置", target: self, action: #selector(exportConfiguration(_:)))
        importButton = NSButton(title: "导入配置", target: self, action: #selector(importConfiguration(_:)))
        
        applyButton.bezelStyle = .rounded
        resetButton.bezelStyle = .rounded
        exportButton.bezelStyle = .rounded
        importButton.bezelStyle = .rounded
        
        let buttons = [applyButton, resetButton, exportButton, importButton]
        buttons.forEach { button in
            button?.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(button!)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            applyButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            applyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            applyButton.widthAnchor.constraint(equalToConstant: 100),
            
            resetButton.centerYAnchor.constraint(equalTo: applyButton.centerYAnchor),
            resetButton.trailingAnchor.constraint(equalTo: applyButton.leadingAnchor, constant: -10),
            resetButton.widthAnchor.constraint(equalToConstant: 100),
            
            exportButton.centerYAnchor.constraint(equalTo: applyButton.centerYAnchor),
            exportButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            exportButton.widthAnchor.constraint(equalToConstant: 100),
            
            importButton.centerYAnchor.constraint(equalTo: applyButton.centerYAnchor),
            importButton.leadingAnchor.constraint(equalTo: exportButton.trailingAnchor, constant: 10),
            importButton.widthAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    // MARK: - Configuration Loading
    
    private func loadCurrentConfiguration() {
        currentProfile = configManager.getCurrentQualityProfile()
        customSettings = configManager.getQualityProfileSettings(currentProfile)
    }
    
    // MARK: - UI Update Methods
    
    private func updateUI() {
        updateProfileSelection()
        updateCustomSettings()
        updatePreview()
        updatePerformanceInfo()
    }
    
    private func updateProfileSelection() {
        switch currentProfile {
        case .performance:
            profileSegmentedControl.selectedSegment = 0
        case .balanced:
            profileSegmentedControl.selectedSegment = 1
        case .quality:
            profileSegmentedControl.selectedSegment = 2
        case .custom:
            profileSegmentedControl.selectedSegment = -1
        }
        
        profileDescriptionLabel.stringValue = currentProfile.description
    }
    
    private func updateCustomSettings() {
        compressionSlider.intValue = Int32(customSettings.compressionLevel)
        compressionValueLabel.stringValue = getCompressionDescription(customSettings.compressionLevel)
        
        colorDepthPopup.selectItem(at: getColorDepthIndex(customSettings.colorDepth))
        
        fontSmoothingCheckbox.state = customSettings.enableFontSmoothing ? .on : .off
        wallpaperCheckbox.state = customSettings.enableWallpaper ? .on : .off
        animationsCheckbox.state = customSettings.enableMenuAnimations ? .on : .off
        themesCheckbox.state = customSettings.enableThemes ? .on : .off
        
        audioQualityPopup.selectItem(at: getAudioQualityIndex(customSettings.audioQuality))
    }
    
    private func updatePreview() {
        let previewText = generateConfigPreview()
        configPreviewTextView.string = previewText
    }
    
    private func updatePerformanceInfo() {
        let analysis = configManager.analyzePerformanceImpact(for: customSettings)
        
        bandwidthLabel.stringValue = "预估带宽: \(analysis.recommendedBandwidth)"
        performanceLabel.stringValue = "性能影响: \(analysis.performanceLevel.displayName)"
        qualityLabel.stringValue = "质量级别: \(analysis.qualityLevel.displayName)"
    }
    
    // MARK: - Helper Methods
    
    private func getCompressionDescription(_ level: Int) -> String {
        switch level {
        case 0: return "无压缩"
        case 1: return "RDP 6.0"
        case 2: return "RDP 6.1"
        default: return "未知"
        }
    }
    
    private func getColorDepthIndex(_ depth: Int) -> Int {
        switch depth {
        case 16: return 0
        case 24: return 1
        case 32: return 2
        default: return 1
        }
    }
    
    private func getColorDepthFromIndex(_ index: Int) -> Int {
        switch index {
        case 0: return 16
        case 1: return 24
        case 2: return 32
        default: return 24
        }
    }
    
    private func getAudioQualityIndex(_ quality: AudioQuality) -> Int {
        switch quality {
        case .disabled: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
    
    private func getAudioQualityFromIndex(_ index: Int) -> AudioQuality {
        switch index {
        case 0: return .disabled
        case 1: return .low
        case 2: return .medium
        case 3: return .high
        default: return .medium
        }
    }
    
    private func generateConfigPreview() -> String {
        return """
        # RDP配置预览
        
        压缩级别: \(getCompressionDescription(customSettings.compressionLevel))
        颜色深度: \(customSettings.colorDepth)位
        字体平滑: \(customSettings.enableFontSmoothing ? "启用" : "禁用")
        桌面壁纸: \(customSettings.enableWallpaper ? "显示" : "隐藏")
        菜单动画: \(customSettings.enableMenuAnimations ? "启用" : "禁用")
        视觉主题: \(customSettings.enableThemes ? "启用" : "禁用")
        音频质量: \(customSettings.audioQuality.displayName)
        
        预估带宽需求: \(customSettings.estimatedBandwidth)
        性能影响: \(customSettings.performanceImpact.displayName)
        质量级别: \(customSettings.qualityLevel.displayName)
        """
    }
    
    // MARK: - Action Methods
    
    @objc private func profileChanged(_ sender: NSSegmentedControl) {
        let profiles: [DisplayQualityProfile] = [.performance, .balanced, .quality]
        currentProfile = profiles[sender.selectedSegment]
        customSettings = configManager.getQualityProfileSettings(currentProfile)
        
        updateCustomSettings()
        updatePreview()
        updatePerformanceInfo()
    }
    
    @objc private func compressionChanged(_ sender: NSSlider) {
        updateCustomSettingsFromUI()
    }
    
    @objc private func checkboxChanged(_ sender: NSButton) {
        updateCustomSettingsFromUI()
    }
    
    @objc private func popupChanged(_ sender: NSPopUpButton) {
        updateCustomSettingsFromUI()
    }
    
    @objc private func applyConfiguration(_ sender: NSButton) {
        do {
            try applyCurrentConfiguration()
            showAlert("成功", message: "配置已成功应用", style: .informational)
            view.window?.close()
        } catch {
            showAlert("应用配置失败", message: error.localizedDescription, style: .critical)
        }
    }
    
    @objc private func resetToDefault(_ sender: NSButton) {
        let alert = NSAlert()
        alert.messageText = "重置配置"
        alert.informativeText = "确定要重置到默认配置吗？"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            configManager.resetToDefaultConfiguration()
            loadCurrentConfiguration()
            updateUI()
            showAlert("成功", message: "配置已重置到默认设置", style: .informational)
        }
    }
    
    @objc private func exportConfiguration(_ sender: NSButton) {
        guard let configString = configManager.exportConfiguration() else {
            showAlert("导出失败", message: "无法导出当前配置", style: .critical)
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "RDP质量配置.json"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try configString.write(to: url, atomically: true, encoding: .utf8)
                showAlert("成功", message: "配置已成功导出", style: .informational)
            } catch {
                showAlert("导出失败", message: error.localizedDescription, style: .critical)
            }
        }
    }
    
    @objc private func importConfiguration(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            do {
                let configString = try String(contentsOf: url, encoding: .utf8)
                if configManager.importConfiguration(configString) {
                    loadCurrentConfiguration()
                    updateUI()
                    showAlert("成功", message: "配置已成功导入", style: .informational)
                } else {
                    showAlert("导入失败", message: "配置文件格式不正确", style: .critical)
                }
            } catch {
                showAlert("导入失败", message: error.localizedDescription, style: .critical)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func updateCustomSettingsFromUI() {
        let compressionLevel = Int(compressionSlider.intValue)
        let colorDepth = getColorDepthFromIndex(colorDepthPopup.indexOfSelectedItem)
        let audioQuality = getAudioQualityFromIndex(audioQualityPopup.indexOfSelectedItem)
        
        let tempSettings = RDPQualitySettings(
            compressionLevel: compressionLevel,
            colorDepth: colorDepth,
            enableFontSmoothing: fontSmoothingCheckbox.state == .on,
            enableWallpaper: wallpaperCheckbox.state == .on,
            enableMenuAnimations: animationsCheckbox.state == .on,
            enableThemes: themesCheckbox.state == .on,
            enableFullWindowDrag: false,
            bitmapCaching: true,
            audioQuality: audioQuality,
            networkOptimization: .broadband,
            estimatedBandwidth: "计算中...",
            performanceImpact: .medium,
            qualityLevel: .standard
        )
        
        let analysis = configManager.analyzePerformanceImpact(for: tempSettings)
        
        customSettings = RDPQualitySettings(
            compressionLevel: compressionLevel,
            colorDepth: colorDepth,
            enableFontSmoothing: fontSmoothingCheckbox.state == .on,
            enableWallpaper: wallpaperCheckbox.state == .on,
            enableMenuAnimations: animationsCheckbox.state == .on,
            enableThemes: themesCheckbox.state == .on,
            enableFullWindowDrag: false,
            bitmapCaching: true,
            audioQuality: audioQuality,
            networkOptimization: .broadband,
            estimatedBandwidth: analysis.recommendedBandwidth,
            performanceImpact: analysis.performanceLevel,
            qualityLevel: analysis.qualityLevel
        )
        
        compressionValueLabel.stringValue = getCompressionDescription(compressionLevel)
        currentProfile = .custom
        profileSegmentedControl.selectedSegment = -1
        
        updatePreview()
        updatePerformanceInfo()
    }
    
    private func applyCurrentConfiguration() throws {
        if currentProfile == .custom {
            let customConfig = RDPCustomConfiguration(
                name: "用户自定义配置",
                settings: customSettings,
                displayOptimization: true
            )
            
            let validation = configManager.validateConfiguration(customConfig)
            if !validation.isValid {
                throw NSError(domain: "ConfigurationError", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: validation.errorMessages.joined(separator: "\n")
                ])
            }
            
            configManager.saveCustomConfiguration(customConfig)
        }
        
        configManager.setQualityProfile(currentProfile)
    }
    
    private func showAlert(_ title: String, message: String, style: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    // MARK: - ConfigurationViewControllerProtocol Implementation
    
    func showQualityConfigurationPanel() {
        // 已经在loadView中实现
    }
    
    func displayQualityProfiles() {
        updateProfileSelection()
    }
    
    func showCustomConfigurationEditor() {
        // 自定义配置编辑器已集成在主界面中
    }
    
    func previewConfiguration(_ config: RDPQualitySettings) {
        customSettings = config
        updatePreview()
        updatePerformanceInfo()
    }
    
    func applyConfiguration(_ profile: DisplayQualityProfile) {
        currentProfile = profile
        configManager.setQualityProfile(profile)
        updateUI()
    }
    
    func resetConfiguration() {
        configManager.resetToDefaultConfiguration()
        loadCurrentConfiguration()
        updateUI()
    }
    
    func exportConfiguration() -> String? {
        return configManager.exportConfiguration()
    }
    
    func importConfiguration(_ configString: String) -> Bool {
        let success = configManager.importConfiguration(configString)
        if success {
            loadCurrentConfiguration()
            updateUI()
        }
        return success
    }
}
