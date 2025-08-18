#!/usr/bin/env swift

import Foundation
import Cocoa

/**
 * JMS协议管理界面布局优化实际验证测试脚本
 * 
 * 测试目标：
 * 1. 创建实际的NSStackView并验证配置
 * 2. 模拟真实的列表项并检查排列
 * 3. 验证Auto Layout约束的实际效果
 * 4. 测试弹性空间的实际作用
 */

print("🧪 JMS协议管理界面布局优化实际验证测试")
print(String(repeating: "=", count: 60))

// MARK: - Flipped View Helper for Testing

class FlippedView: NSView {
    override var isFlipped: Bool {
        return true  // 翻转坐标系统，y=0在顶部
    }
}

// MARK: - 实际布局测试类

class LayoutTestHelper {
    
    // 创建模拟的处理器视图
    static func createMockHandlerView(title: String, height: CGFloat = 36) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.controlColor.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置实际的布局优先级
        containerView.setContentHuggingPriority(NSLayoutConstraint.Priority(1000), for: .vertical)
        containerView.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1000), for: .vertical)
        containerView.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .horizontal)
        containerView.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1000), for: .horizontal)
        
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

// MARK: - 实际测试函数

func testActualStackViewConfiguration() -> Bool {
    print("\n📐 测试1: 实际NSStackView配置验证")
    
    let stackView = NSStackView()
    stackView.orientation = .vertical
    stackView.alignment = .leading
    stackView.distribution = .fill
    stackView.spacing = 4
    stackView.translatesAutoresizingMaskIntoConstraints = false
    
    // 设置布局优先级
    stackView.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .vertical)
    stackView.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1000), for: .vertical)
    
    // 验证配置
    let tests = [
        ("方向", stackView.orientation == .vertical),
        ("对齐", stackView.alignment == .leading),
        ("分布", stackView.distribution == .fill),
        ("间距", stackView.spacing == 4),
        ("垂直拥抱优先级", stackView.contentHuggingPriority(for: .vertical).rawValue == 1),
        ("垂直压缩阻力", stackView.contentCompressionResistancePriority(for: .vertical).rawValue == 1000)
    ]
    
    var allPassed = true
    for (name, passed) in tests {
        let status = passed ? "✅" : "❌"
        print("  \(status) \(name): \(passed ? "正确" : "错误")")
        if !passed { allPassed = false }
    }
    
    return allPassed
}

