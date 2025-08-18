# UI检查器使用指南

## 概述

UI检查器是一个通用的GUI界面调试工具模块，用于分析和诊断macOS应用程序的界面布局问题。它提供了详细的视图层级分析、布局问题检测和自动修复功能。

## 功能特性

### 🔍 核心功能

1. **视图层级分析**
   - 生成完整的视图组件层级树
   - 显示每个视图的详细属性信息
   - 支持递归分析所有子视图

2. **布局问题检测**
   - 自动检测常见的布局问题
   - 识别视图重叠、超出边界等问题
   - 分析空白区域和约束问题

3. **自动修复功能**
   - 修复零尺寸视图
   - 调整超出边界的视图
   - 提供智能修复建议

4. **实时监控**
   - 支持实时监控布局变化
   - 定期检测和报告问题
   - 适用于动态界面调试

## 模块结构

```
Sources/UIInspector/
├── UIInspector.swift          # 核心检查器
└── UILayoutDebugger.swift     # 布局调试工具
```

### UIInspector.swift
- 主要的UI检查器类
- 提供视图层级分析功能
- 生成详细的布局报告

### UILayoutDebugger.swift
- 专门的布局调试工具
- 提供问题诊断和自动修复
- 支持实时监控功能

## 使用方法

### 1. 基本使用

```swift
import UIInspector

// 检查视图层级
view.inspectLayout(title: "我的界面布局")

// 检查窗口布局
window.inspectLayout(title: "主窗口布局")
```

### 2. 详细诊断

```swift
// 使用布局调试工具进行详细诊断
UILayoutDebugger.shared.diagnoseLayout(
    view, 
    expectedLayout: "顶部标题 -> 中间内容 -> 底部按钮"
)
```

### 3. 自动修复

```swift
// 自动修复常见布局问题
UILayoutDebugger.shared.autoFixCommonIssues(view)
```

### 4. 生成报告

```swift
// 生成详细的布局报告
let report = UIInspector.shared.generateLayoutReport(view, title: "界面分析报告")

// 保存报告到文件
UIInspector.shared.saveLayoutReport(view, title: "界面分析", filename: "layout_report.txt")
```

### 5. 实时监控

```swift
// 开始实时监控布局变化
UILayoutDebugger.shared.startLayoutMonitoring(view, interval: 2.0)
```

## 输出示例

### 视图层级结构
```
📱 JMSProtocolManagerViewController
    📐 Frame: (0, 0, 520, 300)
    📏 Bounds: (0, 0, 520, 300)
  📄 NSTextField
      📐 Frame: (20, 180, 200, 20)
      📏 Bounds: (0, 0, 200, 20)
      📝 Text: "📡 协议状态"
      🎨 Font: .AppleSystemUIFont
  📄 NSTextField
      📐 Frame: (20, 160, 460, 16)
      📏 Bounds: (0, 0, 460, 16)
      📝 Text: "正在检查协议状态..."
  📁 NSScrollView
      📐 Frame: (20, 60, 460, 90)
      📏 Bounds: (0, 0, 460, 90)
      📜 HasVerticalScroller: true
      📜 HasHorizontalScroller: false
    📚 NSStackView
        📐 Frame: (0, 0, 460, 90)
        📏 Bounds: (0, 0, 460, 90)
        📚 Orientation: Vertical
        📚 Spacing: 8.0
        📚 ArrangedSubviews: 0
```

### 布局问题检测
```
⚠️ 检测到布局问题:
  - 发现大片空白区域: 空白比例过高: 65%
  - [NSStackView] NSStackView没有arrangedSubviews

💡 修复建议:
  - 考虑调整子视图位置或增加内容填充空白区域
  - 为NSStackView添加arrangedSubviews或检查数据源
```

## 在JMS协议管理界面中的应用

### 集成代码

