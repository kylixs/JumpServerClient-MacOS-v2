#!/usr/bin/env swift

import Foundation
import Cocoa

/**
 * JMS协议管理界面手动布局解决方案验证测试
 * 
 * 测试目标：
 * 1. 验证手动布局能够实现从顶部到底部排列
 * 2. 确认约束设置的正确性
 * 3. 测试空状态和多项目状态
 */

print("🧪 JMS协议管理界面手动布局解决方案验证测试")
print(String(repeating: "=", count: 60))

// MARK: - 测试辅助类

class LayoutTestHelper {
    
    // 创建模拟的处理器视图
    static func createMockHandlerView(title: String, height: CGFloat = 36) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.controlColor.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置布局优先级
        containerView.setContentHuggingPriority(NSLayoutConstraint.Priority(1000), for: .vertical)
        containerView.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1000), for: .vertical)
        
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: height),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -8)
        ])
        
        return containerView
    }
}

// MARK: - 测试函数

func testManualLayoutSolution() -> Bool {
    print("\n🏗️ 测试1: 手动布局解决方案验证")
    
    let containerHeight: CGFloat = 300
    let containerWidth: CGFloat = 400
    let margin: CGFloat = 8
    let spacing: CGFloat = 4
    
    // 创建容器视图（模拟handlersListView）
    let containerView = NSView(frame: NSRect(x: 0, y: 0, width: containerWidth, height: containerHeight))
    
    // 创建处理器视图
    let handlerViews = [
        LayoutTestHelper.createMockHandlerView(title: "处理器1"),
        LayoutTestHelper.createMockHandlerView(title: "处理器2"),
        LayoutTestHelper.createMockHandlerView(title: "处理器3")
    ]
    
    // 手动布局 - 模拟实际实现
    var previousView: NSView? = nil
    var constraints: [NSLayoutConstraint] = []
    
    for (index, handlerView) in handlerViews.enumerated() {
        containerView.addSubview(handlerView)
        
        if let previous = previousView {
            // 不是第一个视图，放在前一个视图下方
            constraints.append(handlerView.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: spacing))
        } else {
            // 第一个视图，放在容器顶部
            constraints.append(handlerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: margin))
        }
        
        // 设置左右边距
        constraints.append(handlerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin))
        constraints.append(handlerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin))
        
        previousView = handlerView
    }
    
    // 设置最后一个视图的底部约束
    if let lastView = previousView {
        let bottomConstraint = lastView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -margin)
        bottomConstraint.priority = NSLayoutConstraint.Priority(999)
        constraints.append(bottomConstraint)
    }
    
    NSLayoutConstraint.activate(constraints)
    
    // 强制布局计算
    containerView.layoutSubtreeIfNeeded()
    
    // 验证结果
    let firstHandler = handlerViews[0]
    let secondHandler = handlerViews[1]
    let thirdHandler = handlerViews[2]
    
    let tests = [
        ("第一个处理器在顶部", firstHandler.frame.minY == margin),
        ("第二个处理器在第一个下方", secondHandler.frame.minY == firstHandler.frame.maxY + spacing),
        ("第三个处理器在第二个下方", thirdHandler.frame.minY == secondHandler.frame.maxY + spacing),
        ("处理器宽度正确", firstHandler.frame.width == containerWidth - 2 * margin),
        ("处理器高度正确", firstHandler.frame.height == 36),
        ("布局顺序正确", firstHandler.frame.minY < secondHandler.frame.minY && secondHandler.frame.minY < thirdHandler.frame.minY)
    ]
    
    var allPassed = true
    for (name, passed) in tests {
        let status = passed ? "✅" : "❌"
        print("  \(status) \(name): \(passed ? "正确" : "错误")")
        if !passed { allPassed = false }
    }
    
    print("  📊 实际布局位置:")
    for (index, view) in handlerViews.enumerated() {
        let frame = view.frame
        print("    处理器\(index + 1): y=\(frame.minY), height=\(frame.height), width=\(frame.width)")
    }
    
    print("  📐 预期位置:")
    print("    处理器1: y=\(margin)")
    print("    处理器2: y=\(margin + 36 + spacing)")
    print("    处理器3: y=\(margin + 36 + spacing + 36 + spacing)")
    
    return allPassed
}