func testActualLayoutArrangement() -> Bool {
    print("\n🏗️ 测试2: 实际布局排列验证（使用flipped坐标系统）")
    
    // 创建flipped容器视图（模拟实际实现）
    let flippedContainer = FlippedView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
    
    // 创建StackView
    let stackView = NSStackView()
    stackView.orientation = .vertical
    stackView.alignment = .leading
    stackView.distribution = .fillProportionally  // 使用fillProportionally
    stackView.spacing = 4
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .vertical)
    stackView.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1000), for: .vertical)
    
    flippedContainer.addSubview(stackView)
    
    // 设置约束（模拟实际代码）
    NSLayoutConstraint.activate([
        stackView.topAnchor.constraint(equalTo: flippedContainer.topAnchor),
        stackView.leadingAnchor.constraint(equalTo: flippedContainer.leadingAnchor),
        stackView.trailingAnchor.constraint(equalTo: flippedContainer.trailingAnchor)
        // 不设置底部约束
    ])
    
    // 添加模拟的处理器视图
    let handlerViews = [
        LayoutTestHelper.createMockHandlerView(title: "处理器1"),
        LayoutTestHelper.createMockHandlerView(title: "处理器2"),
        LayoutTestHelper.createMockHandlerView(title: "处理器3")
    ]
    
    for handlerView in handlerViews {
        stackView.addArrangedSubview(handlerView)
        NSLayoutConstraint.activate([
            handlerView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }
    
    // 添加弹性空间
    let spacerView = LayoutTestHelper.createSpacerView()
    stackView.addArrangedSubview(spacerView)
    NSLayoutConstraint.activate([
        spacerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
    ])
    
    // 强制布局计算
    flippedContainer.layoutSubtreeIfNeeded()
    
    // 在flipped坐标系统中，第一个项目应该在y=0位置
    let firstHandlerFrame = handlerViews[0].frame
    let secondHandlerFrame = handlerViews[1].frame
    let spacerFrame = spacerView.frame
    
    // 验证布局结果
    let tests = [
        ("StackView子视图数量", stackView.arrangedSubviews.count == 4), // 3个处理器 + 1个spacer
        ("第一个视图是处理器", stackView.arrangedSubviews[0] === handlerViews[0]),
        ("最后一个视图是spacer", stackView.arrangedSubviews.last === spacerView),
        ("第一个处理器在顶部", firstHandlerFrame.minY == 0),
        ("第二个处理器在第一个下方", secondHandlerFrame.minY > firstHandlerFrame.maxY),
        ("spacer在所有处理器下方", spacerFrame.minY >= handlerViews.last!.frame.maxY)
    ]
    
    var allPassed = true
    for (name, passed) in tests {
        let status = passed ? "✅" : "❌"
        print("  \(status) \(name): \(passed ? "正确" : "错误")")
        if !passed { allPassed = false }
    }
    
    // 检查视图的实际位置（在flipped坐标系统中）
    print("  📊 实际布局位置（flipped坐标系统）:")
    for (index, view) in stackView.arrangedSubviews.enumerated() {
        let frame = view.frame
        let viewType = index < handlerViews.count ? "处理器\(index + 1)" : "弹性空间"
        print("    \(viewType): y=\(frame.minY), height=\(frame.height)")
    }
    
    print("  💡 flipped坐标系统说明: y=0在顶部，向下递增")
    
    return allPassed
}

func testSpacerViewActualEffect() -> Bool {
    print("\n🌌 测试3: 弹性空间实际效果验证（flipped坐标系统）")
    
    let containerHeight: CGFloat = 200
    let itemHeight: CGFloat = 36
    let itemCount = 2
    
    // 场景：使用flipped坐标系统的StackView with spacer
    let flippedContainer = FlippedView(frame: NSRect(x: 0, y: 0, width: 400, height: containerHeight))
    let stackView = NSStackView()
    stackView.orientation = .vertical
    stackView.distribution = .fillProportionally
    stackView.spacing = 4
    stackView.translatesAutoresizingMaskIntoConstraints = false
    
    flippedContainer.addSubview(stackView)
    NSLayoutConstraint.activate([
        stackView.topAnchor.constraint(equalTo: flippedContainer.topAnchor),
        stackView.leadingAnchor.constraint(equalTo: flippedContainer.leadingAnchor),
        stackView.trailingAnchor.constraint(equalTo: flippedContainer.trailingAnchor)
        // 不设置底部约束
    ])
    
    // 添加处理器项目
    var handlerViews: [NSView] = []
    for i in 1...itemCount {
        let item = LayoutTestHelper.createMockHandlerView(title: "项目\(i)", height: itemHeight)
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
        spacer.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
    ])
    
    // 强制布局计算
    flippedContainer.layoutSubtreeIfNeeded()
    
    // 验证效果
    let firstItem = handlerViews[0]
    let secondItem = handlerViews[1]
    let spacerFrame = spacer.frame
    
    let tests = [
        ("第一个项目在顶部", firstItem.frame.minY == 0),
        ("第二个项目在第一个下方", secondItem.frame.minY > firstItem.frame.maxY),
        ("spacer在最后", spacer === stackView.arrangedSubviews.last),
        ("spacer位置正确", spacerFrame.minY >= secondItem.frame.maxY)
    ]
    
    var allPassed = true
    for (name, passed) in tests {
        let status = passed ? "✅" : "❌"
        print("  \(status) \(name): \(passed ? "正确" : "错误")")
        if !passed { allPassed = false }
    }
    
    print("  📊 实际测量结果（flipped坐标系统）:")
    print("    第一项位置: y=\(firstItem.frame.minY), height=\(firstItem.frame.height)")
    print("    第二项位置: y=\(secondItem.frame.minY), height=\(secondItem.frame.height)")
    print("    spacer位置: y=\(spacerFrame.minY), height=\(spacerFrame.height)")
    print("    容器高度: \(containerHeight)")
    
    return allPassed
}

