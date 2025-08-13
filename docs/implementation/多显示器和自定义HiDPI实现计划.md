# 多显示器支持和自定义HiDPI缩放因子实现计划

## 📋 需求概述

根据更新的需求文档，需要实现以下核心功能：

1. **多显示器支持** - 检测、选择和配置多个显示器
2. **自定义HiDPI缩放因子** - 支持精确到0.01的小数值输入
3. **智能配置建议** - 根据显示器类型自动推荐最佳设置
4. **实时预览** - 显示配置变更的即时效果

## 🎯 实现目标

### 核心功能
- ✅ 检测所有连接的显示器
- ✅ 显示器选择下拉菜单
- ✅ 自动应用选定显示器的配置
- ✅ 自定义缩放因子输入（0.50-5.00，精度0.01）
- ✅ 智能配置推荐系统
- ✅ 实时预览和验证

### 用户体验
- ✅ 直观的多显示器界面
- ✅ 智能默认值和建议
- ✅ 实时反馈和验证
- ✅ 友好的错误提示

## 🏗️ 技术架构

### 1. 数据模型扩展

#### DisplayConfiguration 增强
```swift
public struct DisplayConfiguration {
    // 现有属性
    public let width: Int
    public let height: Int
    public let scaleFactor: Double
    public let colorDepth: Int
    public let isHiDPI: Bool
    public let refreshRate: Double
    public let displayID: CGDirectDisplayID
    
    // 新增属性
    public let displayName: String          // 显示器名称
    public let isBuiltIn: Bool             // 是否内置显示器
    public let physicalSize: CGSize        // 物理尺寸（毫米）
    public let dpi: Double                 // DPI值
    public let recommendedScaleFactor: Double // 推荐缩放因子
    public let displayType: DisplayType    // 显示器类型
}

public enum DisplayType {
    case builtInRetina      // 内置Retina显示器
    case external4K         // 外接4K显示器
    case externalHD         // 外接HD显示器
    case ultraWide          // 超宽显示器
    case unknown            // 未知类型
}
```

#### HiDPISettings 增强
```swift
public struct HiDPISettings {
    public var enabled: Bool
    public var scaleFactor: Double         // 支持精确小数值
    public var isCustom: Bool              // 是否自定义缩放
    public var presetName: String?         // 预设名称（如果使用预设）
    
    // 新增验证和格式化方法
    public var isValidScaleFactor: Bool
    public var scaleFactorPercentage: Int
    public var displayDescription: String
}
```

### 2. 显示器管理服务

#### MultiDisplayManager
```swift
public class MultiDisplayManager {
    // 显示器检测和管理
    public func detectAllDisplays() throws -> [DisplayConfiguration]
    public func getDisplayName(for displayID: CGDirectDisplayID) -> String
    public func isBuiltInDisplay(_ displayID: CGDirectDisplayID) -> Bool
    public func getDisplayType(for config: DisplayConfiguration) -> DisplayType
    
    // 配置推荐
    public func getRecommendedSettings(for display: DisplayConfiguration) -> RDPSettings
    public func getRecommendedScaleFactor(for display: DisplayConfiguration) -> Double
    
    // 显示器变更监听
    public func startMonitoringDisplayChanges()
    public func stopMonitoringDisplayChanges()
}
```

#### ScaleFactorValidator
```swift
public class ScaleFactorValidator {
    public static let minScaleFactor: Double = 0.50
    public static let maxScaleFactor: Double = 5.00
    public static let precision: Double = 0.01
    
    public static func isValid(_ scaleFactor: Double) -> Bool
    public static func clamp(_ scaleFactor: Double) -> Double
    public static func round(_ scaleFactor: Double) -> Double
    public static func getRecommendation(for dpi: Double) -> Double
}
```

### 3. 用户界面组件

#### 新增UI组件
```swift
// 显示器选择下拉菜单
private var displaySelectionPopup: NSPopUpButton!

// 自定义缩放因子输入
private var customScaleFactorField: NSTextField!
private var scaleFactorStepper: NSStepper!
private var scaleFactorPreview: NSTextField!

// 显示器信息面板
private var displayInfoPanel: NSView!
private var displayNameLabel: NSTextField!
private var displaySpecsLabel: NSTextField!
private var recommendationLabel: NSTextField!

// 刷新按钮
private var refreshDisplaysButton: NSButton!
```

#### 界面布局调整
```
┌─────────────────────────────────────────────────────┐
│ RDP设置界面 (扩展为 520px 宽度)                      │
├─────────────────────────────────────────────────────┤
│ 📱 质量配置文件选择                                  │
├─────────────────────────────────────────────────────┤
│ 🖥️ 显示器选择                                       │
│   [显示器1 - 内置Retina (3024×1964)] [刷新]         │
├─────────────────────────────────────────────────────┤
│ 📏 分辨率设置                                        │
│   [2560×1440 (2K)] [自动检测]                       │
│   自定义: [宽度] × [高度]                            │
├─────────────────────────────────────────────────────┤
│ 🔍 HiDPI/缩放设置                                   │
│   ☑️ 启用HiDPI优化                                  │
│   预设: [200% (2.0x)] 自定义: [2.24] [±]            │
│   预览: 125% = 1.25x (推荐用于高DPI显示器)          │
├─────────────────────────────────────────────────────┤
│ ⚙️ 其他设置...                                      │
└─────────────────────────────────────────────────────┘
```

