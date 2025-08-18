#!/usr/bin/env swift

import Foundation
import Cocoa

/**
 * JMS协议管理界面容器视图解决方案验证测试
 * 
 * 测试目标：
 * 1. 验证容器视图 + NSStackView的组合方案
 * 2. 确认弹性空间能够将内容推到顶部
 * 3. 测试从顶部到底部的排列效果
 */

print("🧪 JMS协议管理界面容器视图解决方案验证测试")
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
    
    // 创建弹性空间视图
    static func createSpacerView() -> NSView {
        let spacerView = NSView()
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        spacerView.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .vertical)
        spacerView.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1), for: .vertical)
        return spacerView
    }
}

// MARK: - 测试函数

func testContainerViewSolution() -> Bool {
    print("\n🏗️ 测试1: 容器视图解决方案验证")
    
    let containerHeight: CGFloat = 300
    let containerWidth: CGFloat = 400
    
    // 创建外层容器视图（模拟scrollView的documentView）
    let outerContainer = NSView(frame: NSRect(x: 0, y: 0, width: containerWidth, height: containerHeight))
    
    // 创建StackView
    let stackView = NSStackView()
    stackView.orientation = .vertical
    stackView.alignment = .leading
    stackView.distribution = .fill  // 使用fill分布
    stackView.spacing = 4
    stackView.translatesAutoresizingMaskIntoConstraints = false
    
    outerContainer.addSubview(stackView)
    
    // 关键：只设置顶部和左右约束，不设置底部约束
    NSLayoutConstraint.activate([
        stackView.topAnchor.constraint(equalTo: outerContainer.topAnchor),
        stackView.leadingAnchor.constraint(equalTo: outerContainer.leadingAnchor),
        stackView.trailingAnchor.constraint(equalTo: outerContainer.trailingAnchor)
        // 注意：不设置bottomAnchor约束
    ])
    
    // 添加处理器视图
    let handlerViews = [
        LayoutTestHelper.createMockHandlerView(title: "处理器1"),
        LayoutTestHelper.createMockHandlerView(title: "处理器2"),
        LayoutTestHelper.createMockHandlerView(title: "处理器3")
    ]
    
    for handlerView in handlerViews {
        stackView.addArrangedSubview(handlerView)
        NSLayoutConstraint.activate([
            handlerView.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -16)
        ])
    }
    
    // 关键：添加弹性空间
    let spacer = LayoutTestHelper.createSpacerView()
    stackView.addArrangedSubview(spacer)
    NSLayoutConstraint.activate([
        spacer.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
        spacer.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -16)
    ])
    
    // 强制布局计算
    outerContainer.layoutSubtreeIfNeeded()
    
    // 验证结果
    let firstHandler = handlerViews[0]
    let secondHandler = handlerViews[1]
    let thirdHandler = handlerViews[2]
    let spacerFrame = spacer.frame
    
    let tests = [
        ("StackView子视图数量", stackView.arrangedSubviews.count == 4),
        ("第一个处理器位置", firstHandler.frame.minY <= 10),  // 应该接近顶部
        ("第二个处理器在第一个下方", secondHandler.frame.minY > firstHandler.frame.maxY),
        ("第三个处理器在第二个下方", thirdHandler.frame.minY > secondHandler.frame.maxY),
        ("spacer在最后", spacer === stackView.arrangedSubviews.last),
        ("spacer有高度", spacerFrame.height > 0)
    ]
    
    var allPassed = true
    for (name, passed) in tests {
        let status = passed ? "✅" : "❌"
        print("  \(status) \(name): \(passed ? "正确" : "错误")")
        if !passed { allPassed = false }
    }
    
    print("  📊 实际布局位置:")
    for (index, view) in stackView.arrangedSubviews.enumerated() {
        let frame = view.frame
        let viewType = index < handlerViews.count ? "处理器\(index + 1)" : "弹性空间"
        print("    \(viewType): y=\(frame.minY), height=\(frame.height)")
    }
    
    print("  📐 容器信息:")
    print("    外层容器: \(outerContainer.frame)")
    print("    StackView: \(stackView.frame)")
    
    return allPassed
}

