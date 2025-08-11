//
//  ConfigurationWindowController.swift
//  JMSProtocolHandler
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import Cocoa

/// RDP质量配置窗口控制器
class ConfigurationWindowController: NSWindowController {
    
    // MARK: - Properties
    
    private let configManager = RDPQualityConfigManager.shared
    private var currentProfile: DisplayQualityProfile = .balanced
    private var customSettings: RDPQualitySettings = .balanced
    
    // MARK: - UI Components
    
    @IBOutlet weak var tabView: NSTabView!
    
    // 预设配置选项卡
    @IBOutlet weak var profileSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var profileDescriptionLabel: NSTextField!
    @IBOutlet weak var bandwidthLabel: NSTextField!
    @IBOutlet weak var performanceLabel: NSTextField!
    @IBOutlet weak var qualityLabel: NSTextField!
    
    // 自定义配置选项卡
    @IBOutlet weak var compressionSlider: NSSlider!
    @IBOutlet weak var compressionValueLabel: NSTextField!
    @IBOutlet weak var colorDepthPopup: NSPopUpButton!
    @IBOutlet weak var fontSmoothingCheckbox: NSButton!
    @IBOutlet weak var wallpaperCheckbox: NSButton!
    @IBOutlet weak var animationsCheckbox: NSButton!
    @IBOutlet weak var themesCheckbox: NSButton!
    @IBOutlet weak var windowDragCheckbox: NSButton!
    @IBOutlet weak var bitmapCachingCheckbox: NSButton!
    @IBOutlet weak var audioQualityPopup: NSPopUpButton!
    @IBOutlet weak var networkOptimizationPopup: NSPopUpButton!
    
    // 预览和信息显示
    @IBOutlet weak var configPreviewTextView: NSTextView!
    @IBOutlet weak var customBandwidthLabel: NSTextField!
    @IBOutlet weak var customPerformanceLabel: NSTextField!
    @IBOutlet weak var customQualityLabel: NSTextField!
    
    // 操作按钮
    @IBOutlet weak var applyButton: NSButton!
    @IBOutlet weak var resetButton: NSButton!
    @IBOutlet weak var exportButton: NSButton!
    @IBOutlet weak var importButton: NSButton!
    
    // MARK: - Initialization
    
    convenience init() {
        self.init(windowNibName: "ConfigurationWindow")
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        setupWindow()
        setupUI()
        loadCurrentConfiguration()
        updateUI()
    }
    
    // MARK: - Setup Methods
    
    private func setupWindow() {
        window?.title = "RDP质量配置"
        window?.center()
        window?.isRestorable = false
        window?.styleMask.remove(.resizable)
    }
    
    private func setupUI() {
        setupProfileSegmentedControl()
        setupCompressionSlider()
        setupPopupButtons()
        setupCheckboxes()
        setupTextViews()
        setupButtons()
    }
    
    private func setupProfileSegmentedControl() {
        profileSegmentedControl.segmentCount = 3
        profileSegmentedControl.setLabel("性能优先", forSegment: 0)
        profileSegmentedControl.setLabel("平衡模式", forSegment: 1)
        profileSegmentedControl.setLabel("质量优先", forSegment: 2)
        profileSegmentedControl.selectedSegment = 1 // 默认选择平衡模式
    }
    
    private func setupCompressionSlider() {
        compressionSlider.minValue = 0
        compressionSlider.maxValue = 2
        compressionSlider.numberOfTickMarks = 3
        compressionSlider.allowsTickMarkValuesOnly = true
        compressionSlider.tickMarkPosition = .below
    }
    
    private func setupPopupButtons() {
        // 颜色深度选项
        colorDepthPopup.removeAllItems()
        colorDepthPopup.addItems(withTitles: ["16位", "24位", "32位"])
        
        // 音频质量选项
        audioQualityPopup.removeAllItems()
        audioQualityPopup.addItems(withTitles: [
            AudioQuality.disabled.displayName,
            AudioQuality.low.displayName,
            AudioQuality.medium.displayName,
            AudioQuality.high.displayName
        ])
        
        // 网络优化选项
        networkOptimizationPopup.removeAllItems()
        networkOptimizationPopup.addItems(withTitles: [
            NetworkOptimization.modem.displayName,
            NetworkOptimization.lowBroadband.displayName,
            NetworkOptimization.broadband.displayName,
            NetworkOptimization.lan.displayName,
            NetworkOptimization.auto.displayName
        ])
    }
    
    private func setupCheckboxes() {
        fontSmoothingCheckbox.title = "启用字体平滑"
        wallpaperCheckbox.title = "显示桌面壁纸"
        animationsCheckbox.title = "启用菜单动画"
        themesCheckbox.title = "启用视觉主题"
        windowDragCheckbox.title = "启用完整窗口拖拽"
        bitmapCachingCheckbox.title = "启用位图缓存"
    }
    
