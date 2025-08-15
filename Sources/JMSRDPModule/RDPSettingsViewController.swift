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
    
    // 新增：自定义缩放因子组件
    private var customScaleFactorField: NSTextField!
    private var scaleFactorStepper: NSStepper!
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
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 580))  // 增加宽度和高度以适应更好的布局
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        setupUI()
        loadCurrentSettings()
        
        print("✅ RDP设置界面加载完成")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        updateStatusLabel("就绪")
        
        // 初始化控件状态 - 根据autoDetectionCheckbox的状态决定
        let isAutoDetectionEnabled = autoDetectionCheckbox.state == .on
        updateManualControlsState(!isAutoDetectionEnabled)
        
        logInfo("📱 RDP设置界面已加载，自动检测模式: \(isAutoDetectionEnabled)")
        
        // 选中'自动检测显示器'时，不能改变'预设分辨率'的选项值及自定义宽高的值
        // 移除自动应用显示器配置的逻辑，只设置界面状态
        if isAutoDetectionEnabled {
            updateStatusLabel("✅ 自动检测显示器模式已启用")
        }
        // 手动模式下不再需要刷新显示器列表
    }
    
    // MARK: - UI设置
    private func setupUI() {
        setupTitleAndProfile()
        setupAutoDetectionControls()  // 将自动检测放到第一行
        setupResolutionControls()
        setupHiDPIControls()
        setupCompressionControls()
        setupQualityControls()
        setupEffectControls()
        setupActionButtons()
    }
    
    private func setupTitleAndProfile() {
        // 标题
        let titleLabel = NSTextField(labelWithString: "RDP连接设置")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.frame = NSRect(x: 20, y: 540, width: 200, height: 25)  // 调整到顶部，增加高度
        view.addSubview(titleLabel)
        
        // 配置文件选择
        let profileLabel = NSTextField(labelWithString: "质量配置:")
        profileLabel.frame = NSRect(x: 320, y: 540, width: 80, height: 20)  // 右侧对齐
        view.addSubview(profileLabel)
        
        profileSegmentedControl = NSSegmentedControl()
        profileSegmentedControl.segmentCount = 3
        profileSegmentedControl.setLabel("性能", forSegment: 0)
        profileSegmentedControl.setLabel("平衡", forSegment: 1)
        profileSegmentedControl.setLabel("质量", forSegment: 2)
        profileSegmentedControl.selectedSegment = 1
        profileSegmentedControl.target = self
        profileSegmentedControl.action = #selector(profileChanged(_:))
        profileSegmentedControl.frame = NSRect(x: 410, y: 540, width: 170, height: 25)  // 调整位置和大小
        view.addSubview(profileSegmentedControl)
    }
    
    private func setupAutoDetectionControls() {
        // 自动检测选项 - 增加分组间隙
        autoDetectionCheckbox = NSButton(checkboxWithTitle: "自动检测显示器配置", target: self, action: #selector(autoDetectionChanged(_:)))
        autoDetectionCheckbox.frame = NSRect(x: 30, y: 500, width: 200, height: 20)  // 增加左边距和合理间隙
        autoDetectionCheckbox.state = .on  // 默认启用
        view.addSubview(autoDetectionCheckbox)
    }
    

    
    private func setupResolutionControls() {
        // 分辨率设置区域标题 - 增加分组标识
        let resolutionSectionLabel = NSTextField(labelWithString: "分辨率设置")
        resolutionSectionLabel.font = NSFont.boldSystemFont(ofSize: 14)
        resolutionSectionLabel.frame = NSRect(x: 20, y: 460, width: 120, height: 20)  // 调整位置和宽度
        view.addSubview(resolutionSectionLabel)
        
        // 分辨率选择 - 增加左边距形成分组
        let resolutionLabel = NSTextField(labelWithString: "分辨率:")
        resolutionLabel.frame = NSRect(x: 30, y: 430, width: 80, height: 20)  // 增加左边距，调整位置
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
        resolutionPopup.frame = NSRect(x: 120, y: 430, width: 180, height: 25)  // 调整位置
        view.addSubview(resolutionPopup)
        
        // 自定义分辨率输入框 - 保持在右侧，默认隐藏
        customWidthField = NSTextField()
        customWidthField.placeholderString = "宽度"
        customWidthField.target = self
        customWidthField.action = #selector(customResolutionChanged(_:))
        customWidthField.frame = NSRect(x: 320, y: 430, width: 80, height: 25)  // 调整位置
        customWidthField.isEnabled = false
        customWidthField.isHidden = true  // 默认隐藏
        view.addSubview(customWidthField)
        
        customHeightField = NSTextField()
        customHeightField.placeholderString = "高度"
        customHeightField.target = self
        customHeightField.action = #selector(customResolutionChanged(_:))
        customHeightField.frame = NSRect(x: 420, y: 430, width: 80, height: 25)  // 调整位置
        customHeightField.isEnabled = false
        customHeightField.isHidden = true  // 默认隐藏
        view.addSubview(customHeightField)
    }
    
    private func setupHiDPIControls() {
        // HiDPI设置区域标题 - 增加分组间隙
        let hiDPISectionLabel = NSTextField(labelWithString: "显示优化")
        hiDPISectionLabel.font = NSFont.boldSystemFont(ofSize: 14)
        hiDPISectionLabel.frame = NSRect(x: 20, y: 380, width: 120, height: 20)  // 调整位置和标题
        view.addSubview(hiDPISectionLabel)
        
        // HiDPI启用选项 - 增加左边距形成分组
        hiDPICheckbox = NSButton(checkboxWithTitle: "启用HiDPI优化", target: self, action: #selector(hiDPISettingChanged(_:)))
        hiDPICheckbox.frame = NSRect(x: 30, y: 350, width: 150, height: 20)  // 增加左边距，调整位置
        hiDPICheckbox.state = .off
        view.addSubview(hiDPICheckbox)
        
        // 缩放因子设置 - 保持分组内的合理间隙
        let scaleLabel = NSTextField(labelWithString: "缩放因子:")
        scaleLabel.frame = NSRect(x: 30, y: 320, width: 80, height: 20)  // 增加左边距，调整位置
        view.addSubview(scaleLabel)
        
        scaleFactorSlider = NSSlider()
        scaleFactorSlider.minValue = 1.0
        scaleFactorSlider.maxValue = 3.0
        scaleFactorSlider.doubleValue = 1.0
        scaleFactorSlider.numberOfTickMarks = 9
        scaleFactorSlider.allowsTickMarkValuesOnly = false
        scaleFactorSlider.target = self
        scaleFactorSlider.action = #selector(scaleFactorChanged(_:))
        scaleFactorSlider.frame = NSRect(x: 120, y: 320, width: 150, height: 25)  // 调整位置
        view.addSubview(scaleFactorSlider)
        
        // 精确值输入框放在滑块右侧
        customScaleFactorField = NSTextField()
        customScaleFactorField.placeholderString = "1.00"
        customScaleFactorField.target = self
        customScaleFactorField.action = #selector(customScaleFactorChanged(_:))
        customScaleFactorField.frame = NSRect(x: 280, y: 320, width: 60, height: 25)  // 调整位置
        customScaleFactorField.stringValue = "1.00"
        view.addSubview(customScaleFactorField)
        
        // 缩放因子步进器紧挨着输入框
        scaleFactorStepper = NSStepper()
        scaleFactorStepper.minValue = 0.50
        scaleFactorStepper.maxValue = 5.00
        scaleFactorStepper.increment = 0.01
        scaleFactorStepper.doubleValue = 1.00
        scaleFactorStepper.target = self
        scaleFactorStepper.action = #selector(scaleFactorStepperChanged(_:))
        scaleFactorStepper.frame = NSRect(x: 345, y: 320, width: 20, height: 25)  // 调整位置
        view.addSubview(scaleFactorStepper)
        
        scaleFactorLabel = NSTextField(labelWithString: "100% (1.0x)")
        scaleFactorLabel.frame = NSRect(x: 375, y: 320, width: 100, height: 20)  // 调整位置
        view.addSubview(scaleFactorLabel)
    }
    
    private func setupCompressionControls() {
        // 性能设置区域标题 - 增加新的分组
        let performanceSectionLabel = NSTextField(labelWithString: "性能设置")
        performanceSectionLabel.font = NSFont.boldSystemFont(ofSize: 14)
        performanceSectionLabel.frame = NSRect(x: 20, y: 280, width: 120, height: 20)
        view.addSubview(performanceSectionLabel)
        
        // 压缩级别 - 增加左边距形成分组
        let compressionLabel = NSTextField(labelWithString: "压缩级别:")
        compressionLabel.frame = NSRect(x: 30, y: 250, width: 80, height: 20)  // 增加左边距，调整位置
        view.addSubview(compressionLabel)
        
        compressionSlider = NSSlider()
        compressionSlider.minValue = 0
        compressionSlider.maxValue = 2
        compressionSlider.doubleValue = 1
        compressionSlider.numberOfTickMarks = 3
        compressionSlider.allowsTickMarkValuesOnly = true
        compressionSlider.target = self
        compressionSlider.action = #selector(compressionChanged(_:))
        compressionSlider.frame = NSRect(x: 120, y: 250, width: 150, height: 25)  // 调整位置
        view.addSubview(compressionSlider)
        
        compressionValueLabel = NSTextField(labelWithString: "中等")
        compressionValueLabel.frame = NSRect(x: 280, y: 250, width: 80, height: 20)  // 调整位置
        view.addSubview(compressionValueLabel)
    }
    
    private func setupQualityControls() {
        // 质量设置区域标题 - 增加新的分组
        let qualitySectionLabel = NSTextField(labelWithString: "质量设置")
        qualitySectionLabel.font = NSFont.boldSystemFont(ofSize: 14)
        qualitySectionLabel.frame = NSRect(x: 20, y: 210, width: 120, height: 20)
        view.addSubview(qualitySectionLabel)
        
        // 颜色深度 - 增加左边距形成分组
        let colorDepthLabel = NSTextField(labelWithString: "颜色深度:")
        colorDepthLabel.frame = NSRect(x: 30, y: 180, width: 80, height: 20)  // 增加左边距，调整位置
        view.addSubview(colorDepthLabel)
        
        colorDepthPopup = NSPopUpButton()
        colorDepthPopup.addItems(withTitles: ["16位", "24位", "32位"])
        colorDepthPopup.selectItem(at: 1)
        colorDepthPopup.target = self
        colorDepthPopup.action = #selector(qualityControlChanged(_:))
        colorDepthPopup.frame = NSRect(x: 120, y: 180, width: 100, height: 25)  // 调整位置
        view.addSubview(colorDepthPopup)
        
        // 音频质量 - 同行显示
        let audioLabel = NSTextField(labelWithString: "音频质量:")
        audioLabel.frame = NSRect(x: 250, y: 180, width: 80, height: 20)  // 调整位置
        view.addSubview(audioLabel)
        
        audioQualityPopup = NSPopUpButton()
        audioQualityPopup.addItems(withTitles: ["禁用", "低质量", "中等", "高质量"])
        audioQualityPopup.selectItem(at: 2)
        audioQualityPopup.target = self
        audioQualityPopup.action = #selector(qualityControlChanged(_:))
        audioQualityPopup.frame = NSRect(x: 340, y: 180, width: 100, height: 25)  // 调整位置
        view.addSubview(audioQualityPopup)
    }
    
    private func setupEffectControls() {
        // 视觉效果区域标题 - 增加新的分组
        let effectsSectionLabel = NSTextField(labelWithString: "视觉效果")
        effectsSectionLabel.font = NSFont.boldSystemFont(ofSize: 14)
        effectsSectionLabel.frame = NSRect(x: 20, y: 140, width: 120, height: 20)
        view.addSubview(effectsSectionLabel)
        
        // 特效选项 - 增加左边距形成分组，合理排列
        fontSmoothingCheckbox = NSButton(checkboxWithTitle: "字体平滑", target: self, action: #selector(effectControlChanged(_:)))
        fontSmoothingCheckbox.frame = NSRect(x: 30, y: 110, width: 100, height: 20)  // 增加左边距，调整位置
        fontSmoothingCheckbox.state = .on
        view.addSubview(fontSmoothingCheckbox)
        
        wallpaperCheckbox = NSButton(checkboxWithTitle: "桌面壁纸", target: self, action: #selector(effectControlChanged(_:)))
        wallpaperCheckbox.frame = NSRect(x: 150, y: 110, width: 100, height: 20)  // 同行排列
        wallpaperCheckbox.state = .on
        view.addSubview(wallpaperCheckbox)
        
        animationsCheckbox = NSButton(checkboxWithTitle: "菜单动画", target: self, action: #selector(effectControlChanged(_:)))
        animationsCheckbox.frame = NSRect(x: 270, y: 110, width: 100, height: 20)  // 同行排列
        animationsCheckbox.state = .off
        view.addSubview(animationsCheckbox)
        
        themesCheckbox = NSButton(checkboxWithTitle: "视觉主题", target: self, action: #selector(effectControlChanged(_:)))
        themesCheckbox.frame = NSRect(x: 390, y: 110, width: 100, height: 20)  // 同行排列
        themesCheckbox.state = .on
        view.addSubview(themesCheckbox)
    }
    
    private func setupActionButtons() {
        // 操作按钮 - 底部居中排列，增加合理间隙
        let saveButton = NSButton(title: "保存设置", target: self, action: #selector(saveSettings(_:)))
        saveButton.bezelStyle = .rounded
        saveButton.frame = NSRect(x: 60, y: 60, width: 100, height: 30)  // 调整位置
        view.addSubview(saveButton)
        
        let resetButton = NSButton(title: "重置默认", target: self, action: #selector(resetSettings(_:)))
        resetButton.bezelStyle = .rounded
        resetButton.frame = NSRect(x: 180, y: 60, width: 100, height: 30)  // 调整位置
        view.addSubview(resetButton)
        
        let exportButton = NSButton(title: "导出设置", target: self, action: #selector(exportSettings(_:)))
        exportButton.bezelStyle = .rounded
        exportButton.frame = NSRect(x: 300, y: 60, width: 100, height: 30)  // 调整位置
        view.addSubview(exportButton)
        
        let importButton = NSButton(title: "导入设置", target: self, action: #selector(importSettings(_:)))
        importButton.bezelStyle = .rounded
        importButton.frame = NSRect(x: 420, y: 60, width: 100, height: 30)  // 调整位置
        view.addSubview(importButton)
        
        // 状态标签 - 底部显示
        statusLabel = NSTextField(labelWithString: "状态: 就绪")
        statusLabel.frame = NSRect(x: 20, y: 20, width: 560, height: 20)  // 调整到底部
        statusLabel.textColor = NSColor.secondaryLabelColor
        view.addSubview(statusLabel)
    }
    
    // MARK: - 新的事件处理方法
    
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
    
    // MARK: - 显示器信息处理
    
    private func getDisplayName(for display: DisplayConfiguration) -> String {
        let displayNumber = allDisplays.firstIndex(where: { $0.displayID == display.displayID }) ?? 0
        let isMain = display.displayID == CGMainDisplayID()
        let mainIndicator = isMain ? " (主显示器)" : ""
        let hiDPIIndicator = display.isHiDPI ? " HiDPI" : ""
        
        return "显示器\(displayNumber + 1)\(mainIndicator) - \(display.width)×\(display.height)\(hiDPIIndicator)"
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
        
        // 显示自定义分辨率输入框（因为选择了自定义分辨率）
        customWidthField.isHidden = false
        customHeightField.isHidden = false
        
        // 根据自动检测状态决定是否启用输入框
        let isAutoDetectionEnabled = autoDetectionCheckbox.state == .on
        if isAutoDetectionEnabled {
            // 自动检测模式：输入框保持只读
            customWidthField.isEnabled = false
            customHeightField.isEnabled = false
        } else {
            // 手动模式：可以编辑自定义分辨率
            customWidthField.isEnabled = true
            customHeightField.isEnabled = true
        }
        
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
        
        print("🖥️ 已应用显示器配置 - 分辨率: \(display.width)×\(display.height), HiDPI: \(display.isHiDPI), 实际缩放: \(actualScaleFactor)")
    }
    
    // MARK: - 辅助方法
    private func detectCurrentDisplay() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let displayConfig = try self?.displayDetector.detectPrimaryDisplay(useLogicalResolution: true)
                
                DispatchQueue.main.async {
                    if let config = displayConfig {
                        // 不再更新显示器信息UI，只记录日志
                        print("📺 检测到显示器: \(config.width)×\(config.height)")
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
        let isAutoDetectionEnabled = autoDetectionCheckbox.state == .on
        let isCustom = sender.indexOfSelectedItem == 3
        
        // 控制自定义分辨率输入框的显示/隐藏
        // 只有选中"自定义分辨率"时才显示
        customWidthField.isHidden = !isCustom
        customHeightField.isHidden = !isCustom
        
        if isAutoDetectionEnabled {
            // 自动检测模式：自定义分辨率的宽高始终只读
            customWidthField.isEnabled = false
            customHeightField.isEnabled = false
        } else {
            // 手动模式：只有选择了自定义分辨率时才可以编辑宽高
            customWidthField.isEnabled = isCustom
            customHeightField.isEnabled = isCustom
        }
        
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
    
    @objc private func hiDPISettingChanged(_ sender: NSButton) {
        let isHiDPIEnabled = sender.state == .on
        
        // 无论是否启用自动检测，HiDPI相关的缩放控件都应该根据HiDPI状态来启用/禁用
        scaleFactorSlider.isEnabled = isHiDPIEnabled
        customScaleFactorField.isEnabled = isHiDPIEnabled
        scaleFactorStepper.isEnabled = isHiDPIEnabled
        
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
        
        // 选中'自动检测显示器'时，不能改变'预设分辨率'的选项值及自定义宽高的值
        // 只更新状态标签，不自动应用显示器配置
        if isAutoDetectionEnabled {
            updateStatusLabel("✅ 已启用自动检测显示器模式")
        } else {
            updateStatusLabel("已切换到手动配置模式")
        }
        
        settingsChanged()
    }
    
    private func updateManualControlsState(_ enabled: Bool) {
        // enabled = true 表示手动模式（未选中自动检测）
        // enabled = false 表示自动检测模式（选中自动检测）
        
        // 分辨率设置相关控件
        // 手动模式：可以修改预设分辨率
        // 自动检测模式：预设分辨率只读
        resolutionPopup?.isEnabled = enabled
        
        // 自定义分辨率控件
        let isCustomResolution = resolutionPopup?.indexOfSelectedItem == 3
        if enabled {
            // 手动模式：可以修改自定义分辨率的值（如果选择了自定义分辨率）
            customWidthField?.isEnabled = isCustomResolution
            customHeightField?.isEnabled = isCustomResolution
        } else {
            // 自动检测模式：自定义分辨率的宽高改为只读
            customWidthField?.isEnabled = false
            customHeightField?.isEnabled = false
        }
        
        // HiDPI相关控件
        // 无论哪种模式都可以编辑HiDPI设置
        hiDPICheckbox?.isEnabled = true
        
        // 缩放因子控件
        let isHiDPIEnabled = hiDPICheckbox?.state == .on
        
        // 无论哪种模式，如果启用了HiDPI，都可以调整缩放因子
        scaleFactorSlider?.isEnabled = isHiDPIEnabled
        customScaleFactorField?.isEnabled = isHiDPIEnabled
        scaleFactorStepper?.isEnabled = isHiDPIEnabled
        
        // 如果禁用手动控件，重置相关状态
        if !enabled {
            selectedDisplayIndex = -1
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
        // 使用精确值输入框的值，如果为空则使用滑块的值
        let scaleFactor = customScaleFactorField.doubleValue > 0 ? customScaleFactorField.doubleValue : scaleFactorSlider.doubleValue
        let percentage = Int(scaleFactor * 100)
        scaleFactorLabel.stringValue = "\(percentage)% (\(String(format: "%.2f", scaleFactor))x)"
    }
    
    private func settingsChanged() {
        let currentSettings = getCurrentSettingsFromUI()
        settingsManager.updateSettings(currentSettings)
        delegate?.settingsDidChange(currentSettings)
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
            scaleFactor: getScaleFactorFromUI(),
            autoDetect: true, // 简化界面中默认启用自动检测
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
    
    /// 从UI获取缩放因子
    private func getScaleFactorFromUI() -> Double {
        // 在简化界面中，从缩放下拉菜单获取缩放因子
        if let scalePopup = view.subviews.compactMap({ $0 as? NSPopUpButton }).first(where: { popup in
            popup.itemTitles.contains("150%")
        }) {
            let scaleValues = [1.0, 1.25, 1.5, 2.0]
            let selectedIndex = scalePopup.indexOfSelectedItem
            if selectedIndex >= 0 && selectedIndex < scaleValues.count {
                return scaleValues[selectedIndex]
            }
        }
        
        // 如果找不到缩放控件，返回默认值
        return 1.5 // 默认150%缩放
    }
    
    /// 根据缩放因子更新缩放下拉菜单
    private func updateScalePopupFromSettings(_ scaleFactor: Double) {
        if let scalePopup = view.subviews.compactMap({ $0 as? NSPopUpButton }).first(where: { popup in
            popup.itemTitles.contains("150%")
        }) {
            let scaleValues = [1.0, 1.25, 1.5, 2.0]
            if let index = scaleValues.firstIndex(of: scaleFactor) {
                scalePopup.selectItem(at: index)
            } else {
                // 如果不是标准值，选择最接近的
                let closestIndex = scaleValues.enumerated().min { abs($0.element - scaleFactor) < abs($1.element - scaleFactor) }?.offset ?? 2
                scalePopup.selectItem(at: closestIndex)
            }
        }
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
            
            // 显示自定义分辨率输入框（因为选择了自定义分辨率）
            customWidthField.isHidden = false
            customHeightField.isHidden = false
            
            // 根据自动检测状态决定是否启用输入框
            let isAutoDetectionEnabled = autoDetectionCheckbox?.state == .on
            if isAutoDetectionEnabled == true {
                // 自动检测模式：输入框保持只读
                customWidthField.isEnabled = false
                customHeightField.isEnabled = false
            } else {
                // 手动模式：可以编辑自定义分辨率
                customWidthField.isEnabled = true
                customHeightField.isEnabled = true
            }
        } else {
            customWidthField.stringValue = ""
            customHeightField.stringValue = ""
            
            // 隐藏自定义分辨率输入框（因为选择了预设分辨率）
            customWidthField.isHidden = true
            customHeightField.isHidden = true
            
            customWidthField.isEnabled = false
            customHeightField.isEnabled = false
        }
        
        // 更新HiDPI设置
        hiDPICheckbox?.state = settings.hiDPI.enabled ? .on : .off
        
        // 更新缩放设置（在简化界面中通过缩放下拉菜单）
        updateScalePopupFromSettings(settings.hiDPI.scaleFactor)
        
        // 更新分辨率模式选择（简化界面中跳过）
        // 在简化界面中，分辨率模式通过其他方式处理
        
        // 更新压缩级别（简化界面中没有压缩滑块，跳过）
        // compressionSlider.doubleValue = Double(settings.compressionLevel)
        // updateCompressionLabel()
        
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