func testScrollViewIntegration() -> Bool {
    print("\n📜 测试2: 滚动视图集成验证")
    
    // 创建完整的滚动视图结构
    let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 150))
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    
    // 创建容器视图
    let containerView = NSView()
    containerView.translatesAutoresizingMaskIntoConstraints = false
    
    let stackView = NSStackView()
    stackView.orientation = .vertical
    stackView.distribution = .fill
    stackView.spacing = 4
    stackView.translatesAutoresizingMaskIntoConstraints = false
    
    containerView.addSubview(stackView)
    scrollView.documentView = containerView
    
    // 设置约束（模拟实际实现）
    NSLayoutConstraint.activate([
        stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
        stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
        stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        // 不设置底部约束
    ])
    
    // 添加多个项目
    var handlerViews: [NSView] = []
    for i in 1...5 {
        let item = LayoutTestHelper.createMockHandlerView(title: "协议处理器\(i)", height: 36)
        handlerViews.append(item)
        stackView.addArrangedSubview(item)
        NSLayoutConstraint.activate([
            item.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }
    
    // 添加spacer
    let spacer = LayoutTestHelper.createSpacerView()
    stackView.addArrangedSubview(spacer)
    NSLayoutConstraint.activate([
        spacer.heightAnchor.constraint(greaterThanOrEqualToConstant: 20)
    ])
    
    // 强制布局
    scrollView.layoutSubtreeIfNeeded()
    
    // 测试滚动到顶部
    scrollView.documentView?.scroll(NSPoint.zero)
    
    let firstItem = handlerViews[0]
    let lastItem = handlerViews.last!
    
    let tests = [
        ("容器视图正确设置", scrollView.documentView === containerView),
        ("第一个项目接近顶部", firstItem.frame.minY <= 10),
        ("项目按顺序排列", handlerViews[1].frame.minY > firstItem.frame.maxY),
        ("spacer是最后一个", stackView.arrangedSubviews.last === spacer),
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
    print("    spacer位置: y=\(spacer.frame.minY), height=\(spacer.frame.height)")
    
    return allPassed
}

func testEmptyStateHandling() -> Bool {
    print("\n📝 测试3: 空状态处理验证")
    
    let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
    let stackView = NSStackView()
    stackView.orientation = .vertical
    stackView.distribution = .fill
    stackView.spacing = 4
    stackView.translatesAutoresizingMaskIntoConstraints = false
    
    containerView.addSubview(stackView)
    
    NSLayoutConstraint.activate([
        stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
        stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
        stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
    ])
    
    // 添加空状态标签
    let emptyLabel = NSTextField(labelWithString: "未找到任何jms://协议处理器")
    emptyLabel.font = NSFont.systemFont(ofSize: 12)
    emptyLabel.textColor = NSColor.secondaryLabelColor
    emptyLabel.alignment = .center
    emptyLabel.translatesAutoresizingMaskIntoConstraints = false
    emptyLabel.isEditable = false
    emptyLabel.isBordered = false
    emptyLabel.backgroundColor = NSColor.clear
    
    stackView.addArrangedSubview(emptyLabel)
    
    NSLayoutConstraint.activate([
        emptyLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -16)
    ])
    
    // 强制布局
    containerView.layoutSubtreeIfNeeded()
    
    let tests = [
        ("空状态标签存在", stackView.arrangedSubviews.count == 1),
        ("标签是正确的视图", stackView.arrangedSubviews.first === emptyLabel),
        ("标签位置合理", emptyLabel.frame.minY <= 10)
    ]
    
    var allPassed = true
    for (name, passed) in tests {
        let status = passed ? "✅" : "❌"
        print("  \(status) \(name): \(passed ? "正确" : "错误")")
        if !passed { allPassed = false }
    }
    
    print("  📊 空状态信息:")
    print("    标签位置: y=\(emptyLabel.frame.minY), height=\(emptyLabel.frame.height)")
    print("    标签文本: \(emptyLabel.stringValue)")
    
    return allPassed
}

// MARK: - 主测试函数

func runAllTests() {
    print("\n🚀 开始运行容器视图解决方案验证测试...")
    
    var testResults: [String: Bool] = [:]
    
    testResults["容器视图解决方案"] = testContainerViewSolution()
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
        print("🎉 所有测试通过！容器视图解决方案有效！")
        print("\n💡 解决方案要点:")
        print("  - 使用容器视图包装NSStackView")
        print("  - 只设置顶部和左右约束，不设置底部约束")
        print("  - 添加弹性空间将内容推到顶部")
        print("  - 使用.fill分布方式")
        exit(0)
    } else {
        print("⚠️  有 \(totalCount - passedCount) 个测试失败，需要进一步调整")
        exit(1)
    }
}

// 运行测试
runAllTests()