func testScrollViewIntegration() -> Bool {
    print("\n📜 测试4: 滚动视图集成验证（flipped坐标系统）")
    
    // 创建完整的滚动视图 + flipped容器 + StackView结构
    let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 150))
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    
    // 创建flipped容器（模拟实际实现）
    let flippedContainer = FlippedView()
    flippedContainer.translatesAutoresizingMaskIntoConstraints = false
    
    let stackView = NSStackView()
    stackView.orientation = .vertical
    stackView.distribution = .fillProportionally
    stackView.spacing = 4
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .vertical)
    stackView.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1000), for: .vertical)
    
    flippedContainer.addSubview(stackView)
    scrollView.documentView = flippedContainer
    
    // 设置约束（模拟实际代码）
    NSLayoutConstraint.activate([
        stackView.topAnchor.constraint(equalTo: flippedContainer.topAnchor),
        stackView.leadingAnchor.constraint(equalTo: flippedContainer.leadingAnchor),
        stackView.trailingAnchor.constraint(equalTo: flippedContainer.trailingAnchor)
        // 关键：不设置底部约束
    ])
    
    // 添加多个项目
    var handlerViews: [NSView] = []
    for i in 1...6 {
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
        spacer.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
    ])
    
    // 强制布局
    scrollView.layoutSubtreeIfNeeded()
    
    // 测试滚动到顶部功能
    scrollView.documentView?.scroll(NSPoint.zero)
    
    let firstItem = handlerViews[0]
    let secondItem = handlerViews[1]
    
    let tests = [
        ("flipped容器正确设置为documentView", scrollView.documentView === flippedContainer),
        ("第一个项目在顶部", firstItem.frame.minY == 0),
        ("第二个项目在第一个下方", secondItem.frame.minY > firstItem.frame.maxY),
        ("spacer是最后一个子视图", stackView.arrangedSubviews.last === spacer),
        ("滚动位置在顶部", scrollView.documentVisibleRect.minY == 0)
    ]
    
    var allPassed = true
    for (name, passed) in tests {
        let status = passed ? "✅" : "❌"
        print("  \(status) \(name): \(passed ? "正确" : "错误")")
        if !passed { allPassed = false }
    }
    
    print("  📊 滚动视图状态（flipped坐标系统）:")
    print("    可视区域: \(scrollView.documentVisibleRect)")
    print("    第一项位置: y=\(firstItem.frame.minY), height=\(firstItem.frame.height)")
    print("    第二项位置: y=\(secondItem.frame.minY), height=\(secondItem.frame.height)")
    print("    项目数量: \(stackView.arrangedSubviews.count)")
    
    return allPassed
}

// MARK: - 主测试函数

func runAllTests() {
    print("\n🚀 开始运行所有实际验证测试...")
    
    var testResults: [String: Bool] = [:]
    
    testResults["NSStackView配置"] = testActualStackViewConfiguration()
    testResults["布局排列"] = testActualLayoutArrangement()
    testResults["弹性空间效果"] = testSpacerViewActualEffect()
    testResults["滚动视图集成"] = testScrollViewIntegration()
    
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
        print("🎉 所有测试通过！布局优化实施成功！")
        exit(0)
    } else {
        print("⚠️  有 \(totalCount - passedCount) 个测试失败，需要检查实现")
        exit(1)
    }
}

// 运行测试
runAllTests()