```swift
import UIInspector

class JMSProtocolManagerViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // 延迟执行UI检查，确保界面完全加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // 基本UI检查
            self.view.inspectLayout(title: "JMS协议管理界面初始布局")
            
            // 详细布局诊断
            UILayoutDebugger.shared.diagnoseLayout(
                self.view, 
                expectedLayout: "顶部状态区域 -> 中间列表区域 -> 底部按钮区域"
            )
            
            // 自动修复常见问题
            UILayoutDebugger.shared.autoFixCommonIssues(self.view)
        }
        
        checkProtocolStatus()
    }
    
    private func updateHandlersList() {
        // ... 更新逻辑
        
        // 更新后再次检查布局
        self.view.inspectLayout(title: "JMS协议管理界面更新后布局")
    }
}
```

### 解决的问题

通过UI检查器，我们发现并解决了以下问题：

1. **空白区域过大**
   - 检测到65%的空白比例
   - 建议调整视图位置和尺寸

2. **NSStackView为空**
   - 检测到NSStackView没有arrangedSubviews
   - 提示检查数据源和视图添加逻辑

3. **坐标系统问题**
   - 分析视图的实际Frame和Bounds
   - 确认macOS坐标系统的正确使用

## 最佳实践

### 1. 使用时机
- 在`viewDidLoad`后延迟执行检查
- 在界面更新后进行验证
- 在发现布局问题时进行诊断

### 2. 性能考虑
- 仅在调试模式下启用详细检查
- 避免在生产环境中使用实时监控
- 合理设置监控间隔

### 3. 日志管理
- UI检查器使用LogManager统一日志框架
- 日志会自动保存到文件
- 可以通过日志级别控制输出详细程度

### 4. 报告分析
- 定期生成和保存布局报告
- 对比不同版本的布局变化
- 用于问题追踪和性能优化

## 扩展功能

### 自定义检查规则

```swift
// 可以扩展UILayoutDebugger添加自定义检查
extension UILayoutDebugger {
    func checkCustomLayoutRules(_ view: NSView) -> [String] {
        var issues: [String] = []
        
        // 自定义检查逻辑
        if view is NSButton && view.frame.height < 30 {
            issues.append("按钮高度过小，建议至少30px")
        }
        
        return issues
    }
}
```

### 集成到其他界面

```swift
// 在任何NSViewController中使用
class MyViewController: NSViewController {
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // 检查界面布局
        view.inspectLayout(title: "我的界面")
    }
}
```

## 故障排除

### 常见问题

1. **检查器没有输出**
   - 确认LogManager日志级别设置
   - 检查是否在主线程调用

2. **报告文件保存失败**
   - 检查文档目录权限
   - 确认文件名格式正确

3. **自动修复无效**
   - 某些约束问题需要手动修复
   - 检查视图的约束设置

### 调试技巧

1. **使用延迟检查**
   ```swift
   DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
       // 执行UI检查
   }
   ```

2. **分步骤检查**
   ```swift
   // 先检查基本结构
   view.inspectLayout(title: "基本结构")
   
   // 再检查详细布局
   UILayoutDebugger.shared.diagnoseLayout(view)
   ```

3. **保存检查结果**
   ```swift
   UIInspector.shared.saveLayoutReport(view, title: "问题诊断")
   ```

## 总结

UI检查器是一个强大的GUI调试工具，能够：

- ✅ **快速定位布局问题**：自动检测和分析界面布局
- ✅ **提供详细诊断信息**：生成完整的视图层级和属性报告
- ✅ **支持自动修复**：修复常见的布局问题
- ✅ **通用性强**：可用于任何macOS应用程序的界面调试
- ✅ **易于集成**：简单的API调用即可使用

通过使用UI检查器，我们成功诊断并修复了JMS协议管理界面的布局问题，提高了开发效率和界面质量。

---
**文档版本**: 1.0  
**创建日期**: 2025-08-18  
**适用版本**: JMS Protocol Handler 1.2.0+
