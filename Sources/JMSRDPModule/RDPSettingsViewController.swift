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
    
    // 分辨率和HiDPI相关组件
    private var resolutionPopup: NSPopUpButton!
    private var customWidthField: NSTextField!
    private var customHeightField: NSTextField!
    private var autoDetectButton: NSButton!
    private var hiDPICheckbox: NSButton!
    private var scaleFactorSlider: NSSlider!
    private var scaleFactorLabel: NSTextField!
    private var autoDetectionCheckbox: NSButton!
    private var displayInfoLabel: NSTextField!
    private var bandwidthLabel: NSTextField!
    
    // 新增：多显示器支持组件
    private var displaySelectionPopup: NSPopUpButton!
    private var refreshDisplaysButton: NSButton!
    private var displayInfoPanel: NSView!
    private var displayNameLabel: NSTextField!
    private var displaySpecsLabel: NSTextField!
    private var recommendationLabel: NSTextField!
    
    // 新增：自定义缩放因子组件
    private var customScaleFactorField: NSTextField!
    private var scaleFactorStepper: NSStepper!
    private var scaleFactorPreview: NSTextField!
    private var scaleFactorModeSegment: NSSegmentedControl!
    
    // 服务和数据
    private var displayDetector = DisplayDetector()
    private var allDisplays: [DisplayConfiguration] = []
    private var selectedDisplayIndex: Int = 0
    
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
        view = NSView(frame: NSRect(x: 0, y: 0, width: 580, height: 720))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        setupUI()
        loadCurrentSettings()
        
        print("✅ RDP设置界面加载完成")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        updateStatusLabel("就绪")
        
        logInfo("📱 RDP设置界面已加载，默认不选择显示器以避免修改配置")
        
        // 延迟检测显示器，但不自动选择
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshDisplaysWithoutSelection()
        }
    }
    
    // MARK: - UI设置
    private func setupUI() {
        setupTitleAndProfile()
        setupDisplaySelection()
        setupResolutionControls()
        setupHiDPIControls()
        setupCompressionControls()
        setupQualityControls()
        setupEffectControls()
        setupActionButtons()
        setupStatusLabel()
    }
    
    private func setupDisplaySelection() {
        // 显示器选择区域标题
        let displaySectionLabel = NSTextField(labelWithString: "显示器选择")
        displaySectionLabel.font = NSFont.boldSystemFont(ofSize: 14)
        displaySectionLabel.frame = NSRect(x: 20, y: 650, width: 120, height: 20)
        view.addSubview(displaySectionLabel)
        
        // 显示器选择下拉菜单
        displaySelectionPopup = NSPopUpButton()
        displaySelectionPopup.target = self
        displaySelectionPopup.action = #selector(displaySelectionChanged(_:))
        displaySelectionPopup.frame = NSRect(x: 20, y: 620, width: 400, height: 25)
        view.addSubview(displaySelectionPopup)
        
        // 刷新显示器按钮
        refreshDisplaysButton = NSButton(title: "刷新", target: self, action: #selector(refreshDisplays(_:)))
        refreshDisplaysButton.bezelStyle = .rounded
        refreshDisplaysButton.frame = NSRect(x: 430, y: 620, width: 60, height: 25)
        view.addSubview(refreshDisplaysButton)
        
        // 显示器信息面板
        displayInfoPanel = NSView()
        displayInfoPanel.frame = NSRect(x: 20, y: 560, width: 540, height: 50)
        displayInfoPanel.wantsLayer = true
        displayInfoPanel.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        displayInfoPanel.layer?.cornerRadius = 6
        view.addSubview(displayInfoPanel)
        
        // 显示器名称标签
        displayNameLabel = NSTextField(labelWithString: "检测中...")
        displayNameLabel.font = NSFont.boldSystemFont(ofSize: 12)
        displayNameLabel.frame = NSRect(x: 10, y: 25, width: 520, height: 20)
        displayInfoPanel.addSubview(displayNameLabel)
        
        // 显示器规格标签
        displaySpecsLabel = NSTextField(labelWithString: "")
        displaySpecsLabel.font = NSFont.systemFont(ofSize: 11)
        displaySpecsLabel.textColor = NSColor.secondaryLabelColor
        displaySpecsLabel.frame = NSRect(x: 10, y: 5, width: 350, height: 15)
        displayInfoPanel.addSubview(displaySpecsLabel)
        
        // 推荐配置标签
        recommendationLabel = NSTextField(labelWithString: "")
        recommendationLabel.font = NSFont.systemFont(ofSize: 11)
        recommendationLabel.textColor = NSColor.systemBlue
        recommendationLabel.frame = NSRect(x: 370, y: 5, width: 160, height: 15)
        displayInfoPanel.addSubview(recommendationLabel)
        
        // 注意：不在这里调用refreshDisplays，而是在viewDidLoad中调用
    }
    
    private func setupTitleAndProfile() {
        // 标题
        let titleLabel = NSTextField(labelWithString: "RDP连接设置")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.frame = NSRect(x: 20, y: 680, width: 200, height: 20)
        view.addSubview(titleLabel)
        
        // 配置文件选择
        let profileLabel = NSTextField(labelWithString: "质量配置:")
        profileLabel.frame = NSRect(x: 300, y: 680, width: 80, height: 20)
        view.addSubview(profileLabel)
        
        profileSegmentedControl = NSSegmentedControl()
        profileSegmentedControl.segmentCount = 3
        profileSegmentedControl.setLabel("性能", forSegment: 0)
        profileSegmentedControl.setLabel("平衡", forSegment: 1)
        profileSegmentedControl.setLabel("质量", forSegment: 2)
        profileSegmentedControl.selectedSegment = 1
        profileSegmentedControl.target = self
        profileSegmentedControl.action = #selector(profileChanged(_:))
        profileSegmentedControl.frame = NSRect(x: 380, y: 680, width: 180, height: 25)
        view.addSubview(profileSegmentedControl)
    }
    
    private func setupResolutionControls() {
        // 分辨率设置区域标题
        let resolutionSectionLabel = NSTextField(labelWithString: "分辨率设置")
        resolutionSectionLabel.font = NSFont.boldSystemFont(ofSize: 14)
        resolutionSectionLabel.frame = NSRect(x: 20, y: 520, width: 100, height: 20)
        view.addSubview(resolutionSectionLabel)
        
        // 分辨率预设选择
        let resolutionLabel = NSTextField(labelWithString: "预设分辨率:")
        resolutionLabel.frame = NSRect(x: 20, y: 490, width: 100, height: 20)
        view.addSubview(resolutionLabel)
        
        resolutionPopup = NSPopUpButton()
        resolutionPopup.addItems(withTitles: [
            "1920×1080 (Full HD)",
            "2560×1440 (2K)",
            "3840×2160 (4K)",
            "自定义分辨率"
        ])
        resolutionPopup.selectItem(at: 1)
        resolutionPopup.target = self
        resolutionPopup.action = #selector(resolutionChanged(_:))
        resolutionPopup.frame = NSRect(x: 130, y: 490, width: 180, height: 25)
        view.addSubview(resolutionPopup)
        
        // 自动检测按钮
        autoDetectButton = NSButton(title: "自动检测", target: self, action: #selector(autoDetectResolution(_:)))
        autoDetectButton.bezelStyle = .rounded
        autoDetectButton.frame = NSRect(x: 320, y: 490, width: 80, height: 25)
        view.addSubview(autoDetectButton)
        
        // 自定义分辨率输入
        let customLabel = NSTextField(labelWithString: "自定义:")
        customLabel.frame = NSRect(x: 20, y: 460, width: 60, height: 20)
        view.addSubview(customLabel)
        
        customWidthField = NSTextField()
        customWidthField.placeholderString = "宽度"
        customWidthField.target = self
        customWidthField.action = #selector(customResolutionChanged(_:))
        customWidthField.frame = NSRect(x: 80, y: 460, width: 80, height: 25)
        customWidthField.isEnabled = false
        view.addSubview(customWidthField)
        
        let xLabel = NSTextField(labelWithString: "×")
        xLabel.frame = NSRect(x: 170, y: 460, width: 15, height: 20)
        view.addSubview(xLabel)
        
        customHeightField = NSTextField()
        customHeightField.placeholderString = "高度"
        customHeightField.target = self
        customHeightField.action = #selector(customResolutionChanged(_:))
        customHeightField.frame = NSRect(x: 190, y: 460, width: 80, height: 25)
        customHeightField.isEnabled = false
        view.addSubview(customHeightField)
        
        // 带宽需求显示
        bandwidthLabel = NSTextField(labelWithString: "预计带宽: 5-10 Mbps")
        bandwidthLabel.frame = NSRect(x: 290, y: 460, width: 200, height: 20)
        bandwidthLabel.textColor = NSColor.secondaryLabelColor
        view.addSubview(bandwidthLabel)
    }
    
    private func setupHiDPIControls() {
        // HiDPI设置区域标题
        let hiDPISectionLabel = NSTextField(labelWithString: "HiDPI/缩放设置")
        hiDPISectionLabel.font = NSFont.boldSystemFont(ofSize: 14)
        hiDPISectionLabel.frame = NSRect(x: 20, y: 420, width: 150, height: 20)
        view.addSubview(hiDPISectionLabel)
        
        // HiDPI启用选项
        hiDPICheckbox = NSButton(checkboxWithTitle: "启用HiDPI优化", target: self, action: #selector(hiDPISettingChanged(_:)))
        hiDPICheckbox.frame = NSRect(x: 20, y: 390, width: 150, height: 20)
        hiDPICheckbox.state = .off
        view.addSubview(hiDPICheckbox)
        
        // 缩放模式选择
        let scaleModeLabel = NSTextField(labelWithString: "缩放模式:")
        scaleModeLabel.frame = NSRect(x: 20, y: 360, width: 80, height: 20)
        view.addSubview(scaleModeLabel)
        
        scaleFactorModeSegment = NSSegmentedControl()
        scaleFactorModeSegment.segmentCount = 2
        scaleFactorModeSegment.setLabel("预设", forSegment: 0)
        scaleFactorModeSegment.setLabel("自定义", forSegment: 1)
        scaleFactorModeSegment.selectedSegment = 0
        scaleFactorModeSegment.target = self
        scaleFactorModeSegment.action = #selector(scaleFactorModeChanged(_:))
        scaleFactorModeSegment.frame = NSRect(x: 110, y: 360, width: 120, height: 25)
        view.addSubview(scaleFactorModeSegment)
        
        // 预设缩放因子滑块
        let scaleLabel = NSTextField(labelWithString: "缩放因子:")
        scaleLabel.frame = NSRect(x: 20, y: 330, width: 80, height: 20)
        view.addSubview(scaleLabel)
        
        scaleFactorSlider = NSSlider()
        scaleFactorSlider.minValue = 1.0
        scaleFactorSlider.maxValue = 3.0
        scaleFactorSlider.doubleValue = 1.0
        scaleFactorSlider.numberOfTickMarks = 9
        scaleFactorSlider.allowsTickMarkValuesOnly = false
        scaleFactorSlider.target = self
        scaleFactorSlider.action = #selector(scaleFactorChanged(_:))
        scaleFactorSlider.frame = NSRect(x: 110, y: 330, width: 150, height: 25)
        view.addSubview(scaleFactorSlider)
        
        scaleFactorLabel = NSTextField(labelWithString: "100% (1.0x)")
        scaleFactorLabel.frame = NSRect(x: 270, y: 330, width: 100, height: 20)
        view.addSubview(scaleFactorLabel)
        
        // 自定义缩放因子输入
        let customScaleLabel = NSTextField(labelWithString: "精确值:")
        customScaleLabel.frame = NSRect(x: 20, y: 300, width: 60, height: 20)
        view.addSubview(customScaleLabel)
        
        customScaleFactorField = NSTextField()
        customScaleFactorField.placeholderString = "1.00"
        customScaleFactorField.target = self
        customScaleFactorField.action = #selector(customScaleFactorChanged(_:))
        customScaleFactorField.frame = NSRect(x: 90, y: 300, width: 80, height: 25)
        customScaleFactorField.isEnabled = false
        view.addSubview(customScaleFactorField)
        
        // 缩放因子步进器
        scaleFactorStepper = NSStepper()
        scaleFactorStepper.minValue = 0.50
        scaleFactorStepper.maxValue = 5.00
        scaleFactorStepper.increment = 0.01
        scaleFactorStepper.doubleValue = 1.00
        scaleFactorStepper.target = self
        scaleFactorStepper.action = #selector(scaleFactorStepperChanged(_:))
        scaleFactorStepper.frame = NSRect(x: 175, y: 300, width: 20, height: 25)
        scaleFactorStepper.isEnabled = false
        view.addSubview(scaleFactorStepper)
        
        // 缩放预览标签
        scaleFactorPreview = NSTextField(labelWithString: "100% = 1.0x (标准)")
        scaleFactorPreview.font = NSFont.systemFont(ofSize: 11)
        scaleFactorPreview.textColor = NSColor.secondaryLabelColor
        scaleFactorPreview.frame = NSRect(x: 210, y: 300, width: 200, height: 20)
        view.addSubview(scaleFactorPreview)
        
        // 自动检测选项
        autoDetectionCheckbox = NSButton(checkboxWithTitle: "自动检测显示器配置", target: self, action: #selector(autoDetectionChanged(_:)))
        autoDetectionCheckbox.frame = NSRect(x: 20, y: 270, width: 180, height: 20)
        autoDetectionCheckbox.state = .on
        view.addSubview(autoDetectionCheckbox)
    }
    
    private func setupCompressionControls() {
        // 压缩级别
        let compressionLabel = NSTextField(labelWithString: "压缩级别:")
        compressionLabel.frame = NSRect(x: 20, y: 230, width: 80, height: 20)
        view.addSubview(compressionLabel)
        
        compressionSlider = NSSlider()
        compressionSlider.minValue = 0
        compressionSlider.maxValue = 2
        compressionSlider.doubleValue = 1
        compressionSlider.numberOfTickMarks = 3
        compressionSlider.allowsTickMarkValuesOnly = true
        compressionSlider.target = self
        compressionSlider.action = #selector(compressionChanged(_:))
        compressionSlider.frame = NSRect(x: 110, y: 230, width: 150, height: 25)
        view.addSubview(compressionSlider)
        
        compressionValueLabel = NSTextField(labelWithString: "中等")
        compressionValueLabel.frame = NSRect(x: 270, y: 230, width: 80, height: 20)
        view.addSubview(compressionValueLabel)
    }
    
    private func setupQualityControls() {
        // 颜色深度
        let colorDepthLabel = NSTextField(labelWithString: "颜色深度:")
        colorDepthLabel.frame = NSRect(x: 20, y: 190, width: 80, height: 20)
        view.addSubview(colorDepthLabel)
        
        colorDepthPopup = NSPopUpButton()
        colorDepthPopup.addItems(withTitles: ["16位", "24位", "32位"])
        colorDepthPopup.selectItem(at: 1)
        colorDepthPopup.target = self
        colorDepthPopup.action = #selector(qualityControlChanged(_:))
        colorDepthPopup.frame = NSRect(x: 110, y: 190, width: 100, height: 25)
        view.addSubview(colorDepthPopup)
        
        // 音频质量
        let audioLabel = NSTextField(labelWithString: "音频质量:")
        audioLabel.frame = NSRect(x: 220, y: 190, width: 80, height: 20)
        view.addSubview(audioLabel)
        
        audioQualityPopup = NSPopUpButton()
        audioQualityPopup.addItems(withTitles: ["禁用", "低质量", "中等", "高质量"])
        audioQualityPopup.selectItem(at: 2)
        audioQualityPopup.target = self
        audioQualityPopup.action = #selector(qualityControlChanged(_:))
        audioQualityPopup.frame = NSRect(x: 310, y: 190, width: 100, height: 25)
        view.addSubview(audioQualityPopup)
    }
    
    private func setupEffectControls() {
        // 特效选项
        fontSmoothingCheckbox = NSButton(checkboxWithTitle: "字体平滑", target: self, action: #selector(effectControlChanged(_:)))
        fontSmoothingCheckbox.frame = NSRect(x: 20, y: 150, width: 100, height: 20)
        fontSmoothingCheckbox.state = .on
        view.addSubview(fontSmoothingCheckbox)
        
        wallpaperCheckbox = NSButton(checkboxWithTitle: "桌面壁纸", target: self, action: #selector(effectControlChanged(_:)))
        wallpaperCheckbox.frame = NSRect(x: 130, y: 150, width: 100, height: 20)
        wallpaperCheckbox.state = .on
        view.addSubview(wallpaperCheckbox)
        
        animationsCheckbox = NSButton(checkboxWithTitle: "菜单动画", target: self, action: #selector(effectControlChanged(_:)))
        animationsCheckbox.frame = NSRect(x: 240, y: 150, width: 100, height: 20)
        animationsCheckbox.state = .off
        view.addSubview(animationsCheckbox)
        
        themesCheckbox = NSButton(checkboxWithTitle: "视觉主题", target: self, action: #selector(effectControlChanged(_:)))
        themesCheckbox.frame = NSRect(x: 350, y: 150, width: 100, height: 20)
        themesCheckbox.state = .on
        view.addSubview(themesCheckbox)
    }
    
    private func setupActionButtons() {
        // 操作按钮
        let saveButton = NSButton(title: "保存设置", target: self, action: #selector(saveSettings(_:)))
        saveButton.bezelStyle = .rounded
        saveButton.frame = NSRect(x: 20, y: 100, width: 100, height: 30)
        view.addSubview(saveButton)
        
        let resetButton = NSButton(title: "重置默认", target: self, action: #selector(resetSettings(_:)))
        resetButton.bezelStyle = .rounded
        resetButton.frame = NSRect(x: 130, y: 100, width: 100, height: 30)
        view.addSubview(resetButton)
        
        let exportButton = NSButton(title: "导出设置", target: self, action: #selector(exportSettings(_:)))
        exportButton.bezelStyle = .rounded
        exportButton.frame = NSRect(x: 240, y: 100, width: 100, height: 30)
        view.addSubview(exportButton)
        
        let importButton = NSButton(title: "导入设置", target: self, action: #selector(importSettings(_:)))
        importButton.bezelStyle = .rounded
        importButton.frame = NSRect(x: 350, y: 100, width: 100, height: 30)
        view.addSubview(importButton)
        
        // 应用推荐设置按钮
        let applyRecommendedButton = NSButton(title: "应用推荐设置", target: self, action: #selector(applyRecommendedSettings(_:)))
        applyRecommendedButton.bezelStyle = .rounded
        applyRecommendedButton.frame = NSRect(x: 460, y: 100, width: 100, height: 30)
        view.addSubview(applyRecommendedButton)
    }
    
    private func setupStatusLabel() {
        statusLabel = NSTextField(labelWithString: "状态: 就绪")
        statusLabel.frame = NSRect(x: 20, y: 60, width: 540, height: 20)
        statusLabel.textColor = NSColor.secondaryLabelColor
        view.addSubview(statusLabel)
    }
    
    // MARK: - 显示器选择事件处理
    
    @objc private func displaySelectionChanged(_ sender: NSPopUpButton) {
        selectedDisplayIndex = sender.indexOfSelectedItem
        
        guard selectedDisplayIndex < allDisplays.count else { return }
        
        let selectedDisplay = allDisplays[selectedDisplayIndex]
        
        // 自动应用选定显示器的配置
        applyDisplayConfiguration(selectedDisplay)
        
        // 更新显示器信息
        updateDisplayInfo(selectedDisplay)
        
        // 触发设置变更
        settingsChanged()
        
        updateStatusLabel("已切换到显示器: \(selectedDisplay.displayName ?? "未知显示器")")
    }
    
    @objc private func refreshDisplays(_ sender: NSButton?) {
        refreshDisplaysWithoutSelection()
    }
    
    private func refreshDisplaysWithoutSelection() {
        updateStatusLabel("正在刷新显示器列表...")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let displays = try self?.displayDetector.detectAllDisplays() ?? []
                
                DispatchQueue.main.async {
                    self?.allDisplays = displays
                    self?.updateDisplaySelectionMenuWithoutSelection()
                    self?.updateStatusLabel("显示器列表已更新，检测到 \(displays.count) 个显示器")
                }
            } catch {
                DispatchQueue.main.async {
                    self?.updateStatusLabel("显示器检测失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 自定义缩放因子事件处理
    
    @objc private func scaleFactorModeChanged(_ sender: NSSegmentedControl) {
        let isCustomMode = sender.selectedSegment == 1
        
        // 切换控件状态
        scaleFactorSlider.isEnabled = !isCustomMode && hiDPICheckbox.state == .on
        customScaleFactorField.isEnabled = isCustomMode && hiDPICheckbox.state == .on
        scaleFactorStepper.isEnabled = isCustomMode && hiDPICheckbox.state == .on
        
        if isCustomMode {
            // 切换到自定义模式，同步滑块值到输入框
            customScaleFactorField.doubleValue = scaleFactorSlider.doubleValue
            scaleFactorStepper.doubleValue = scaleFactorSlider.doubleValue
        } else {
            // 切换到预设模式，同步输入框值到滑块
            scaleFactorSlider.doubleValue = customScaleFactorField.doubleValue
        }
        
        updateScaleFactorPreview()
        settingsChanged()
    }
    
    @objc private func customScaleFactorChanged(_ sender: NSTextField) {
        let value = sender.doubleValue
        
        // 验证输入值
        if value < 0.50 || value > 5.00 {
            sender.doubleValue = max(0.50, min(5.00, value))
            updateStatusLabel("缩放因子已调整到有效范围 (0.50-5.00)")
        }
        
        // 同步到步进器
        scaleFactorStepper.doubleValue = sender.doubleValue
        
        updateScaleFactorPreview()
        settingsChanged()
    }
    
    @objc private func scaleFactorStepperChanged(_ sender: NSStepper) {
        // 同步到输入框
        customScaleFactorField.doubleValue = sender.doubleValue
        
        updateScaleFactorPreview()
        settingsChanged()
    }
    
    // MARK: - 显示器管理辅助方法
    
    private func updateDisplaySelectionMenu() {
        updateDisplaySelectionMenuWithoutSelection()
    }
    
    private func updateDisplaySelectionMenuWithoutSelection() {
        // 确保UI组件已经初始化
        guard let displaySelectionPopup = displaySelectionPopup else {
            logWarning("⚠️ 显示器选择菜单尚未初始化，跳过更新")
            return
        }
        
        displaySelectionPopup.removeAllItems()
        
        // 首先添加默认的"请选择显示器"选项
        displaySelectionPopup.addItem(withTitle: "请选择显示器...")
        
        // 添加检测到的显示器
        for (_, display) in allDisplays.enumerated() {
            let displayName = getDisplayName(for: display)
            displaySelectionPopup.addItem(withTitle: displayName)
        }
        
        // 默认选择"请选择显示器"，不自动选择任何显示器
        displaySelectionPopup.selectItem(at: 0)
        selectedDisplayIndex = -1 // 表示未选择
        
        // 更新显示器信息为未选择状态
        displayNameLabel.stringValue = "未选择显示器"
        displaySpecsLabel.stringValue = "请选择显示器以查看详细信息和应用推荐配置"
        recommendationLabel.stringValue = ""
        
        logInfo("📺 显示器菜单已更新，检测到 \(allDisplays.count) 个显示器，默认未选择")
    }
    
    private func getDisplayName(for display: DisplayConfiguration) -> String {
        let displayNumber = allDisplays.firstIndex(where: { $0.displayID == display.displayID }) ?? 0
        let isMain = display.displayID == CGMainDisplayID()
        let mainIndicator = isMain ? " (主显示器)" : ""
        let hiDPIIndicator = display.isHiDPI ? " HiDPI" : ""
        
        return "显示器\(displayNumber + 1)\(mainIndicator) - \(display.width)×\(display.height)\(hiDPIIndicator)"
    }
    
    private func updateDisplayInfo(_ display: DisplayConfiguration) {
        // 确保UI组件已经初始化
        guard let displayNameLabel = displayNameLabel,
              let displaySpecsLabel = displaySpecsLabel,
              let recommendationLabel = recommendationLabel else {
            print("⚠️ 显示器信息UI组件尚未初始化，跳过更新")
            return
        }
        
        // 更新显示器名称
        displayNameLabel.stringValue = getDisplayName(for: display)
        
        // 更新显示器规格
        let dpiText = String(format: "%.0f", display.dpi ?? 96.0)
        let refreshText = display.refreshRate > 0 ? String(format: "%.0fHz", display.refreshRate) : "未知"
        displaySpecsLabel.stringValue = "DPI: \(dpiText), 刷新率: \(refreshText), 颜色深度: \(display.colorDepth)位"
        
        // 更新推荐配置
        let recommendedScale = getRecommendedScaleFactor(for: display)
        recommendationLabel.stringValue = "推荐缩放: \(String(format: "%.2f", recommendedScale))x"
    }
    
    private func getRecommendedScaleFactor(for display: DisplayConfiguration) -> Double {
        // 基于DPI的智能推荐
        let dpi = display.dpi ?? 96.0
        switch dpi {
        case ..<120:
            return 1.0
        case 120..<150:
            return 1.25
        case 150..<200:
            return 1.5
        case 200..<250:
            return 2.0
        case 250..<300:
            return 2.5
        default:
            return 3.0
        }
    }
    
    private func updateScaleFactorPreview() {
        let scaleFactor: Double
        
        if scaleFactorModeSegment.selectedSegment == 1 {
            // 自定义模式
            scaleFactor = customScaleFactorField.doubleValue
        } else {
            // 预设模式
            scaleFactor = scaleFactorSlider.doubleValue
        }
        
        let percentage = Int(scaleFactor * 100)
        let description = getScaleFactorDescription(scaleFactor)
        
        scaleFactorPreview.stringValue = "\(percentage)% = \(String(format: "%.2f", scaleFactor))x (\(description))"
        
        // 更新滑块标签
        scaleFactorLabel.stringValue = "\(percentage)% (\(String(format: "%.2f", scaleFactor))x)"
    }
    
    private func getScaleFactorDescription(_ scaleFactor: Double) -> String {
        switch scaleFactor {
        case ..<1.0:
            return "缩小显示"
        case 1.0:
            return "标准"
        case 1.0..<1.5:
            return "轻微放大"
        case 1.5..<2.0:
            return "中等放大"
        case 2.0..<3.0:
            return "高DPI优化"
        default:
            return "超高DPI"
        }
    }
    
    private func applyDisplayConfiguration(_ display: DisplayConfiguration) {
        // 更新分辨率设置
        customWidthField.stringValue = String(display.width)
        customHeightField.stringValue = String(display.height)
        
        // 如果是自定义分辨率，切换到自定义模式
        resolutionPopup.selectItem(at: 3) // "自定义分辨率"
        customWidthField.isEnabled = true
        customHeightField.isEnabled = true
        
        // 更新HiDPI设置
        hiDPICheckbox.state = display.isHiDPI ? .on : .off
        
        // 使用显示器的实际缩放因子，而不是推荐值
        let actualScaleFactor = display.scaleFactor
        
        if scaleFactorModeSegment.selectedSegment == 1 {
            // 自定义模式 - 使用实际缩放因子
            customScaleFactorField.doubleValue = actualScaleFactor
            scaleFactorStepper.doubleValue = actualScaleFactor
        } else {
            // 预设模式 - 使用实际缩放因子
            scaleFactorSlider.doubleValue = actualScaleFactor
        }
        
        // 启用/禁用相关控件
        let hiDPIEnabled = display.isHiDPI
        scaleFactorSlider.isEnabled = hiDPIEnabled && scaleFactorModeSegment.selectedSegment == 0
        customScaleFactorField.isEnabled = hiDPIEnabled && scaleFactorModeSegment.selectedSegment == 1
        scaleFactorStepper.isEnabled = hiDPIEnabled && scaleFactorModeSegment.selectedSegment == 1
        
        updateScaleFactorPreview()
        updateBandwidthDisplay()
        
        print("🖥️ 已应用显示器配置 - 分辨率: \(display.width)×\(display.height), HiDPI: \(display.isHiDPI), 实际缩放: \(actualScaleFactor)")
    }
    
    private func updateBandwidthDisplay() {
        // 根据当前设置计算预计带宽需求
        let width = Int(customWidthField.stringValue) ?? 1920
        let height = Int(customHeightField.stringValue) ?? 1080
        let colorDepth = (colorDepthPopup.indexOfSelectedItem + 1) * 8 + 8 // 16, 24, 32
        let compression = compressionSlider.intValue
        
        // 简化的带宽计算
        let pixelCount = width * height
        let bitsPerPixel = colorDepth
        let rawBandwidth = Double(pixelCount * bitsPerPixel) / 8.0 / 1024.0 / 1024.0 * 30.0 // 30fps
        
        // 应用压缩因子
        let compressionFactor: Double
        switch compression {
        case 0: compressionFactor = 1.0      // 无压缩
        case 1: compressionFactor = 0.3      // 中等压缩
        case 2: compressionFactor = 0.1      // 高压缩
        default: compressionFactor = 0.3
        }
        
        let estimatedBandwidth = rawBandwidth * compressionFactor
        
        if estimatedBandwidth < 1.0 {
            bandwidthLabel.stringValue = String(format: "预计带宽: %.1f Kbps", estimatedBandwidth * 1024)
        } else {
            bandwidthLabel.stringValue = String(format: "预计带宽: %.1f Mbps", estimatedBandwidth)
        }
    }
    
    // MARK: - 辅助方法
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
        updateBandwidthDisplay()
    }
    
    // MARK: - 数据管理
    private func loadCurrentSettings() {
        logInfo("📋 开始加载当前配置文件参数...")
        
        let settings = settingsManager.currentSettings
        
        logInfo("📄 配置文件内容:")
        logInfo("   配置名称: \(settings.profileName)")
        logInfo("   分辨率: \(settings.resolution.width)×\(settings.resolution.height)")
        logInfo("   自定义分辨率: \(settings.resolution.isCustom)")
        logInfo("   HiDPI启用: \(settings.hiDPI.enabled)")
        logInfo("   缩放因子: \(settings.hiDPI.scaleFactor)")
        logInfo("   自动检测: \(settings.useAutoDetection)")
        logInfo("   压缩级别: \(settings.compressionLevel)")
        logInfo("   颜色深度: \(settings.colorDepth)")
        logInfo("   音频质量: \(settings.audioQuality)")
        
        // 更新UI界面，不触发设置变更事件（避免在加载时修改配置）
        updateUIWithSettings(settings)
        
        logInfo("✅ 配置文件参数加载完成，未触发设置变更")
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
        
        // 更新带宽显示
        updateBandwidthDisplay()
    }
    
    private func updateCompressionLabel() {
        let level = Int(compressionSlider.doubleValue)
        let labels = ["无压缩", "中等", "高压缩"]
        compressionValueLabel.stringValue = labels[level]
    }
    
    private func updateStatusLabel(_ message: String) {
        // 确保statusLabel已经初始化
        guard let statusLabel = statusLabel else {
            print("⚠️ statusLabel尚未初始化，跳过状态更新: \(message)")
            return
        }
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
