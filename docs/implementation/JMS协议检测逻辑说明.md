# JMS协议检测逻辑说明

## 📋 问题分析

在单元测试中发现JMS协议检测结果显示了不正确的路径信息：
- 显示：`JMSProtocolHandler at /Applications/Xcode.app/Contents/Developer/usr/bin`
- 期望：`JMSProtocolHandler at /Applications/JMSProtocolHandler.app`

## 🔍 根本原因

### 1. 测试环境特殊性
在单元测试环境中，`Bundle.main.bundlePath` 返回的是测试运行器的路径，而不是JMSProtocolHandler应用的路径：
- 测试环境：`/Applications/Xcode.app/Contents/Developer/usr/bin`
- 实际应用：`/Applications/JMSProtocolHandler.app`

### 2. macOS系统规则
macOS的Launch Services系统决定协议处理器的优先级，我们的检测逻辑应该：
- **遵循系统规则**：不干预macOS的协议处理器选择
- **如实报告**：准确反映系统当前状态
- **避免假设**：不基于路径模式做主观判断

## ✅ 修复方案

### 1. 检测逻辑改进
```swift
// 修复前：基于路径模式判断
let isCurrentApp = handler.appPath.contains("JMSProtocolHandler.app") && 
                   currentAppPath.contains("JMSProtocolHandler.app")

// 修复后：严格路径匹配
let isCurrentApp = handler.appPath == currentAppPath
```

### 2. 系统规则遵循
- **默认处理器**：完全依赖`NSWorkspace.shared.urlForApplication(toOpen:)`
- **状态分类**：基于实际路径匹配，不做主观推断
- **多应用处理**：如实显示系统中存在的所有JMSProtocolHandler应用

### 3. 测试环境适配
```swift
// 在测试环境中的正确行为
currentAppPath = "/Applications/Xcode.app/Contents/Developer/usr/bin"  // 测试运行器
defaultHandler = "/Users/.../build/Release/JMSProtocolHandler.app"    // 系统默认

// 结果：
// - 默认处理器：构建输出的JMSProtocolHandler.app (系统选择)
// - 当前应用：测试运行器 (Bundle.main的真实值)
// - 其他应用：/Applications/JMSProtocolHandler.app (如果存在)
```

## 📊 正确的检测结果

### 测试环境中的预期结果
```
🔍 检测到的协议处理器:
  ✅ JMSProtocolHandler (系统默认)
     路径: /Users/.../build/Release/JMSProtocolHandler.app
     默认: true
     有效: true

  ⚠️ JMSProtocolHandler (其他应用)
     路径: /Applications/JMSProtocolHandler.app
     默认: false
     有效: true

当前应用路径: /Applications/Xcode.app/Contents/Developer/usr/bin
当前应用是否为默认处理器: false
```

### 生产环境中的预期结果
```
🔍 检测到的协议处理器:
  ✅ JMSProtocolHandler (当前应用)
     路径: /Applications/JMSProtocolHandler.app
     默认: true
     有效: true

当前应用路径: /Applications/JMSProtocolHandler.app
当前应用是否为默认处理器: true
```

## 🎯 设计原则

### 1. 系统规则优先
- **不干预**：不尝试"修正"系统的协议处理器选择
- **如实反映**：准确显示系统当前状态
- **遵循标准**：完全依赖macOS Launch Services API

### 2. 环境适应性
- **测试环境**：接受Bundle.main指向测试运行器的事实
- **开发环境**：正确处理构建输出目录的应用
- **生产环境**：准确识别安装在/Applications/的应用

### 3. 用户体验
- **信息透明**：清楚显示每个处理器的状态和来源
- **操作明确**：让用户了解哪个是系统默认处理器
- **选择自由**：不强制用户接受特定的处理器选择

## 🔧 实现细节

### 1. 初始化逻辑
```swift
private init() {
    self.currentBundleId = Bundle.main.bundleIdentifier ?? "com.jumpserver.JMSProtocolHandler"
    
    let bundlePath = Bundle.main.bundlePath
    if bundlePath.contains("JMSProtocolHandler.app") {
        self.currentAppPath = bundlePath
    } else {
        // 在测试环境中，查找实际的JMSProtocolHandler.app
        self.currentAppPath = Self.findJMSProtocolHandlerPath() ?? bundlePath
    }
}
```

### 2. 检测逻辑
```swift
private func scanProtocolHandlers() throws -> [ProtocolHandlerModel] {
    var handlers: [ProtocolHandlerModel] = []
    
    // 1. 获取系统默认处理器（macOS决定）
    if let defaultHandler = getDefaultHandler() {
        handlers.append(defaultHandler)
    }
    
    // 2. 扫描已知位置的JMSProtocolHandler应用
    let knownPaths = [
        "/Applications/JMSProtocolHandler.app",
        NSHomeDirectory() + "/Applications/JMSProtocolHandler.app"
    ]
    
    // 3. 合并并去重
    return handlers.uniqued().map { validateHandler($0) }
}
```

### 3. 验证逻辑
```swift
private func validateHandler(_ handler: ProtocolHandlerModel) -> ProtocolHandlerModel {
    let isValid = FileManager.default.fileExists(atPath: handler.appPath)
    let status: ProtocolHandlerStatus
    
    if !isValid {
        status = .invalid
    } else if handler.appPath == currentAppPath {
        status = .currentApp  // 严格路径匹配
    } else {
        status = .otherApp
    }
    
    return ProtocolHandlerModel(...)
}
```

## 📋 测试验证

### 1. 单元测试调整
- **接受现实**：测试环境中可能没有"当前应用"
- **验证核心**：重点验证系统默认处理器的正确识别
- **逻辑一致**：确保检测逻辑在不同环境中的一致性

### 2. 集成测试
- **实际环境**：在安装了JMSProtocolHandler.app的环境中测试
- **协议注册**：验证协议注册后的检测结果
- **多版本处理**：测试系统中存在多个版本时的行为

## 🎉 总结

通过这次修复，JMS协议检测逻辑现在：

### ✅ 遵循系统规则
- 完全依赖macOS Launch Services的协议处理器选择
- 不基于路径模式做主观判断
- 如实反映系统当前状态

### ✅ 环境适应性强
- 正确处理测试环境的特殊情况
- 适应开发和生产环境的不同路径
- 准确识别各种部署场景

### ✅ 用户体验良好
- 清晰显示每个处理器的真实状态
- 提供准确的系统默认处理器信息
- 支持用户做出明智的协议管理决策

**核心理念**：尊重系统规则，如实反映现状，让用户基于准确信息做出选择。

---

**修复日期**: 2025-01-18  
**影响范围**: ProtocolDetectionService  
**测试状态**: 需要在实际环境中验证  
**文档状态**: ✅ 完整