    private func setupTextViews() {
        configPreviewTextView.isEditable = false
        configPreviewTextView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        configPreviewTextView.backgroundColor = NSColor.controlBackgroundColor
    }
    
    private func setupButtons() {
        applyButton.title = "应用配置"
        resetButton.title = "重置默认"
        exportButton.title = "导出配置"
        importButton.title = "导入配置"
    }
    
    // MARK: - Configuration Loading
    
    private func loadCurrentConfiguration() {
        currentProfile = configManager.getCurrentQualityProfile()
        
        switch currentProfile {
        case .performance:
            customSettings = RDPQualitySettings.performanceOptimized
        case .balanced:
            customSettings = RDPQualitySettings.balanced
        case .quality:
            customSettings = RDPQualitySettings.qualityOptimized
        case .custom:
            if let customConfig = configManager.getCustomConfiguration() {
                customSettings = customConfig.settings
            } else {
                customSettings = RDPQualitySettings.balanced
            }
        }
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
            profileSegmentedControl.selectedSegment = -1 // 无选择
        }
        
        updateProfileDescription()
    }
    
    private func updateProfileDescription() {
        let profile = getSelectedProfile()
        profileDescriptionLabel.stringValue = profile.description
    }
    
    private func updateCustomSettings() {
        compressionSlider.intValue = Int32(customSettings.compressionLevel)
        compressionValueLabel.stringValue = getCompressionDescription(customSettings.compressionLevel)
        
        colorDepthPopup.selectItem(at: getColorDepthIndex(customSettings.colorDepth))
        
        fontSmoothingCheckbox.state = customSettings.enableFontSmoothing ? .on : .off
        wallpaperCheckbox.state = customSettings.enableWallpaper ? .on : .off
        animationsCheckbox.state = customSettings.enableMenuAnimations ? .on : .off
        themesCheckbox.state = customSettings.enableThemes ? .on : .off
        windowDragCheckbox.state = customSettings.enableFullWindowDrag ? .on : .off
        bitmapCachingCheckbox.state = customSettings.bitmapCaching ? .on : .off
        
        audioQualityPopup.selectItem(at: getAudioQualityIndex(customSettings.audioQuality))
        networkOptimizationPopup.selectItem(at: getNetworkOptimizationIndex(customSettings.networkOptimization))
    }
    
    private func updatePreview() {
        let previewText = generateConfigPreview()
        configPreviewTextView.string = previewText
    }
    
    private func updatePerformanceInfo() {
        let analysis = configManager.analyzePerformanceImpact(for: customSettings)
        
        // 更新预设配置信息
        let presetSettings = getSelectedProfileSettings()
        let presetAnalysis = configManager.analyzePerformanceImpact(for: presetSettings)
        
        bandwidthLabel.stringValue = "预估带宽: \(presetAnalysis.recommendedBandwidth)"
        performanceLabel.stringValue = "性能影响: \(presetAnalysis.performanceLevel.displayName)"
        qualityLabel.stringValue = "质量级别: \(presetAnalysis.qualityLevel.displayName)"
        
        // 更新自定义配置信息
        customBandwidthLabel.stringValue = "预估带宽: \(analysis.recommendedBandwidth)"
        customPerformanceLabel.stringValue = "性能影响: \(analysis.performanceLevel.displayName)"
        customQualityLabel.stringValue = "质量级别: \(analysis.qualityLevel.displayName)"
    }
    
    // MARK: - Helper Methods
    
    private func getSelectedProfile() -> DisplayQualityProfile {
        switch profileSegmentedControl.selectedSegment {
        case 0: return .performance
        case 1: return .balanced
        case 2: return .quality
        default: return .custom
        }
    }
    
    private func getSelectedProfileSettings() -> RDPQualitySettings {
        let profile = getSelectedProfile()
        return configManager.getQualityProfileSettings(profile)
    }
    
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
    
    private func getNetworkOptimizationIndex(_ optimization: NetworkOptimization) -> Int {
        switch optimization {
        case .modem: return 0
        case .lowBroadband: return 1
        case .broadband: return 2
        case .lan: return 3
        case .auto: return 4
        }
    }
    
    private func getNetworkOptimizationFromIndex(_ index: Int) -> NetworkOptimization {
        switch index {
        case 0: return .modem
        case 1: return .lowBroadband
        case 2: return .broadband
        case 3: return .lan
        case 4: return .auto
        default: return .broadband
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
        窗口拖拽: \(customSettings.enableFullWindowDrag ? "启用" : "禁用")
        位图缓存: \(customSettings.bitmapCaching ? "启用" : "禁用")
        音频质量: \(customSettings.audioQuality.displayName)
        网络优化: \(customSettings.networkOptimization.displayName)
        
        预估带宽需求: \(customSettings.estimatedBandwidth)
        性能影响: \(customSettings.performanceImpact.displayName)
        质量级别: \(customSettings.qualityLevel.displayName)
        """
    }
    
    // MARK: - Action Methods
    
    @IBAction func profileChanged(_ sender: NSSegmentedControl) {
        let newProfile = getSelectedProfile()
        currentProfile = newProfile
        customSettings = getSelectedProfileSettings()
        
        updateCustomSettings()
        updatePreview()
        updatePerformanceInfo()
        updateProfileDescription()
    }
    
    @IBAction func compressionChanged(_ sender: NSSlider) {
        updateCustomSettingsFromUI()
        updatePreview()
        updatePerformanceInfo()
    }
    
    @IBAction func colorDepthChanged(_ sender: NSPopUpButton) {
        updateCustomSettingsFromUI()
        updatePreview()
        updatePerformanceInfo()
    }
    
    @IBAction func checkboxChanged(_ sender: NSButton) {
        updateCustomSettingsFromUI()
        updatePreview()
        updatePerformanceInfo()
    }
    
    @IBAction func popupChanged(_ sender: NSPopUpButton) {
        updateCustomSettingsFromUI()
        updatePreview()
        updatePerformanceInfo()
    }
    
    @IBAction func applyConfiguration(_ sender: NSButton) {
        do {
            try applyCurrentConfiguration()
            showSuccessAlert("配置已成功应用")
            window?.close()
        } catch {
            showErrorAlert("应用配置失败", message: error.localizedDescription)
        }
    }
    
    @IBAction func resetToDefault(_ sender: NSButton) {
        let alert = NSAlert()
        alert.messageText = "重置配置"
        alert.informativeText = "确定要重置到默认配置吗？这将清除所有自定义设置。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            configManager.resetToDefaultConfiguration()
            loadCurrentConfiguration()
            updateUI()
            showSuccessAlert("配置已重置到默认设置")
        }
    }
    
    @IBAction func exportConfiguration(_ sender: NSButton) {
        guard let configString = configManager.exportConfiguration() else {
            showErrorAlert("导出失败", message: "无法导出当前配置")
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "RDP质量配置.json"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try configString.write(to: url, atomically: true, encoding: .utf8)
                showSuccessAlert("配置已成功导出到 \(url.lastPathComponent)")
            } catch {
                showErrorAlert("导出失败", message: error.localizedDescription)
            }
        }
    }
    
    @IBAction func importConfiguration(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            do {
                let configString = try String(contentsOf: url, encoding: .utf8)
                if configManager.importConfiguration(configString) {
                    loadCurrentConfiguration()
                    updateUI()
                    showSuccessAlert("配置已成功导入")
                } else {
                    showErrorAlert("导入失败", message: "配置文件格式不正确")
                }
            } catch {
                showErrorAlert("导入失败", message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func updateCustomSettingsFromUI() {
        let compressionLevel = Int(compressionSlider.intValue)
        let colorDepth = getColorDepthFromIndex(colorDepthPopup.indexOfSelectedItem)
        let audioQuality = getAudioQualityFromIndex(audioQualityPopup.indexOfSelectedItem)
        let networkOptimization = getNetworkOptimizationFromIndex(networkOptimizationPopup.indexOfSelectedItem)
        
        // 计算预估带宽和性能影响
        let tempSettings = RDPQualitySettings(
            compressionLevel: compressionLevel,
            colorDepth: colorDepth,
            enableFontSmoothing: fontSmoothingCheckbox.state == .on,
            enableWallpaper: wallpaperCheckbox.state == .on,
            enableMenuAnimations: animationsCheckbox.state == .on,
            enableThemes: themesCheckbox.state == .on,
            enableFullWindowDrag: windowDragCheckbox.state == .on,
            bitmapCaching: bitmapCachingCheckbox.state == .on,
            audioQuality: audioQuality,
            networkOptimization: networkOptimization,
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
            enableFullWindowDrag: windowDragCheckbox.state == .on,
            bitmapCaching: bitmapCachingCheckbox.state == .on,
            audioQuality: audioQuality,
            networkOptimization: networkOptimization,
            estimatedBandwidth: analysis.recommendedBandwidth,
            performanceImpact: analysis.performanceLevel,
            qualityLevel: analysis.qualityLevel
        )
        
        compressionValueLabel.stringValue = getCompressionDescription(compressionLevel)
        currentProfile = .custom
        profileSegmentedControl.selectedSegment = -1
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
    
    private func showSuccessAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "成功"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    private func showErrorAlert(_ title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
}
