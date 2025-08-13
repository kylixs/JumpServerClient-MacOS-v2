//
//  RDPSettingsViewController.swift
//  RDP设置视图控制器模块
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import Cocoa
import JMSCore

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
    
    // 新增：分辨率和HiDPI相关组件
    private var resolutionPopup: NSPopUpButton!
    private var customWidthField: NSTextField!
    private var customHeightField: NSTextField!
    private var autoDetectButton: NSButton!
    private var hiDPICheckbox: NSButton!
    private var scaleFactorSlider: NSSlider!
    private var scaleFactorLabel: NSTextField!
    private var autoDetectionCheckbox: NSButton!
    private var displayInfoLabel: NSTextField!
    private var previewTextView: NSTextView!
    private var displayDetector = DisplayDetector()
    
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
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 650))
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
        setupResolutionControls()
        setupHiDPIControls()
        setupCompressionControls()
        setupQualityControls()
        setupEffectControls()
        setupPreviewArea()
        setupActionButtons()
        setupStatusLabel()
    }
    
    private func setupTitleAndProfile() {
        // 标题
        let titleLabel = NSTextField(labelWithString: "RDP质量设置")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        titleLabel.frame = NSRect(x: 20, y: 610, width: 200, height: 25)
        view.addSubview(titleLabel)
        
        // 预设配置选择器
        let profileLabel = NSTextField(labelWithString: "预设配置:")
        profileLabel.frame = NSRect(x: 20, y: 570, width: 80, height: 20)
        view.addSubview(profileLabel)
        
        profileSegmentedControl = NSSegmentedControl()
        profileSegmentedControl.segmentCount = 3
        profileSegmentedControl.setLabel("性能", forSegment: 0)
        profileSegmentedControl.setLabel("平衡", forSegment: 1)
        profileSegmentedControl.setLabel("质量", forSegment: 2)
        profileSegmentedControl.selectedSegment = 1
        profileSegmentedControl.target = self
        profileSegmentedControl.action = #selector(profileChanged(_:))
        profileSegmentedControl.frame = NSRect(x: 110, y: 570, width: 200, height: 25)
        view.addSubview(profileSegmentedControl)
    }
    
    private func setupResolutionControls() {
        // 分辨率设置区域标题
        let resolutionSectionLabel = NSTextField(labelWithString: "分辨率设置")
        resolutionSectionLabel.font = NSFont.boldSystemFont(ofSize: 14)
        resolutionSectionLabel.frame = NSRect(x: 20, y: 530, width: 120, height: 20)
        view.addSubview(resolutionSectionLabel)
        
        // 分辨率选择
        let resolutionLabel = NSTextField(labelWithString: "分辨率:")
        resolutionLabel.frame = NSRect(x: 20, y: 500, width: 80, height: 20)
        view.addSubview(resolutionLabel)
        
        resolutionPopup = NSPopUpButton()
        resolutionPopup.addItems(withTitles: [
            "1920×1080 (Full HD)",
            "2560×1440 (2K)",
            "3840×2160 (4K)",
            "自定义分辨率"
        ])
        resolutionPopup.selectItem(at: 0)
        resolutionPopup.target = self
        resolutionPopup.action = #selector(resolutionChanged(_:))
        resolutionPopup.frame = NSRect(x: 110, y: 500, width: 150, height: 25)
        view.addSubview(resolutionPopup)
        
        // 自动检测按钮
        autoDetectButton = NSButton(title: "自动检测", target: self, action: #selector(autoDetectResolution(_:)))
        autoDetectButton.bezelStyle = .rounded
        autoDetectButton.frame = NSRect(x: 270, y: 500, width: 80, height: 25)
        view.addSubview(autoDetectButton)
        
        // 自定义分辨率输入框
        let customLabel = NSTextField(labelWithString: "自定义:")
        customLabel.frame = NSRect(x: 20, y: 470, width: 60, height: 20)
        view.addSubview(customLabel)
        
        customWidthField = NSTextField()
        customWidthField.placeholderString = "宽度"
        customWidthField.frame = NSRect(x: 90, y: 470, width: 80, height: 25)
        customWidthField.target = self
        customWidthField.action = #selector(customResolutionChanged(_:))
        customWidthField.isEnabled = false
        view.addSubview(customWidthField)
        
        let xLabel = NSTextField(labelWithString: "×")
        xLabel.frame = NSRect(x: 175, y: 470, width: 15, height: 20)
        view.addSubview(xLabel)
        
        customHeightField = NSTextField()
        customHeightField.placeholderString = "高度"
        customHeightField.frame = NSRect(x: 195, y: 470, width: 80, height: 25)
        customHeightField.target = self
        customHeightField.action = #selector(customResolutionChanged(_:))
        customHeightField.isEnabled = false
        view.addSubview(customHeightField)
        
        // 显示器信息
        displayInfoLabel = NSTextField(labelWithString: "当前显示器: 检测中...")
        displayInfoLabel.frame = NSRect(x: 20, y: 440, width: 350, height: 20)
        displayInfoLabel.textColor = NSColor.secondaryLabelColor
        view.addSubview(displayInfoLabel)
        
        // 检测当前显示器信息
        detectCurrentDisplay()
    }
    
    private func setupHiDPIControls() {
        // HiDPI设置区域标题
        let hiDPISectionLabel = NSTextField(labelWithString: "HiDPI/缩放设置")
        hiDPISectionLabel.font = NSFont.boldSystemFont(ofSize: 14)
        hiDPISectionLabel.frame = NSRect(x: 20, y: 400, width: 150, height: 20)
        view.addSubview(hiDPISectionLabel)
        
        // HiDPI启用选项
        hiDPICheckbox = NSButton(checkboxWithTitle: "启用HiDPI优化", target: self, action: #selector(hiDPISettingChanged(_:)))
        hiDPICheckbox.frame = NSRect(x: 20, y: 370, width: 150, height: 20)
        hiDPICheckbox.state = .off
        view.addSubview(hiDPICheckbox)
        
        // 缩放因子设置
        let scaleLabel = NSTextField(labelWithString: "缩放因子:")
        scaleLabel.frame = NSRect(x: 20, y: 340, width: 80, height: 20)
        view.addSubview(scaleLabel)
        
        scaleFactorSlider = NSSlider()
        scaleFactorSlider.minValue = 1.0
        scaleFactorSlider.maxValue = 3.0
        scaleFactorSlider.doubleValue = 1.0
        scaleFactorSlider.numberOfTickMarks = 5
        scaleFactorSlider.allowsTickMarkValuesOnly = true
        scaleFactorSlider.target = self
        scaleFactorSlider.action = #selector(scaleFactorChanged(_:))
        scaleFactorSlider.frame = NSRect(x: 110, y: 340, width: 150, height: 25)
        scaleFactorSlider.isEnabled = false
        view.addSubview(scaleFactorSlider)
        
        scaleFactorLabel = NSTextField(labelWithString: "100% (标准)")
        scaleFactorLabel.frame = NSRect(x: 270, y: 340, width: 100, height: 20)
        view.addSubview(scaleFactorLabel)
        
        // 自动检测选项
        autoDetectionCheckbox = NSButton(checkboxWithTitle: "自动检测显示器配置", target: self, action: #selector(autoDetectionChanged(_:)))
        autoDetectionCheckbox.frame = NSRect(x: 20, y: 310, width: 180, height: 20)
        autoDetectionCheckbox.state = .on
        view.addSubview(autoDetectionCheckbox)
    }
    
    private func setupCompressionControls() {
        // 压缩级别
        let compressionLabel = NSTextField(labelWithString: "压缩级别:")
        compressionLabel.frame = NSRect(x: 20, y: 270, width: 80, height: 20)
        view.addSubview(compressionLabel)
        
        compressionSlider = NSSlider()
        compressionSlider.minValue = 0
        compressionSlider.maxValue = 2
        compressionSlider.doubleValue = 1
        compressionSlider.numberOfTickMarks = 3
        compressionSlider.allowsTickMarkValuesOnly = true
        compressionSlider.target = self
        compressionSlider.action = #selector(compressionChanged(_:))
        compressionSlider.frame = NSRect(x: 110, y: 270, width: 150, height: 25)
        view.addSubview(compressionSlider)
        
        compressionValueLabel = NSTextField(labelWithString: "中等")
        compressionValueLabel.frame = NSRect(x: 270, y: 270, width: 80, height: 20)
        view.addSubview(compressionValueLabel)
    }
    
    private func setupQualityControls() {
        // 颜色深度
        let colorDepthLabel = NSTextField(labelWithString: "颜色深度:")
        colorDepthLabel.frame = NSRect(x: 20, y: 230, width: 80, height: 20)
        view.addSubview(colorDepthLabel)
        
        colorDepthPopup = NSPopUpButton()
        colorDepthPopup.addItems(withTitles: ["16位", "24位", "32位"])
        colorDepthPopup.selectItem(at: 1)
        colorDepthPopup.target = self
        colorDepthPopup.action = #selector(qualityControlChanged(_:))
        colorDepthPopup.frame = NSRect(x: 110, y: 230, width: 100, height: 25)
        view.addSubview(colorDepthPopup)
        
        // 音频质量
        let audioLabel = NSTextField(labelWithString: "音频质量:")
        audioLabel.frame = NSRect(x: 220, y: 230, width: 80, height: 20)
        view.addSubview(audioLabel)
        
        audioQualityPopup = NSPopUpButton()
        audioQualityPopup.addItems(withTitles: ["禁用", "低质量", "中等", "高质量"])
        audioQualityPopup.selectItem(at: 2)
        audioQualityPopup.target = self
        audioQualityPopup.action = #selector(qualityControlChanged(_:))
        audioQualityPopup.frame = NSRect(x: 310, y: 230, width: 100, height: 25)
        view.addSubview(audioQualityPopup)
    }
    
    private func setupEffectControls() {
        // 特效选项
        fontSmoothingCheckbox = NSButton(checkboxWithTitle: "字体平滑", target: self, action: #selector(effectControlChanged(_:)))
        fontSmoothingCheckbox.frame = NSRect(x: 20, y: 190, width: 100, height: 20)
        fontSmoothingCheckbox.state = .on
        view.addSubview(fontSmoothingCheckbox)
        
        wallpaperCheckbox = NSButton(checkboxWithTitle: "桌面壁纸", target: self, action: #selector(effectControlChanged(_:)))
        wallpaperCheckbox.frame = NSRect(x: 130, y: 190, width: 100, height: 20)
        wallpaperCheckbox.state = .on
        view.addSubview(wallpaperCheckbox)
        
        animationsCheckbox = NSButton(checkboxWithTitle: "菜单动画", target: self, action: #selector(effectControlChanged(_:)))
        animationsCheckbox.frame = NSRect(x: 20, y: 160, width: 100, height: 20)
        animationsCheckbox.state = .off
        view.addSubview(animationsCheckbox)
        
        themesCheckbox = NSButton(checkboxWithTitle: "视觉主题", target: self, action: #selector(effectControlChanged(_:)))
        themesCheckbox.frame = NSRect(x: 130, y: 160, width: 100, height: 20)
        themesCheckbox.state = .on
        view.addSubview(themesCheckbox)
    }
    
    private func setupPreviewArea() {
        // 预览区域标题
        let previewLabel = NSTextField(labelWithString: "配置预览")
        previewLabel.font = NSFont.boldSystemFont(ofSize: 14)
        previewLabel.frame = NSRect(x: 320, y: 530, width: 100, height: 20)
        view.addSubview(previewLabel)
        
        // 预览文本区域
        let scrollView = NSScrollView()
        scrollView.frame = NSRect(x: 320, y: 160, width: 260, height: 360)
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        
        previewTextView = NSTextView()
        previewTextView.isEditable = false
        previewTextView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        previewTextView.textColor = NSColor.labelColor
        previewTextView.backgroundColor = NSColor.controlBackgroundColor
        
        scrollView.documentView = previewTextView
        view.addSubview(scrollView)
    }
    
    private func setupActionButtons() {
        // 操作按钮
        let saveButton = NSButton(title: "保存设置", target: self, action: #selector(saveSettings(_:)))
        saveButton.bezelStyle = .rounded
        saveButton.frame = NSRect(x: 20, y: 80, width: 100, height: 30)
        view.addSubview(saveButton)
        
        let resetButton = NSButton(title: "重置默认", target: self, action: #selector(resetSettings(_:)))
        resetButton.bezelStyle = .rounded
        resetButton.frame = NSRect(x: 130, y: 80, width: 100, height: 30)
        view.addSubview(resetButton)
        
        let exportButton = NSButton(title: "导出设置", target: self, action: #selector(exportSettings(_:)))
        exportButton.bezelStyle = .rounded
        exportButton.frame = NSRect(x: 240, y: 80, width: 100, height: 30)
        view.addSubview(exportButton)
        
        let importButton = NSButton(title: "导入设置", target: self, action: #selector(importSettings(_:)))
        importButton.bezelStyle = .rounded
        importButton.frame = NSRect(x: 350, y: 80, width: 100, height: 30)
        view.addSubview(importButton)
        
        // 应用推荐设置按钮
        let applyRecommendedButton = NSButton(title: "应用推荐设置", target: self, action: #selector(applyRecommendedSettings(_:)))
        applyRecommendedButton.bezelStyle = .rounded
        applyRecommendedButton.frame = NSRect(x: 460, y: 80, width: 120, height: 30)
        view.addSubview(applyRecommendedButton)
    }
    
    private func setupStatusLabel() {
        statusLabel = NSTextField(labelWithString: "状态: 就绪")
        statusLabel.frame = NSRect(x: 20, y: 40, width: 560, height: 20)
        statusLabel.textColor = NSColor.secondaryLabelColor
        view.addSubview(statusLabel)
    }
    
    // MARK: - 显示器检测
    private func detectCurrentDisplay() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let displayConfig = try self?.displayDetector.detectPrimaryDisplay()
                
                DispatchQueue.main.async {
                    if let config = displayConfig {
                        self?.updateDisplayInfo(config)
                    } else {
                        self?.displayInfoLabel.stringValue = "当前显示器: 检测失败"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.displayInfoLabel.stringValue = "当前显示器: 检测失败 - \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func updateDisplayInfo(_ config: DisplayConfiguration) {
        let hiDPIStatus = config.isHiDPI ? "HiDPI" : "标准"
        displayInfoLabel.stringValue = "当前显示器: \(config.width)×\(config.height) (\(hiDPIStatus), 缩放: \(Int(config.scaleFactor * 100))%)"
        
        // 如果启用自动检测，更新UI
        if autoDetectionCheckbox.state == .on {
            applyDisplayConfiguration(config)
        }
    }
    
    private func applyDisplayConfiguration(_ config: DisplayConfiguration) {
        // 更新分辨率设置
        let resolutionText = "\(config.width)×\(config.height)"
        let presetTitles = resolutionPopup.itemTitles
        
        var foundPreset = false
        for (index, title) in presetTitles.enumerated() {
            if title.contains(resolutionText) {
                resolutionPopup.selectItem(at: index)
                foundPreset = true
                break
            }
        }
        
        if !foundPreset {
            // 设置为自定义分辨率
            resolutionPopup.selectItem(at: 3) // "自定义分辨率"
            customWidthField.stringValue = "\(config.width)"
            customHeightField.stringValue = "\(config.height)"
            customWidthField.isEnabled = true
            customHeightField.isEnabled = true
        }
        
        // 更新HiDPI设置
        hiDPICheckbox.state = config.isHiDPI ? .on : .off
        scaleFactorSlider.doubleValue = config.scaleFactor
        scaleFactorSlider.isEnabled = config.isHiDPI
        updateScaleFactorLabel()
        
        updatePreview()
    }
    
    // MARK: - 新的事件处理方法
    
    @objc private func resolutionChanged(_ sender: NSPopUpButton) {
        let isCustom = sender.indexOfSelectedItem == 3
        customWidthField.isEnabled = isCustom
        customHeightField.isEnabled = isCustom
        
        if !isCustom {
            customWidthField.stringValue = ""
            customHeightField.stringValue = ""
        }
        
        settingsChanged()
    }
    
    @objc private func customResolutionChanged(_ sender: NSTextField) {
        // 验证输入
        if let width = Int(customWidthField.stringValue),
           let height = Int(customHeightField.stringValue) {
            let resolution = ResolutionSettings(width: width, height: height, isCustom: true)
            if !resolution.isValid {
                updateStatusLabel("分辨率超出有效范围 (800×600 到 7680×4320)")
                return
            }
        }
        
        settingsChanged()
    }
    
    @objc private func autoDetectResolution(_ sender: NSButton) {
        detectCurrentDisplay()
        updateStatusLabel("正在检测显示器配置...")
    }
    
    @objc private func hiDPISettingChanged(_ sender: NSButton) {
        scaleFactorSlider.isEnabled = sender.state == .on
        if sender.state == .off {
            scaleFactorSlider.doubleValue = 1.0
            updateScaleFactorLabel()
        }
        settingsChanged()
    }
    
    @objc private func scaleFactorChanged(_ sender: NSSlider) {
        updateScaleFactorLabel()
        settingsChanged()
    }
    
    @objc private func autoDetectionChanged(_ sender: NSButton) {
        if sender.state == .on {
            detectCurrentDisplay()
        }
        settingsChanged()
    }
    
    @objc private func applyRecommendedSettings(_ sender: NSButton) {
        do {
            let displayConfig = try displayDetector.detectPrimaryDisplay()
            applyDisplayConfiguration(displayConfig)
            updateStatusLabel("已应用推荐设置")
        } catch {
            updateStatusLabel("无法检测显示器配置")
            showAlert("检测失败", message: error.localizedDescription)
        }
    }
    
    private func updateScaleFactorLabel() {
        let scaleFactor = scaleFactorSlider.doubleValue
        let hiDPISettings = HiDPISettings(enabled: true, scaleFactor: scaleFactor)
        scaleFactorLabel.stringValue = hiDPISettings.scaleFactorDescription
    }
    
    private func settingsChanged() {
        let currentSettings = getCurrentSettingsFromUI()
        settingsManager.updateSettings(currentSettings)
        delegate?.settingsDidChange(currentSettings)
        updatePreview()
    }
    
    private func updatePreview() {
        let currentSettings = getCurrentSettingsFromUI()
        previewTextView.string = currentSettings.generatePreview()
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
        
        // 获取分辨率设置
        let resolution: ResolutionSettings
        if resolutionPopup.indexOfSelectedItem == 3 { // 自定义分辨率
            let width = Int(customWidthField.stringValue) ?? 1920
            let height = Int(customHeightField.stringValue) ?? 1080
            resolution = ResolutionSettings(width: width, height: height, isCustom: true)
        } else {
            let presets = ResolutionSettings.presets
            if resolutionPopup.indexOfSelectedItem < presets.count {
                resolution = presets[resolutionPopup.indexOfSelectedItem]
            } else {
                resolution = ResolutionSettings.fullHD
            }
        }
        
        // 获取HiDPI设置
        let hiDPI = HiDPISettings(
            enabled: hiDPICheckbox.state == .on,
            scaleFactor: scaleFactorSlider.doubleValue,
            autoDetect: autoDetectionCheckbox.state == .on,
            forceHiDPI: false
        )
        
        return RDPSettings(
            profileName: profileName,
            compressionLevel: Int(compressionSlider.doubleValue),
            colorDepth: colorDepth,
            audioQuality: audioQuality,
            enableFontSmoothing: fontSmoothingCheckbox.state == .on,
            enableWallpaper: wallpaperCheckbox.state == .on,
            enableMenuAnimations: animationsCheckbox.state == .on,
            enableThemes: themesCheckbox.state == .on,
            resolution: resolution,
            hiDPI: hiDPI,
            useAutoDetection: autoDetectionCheckbox.state == .on
        )
    }
    
    private func updateUIWithSettings(_ settings: RDPSettings) {
        // 更新预设配置选择器
        let profiles = ["性能优先", "平衡模式", "质量优先"]
        if let index = profiles.firstIndex(of: settings.profileName) {
            profileSegmentedControl.selectedSegment = index
        }
        
        // 更新分辨率设置
        let resolutionText = "\(settings.resolution.width)×\(settings.resolution.height)"
        let presetTitles = resolutionPopup.itemTitles
        
        var foundPreset = false
        for (index, title) in presetTitles.enumerated() {
            if title.contains(resolutionText) && !settings.resolution.isCustom {
                resolutionPopup.selectItem(at: index)
                foundPreset = true
                break
            }
        }
        
        if !foundPreset || settings.resolution.isCustom {
            resolutionPopup.selectItem(at: 3) // "自定义分辨率"
            customWidthField.stringValue = "\(settings.resolution.width)"
            customHeightField.stringValue = "\(settings.resolution.height)"
            customWidthField.isEnabled = true
            customHeightField.isEnabled = true
        } else {
            customWidthField.stringValue = ""
            customHeightField.stringValue = ""
            customWidthField.isEnabled = false
            customHeightField.isEnabled = false
        }
        
        // 更新HiDPI设置
        hiDPICheckbox.state = settings.hiDPI.enabled ? .on : .off
        scaleFactorSlider.doubleValue = settings.hiDPI.scaleFactor
        scaleFactorSlider.isEnabled = settings.hiDPI.enabled
        updateScaleFactorLabel()
        
        autoDetectionCheckbox.state = settings.useAutoDetection ? .on : .off
        
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
        
        // 更新预览
        updatePreview()
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
        settingsChanged()
        updateStatusLabel("压缩级别已更改")
    }
    
    @objc private func qualityControlChanged(_ sender: NSControl) {
        settingsChanged()
        updateStatusLabel("质量设置已更改")
    }
    
    @objc private func effectControlChanged(_ sender: NSButton) {
        settingsChanged()
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