func testScrollViewIntegration() -> Bool {
    print("\n📜 测试2: 滚动视图集成验证")
    
    // 创建完整的滚动视图结构
    let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 150))
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    
    // 创建容器视图（模拟handlersListView）
    let containerView = NSView()
    containerView.translatesAutoresizingMaskIntoConstraints = false
    
    scrollView.documentView = containerView
    
    // 设置容器约束
    NSLayoutConstraint.activate([
        containerView.topAnchor.constraint(equalTo: scrollView.documentView!.topAnchor),
        containerView.leadingAnchor.constraint(equalTo: scrollView.documentView!.leadingAnchor),
        containerView.trailingAnchor.constraint(equalTo: scrollView.documentView!.trailingAnchor),
        containerView.bottomAnchor.constraint(equalTo: scrollView.documentView!.bottomAnchor)
    ])
    
    // 添加多个项目
    let handlerViews = (1...6).map { LayoutTestHelper.createMockHandlerView(title: "协议处理器\($0)", height: 36) }
    
    // 手动布局
    var previousView: NSView? = nil
    var constraints: [NSLayoutConstraint] = []
    let margin: CGFloat = 8
    let spacing: CGFloat = 4
    
    for handlerView in handlerViews {
        containerView.addSubview(handlerView)
        
        if let previous = previousView {
            constraints.append(handlerView.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: spacing))
        } else {
            constraints.append(handlerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: margin))
        }
        
        constraints.append(handlerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin))
        constraints.append(handlerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin))
        
        previousView = handlerView
    }
    
    // 设置最后一个视图的底部约束
    if let lastView = previousView {
        let bottomConstraint = lastView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -margin)
        bottomConstraint.priority = NSLayoutConstraint.Priority(999)
        constraints.append(bottomConstraint)
    }
    
    NSLayoutConstraint.activate(constraints)
    
    // 强制布局
    scrollView.layoutSubtreeIfNeeded()
    
    // 测试滚动到顶部
    scrollView.documentView?.scroll(NSPoint.zero)
    
    let firstItem = handlerViews[0]
    let lastItem = handlerViews.last!
    
    let tests = [
        ("容器视图正确设置", scrollView.documentView === containerView),
        ("第一个项目在顶部", firstItem.frame.minY == margin),
        ("项目按顺序排列", handlerViews[1].frame.minY > firstItem.frame.maxY),
        ("最后一个项目位置正确", lastItem.frame.minY > handlerViews[handlerViews.count-2].frame.maxY),
        ("滚动位置在顶部", scrollView.documentVisibleRect.minY == 0)
    ]
    
    var allPassed = true
    for (name, passed) in tests {
        let status = passed ? "✅" : "❌"
        print("  \(status) \(name): \(passed ? "正确" : "错误")")
        if !passed { allPassed = false }
    }
    
    print("  📊 滚动视图状态:")
    print("    可视区域: \(scrollView.documentVisibleRect)")
    print("    第一项位置: y=\(firstItem.frame.minY)")
    print("    最后项位置: y=\(lastItem.frame.minY)")
    print("    容器内容高度: \(containerView.frame.height)")
    
    return allPassed
}

func testEmptyStateHandling() -> Bool {
    print("\n📝 测试3: 空状态处理验证")
    
    let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
    
    // 添加空状态标签
    let emptyLabel = NSTextField(labelWithString: "未找到任何jms://协议处理器")
    emptyLabel.font = NSFont.systemFont(ofSize: 12)
    emptyLabel.textColor = NSColor.secondaryLabelColor
    emptyLabel.alignment = .center
    emptyLabel.translatesAutoresizingMaskIntoConstraints = false
    emptyLabel.isEditable = false
    emptyLabel.isBordered = false
    emptyLabel.backgroundColor = NSColor.clear
    
    containerView.addSubview(emptyLabel)
    
    // 居中显示空状态标签
    NSLayoutConstraint.activate([
        emptyLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        emptyLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
        emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 20),
        emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -20)
    ])
    
    // 强制布局
    containerView.layoutSubtreeIfNeeded()
    
    let tests = [
        ("空状态标签存在", containerView.subviews.count == 1),
        ("标签是正确的视图", containerView.subviews.first === emptyLabel),
        ("标签位置在顶部附近", emptyLabel.frame.minY == 20),
        ("标签水平居中", abs(emptyLabel.frame.midX - containerView.frame.midX) < 1)
    ]
    
    var allPassed = true
    for (name, passed) in tests {
        let status = passed ? "✅" : "❌"
        print("  \(status) \(name): \(passed ? "正确" : "错误")")
        if !passed { allPassed = false }
    }
    
    print("  📊 空状态信息:")
    print("    标签位置: y=\(emptyLabel.frame.minY), x=\(emptyLabel.frame.minX)")
    print("    标签大小: \(emptyLabel.frame.size)")
    print("    容器中心: x=\(containerView.frame.midX)")
    print("    标签中心: x=\(emptyLabel.frame.midX)")
    
    return allPassed
}

// MARK: - 主测试函数

func runAllTests() {
    print("\n🚀 开始运行手动布局解决方案验证测试...")
    
    var testResults: [String: Bool] = [:]
    
    testResults["手动布局解决方案"] = testManualLayoutSolution()
    testResults["滚动视图集成"] = testScrollViewIntegration()
    testResults["空状态处理"] = testEmptyStateHandling()
    
    // 汇总结果
    print("\n📊 测试结果汇总:")
    print(String(repeating: "-", count: 40))
    
    let passedCount = testResults.values.filter { $0 }.count
    let totalCount = testResults.count
    
    for (testName, passed) in testResults {
        let status = passed ? "✅ 通过" : "❌ 失败"
        print("  \(testName): \(status)")
    }
    
    print(String(repeating: "-", count: 40))
    print("总体结果: \(passedCount)/\(totalCount) 测试通过")
    
    if passedCount == totalCount {
        print("🎉 所有测试通过！手动布局解决方案有效！")
        print("\n💡 解决方案要点:")
        print("  - 使用普通NSView替代NSStackView")
        print("  - 手动设置每个子视图的约束")
        print("  - 第一个视图固定在顶部")
        print("  - 后续视图依次排列在前一个视图下方")
        print("  - 完全控制布局，确保从顶部到底部排列")
        exit(0)
    } else {
        print("⚠️  有 \(totalCount - passedCount) 个测试失败，需要进一步调整")
        exit(1)
    }
}

// 运行测试
runAllTests()
