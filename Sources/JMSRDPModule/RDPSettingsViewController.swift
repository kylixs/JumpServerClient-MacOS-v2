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
    private var hiDPICheckbox: NSButton!
    private var scaleFactorSlider: NSSlider!
    private var scaleFactorLabel: NSTextField!
    private var autoDetectionCheckbox: NSButton!
    private var displayInfoLabel: NSTextField!
    private var bandwidthLabel: NSTextField!
    
    // 新增：多显示器支持组件
    private var displaySelectionPopup: NSPopUpButton!
    private var refreshDisplaysButton: NSButton!
    
    // 新增：显示和连接设置组件
    private var smartSizingCheckbox: NSButton!
    private var screenModePopup: NSPopUpButton!
    private var autoResizeCheckbox: NSButton!
    private var desktopCompositionCheckbox: NSButton!
    private var remoteFXCheckbox: NSButton!
    private var displayInfoPanel: NSView!
    private var displayNameLabel: NSTextField!
    private var displaySpecsLabel: NSTextField!
    private var recommendationLabel: NSTextField!
    
    // 新增：自定义缩放因子组件
    private var customScaleFactorField: NSTextField!
    private var scaleFactorStepper: NSStepper!
    
    // 新增：分辨率模式选择组件
    private var autoDetectRadio: NSButton!
    private var manualSetRadio: NSButton!
    private var scaleFactorPreview: NSTextField!
    
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
        view = NSView(frame: NSRect(x: 0, y: 0, width: 580, height: 700)) // 增加高度到700px
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        setupUI()
        // 注意：不在loadView中调用loadCurrentSettings()，避免访问未初始化的控件
        
        print("✅ RDP设置界面加载完成")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // 确保所有UI控件都已初始化后再加载设置
        loadCurrentSettings()
        updateStatusLabel("就绪")
        
        // 初始化控件状态 - 根据当前设置决定显示模式
        let settings = settingsManager.currentSettings
        if settings.useAutoDetection {
            // 自动检测模式下，刷新显示器列表
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.refreshDisplaysAndSelectFirst()
            }
        } else {
            // 手动模式下，确保界面状态正确
            showResolutionModeArea(autoDetect: false)
        }
        
        logInfo("📱 RDP设置界面已加载，自动检测模式: \(settings.useAutoDetection)")
    }
    
    // MARK: - UI设置
    private func setupUI() {
        setupTitleAndProfile()           // Y: 660-680 标题和质量配置
        setupResolutionModeSelection()   // Y: 580-640 分辨率设置（核心功能）
        setupDisplaySettings()           // Y: 520-560 显示设置
        setupOtherOptions()             // Y: 460-500 其他选项
        setupActionButtons()            // Y: 400-440 操作按钮和状态
    }
    
    private func setupTitleAndProfile() {
        // 标题
        let titleLabel = NSTextField(labelWithString: "RDP连接设置")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.frame = NSRect(x: 20, y: 665, width: 200, height: 20)
        view.addSubview(titleLabel)
        
        // 配置文件选择
        let profileLabel = NSTextField(labelWithString: "质量预设:")
        profileLabel.frame = NSRect(x: 300, y: 665, width: 80, height: 20)
        view.addSubview(profileLabel)
        
        profileSegmentedControl = NSSegmentedControl()
        profileSegmentedControl.segmentCount = 3
        profileSegmentedControl.setLabel("性能", forSegment: 0)
        profileSegmentedControl.setLabel("平衡", forSegment: 1)
        profileSegmentedControl.setLabel("质量", forSegment: 2)
        profileSegmentedControl.selectedSegment = 1
        profileSegmentedControl.target = self
        profileSegmentedControl.action = #selector(profileChanged(_:))
        profileSegmentedControl.frame = NSRect(x: 380, y: 660, width: 180, height: 25)
        view.addSubview(profileSegmentedControl)
    }
    
    private func setupResolutionModeSelection() {
        // 分辨率设置区域背景面板
        let resolutionSectionPanel = NSView()
        resolutionSectionPanel.frame = NSRect(x: 10, y: 580, width: 560, height: 60)
        resolutionSectionPanel.wantsLayer = true
        resolutionSectionPanel.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        resolutionSectionPanel.layer?.cornerRadius = 8
        view.addSubview(resolutionSectionPanel)
        
        // 分辨率设置区域标题
        let resolutionSectionLabel = NSTextField(labelWithString: "📐 分辨率设置")
        resolutionSectionLabel.font = NSFont.boldSystemFont(ofSize: 14)
        resolutionSectionLabel.frame = NSRect(x: 20, y: 635, width: 150, height: 20)
        view.addSubview(resolutionSectionLabel)
        
        // 分辨率模式选择（二选一）
        autoDetectRadio = NSButton(radioButtonWithTitle: "自动检测", target: self, action: #selector(resolutionModeChanged(_:)))
        autoDetectRadio.frame = NSRect(x: 20, y: 610, width: 100, height: 20)
        autoDetectRadio.state = .on // 默认选择自动检测
        autoDetectRadio.tag = 1000
        view.addSubview(autoDetectRadio)
        
        manualSetRadio = NSButton(radioButtonWithTitle: "手动设置", target: self, action: #selector(resolutionModeChanged(_:)))
        manualSetRadio.frame = NSRect(x: 130, y: 610, width: 100, height: 20)
        manualSetRadio.state = .off
        manualSetRadio.tag = 1001
        view.addSubview(manualSetRadio)
        
        // 自动检测模式区域
        setupAutoDetectArea()
        
        // 手动设置模式区域
        setupManualSetArea()
    }
    
    private func setupAutoDetectArea() {
        // 自动检测区域背景
        let autoDetectPanel = NSView()
        autoDetectPanel.frame = NSRect(x: 30, y: 585, width: 520, height: 20)
        autoDetectPanel.identifier = NSUserInterfaceItemIdentifier("autoDetectPanel")
        view.addSubview(autoDetectPanel)
        
        // 目标显示器标签
        let displayLabel = NSTextField(labelWithString: "目标显示器:")
        displayLabel.frame = NSRect(x: 0, y: 0, width: 80, height: 20)
        autoDetectPanel.addSubview(displayLabel)
        
        // 显示器选择下拉菜单
        displaySelectionPopup = NSPopUpButton()
        displaySelectionPopup.addItem(withTitle: "主显示器")
        displaySelectionPopup.target = self
        displaySelectionPopup.action = #selector(displaySelectionChanged(_:))
        displaySelectionPopup.frame = NSRect(x: 90, y: 0, width: 200, height: 25)
        autoDetectPanel.addSubview(displaySelectionPopup)
        
        // 刷新按钮
        refreshDisplaysButton = NSButton(title: "刷新", target: self, action: #selector(refreshDisplays(_:)))
        refreshDisplaysButton.bezelStyle = .rounded
        refreshDisplaysButton.frame = NSRect(x: 300, y: 0, width: 60, height: 25)
        autoDetectPanel.addSubview(refreshDisplaysButton)
    }
    
    private func setupManualSetArea() {
        // 手动设置区域背景
        let manualSetPanel = NSView()
        manualSetPanel.frame = NSRect(x: 30, y: 580, width: 520, height: 45)
        manualSetPanel.identifier = NSUserInterfaceItemIdentifier("manualSetPanel")
        manualSetPanel.isHidden = true // 默认隐藏
        view.addSubview(manualSetPanel)
        
        // 分辨率标签
        let resolutionLabel = NSTextField(labelWithString: "分辨率:")
        resolutionLabel.frame = NSRect(x: 0, y: 20, width: 60, height: 20)
        manualSetPanel.addSubview(resolutionLabel)
        
        // 分辨率预设选择
        resolutionPopup = NSPopUpButton()
        resolutionPopup.addItems(withTitles: [
            "1920×1080 (推荐)",
            "2560×1440 (2K)",
            "3840×2160 (4K)",
            "自定义分辨率"
        ])
        resolutionPopup.selectItem(at: 0)
        resolutionPopup.target = self
        resolutionPopup.action = #selector(resolutionChanged(_:))
        resolutionPopup.frame = NSRect(x: 70, y: 20, width: 150, height: 25)
        manualSetPanel.addSubview(resolutionPopup)
        
        // 自定义分辨率输入区域（仅在选择自定义时显示）
        let customResolutionPanel = NSView()
        customResolutionPanel.frame = NSRect(x: 0, y: 0, width: 520, height: 20)
        customResolutionPanel.identifier = NSUserInterfaceItemIdentifier("customResolutionPanel")
        customResolutionPanel.isHidden = true
        manualSetPanel.addSubview(customResolutionPanel)
        
        let widthLabel = NSTextField(labelWithString: "宽度:")
        widthLabel.frame = NSRect(x: 0, y: 0, width: 40, height: 20)
        customResolutionPanel.addSubview(widthLabel)
        
        customWidthField = NSTextField()
        customWidthField.placeholderString = "1920"
        customWidthField.target = self
        customWidthField.action = #selector(customResolutionChanged(_:))
        customWidthField.frame = NSRect(x: 45, y: 0, width: 60, height: 25)
        customWidthField.isEditable = true
        customWidthField.isSelectable = true
        customWidthField.isBezeled = true
        customWidthField.bezelStyle = .squareBezel
        customResolutionPanel.addSubview(customWidthField)
        
        let heightLabel = NSTextField(labelWithString: "高度:")
        heightLabel.frame = NSRect(x: 115, y: 0, width: 40, height: 20)
        customResolutionPanel.addSubview(heightLabel)
        
        customHeightField = NSTextField()
        customHeightField.placeholderString = "1080"
        customHeightField.target = self
        customHeightField.action = #selector(customResolutionChanged(_:))
        customHeightField.frame = NSRect(x: 160, y: 0, width: 60, height: 25)
        customHeightField.isEditable = true
        customHeightField.isSelectable = true
        customHeightField.isBezeled = true
        customHeightField.bezelStyle = .squareBezel
        customResolutionPanel.addSubview(customHeightField)
        
        // 初始状态：自定义分辨率输入框禁用（因为默认选择的不是自定义分辨率）
        customWidthField.isEnabled = false
        customHeightField.isEnabled = false
    }
    
    private func setupDisplaySettings() {
        // 显示设置区域背景面板
        let displaySettingsPanel = NSView()
        displaySettingsPanel.frame = NSRect(x: 10, y: 520, width: 560, height: 40)
        displaySettingsPanel.wantsLayer = true
        displaySettingsPanel.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        displaySettingsPanel.layer?.cornerRadius = 8
        view.addSubview(displaySettingsPanel)
        
        // 显示设置区域标题
        let displaySettingsLabel = NSTextField(labelWithString: "🎨 显示设置")
        displaySettingsLabel.font = NSFont.boldSystemFont(ofSize: 14)
        displaySettingsLabel.frame = NSRect(x: 20, y: 555, width: 100, height: 20)
        view.addSubview(displaySettingsLabel)
        
        // HiDPI优化
        hiDPICheckbox = NSButton(checkboxWithTitle: "HiDPI优化", target: self, action: #selector(hiDPISettingChanged(_:)))
        hiDPICheckbox.frame = NSRect(x: 20, y: 530, width: 100, height: 20)
        hiDPICheckbox.state = .on
        view.addSubview(hiDPICheckbox)
        
        // 缩放设置
        let scaleLabel = NSTextField(labelWithString: "缩放:")
        scaleLabel.frame = NSRect(x: 130, y: 530, width: 40, height: 20)
        view.addSubview(scaleLabel)
        
        let scalePopup = NSPopUpButton()
        scalePopup.addItems(withTitles: ["100%", "125%", "150%", "200%"])
        scalePopup.selectItem(at: 2) // 默认150%
        scalePopup.frame = NSRect(x: 175, y: 530, width: 70, height: 25)
        view.addSubview(scalePopup)
        
        // 颜色深度
        let colorLabel = NSTextField(labelWithString: "颜色:")
        colorLabel.frame = NSRect(x: 255, y: 530, width: 40, height: 20)
        view.addSubview(colorLabel)
        
        colorDepthPopup = NSPopUpButton()
        colorDepthPopup.addItems(withTitles: ["16位", "24位", "32位"])
        colorDepthPopup.selectItem(at: 1) // 默认24位
        colorDepthPopup.target = self
        colorDepthPopup.action = #selector(qualityControlChanged(_:))
        colorDepthPopup.frame = NSRect(x: 300, y: 530, width: 70, height: 25)
        view.addSubview(colorDepthPopup)
        
        // 音频质量
        let audioLabel = NSTextField(labelWithString: "音频:")
        audioLabel.frame = NSRect(x: 380, y: 530, width: 40, height: 20)
        view.addSubview(audioLabel)
        
        audioQualityPopup = NSPopUpButton()
        audioQualityPopup.addItems(withTitles: ["禁用", "低质量", "中等", "高质量"])
        audioQualityPopup.selectItem(at: 2) // 默认中等
        audioQualityPopup.target = self
        audioQualityPopup.action = #selector(qualityControlChanged(_:))
        audioQualityPopup.frame = NSRect(x: 425, y: 530, width: 80, height: 25)
        view.addSubview(audioQualityPopup)
    }
    
    private func setupOtherOptions() {
        // 其他选项区域背景面板
        let otherOptionsPanel = NSView()
        otherOptionsPanel.frame = NSRect(x: 10, y: 460, width: 560, height: 40)
        otherOptionsPanel.wantsLayer = true
        otherOptionsPanel.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        otherOptionsPanel.layer?.cornerRadius = 8
        view.addSubview(otherOptionsPanel)
        
        // 其他选项区域标题
        let otherOptionsLabel = NSTextField(labelWithString: "⚙️ 其他选项")
        otherOptionsLabel.font = NSFont.boldSystemFont(ofSize: 14)
        otherOptionsLabel.frame = NSRect(x: 20, y: 495, width: 100, height: 20)
        view.addSubview(otherOptionsLabel)
        
        // 字体平滑
        fontSmoothingCheckbox = NSButton(checkboxWithTitle: "字体平滑", target: self, action: #selector(effectControlChanged(_:)))
        fontSmoothingCheckbox.frame = NSRect(x: 20, y: 470, width: 80, height: 20)
        fontSmoothingCheckbox.state = .on
        view.addSubview(fontSmoothingCheckbox)
        
        // 桌面壁纸
        wallpaperCheckbox = NSButton(checkboxWithTitle: "桌面壁纸", target: self, action: #selector(effectControlChanged(_:)))
        wallpaperCheckbox.frame = NSRect(x: 110, y: 470, width: 80, height: 20)
        wallpaperCheckbox.state = .on
        view.addSubview(wallpaperCheckbox)
        
        // 智能缩放
        smartSizingCheckbox = NSButton(checkboxWithTitle: "智能缩放", target: self, action: #selector(advancedControlChanged(_:)))
        smartSizingCheckbox.frame = NSRect(x: 200, y: 470, width: 80, height: 20)
        smartSizingCheckbox.state = .off
        view.addSubview(smartSizingCheckbox)
        
        // 屏幕模式
        let screenModeLabel = NSTextField(labelWithString: "屏幕模式:")
        screenModeLabel.frame = NSRect(x: 290, y: 470, width: 70, height: 20)
        view.addSubview(screenModeLabel)
        
        screenModePopup = NSPopUpButton()
        screenModePopup.addItems(withTitles: ["窗口", "全屏"])
        screenModePopup.selectItem(at: 1) // 默认全屏
        screenModePopup.target = self
        screenModePopup.action = #selector(advancedControlChanged(_:))
        screenModePopup.frame = NSRect(x: 365, y: 470, width: 70, height: 25)
        view.addSubview(screenModePopup)
    }
    
    private func setupActionButtons() {
        // 操作区域背景面板
        let actionPanel = NSView()
        actionPanel.frame = NSRect(x: 10, y: 400, width: 560, height: 40)
        actionPanel.wantsLayer = true
        actionPanel.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        actionPanel.layer?.cornerRadius = 8
        view.addSubview(actionPanel)
        
        // 操作按钮
        let saveButton = NSButton(title: "保存", target: self, action: #selector(saveSettings(_:)))
        saveButton.bezelStyle = .rounded
        saveButton.frame = NSRect(x: 20, y: 415, width: 60, height: 30)
        view.addSubview(saveButton)
        
        let resetButton = NSButton(title: "重置", target: self, action: #selector(resetSettings(_:)))
        resetButton.bezelStyle = .rounded
        resetButton.frame = NSRect(x: 90, y: 415, width: 60, height: 30)
        view.addSubview(resetButton)
        
        let exportButton = NSButton(title: "导出", target: self, action: #selector(exportSettings(_:)))
        exportButton.bezelStyle = .rounded
        exportButton.frame = NSRect(x: 160, y: 415, width: 60, height: 30)
        view.addSubview(exportButton)
        
        let importButton = NSButton(title: "导入", target: self, action: #selector(importSettings(_:)))
        importButton.bezelStyle = .rounded
        importButton.frame = NSRect(x: 230, y: 415, width: 60, height: 30)
        view.addSubview(importButton)
        
        // 状态标签
        statusLabel = NSTextField(labelWithString: "状态: 就绪")
        statusLabel.frame = NSRect(x: 350, y: 420, width: 200, height: 20)
        statusLabel.textColor = NSColor.secondaryLabelColor
        view.addSubview(statusLabel)
    }
    
    // MARK: - 显示器选择事件处理
    
    @objc private func displaySelectionChanged(_ sender: NSPopUpButton) {
        let selectedIndex = sender.indexOfSelectedItem
        
        // 如果选择的是"请选择显示器..."（索引0），清空信息显示
        if selectedIndex == 0 {
            selectedDisplayIndex = -1
            clearDisplayInfo()
            logInfo("📺 用户取消选择显示器")
            return
        }
        
        // 调整索引（因为第0项是"请选择显示器..."）
        let displayIndex = selectedIndex - 1
        selectedDisplayIndex = displayIndex
        
        guard displayIndex >= 0 && displayIndex < allDisplays.count else { 
            logWarning("⚠️ 显示器索引超出范围: \(displayIndex)")
            return 
        }
        
        let selectedDisplay = allDisplays[displayIndex]
        
        logInfo("📺 用户选择显示器: \(selectedDisplay.displayName ?? "未知")，仅显示信息")
        
        // 仅更新显示器信息，不应用配置
        updateDisplayInfo(selectedDisplay)
        
        updateStatusLabel("已选择显示器: \(selectedDisplay.displayName ?? "未知显示器")（点击'应用推荐'来应用配置）")
    }
    
    @objc private func applySelectedDisplayConfig(_ sender: NSButton) {
        guard selectedDisplayIndex >= 0 && selectedDisplayIndex < allDisplays.count else {
            showAlert("未选择显示器", message: "请先选择一个显示器，然后点击'应用推荐'来应用其配置。")
            return
        }
        
        let selectedDisplay = allDisplays[selectedDisplayIndex]
        
        logInfo("🔧 用户点击应用推荐配置: \(selectedDisplay.displayName ?? "未知")")
        
        // 显示确认对话框
        let alert = NSAlert()
        alert.messageText = "应用推荐配置"
        alert.informativeText = """
        确定要应用以下推荐配置吗？
        
        显示器: \(selectedDisplay.displayName ?? "未知")
        分辨率: \(selectedDisplay.width)×\(selectedDisplay.height)
        HiDPI: \(selectedDisplay.isHiDPI ? "启用" : "禁用")
        推荐缩放: \(selectedDisplay.recommendedScaleFactor)x
        
        这将修改当前的RDP设置。
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "应用配置")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // 用户确认应用配置
            applyDisplayConfiguration(selectedDisplay)
            settingsChanged()
            updateStatusLabel("✅ 已应用显示器推荐配置: \(selectedDisplay.displayName ?? "未知显示器")")
            logInfo("✅ 已应用显示器推荐配置")
            
            // 显示成功通知
            showAlert("配置已应用", message: "显示器推荐配置已成功应用到RDP设置中。")
        } else {
            // 用户取消
            updateStatusLabel("已取消应用配置")
            logInfo("❌ 用户取消应用显示器配置")
        }
    }
    
    private func clearDisplayInfo() {
        displayNameLabel.stringValue = "未选择显示器"
        displaySpecsLabel.stringValue = "请选择显示器以查看详细信息"
        recommendationLabel.stringValue = ""
        
        // 清空详细信息
        if displayInfoPanel.subviews.count > 3 {
            if let detailLabel = displayInfoPanel.subviews[3] as? NSTextField {
                detailLabel.stringValue = ""
            }
        }
    }
    
    @objc private func refreshDisplays(_ sender: NSButton?) {
        refreshDisplaysWithoutSelection()
    }
    
    private func refreshDisplaysWithoutSelection() {
        updateStatusLabel("正在刷新显示器列表...")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let displays = try self?.displayDetector.detectAllDisplays(useLogicalResolution: true) ?? []
                
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
    
    private func refreshDisplaysAndSelectFirst() {
        updateStatusLabel("正在刷新显示器列表...")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let displays = try self?.displayDetector.detectAllDisplays(useLogicalResolution: true) ?? []
                
                DispatchQueue.main.async {
                    self?.allDisplays = displays
                    self?.updateDisplaySelectionMenuAndSelectFirst()
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
    
    @objc private func customScaleFactorChanged(_ sender: NSTextField) {
        let value = sender.doubleValue
        
        // 验证输入值
        if value < 0.50 || value > 5.00 {
            sender.doubleValue = max(0.50, min(5.00, value))
            updateStatusLabel("缩放因子已调整到有效范围 (0.50-5.00)")
        }
        
        // 同步到滑块和步进器
        let clampedValue = max(0.50, min(5.00, sender.doubleValue))
        
        // 只有在滑块范围内才同步到滑块
        if clampedValue >= scaleFactorSlider.minValue && clampedValue <= scaleFactorSlider.maxValue {
            scaleFactorSlider.doubleValue = clampedValue
        }
        
        scaleFactorStepper.doubleValue = clampedValue
        
        updateScaleFactorLabel()
        settingsChanged()
    }
    
    @objc private func scaleFactorStepperChanged(_ sender: NSStepper) {
        // 同步到输入框
        customScaleFactorField.doubleValue = sender.doubleValue
        
        // 只有在滑块范围内才同步到滑块
        let value = sender.doubleValue
        if value >= scaleFactorSlider.minValue && value <= scaleFactorSlider.maxValue {
            scaleFactorSlider.doubleValue = value
        }
        
        updateScaleFactorLabel()
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
    
    private func updateDisplaySelectionMenuAndSelectFirst() {
        // 确保UI组件已经初始化
        guard let displaySelectionPopup = displaySelectionPopup else {
            logWarning("⚠️ 显示器选择菜单尚未初始化，跳过更新")
            return
        }
        
        // 清空现有项目
        displaySelectionPopup.removeAllItems()
        
        // 首先添加默认的"请选择显示器"选项
        displaySelectionPopup.addItem(withTitle: "请选择显示器...")
        
        // 添加检测到的显示器
        for (_, display) in allDisplays.enumerated() {
            let displayName = getDisplayName(for: display)
            displaySelectionPopup.addItem(withTitle: displayName)
        }
        
        // 如果有显示器，默认选择第一个显示器
        if !allDisplays.isEmpty {
            displaySelectionPopup.selectItem(at: 1) // 选择第一个显示器（索引1，因为索引0是"请选择显示器..."）
            selectedDisplayIndex = 0 // 第一个显示器的实际索引
            
            let firstDisplay = allDisplays[0]
            updateDisplayInfo(firstDisplay)
            updateStatusLabel("已默认选择显示器: \(firstDisplay.displayName ?? "未知显示器")（点击'应用推荐'来应用配置）")
            
            logInfo("📺 显示器菜单已更新，检测到 \(allDisplays.count) 个显示器，默认选择第一个")
        } else {
            // 没有显示器时的处理
            displaySelectionPopup.selectItem(at: 0)
            selectedDisplayIndex = -1
            clearDisplayInfo()
            logInfo("📺 显示器菜单已更新，未检测到显示器")
        }
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
            logWarning("⚠️ 显示器信息UI组件尚未初始化，跳过更新")
            return
        }
        
        // 更新显示器名称
        displayNameLabel.stringValue = getDisplayName(for: display)
        
        // 更新显示器规格信息
        let dpiInfo = display.dpi != nil && display.dpi! > 0 ? String(format: "%.0f DPI", display.dpi!) : "DPI未知"
        let refreshInfo = display.refreshRate > 0 ? "\(display.refreshRate)Hz" : "刷新率未知"
        let colorInfo = "\(display.colorDepth)位色彩"
        
        displaySpecsLabel.stringValue = "分辨率: \(display.width)×\(display.height) | \(dpiInfo) | \(refreshInfo) | \(colorInfo)"
        
        // 更新推荐配置信息
        let hiDPIStatus = display.isHiDPI ? "启用HiDPI" : "标准显示"
        let scaleInfo = String(format: "推荐缩放: %.1fx", display.recommendedScaleFactor)
        let typeInfo = "类型: \(display.displayType.description)"
        
        recommendationLabel.stringValue = "\(hiDPIStatus) | \(scaleInfo) | \(typeInfo)"
        
        // 更新详细信息（如果有详细信息标签）
        if displayInfoPanel.subviews.count > 3 {
            if let detailLabel = displayInfoPanel.subviews[3] as? NSTextField {
                let builtInInfo = display.isBuiltIn ? "内置显示器" : "外接显示器"
                let physicalSize = display.physicalSize != nil ? 
                    String(format: "物理尺寸: %.1f×%.1f mm", display.physicalSize!.width, display.physicalSize!.height) : 
                    "物理尺寸未知"
                
                detailLabel.stringValue = "\(builtInInfo) | \(physicalSize) | 缩放因子: \(display.scaleFactor)x"
            }
        }
        
        logInfo("📺 显示器信息已更新: \(display.displayName ?? "未知")")
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
        
        // 使用显示器的实际缩放因子，同时更新滑块和精确值输入框
        let actualScaleFactor = display.scaleFactor
        
        scaleFactorSlider.doubleValue = actualScaleFactor
        customScaleFactorField.doubleValue = actualScaleFactor
        scaleFactorStepper.doubleValue = actualScaleFactor
        
        // 启用/禁用相关控件
        let hiDPIEnabled = display.isHiDPI
        scaleFactorSlider.isEnabled = hiDPIEnabled
        customScaleFactorField.isEnabled = hiDPIEnabled
        scaleFactorStepper.isEnabled = hiDPIEnabled
        
        updateScaleFactorLabel()
        updateBandwidthDisplay()
        
        print("🖥️ 已应用显示器配置 - 分辨率: \(display.width)×\(display.height), HiDPI: \(display.isHiDPI), 实际缩放: \(actualScaleFactor)")
    }
    
    private func updateBandwidthDisplay() {
        // 简化界面中没有带宽显示标签，直接返回
        return
    }
    
    // MARK: - 辅助方法
    private func detectCurrentDisplay() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let displayConfig = try self?.displayDetector.detectPrimaryDisplay(useLogicalResolution: true)
                
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
        let isCustom = sender.indexOfSelectedItem == 3 // "自定义分辨率"是第4个选项
        
        // 显示/隐藏自定义分辨率输入区域
        if let manualSetPanel = view.subviews.first(where: { $0.identifier?.rawValue == "manualSetPanel" }),
           let customResolutionPanel = manualSetPanel.subviews.first(where: { $0.identifier?.rawValue == "customResolutionPanel" }) {
            customResolutionPanel.isHidden = !isCustom
        }
        
        // 启用/禁用自定义分辨率输入框
        if isCustom {
            customWidthField?.isEnabled = true
            customHeightField?.isEnabled = true
            // 设置默认值（如果为空）
            if customWidthField?.stringValue.isEmpty == true {
                customWidthField?.stringValue = "1920"
            }
            if customHeightField?.stringValue.isEmpty == true {
                customHeightField?.stringValue = "1080"
            }
        } else {
            customWidthField?.isEnabled = false
            customHeightField?.isEnabled = false
            customWidthField?.stringValue = ""
            customHeightField?.stringValue = ""
        }
        
        settingsChanged()
        updateStatusLabel("分辨率设置已更改")
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
    
    @objc private func hiDPISettingChanged(_ sender: NSButton) {
        let isAutoDetectionEnabled = autoDetectionCheckbox.state == .on
        let isHiDPIEnabled = sender.state == .on
        
        // 只有在手动模式下才启用相关控件
        if !isAutoDetectionEnabled {
            scaleFactorSlider.isEnabled = isHiDPIEnabled
            customScaleFactorField.isEnabled = isHiDPIEnabled
            scaleFactorStepper.isEnabled = isHiDPIEnabled
        }
        
        if !isHiDPIEnabled {
            scaleFactorSlider.doubleValue = 1.0
            customScaleFactorField.doubleValue = 1.0
            scaleFactorStepper.doubleValue = 1.0
            updateScaleFactorLabel()
        }
        
        settingsChanged()
    }
    
    @objc private func scaleFactorChanged(_ sender: NSSlider) {
        // 同步滑块值到精确值输入框
        customScaleFactorField.doubleValue = sender.doubleValue
        scaleFactorStepper.doubleValue = sender.doubleValue
        
        updateScaleFactorLabel()
        settingsChanged()
    }
    
    @objc private func autoDetectionChanged(_ sender: NSButton) {
        let isAutoDetectionEnabled = sender.state == .on
        
        // 启用/禁用手动配置控件
        updateManualControlsState(!isAutoDetectionEnabled)
        
        // 如果启用自动检测，自动检测并应用显示器配置
        if isAutoDetectionEnabled {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                do {
                    let displayConfig = try self?.displayDetector.detectPrimaryDisplay(useLogicalResolution: true)
                    
                    DispatchQueue.main.async {
                        if let config = displayConfig {
                            self?.applyDisplayConfiguration(config)
                            self?.settingsChanged()
                            self?.updateStatusLabel("✅ 已自动检测并应用显示器配置")
                        } else {
                            self?.updateStatusLabel("⚠️ 自动检测失败，请手动配置")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self?.updateStatusLabel("❌ 显示器检测失败: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            updateStatusLabel("已切换到手动配置模式")
        }
        
        settingsChanged()
    }
    
    private func updateManualControlsState(_ enabled: Bool) {
        // 显示器选择相关控件
        displaySelectionPopup?.isEnabled = enabled
        refreshDisplaysButton?.isEnabled = enabled
        
        // 分辨率设置相关控件
        resolutionPopup?.isEnabled = enabled
        
        // 自定义分辨率控件（只有在手动模式且选择了自定义分辨率时才启用）
        let isCustomResolution = resolutionPopup?.indexOfSelectedItem == 3
        customWidthField?.isEnabled = enabled && isCustomResolution
        customHeightField?.isEnabled = enabled && isCustomResolution
        
        // HiDPI相关控件
        hiDPICheckbox?.isEnabled = enabled
        
        // 缩放因子控件
        let isHiDPIEnabled = hiDPICheckbox?.state == .on
        
        scaleFactorSlider?.isEnabled = enabled && isHiDPIEnabled
        customScaleFactorField?.isEnabled = enabled && isHiDPIEnabled
        scaleFactorStepper?.isEnabled = enabled && isHiDPIEnabled
        
        // 更新界面视觉反馈
        displayInfoPanel?.alphaValue = enabled ? 1.0 : 0.6
        
        // 如果禁用手动控件，清空显示器选择
        if !enabled {
            displaySelectionPopup?.selectItem(at: 0) // 选择"请选择显示器..."
            selectedDisplayIndex = -1
            clearDisplayInfo()
        }
    }
    

    

    
    @objc private func applyRecommendedSettings(_ sender: NSButton) {
        do {
            let displayConfig = try displayDetector.detectPrimaryDisplay(useLogicalResolution: true)
            applyDisplayConfiguration(displayConfig)
            updateStatusLabel("已应用推荐设置")
        } catch {
            updateStatusLabel("无法检测显示器配置")
            showAlert("检测失败", message: error.localizedDescription)
        }
    }
    
    private func updateScaleFactorLabel() {
        // 简化界面中没有缩放因子标签，直接返回
        return
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
        // 安全检查：确保关键控件已初始化
        guard let profileSegmentedControl = profileSegmentedControl,
              let colorDepthPopup = colorDepthPopup,
              let audioQualityPopup = audioQualityPopup,
              let resolutionPopup = resolutionPopup,
              let autoDetectRadio = autoDetectRadio,
              let hiDPICheckbox = hiDPICheckbox,
              let fontSmoothingCheckbox = fontSmoothingCheckbox,
              let wallpaperCheckbox = wallpaperCheckbox,
              let smartSizingCheckbox = smartSizingCheckbox,
              let screenModePopup = screenModePopup else {
            print("⚠️ 警告：UI控件尚未完全初始化，返回默认设置")
            return settingsManager.currentSettings
        }
        
        let profiles = ["性能优先", "平衡模式", "质量优先"]
        let profileName = profiles[profileSegmentedControl.selectedSegment]
        
        let colorDepths = [16, 24, 32]
        let colorDepth = colorDepths[colorDepthPopup.indexOfSelectedItem]
        
        let audioQualities = ["禁用", "低质量", "中等", "高质量"]
        let audioQuality = audioQualities[audioQualityPopup.indexOfSelectedItem]
        
        // 获取分辨率设置
        let resolution: ResolutionSettings
        if resolutionPopup.indexOfSelectedItem == 3 { // 自定义分辨率
            let width = Int(customWidthField?.stringValue ?? "1920") ?? 1920
            let height = Int(customHeightField?.stringValue ?? "1080") ?? 1080
            resolution = ResolutionSettings(width: width, height: height, isCustom: true)
        } else {
            let presets = ResolutionSettings.presets
            if resolutionPopup.indexOfSelectedItem < presets.count {
                resolution = presets[resolutionPopup.indexOfSelectedItem]
            } else {
                resolution = ResolutionSettings.fullHD
            }
        }
        
        // 获取HiDPI设置（简化版本）
        let hiDPI = HiDPISettings(
            enabled: hiDPICheckbox.state == .on,
            scaleFactor: 1.5, // 默认缩放因子
            autoDetect: autoDetectRadio.state == .on,
            forceHiDPI: false
        )
        
        return RDPSettings(
            profileName: profileName,
            compressionLevel: 1, // 默认中等压缩
            colorDepth: colorDepth,
            audioQuality: audioQuality,
            enableFontSmoothing: fontSmoothingCheckbox.state == .on,
            enableWallpaper: wallpaperCheckbox.state == .on,
            enableMenuAnimations: false, // 简化界面中没有这个选项
            enableThemes: false, // 简化界面中没有这个选项
            resolution: resolution,
            hiDPI: hiDPI,
            useAutoDetection: autoDetectRadio.state == .on,
            enableSmartSizing: smartSizingCheckbox.state == .on,
            screenModeId: screenModePopup.indexOfSelectedItem + 1, // 1=窗口, 2=全屏
            enableAutoResize: false, // 简化界面中没有这个选项
            enableDesktopComposition: false, // 简化界面中没有这个选项
            enableRemoteFX: false // 简化界面中没有这个选项
        )
    }
    
    private func updateUIWithSettings(_ settings: RDPSettings) {
        // 安全检查：确保关键控件已初始化
        guard let profileSegmentedControl = profileSegmentedControl,
              let resolutionPopup = resolutionPopup,
              let autoDetectRadio = autoDetectRadio,
              let manualSetRadio = manualSetRadio else {
            print("⚠️ 警告：UI控件尚未完全初始化，跳过设置更新")
            return
        }
        
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
        hiDPICheckbox?.state = settings.hiDPI.enabled ? .on : .off
        
        // 更新分辨率模式选择
        autoDetectRadio.state = settings.useAutoDetection ? .on : .off
        manualSetRadio.state = settings.useAutoDetection ? .off : .on
        showResolutionModeArea(autoDetect: settings.useAutoDetection)
        
        // 更新颜色深度
        let colorDepths = [16, 24, 32]
        if let index = colorDepths.firstIndex(of: settings.colorDepth) {
            colorDepthPopup?.selectItem(at: index)
        }
        
        // 更新音频质量
        let audioQualities = ["禁用", "低质量", "中等", "高质量"]
        if let index = audioQualities.firstIndex(of: settings.audioQuality) {
            audioQualityPopup?.selectItem(at: index)
        }
        
        // 更新特效选项
        fontSmoothingCheckbox?.state = settings.enableFontSmoothing ? .on : .off
        wallpaperCheckbox?.state = settings.enableWallpaper ? .on : .off
        
        // 更新高级显示设置
        smartSizingCheckbox?.state = settings.enableSmartSizing ? .on : .off
        screenModePopup?.selectItem(at: settings.screenModeId - 1) // 1=窗口, 2=全屏
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
    
    @objc private func qualityControlChanged(_ sender: NSControl) {
        settingsChanged()
        updateStatusLabel("质量设置已更改")
    }
    
    @objc private func effectControlChanged(_ sender: NSButton) {
        settingsChanged()
        updateStatusLabel("特效设置已更改")
    }
    
    @objc private func advancedControlChanged(_ sender: NSControl) {
        settingsChanged()
        updateStatusLabel("高级显示设置已更改")
    }
    
    @objc private func displayModeChanged(_ sender: NSButton) {
        // 实现二选一逻辑
        if sender.tag == 1000 { // 自动检测
            if sender.state == .on {
                // 启用自动检测，禁用手动模式
                if let manualCheckbox = view.viewWithTag(1001) as? NSButton {
                    manualCheckbox.state = .off
                }
                showAutoDetectionControls(true)
                showManualDisplayControls(false)
                updateStatusLabel("已切换到自动检测模式")
            }
        } else if sender.tag == 1001 { // 手动模式
            if sender.state == .on {
                // 启用手动模式，禁用自动检测
                if let autoCheckbox = view.viewWithTag(1000) as? NSButton {
                    autoCheckbox.state = .off
                }
                showAutoDetectionControls(false)
                showManualDisplayControls(true)
                updateStatusLabel("已切换到手动设置模式")
            }
        }
        
        // 确保至少有一个选项被选中
        let autoCheckbox = view.viewWithTag(1000) as? NSButton
        let manualCheckbox = view.viewWithTag(1001) as? NSButton
        
        if autoCheckbox?.state == .off && manualCheckbox?.state == .off {
            // 如果都没选中，默认选中自动检测
            autoCheckbox?.state = .on
            showAutoDetectionControls(true)
            showManualDisplayControls(false)
        }
        
        settingsChanged()
    }
    
    @objc private func resolutionModeChanged(_ sender: NSButton) {
        // 实现单选按钮互斥逻辑
        if sender.tag == 1000 { // 自动检测
            manualSetRadio.state = .off
            showResolutionModeArea(autoDetect: true)
            updateStatusLabel("已切换到自动检测分辨率模式")
        } else if sender.tag == 1001 { // 手动设置
            autoDetectRadio.state = .off
            showResolutionModeArea(autoDetect: false)
            updateStatusLabel("已切换到手动设置分辨率模式")
        }
        
        settingsChanged()
    }
    
    private func showResolutionModeArea(autoDetect: Bool) {
        // 显示/隐藏分辨率模式相关区域
        if let autoDetectPanel = view.subviews.first(where: { $0.identifier?.rawValue == "autoDetectPanel" }) {
            autoDetectPanel.isHidden = !autoDetect
        }
        
        if let manualSetPanel = view.subviews.first(where: { $0.identifier?.rawValue == "manualSetPanel" }) {
            manualSetPanel.isHidden = autoDetect
        }
    }
    
    private func showAutoDetectionControls(_ show: Bool) {
        // 显示/隐藏自动检测相关控件
        view.subviews.forEach { subview in
            if let identifier = subview.identifier?.rawValue,
               identifier.hasPrefix("autoDetection") {
                subview.isHidden = !show
            }
        }
    }
    
    private func showManualDisplayControls(_ show: Bool) {
        // 显示/隐藏手动显示器选择相关控件
        view.subviews.forEach { subview in
            if let identifier = subview.identifier?.rawValue,
               identifier.hasPrefix("manualDisplay") {
                subview.isHidden = !show
            }
        }
        
        // 特别处理主要控件
        displaySelectionPopup?.isHidden = !show
        refreshDisplaysButton?.isHidden = !show
        displayInfoPanel?.isHidden = !show
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