## 🔧 实现步骤

### Phase 1: 数据模型和核心服务 (1-2天)

1. **扩展DisplayConfiguration结构体**
   - 添加显示器名称、类型、DPI等属性
   - 实现显示器类型检测逻辑
   - 添加推荐配置计算方法

2. **创建MultiDisplayManager服务**
   - 实现多显示器检测
   - 添加显示器名称获取
   - 实现显示器类型识别

3. **创建ScaleFactorValidator**
   - 实现缩放因子验证逻辑
   - 添加智能推荐算法
   - 实现精度控制

### Phase 2: 用户界面实现 (2-3天)

1. **添加显示器选择组件**
   - 显示器下拉菜单
   - 显示器信息显示
   - 刷新按钮

2. **实现自定义缩放因子输入**
   - 数值输入框
   - 步进器控件
   - 实时预览标签

3. **界面布局调整**
   - 扩展窗口宽度
   - 重新排列组件
   - 优化视觉层次

### Phase 3: 交互逻辑实现 (2-3天)

1. **显示器选择逻辑**
   - 选择变更事件处理
   - 自动配置应用
   - 推荐设置更新

2. **缩放因子输入逻辑**
   - 实时验证
   - 格式化显示
   - 错误提示

3. **智能推荐系统**
   - 根据显示器类型推荐
   - DPI基础推荐
   - 用户偏好学习

### Phase 4: 测试和优化 (1-2天)

1. **功能测试**
   - 多显示器环境测试
   - 缩放因子精度测试
   - 边界条件测试

2. **用户体验优化**
   - 响应速度优化
   - 错误提示改进
   - 界面流畅性提升

## 📊 技术细节

### 显示器检测增强

```swift
extension DisplayDetector {
    public func detectDisplayWithDetails(displayID: CGDirectDisplayID) throws -> DisplayConfiguration {
        // 获取基本信息
        let (width, height, scaleFactor, isHiDPI) = try getPhysicalResolutionAndScale(displayID: displayID)
        
        // 获取显示器名称
        let displayName = getDisplayName(displayID)
        
        // 检测显示器类型
        let displayType = determineDisplayType(displayID: displayID, width: width, height: height)
        
        // 计算推荐缩放因子
        let recommendedScale = calculateRecommendedScaleFactor(
            displayType: displayType,
            dpi: calculateDPI(displayID),
            physicalSize: CGDisplayScreenSize(displayID)
        )
        
        return DisplayConfiguration(
            width: width,
            height: height,
            scaleFactor: scaleFactor,
            colorDepth: detectColorDepth(displayID: displayID),
            isHiDPI: isHiDPI,
            refreshRate: getRefreshRate(displayID: displayID),
            displayID: displayID,
            displayName: displayName,
            isBuiltIn: isBuiltInDisplay(displayID),
            physicalSize: CGDisplayScreenSize(displayID),
            dpi: calculateDPI(displayID),
            recommendedScaleFactor: recommendedScale,
            displayType: displayType
        )
    }
}
```

### 缩放因子验证

```swift
extension ScaleFactorValidator {
    public static func validateAndFormat(_ input: String) -> (isValid: Bool, value: Double?, error: String?) {
        guard let value = Double(input) else {
            return (false, nil, "请输入有效的数值")
        }
        
        guard value >= minScaleFactor && value <= maxScaleFactor else {
            return (false, nil, "缩放因子必须在 \(minScaleFactor) 到 \(maxScaleFactor) 之间")
        }
        
        let roundedValue = round(value / precision) * precision
        return (true, roundedValue, nil)
    }
    
    public static func getRecommendationText(for dpi: Double) -> String {
        let recommended = getRecommendation(for: dpi)
        switch dpi {
        case ..<120:
            return "推荐 \(recommended)x - 适合标准DPI显示器"
        case 120..<150:
            return "推荐 \(recommended)x - 适合中等DPI显示器"
        case 150..<200:
            return "推荐 \(recommended)x - 适合高DPI显示器"
        default:
            return "推荐 \(recommended)x - 适合超高DPI显示器"
        }
    }
}
```

## 🧪 测试计划

### 单元测试
- MultiDisplayManager 功能测试
- ScaleFactorValidator 验证测试
- DisplayConfiguration 扩展测试

### 集成测试
- 多显示器环境测试
- 显示器切换测试
- 缩放因子应用测试

### 用户体验测试
- 界面响应性测试
- 错误处理测试
- 边界条件测试

## 📈 性能目标

- 显示器检测时间: < 50ms
- 界面响应时间: < 100ms
- 缩放因子验证: < 1ms
- 内存使用增长: < 2MB

## 🎯 验收标准

### 功能完整性
- ✅ 支持检测和选择多个显示器
- ✅ 支持0.50-5.00范围的自定义缩放因子
- ✅ 提供智能配置推荐
- ✅ 实时预览和验证

### 用户体验
- ✅ 直观的多显示器选择界面
- ✅ 清晰的缩放因子输入和预览
- ✅ 友好的错误提示和建议
- ✅ 流畅的交互响应

### 技术质量
- ✅ 代码覆盖率 > 90%
- ✅ 性能指标达标
- ✅ 错误处理完善
- ✅ 兼容性良好

这个实现计划确保了新需求的完整实现，同时保持了代码质量和用户体验的高标准。
