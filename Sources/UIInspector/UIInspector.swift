import Foundation
import AppKit
import JMSCore

/// UI检查器 - 专注于分析和生成报告的GUI调试工具
public class UIInspector {
    
    /// 单例实例
    public static let shared = UIInspector()
    
    /// 日志管理器
    private let logger = LogManager.shared
    
    /// 报告版本号
    private var reportVersion = 1
    
    private init() {}
    
    /// 生成完整的UI分析报告
    /// - Parameters:
    ///   - view: 要分析的根视图
    ///   - title: 报告标题
    ///   - expectedLayout: 期望的布局描述
    /// - Returns: 详细的分析报告
    public func generateUIAnalysisReport(_ view: NSView, title: String = "UI Analysis Report", expectedLayout: String = "") -> UIAnalysisReport {
        logger.info("📊 开始生成UI分析报告: \(title)")
        
        let report = UIAnalysisReport(
            title: title,
            version: reportVersion,
            timestamp: Date(),
            expectedLayout: expectedLayout
        )
        
        // 基本信息收集
        report.basicInfo = collectBasicInfo(view)
        
        // 视图层级分析
        report.viewHierarchy = analyzeViewHierarchy(view)
        
        // 布局问题检测
        report.layoutIssues = detectLayoutIssues(view)
        
        // 空间利用分析
        report.spaceUtilization = analyzeSpaceUtilization(view)
        
        // 约束分析
        report.constraintAnalysis = analyzeConstraints(view)
        
        // 坐标分析
        report.coordinateAnalysis = analyzeCoordinates(view)
        
        // 生成改进建议
        report.improvementSuggestions = generateImprovementSuggestions(report)
        
        reportVersion += 1
        
        logger.info("✅ UI分析报告生成完成")
        return report
    }
    
    /// 收集基本信息
    /// - Parameter view: 根视图
    /// - Returns: 基本信息
    private func collectBasicInfo(_ view: NSView) -> BasicInfo {
        let info = BasicInfo()
        
        info.rootViewType = String(describing: type(of: view))
        info.rootViewFrame = view.frame
        info.rootViewBounds = view.bounds
        info.totalSubviews = countTotalSubviews(view)
        info.maxDepth = calculateMaxDepth(view)
        
        if let window = view.window {
            info.windowFrame = window.frame
            info.windowTitle = window.title
        }
        
        return info
    }
    
    /// 分析视图层级结构
    /// - Parameter view: 根视图
    /// - Returns: 层级结构数据
    private func analyzeViewHierarchy(_ view: NSView) -> ViewHierarchyNode {
        return buildHierarchyNode(view, level: 0, parentPath: "")
    }
    
    /// 构建层级节点
    /// - Parameters:
    ///   - view: 当前视图
    ///   - level: 层级深度
    ///   - parentPath: 父视图路径
    /// - Returns: 层级节点
    private func buildHierarchyNode(_ view: NSView, level: Int, parentPath: String = "") -> ViewHierarchyNode {
        let node = ViewHierarchyNode()
        
        node.className = String(describing: type(of: view))
        node.frame = view.frame
        node.bounds = view.bounds
        node.isHidden = view.isHidden
        node.alpha = view.alphaValue
        node.level = level
        node.hasConstraints = !view.constraints.isEmpty
        node.usesAutoLayout = !view.translatesAutoresizingMaskIntoConstraints
        
        // 构建视图路径
        node.viewPath = parentPath.isEmpty ? node.className : "\(parentPath) -> \(node.className)"
        
        // 计算坐标信息
        node.coordinateInfo = calculateCoordinateInfo(for: view)
        
        // 收集特殊属性
        if let textField = view as? NSTextField {
            node.specialProperties["text"] = textField.stringValue
            node.specialProperties["font"] = textField.font?.displayName ?? "nil"
            node.specialProperties["editable"] = String(textField.isEditable)
        }
        
        if let button = view as? NSButton {
            node.specialProperties["title"] = button.title
            node.specialProperties["enabled"] = String(button.isEnabled)
            node.specialProperties["bezelStyle"] = String(describing: button.bezelStyle)
        }
        
        if let scrollView = view as? NSScrollView {
            node.specialProperties["hasVerticalScroller"] = String(scrollView.hasVerticalScroller)
            node.specialProperties["hasHorizontalScroller"] = String(scrollView.hasHorizontalScroller)
            node.specialProperties["hasDocumentView"] = String(scrollView.documentView != nil)
        }
        
        if let stackView = view as? NSStackView {
            node.specialProperties["orientation"] = stackView.orientation == .horizontal ? "Horizontal" : "Vertical"
            node.specialProperties["spacing"] = String(format: "%.1f", stackView.spacing)
            node.specialProperties["arrangedSubviewsCount"] = String(stackView.arrangedSubviews.count)
            node.specialProperties["alignment"] = String(describing: stackView.alignment)
        }
        
        // 递归处理子视图
        for subview in view.subviews {
            node.children.append(buildHierarchyNode(subview, level: level + 1, parentPath: node.viewPath))
        }
        
        return node
    }
    
    /// 检测布局问题
    /// - Parameter view: 根视图
    /// - Returns: 布局问题列表
    private func detectLayoutIssues(_ view: NSView) -> [LayoutIssue] {
        var issues: [LayoutIssue] = []
        
        detectViewIssues(view, issues: &issues, path: String(describing: type(of: view)))
        
        return issues
    }
    
    /// 递归检测视图问题
    /// - Parameters:
    ///   - view: 当前视图
    ///   - issues: 问题列表
    ///   - path: 视图路径
    private func detectViewIssues(_ view: NSView, issues: inout [LayoutIssue], path: String) {
        let className = String(describing: type(of: view))
        let currentPath = path.isEmpty ? className : "\(path) -> \(className)"
        
        // 检查尺寸问题
        if view.frame.width <= 0 || view.frame.height <= 0 {
            issues.append(LayoutIssue(
                type: .invalidSize,
                severity: .high,
                path: currentPath,
                description: "视图尺寸异常: \(formatRect(view.frame))",
                suggestion: "检查视图的frame设置，确保宽高为正值"
            ))
        }
        
        // 检查可见性问题
        if view.isHidden && !view.subviews.isEmpty {
            issues.append(LayoutIssue(
                type: .hiddenWithSubviews,
                severity: .medium,
                path: currentPath,
                description: "隐藏的视图包含\(view.subviews.count)个子视图",
                suggestion: "考虑是否需要隐藏子视图或显示父视图"
            ))
        }
        
        // 检查透明度问题
        if view.alphaValue <= 0 && !view.subviews.isEmpty {
            issues.append(LayoutIssue(
                type: .transparentWithSubviews,
                severity: .medium,
                path: currentPath,
                description: "完全透明的视图包含\(view.subviews.count)个子视图",
                suggestion: "检查透明度设置是否正确"
            ))
        }
        
        // 检查NSStackView特殊问题
        if let stackView = view as? NSStackView {
            if stackView.arrangedSubviews.isEmpty {
                issues.append(LayoutIssue(
                    type: .emptyStackView,
                    severity: .high,
                    path: currentPath,
                    description: "NSStackView没有arrangedSubviews",
                    suggestion: "检查数据源，确保向NSStackView添加了arrangedSubviews"
                ))
            }
            
            // 检查arrangedSubviews是否都在subviews中
            for arrangedSubview in stackView.arrangedSubviews {
                if !stackView.subviews.contains(arrangedSubview) {
                    issues.append(LayoutIssue(
                        type: .inconsistentStackView,
                        severity: .high,
                        path: currentPath,
                        description: "ArrangedSubview不在subviews中",
                        suggestion: "使用addArrangedSubview()而不是addSubview()"
                    ))
                }
            }
        }
        
        // 检查NSScrollView问题
        if let scrollView = view as? NSScrollView {
            if scrollView.documentView == nil {
                issues.append(LayoutIssue(
                    type: .missingDocumentView,
                    severity: .high,
                    path: currentPath,
                    description: "NSScrollView没有documentView",
                    suggestion: "为NSScrollView设置documentView"
                ))
            }
        }
        
        // 检查约束问题
        if !view.translatesAutoresizingMaskIntoConstraints && view.constraints.isEmpty && view.superview != nil {
            let hasExternalConstraints = view.superview?.constraints.contains { constraint in
                constraint.firstItem === view || constraint.secondItem === view
            } ?? false
            
            if !hasExternalConstraints {
                issues.append(LayoutIssue(
                    type: .missingConstraints,
                    severity: .high,
                    path: currentPath,
                    description: "禁用了autoresizing mask但没有约束",
                    suggestion: "添加必要的Auto Layout约束或启用translatesAutoresizingMaskIntoConstraints"
                ))
            }
        }
        
        // 检查子视图超出边界
        for subview in view.subviews {
            if !view.bounds.contains(subview.frame) {
                issues.append(LayoutIssue(
                    type: .subviewOutOfBounds,
                    severity: .medium,
                    path: "\(currentPath) -> \(String(describing: type(of: subview)))",
                    description: "子视图超出父视图边界",
                    suggestion: "调整子视图的frame或父视图的bounds"
                ))
            }
        }
        
        // 递归检查子视图
        for subview in view.subviews {
            detectViewIssues(subview, issues: &issues, path: currentPath)
        }
    }
    
    /// 分析空间利用率
    /// - Parameter view: 根视图
    /// - Returns: 空间利用分析
    private func analyzeSpaceUtilization(_ view: NSView) -> SpaceUtilizationAnalysis {
        let analysis = SpaceUtilizationAnalysis()
        
        let totalArea = view.bounds.width * view.bounds.height
        var coveredArea: CGFloat = 0
        var visibleSubviews = 0
        
        for subview in view.subviews {
            if !subview.isHidden && subview.alphaValue > 0 {
                coveredArea += subview.frame.width * subview.frame.height
                visibleSubviews += 1
            }
        }
        
        analysis.totalArea = totalArea
        analysis.coveredArea = coveredArea
        analysis.emptyArea = totalArea - coveredArea
        analysis.utilizationRatio = totalArea > 0 ? coveredArea / totalArea : 0
        analysis.visibleSubviewsCount = visibleSubviews
        analysis.hiddenSubviewsCount = view.subviews.count - visibleSubviews
        
        // 分析空间利用效率
        if analysis.utilizationRatio < 0.3 {
            analysis.efficiency = .poor
            analysis.recommendation = "空间利用率过低(\(Int(analysis.utilizationRatio * 100))%)，考虑调整布局或增加内容"
        } else if analysis.utilizationRatio < 0.6 {
            analysis.efficiency = .fair
            analysis.recommendation = "空间利用率一般(\(Int(analysis.utilizationRatio * 100))%)，可以进一步优化"
        } else {
            analysis.efficiency = .good
            analysis.recommendation = "空间利用率良好(\(Int(analysis.utilizationRatio * 100))%)"
        }
        
        return analysis
    }
    
    /// 分析约束
    /// - Parameter view: 根视图
    /// - Returns: 约束分析
    private func analyzeConstraints(_ view: NSView) -> ConstraintAnalysis {
        let analysis = ConstraintAnalysis()
        
        func analyzeViewConstraints(_ v: NSView) {
            analysis.totalViews += 1
            
            if v.translatesAutoresizingMaskIntoConstraints {
                analysis.frameBasedViews += 1
            } else {
                analysis.autoLayoutViews += 1
            }
            
            analysis.totalConstraints += v.constraints.count
            
            // 检查约束冲突（简单检测）
            for constraint in v.constraints {
                if !constraint.isActive {
                    analysis.inactiveConstraints += 1
                }
            }
            
            for subview in v.subviews {
                analyzeViewConstraints(subview)
            }
        }
        
        analyzeViewConstraints(view)
        
        // 生成建议
        if analysis.autoLayoutViews > 0 && analysis.frameBasedViews > 0 {
            analysis.recommendation = "混合使用Frame和Auto Layout，建议统一使用Auto Layout"
        } else if analysis.autoLayoutViews == 0 {
            analysis.recommendation = "完全使用Frame布局，对于复杂界面建议考虑Auto Layout"
        } else {
            analysis.recommendation = "使用Auto Layout布局，布局方式一致"
        }
        
        return analysis
    }
    
    /// 计算视图的坐标信息
    /// - Parameter view: 要分析的视图
    /// - Returns: 坐标信息
    private func calculateCoordinateInfo(for view: NSView) -> CoordinateInfo {
        let relativeFrame = view.frame
        var absoluteFrame = relativeFrame
        var parentFrame: NSRect? = nil
        var conversionSuccessful = true
        
        // 获取父视图信息
        if let superview = view.superview {
            parentFrame = superview.frame
            
            // 尝试转换到窗口坐标系
            if view.window != nil {
                let convertedOrigin = superview.convert(relativeFrame.origin, to: nil)
                absoluteFrame = NSRect(origin: convertedOrigin, size: relativeFrame.size)
            } else {
                // 如果没有窗口，计算相对于根视图的坐标
                var currentView = view
                var accumulatedOrigin = relativeFrame.origin
                
                while let parent = currentView.superview {
                    accumulatedOrigin.x += parent.frame.origin.x
                    accumulatedOrigin.y += parent.frame.origin.y
                    currentView = parent
                }
                
                absoluteFrame = NSRect(origin: accumulatedOrigin, size: relativeFrame.size)
                conversionSuccessful = false
            }
        }
        
        return CoordinateInfo(
            relativeFrame: relativeFrame,
            absoluteFrame: absoluteFrame,
            parentFrame: parentFrame,
            conversionSuccessful: conversionSuccessful
        )
    }
    
    /// 分析坐标问题
    /// - Parameter view: 根视图
    /// - Returns: 坐标分析结果
    private func analyzeCoordinates(_ view: NSView) -> CoordinateAnalysis {
        let analysis = CoordinateAnalysis()
        
        analyzeViewCoordinates(view, analysis: analysis, parentPath: "")
        
        return analysis
    }
    
    /// 递归分析视图坐标
    /// - Parameters:
    ///   - view: 当前视图
    ///   - analysis: 分析结果
    ///   - parentPath: 父视图路径
    private func analyzeViewCoordinates(_ view: NSView, analysis: CoordinateAnalysis, parentPath: String) {
        let className = String(describing: type(of: view))
        let currentPath = parentPath.isEmpty ? className : "\(parentPath) -> \(className)"
        let coordInfo = calculateCoordinateInfo(for: view)
        
        // 检查坐标转换失败
        if !coordInfo.conversionSuccessful {
            analysis.coordinateConversionFailures += 1
            analysis.coordinateIssues.append(CoordinateIssue(
                viewPath: currentPath,
                issueType: .conversionFailure,
                description: "坐标转换失败，无法获取准确的窗口坐标",
                relativeFrame: coordInfo.relativeFrame,
                absoluteFrame: coordInfo.absoluteFrame,
                parentFrame: coordInfo.parentFrame,
                suggestion: "检查视图是否正确添加到窗口层级中"
            ))
        }
        
        // 检查负坐标
        if coordInfo.relativeFrame.origin.x < 0 || coordInfo.relativeFrame.origin.y < 0 {
            analysis.coordinateIssues.append(CoordinateIssue(
                viewPath: currentPath,
                issueType: .negativeCoordinates,
                description: "视图使用负坐标: \(coordInfo.relativeFrame.formattedString)",
                relativeFrame: coordInfo.relativeFrame,
                absoluteFrame: coordInfo.absoluteFrame,
                parentFrame: coordInfo.parentFrame,
                suggestion: "检查视图位置设置，负坐标可能导致显示问题"
            ))
        }
        
        // 检查是否超出父容器边界
        if let parentFrame = coordInfo.parentFrame {
            let parentBounds = NSRect(origin: .zero, size: parentFrame.size)
            if !parentBounds.fullyContains(coordInfo.relativeFrame) {
                analysis.viewsOutOfParentBounds += 1
                analysis.coordinateIssues.append(CoordinateIssue(
                    viewPath: currentPath,
                    issueType: .outOfParentBounds,
                    description: "视图超出父容器边界",
                    relativeFrame: coordInfo.relativeFrame,
                    absoluteFrame: coordInfo.absoluteFrame,
                    parentFrame: coordInfo.parentFrame,
                    suggestion: "调整视图位置或父容器尺寸，确保子视图完全在父容器内"
                ))
            }
        }
        
        // 检查是否超出窗口边界
        if let window = view.window {
            let windowBounds = NSRect(origin: .zero, size: window.frame.size)
            if !windowBounds.fullyContains(coordInfo.absoluteFrame) {
                analysis.viewsOutOfWindowBounds += 1
                analysis.coordinateIssues.append(CoordinateIssue(
                    viewPath: currentPath,
                    issueType: .outOfWindowBounds,
                    description: "视图超出窗口边界",
                    relativeFrame: coordInfo.relativeFrame,
                    absoluteFrame: coordInfo.absoluteFrame,
                    parentFrame: coordInfo.parentFrame,
                    suggestion: "调整视图位置或窗口尺寸，确保视图完全在窗口内"
                ))
            }
        }
        
        // 检查坐标一致性（相对坐标和绝对坐标的逻辑关系）
        if let parentFrame = coordInfo.parentFrame {
            let expectedAbsoluteX = parentFrame.origin.x + coordInfo.relativeFrame.origin.x
            let expectedAbsoluteY = parentFrame.origin.y + coordInfo.relativeFrame.origin.y
            let tolerance: CGFloat = 1.0 // 允许1像素的误差
            
            if abs(coordInfo.absoluteFrame.origin.x - expectedAbsoluteX) > tolerance ||
               abs(coordInfo.absoluteFrame.origin.y - expectedAbsoluteY) > tolerance {
                analysis.inconsistentCoordinates += 1
                analysis.coordinateIssues.append(CoordinateIssue(
                    viewPath: currentPath,
                    issueType: .coordinateInconsistency,
                    description: "相对坐标和绝对坐标不一致",
                    relativeFrame: coordInfo.relativeFrame,
                    absoluteFrame: coordInfo.absoluteFrame,
                    parentFrame: coordInfo.parentFrame,
                    suggestion: "检查视图层级结构和坐标转换逻辑"
                ))
            }
        }
        
        // 递归检查子视图
        for subview in view.subviews {
            analyzeViewCoordinates(subview, analysis: analysis, parentPath: currentPath)
        }
    }
    
    /// 生成改进建议
    /// - Parameter report: 分析报告
    /// - Returns: 改进建议列表
    private func generateImprovementSuggestions(_ report: UIAnalysisReport) -> [ImprovementSuggestion] {
        var suggestions: [ImprovementSuggestion] = []
        
        // 基于空间利用率的建议
        if report.spaceUtilization.efficiency == .poor {
            suggestions.append(ImprovementSuggestion(
                category: .layout,
                priority: .high,
                title: "优化空间利用率",
                description: "当前空间利用率仅为\(Int(report.spaceUtilization.utilizationRatio * 100))%",
                actionItems: [
                    "调整视图位置，减少空白区域",
                    "增加内容填充空白空间",
                    "考虑缩小窗口尺寸",
                    "重新设计布局结构"
                ]
            ))
        }
        
        // 基于布局问题的建议
        let highSeverityIssues = report.layoutIssues.filter { $0.severity == .high }
        if !highSeverityIssues.isEmpty {
            suggestions.append(ImprovementSuggestion(
                category: .bugFix,
                priority: .high,
                title: "修复严重布局问题",
                description: "发现\(highSeverityIssues.count)个严重布局问题",
                actionItems: highSeverityIssues.map { $0.suggestion }
            ))
        }
        
        // 基于约束分析的建议
        if report.constraintAnalysis.frameBasedViews > 0 && report.constraintAnalysis.autoLayoutViews > 0 {
            suggestions.append(ImprovementSuggestion(
                category: .architecture,
                priority: .medium,
                title: "统一布局方式",
                description: "混合使用Frame(\(report.constraintAnalysis.frameBasedViews))和Auto Layout(\(report.constraintAnalysis.autoLayoutViews))",
                actionItems: [
                    "将Frame布局的视图迁移到Auto Layout",
                    "使用约束替代硬编码的frame值",
                    "确保布局在不同屏幕尺寸下的适应性"
                ]
            ))
        }
        
        // 基于坐标分析的建议
        let coordIssues = report.coordinateAnalysis.coordinateIssues
        if !coordIssues.isEmpty {
            let outOfBoundsCount = coordIssues.filter { $0.issueType == .outOfParentBounds || $0.issueType == .outOfWindowBounds }.count
            let inconsistentCount = coordIssues.filter { $0.issueType == .coordinateInconsistency }.count
            let negativeCount = coordIssues.filter { $0.issueType == .negativeCoordinates }.count
            
            if outOfBoundsCount > 0 {
                suggestions.append(ImprovementSuggestion(
                    category: .coordinates,
                    priority: .high,
                    title: "修复视图边界问题",
                    description: "发现\(outOfBoundsCount)个视图超出边界",
                    actionItems: [
                        "检查视图的frame设置，确保在父容器范围内",
                        "调整父容器尺寸以容纳所有子视图",
                        "使用Auto Layout约束避免硬编码位置",
                        "验证窗口尺寸是否足够容纳所有内容"
                    ]
                ))
            }
            
            if inconsistentCount > 0 {
                suggestions.append(ImprovementSuggestion(
                    category: .coordinates,
                    priority: .medium,
                    title: "修复坐标一致性问题",
                    description: "发现\(inconsistentCount)个坐标不一致问题",
                    actionItems: [
                        "检查视图层级结构是否正确",
                        "验证坐标转换逻辑",
                        "确保视图正确添加到父容器中",
                        "使用Auto Layout避免手动坐标计算"
                    ]
                ))
            }
            
            if negativeCount > 0 {
                suggestions.append(ImprovementSuggestion(
                    category: .coordinates,
                    priority: .medium,
                    title: "修复负坐标问题",
                    description: "发现\(negativeCount)个视图使用负坐标",
                    actionItems: [
                        "检查视图位置设置，避免使用负坐标",
                        "调整布局逻辑，确保所有视图位置为正值",
                        "考虑调整父容器的bounds或origin",
                        "使用Auto Layout的leading/trailing约束替代x坐标"
                    ]
                ))
            }
        }
        
        return suggestions
    }
    
    /// 保存报告到文件
    /// - Parameters:
    ///   - report: 分析报告
    ///   - filename: 文件名（可选）
    public func saveReport(_ report: UIAnalysisReport, filename: String? = nil) {
        let reportText = formatReportAsText(report)
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = filename ?? "UIAnalysis_\(report.title.replacingOccurrences(of: " ", with: "_"))_v\(report.version)_\(Int(report.timestamp.timeIntervalSince1970)).txt"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try reportText.write(to: fileURL, atomically: true, encoding: .utf8)
            logger.info("📄 UI分析报告已保存: \(fileURL.path)")
        } catch {
            logger.error("❌ 保存UI分析报告失败: \(error)")
        }
    }
    
    /// 将报告格式化为文本
    /// - Parameter report: 分析报告
    /// - Returns: 格式化的文本
    private func formatReportAsText(_ report: UIAnalysisReport) -> String {
        var lines: [String] = []
        
        // 报告头部
        lines.append("# \(report.title)")
        lines.append("版本: v\(report.version)")
        lines.append("生成时间: \(report.timestamp)")
        lines.append("期望布局: \(report.expectedLayout)")
        lines.append("")
        
        // 基本信息
        lines.append("## 基本信息")
        lines.append("- 根视图类型: \(report.basicInfo.rootViewType)")
        lines.append("- 根视图Frame: \(formatRect(report.basicInfo.rootViewFrame))")
        lines.append("- 总子视图数: \(report.basicInfo.totalSubviews)")
        lines.append("- 最大层级深度: \(report.basicInfo.maxDepth)")
        if let windowFrame = report.basicInfo.windowFrame {
            lines.append("- 窗口Frame: \(formatRect(windowFrame))")
        }
        lines.append("")
        
        // 空间利用分析
        lines.append("## 空间利用分析")
        lines.append("- 总面积: \(Int(report.spaceUtilization.totalArea)) px²")
        lines.append("- 已使用面积: \(Int(report.spaceUtilization.coveredArea)) px²")
        lines.append("- 空白面积: \(Int(report.spaceUtilization.emptyArea)) px²")
        lines.append("- 利用率: \(Int(report.spaceUtilization.utilizationRatio * 100))%")
        lines.append("- 效率评级: \(report.spaceUtilization.efficiency)")
        lines.append("- 建议: \(report.spaceUtilization.recommendation)")
        lines.append("")
        
        // 布局问题
        lines.append("## 布局问题 (\(report.layoutIssues.count)个)")
        if report.layoutIssues.isEmpty {
            lines.append("✅ 未发现布局问题")
        } else {
            for issue in report.layoutIssues {
                let severityIcon = issue.severity == .high ? "🔴" : issue.severity == .medium ? "🟡" : "🟢"
                lines.append("\(severityIcon) [\(issue.type)] \(issue.description)")
                lines.append("   路径: \(issue.path)")
                lines.append("   建议: \(issue.suggestion)")
                lines.append("")
            }
        }
        
        // 约束分析
        lines.append("## 约束分析")
        lines.append("- 总视图数: \(report.constraintAnalysis.totalViews)")
        lines.append("- Frame布局视图: \(report.constraintAnalysis.frameBasedViews)")
        lines.append("- Auto Layout视图: \(report.constraintAnalysis.autoLayoutViews)")
        lines.append("- 总约束数: \(report.constraintAnalysis.totalConstraints)")
        lines.append("- 非活跃约束: \(report.constraintAnalysis.inactiveConstraints)")
        lines.append("- 建议: \(report.constraintAnalysis.recommendation)")
        lines.append("")
        
        // 坐标分析
        lines.append("## 坐标分析")
        lines.append("- 坐标不一致: \(report.coordinateAnalysis.inconsistentCoordinates)个")
        lines.append("- 超出父容器边界: \(report.coordinateAnalysis.viewsOutOfParentBounds)个")
        lines.append("- 超出窗口边界: \(report.coordinateAnalysis.viewsOutOfWindowBounds)个")
        lines.append("- 坐标转换失败: \(report.coordinateAnalysis.coordinateConversionFailures)个")
        lines.append("")
        
        // 坐标问题详情
        if !report.coordinateAnalysis.coordinateIssues.isEmpty {
            lines.append("## 坐标问题详情 (\(report.coordinateAnalysis.coordinateIssues.count)个)")
            for issue in report.coordinateAnalysis.coordinateIssues {
                let typeIcon = getCoordinateIssueIcon(issue.issueType)
                lines.append("\(typeIcon) [\(issue.issueType.rawValue)] \(issue.description)")
                lines.append("   路径: \(issue.viewPath)")
                lines.append("   相对坐标: \(issue.relativeFrame.formattedString)")
                lines.append("   绝对坐标: \(issue.absoluteFrame.formattedString)")
                if let parentFrame = issue.parentFrame {
                    lines.append("   父容器: \(parentFrame.formattedString)")
                }
                lines.append("   建议: \(issue.suggestion)")
                lines.append("")
            }
        }
        
        // 改进建议
        lines.append("## 改进建议 (\(report.improvementSuggestions.count)个)")
        for suggestion in report.improvementSuggestions {
            let priorityIcon = suggestion.priority == .high ? "🔴" : suggestion.priority == .medium ? "🟡" : "🟢"
            lines.append("\(priorityIcon) [\(suggestion.category)] \(suggestion.title)")
            lines.append("   描述: \(suggestion.description)")
            lines.append("   行动项:")
            for actionItem in suggestion.actionItems {
                lines.append("   - \(actionItem)")
            }
            lines.append("")
        }
        
        // 视图层级结构
        lines.append("## 视图层级结构")
        lines.append(formatHierarchyNode(report.viewHierarchy, level: 0))
        
        return lines.joined(separator: "\n")
    }
    
    /// 格式化层级节点
    /// - Parameters:
    ///   - node: 层级节点
    ///   - level: 层级深度
    /// - Returns: 格式化的字符串
    private func formatHierarchyNode(_ node: ViewHierarchyNode, level: Int) -> String {
        var lines: [String] = []
        let indent = String(repeating: "  ", count: level)
        let icon = node.children.isEmpty ? "📄" : "📁"
        
        var info = "\(indent)\(icon) \(node.className)"
        if node.isHidden { info += " [HIDDEN]" }
        if node.alpha < 1.0 { info += " [α=\(String(format: "%.2f", node.alpha))]" }
        
        lines.append(info)
        lines.append("\(indent)    📐 相对Frame: \(formatRect(node.frame))")
        
        // 添加坐标信息
        if let coordInfo = node.coordinateInfo {
            lines.append("\(indent)    🌍 绝对Frame: \(coordInfo.absoluteFrame.formattedString)")
            if let parentFrame = coordInfo.parentFrame {
                lines.append("\(indent)    👆 父容器Frame: \(parentFrame.formattedString)")
            }
            if !coordInfo.conversionSuccessful {
                lines.append("\(indent)    ⚠️ 坐标转换失败")
            }
        }
        
        // 添加特殊属性
        for (key, value) in node.specialProperties {
            lines.append("\(indent)    \(key): \(value)")
        }
        
        // 递归处理子节点
        for child in node.children {
            lines.append(formatHierarchyNode(child, level: level + 1))
        }
        
        return lines.joined(separator: "\n")
    }
    
    /// 获取坐标问题图标
    /// - Parameter issueType: 问题类型
    /// - Returns: 对应的图标
    private func getCoordinateIssueIcon(_ issueType: CoordinateIssueType) -> String {
        switch issueType {
        case .outOfParentBounds:
            return "🔴"
        case .outOfWindowBounds:
            return "🟠"
        case .coordinateInconsistency:
            return "🟡"
        case .conversionFailure:
            return "🔵"
        case .negativeCoordinates:
            return "🟣"
        case .unexpectedPosition:
            return "⚫"
        }
    }
    
    // MARK: - 辅助方法
    
    private func countTotalSubviews(_ view: NSView) -> Int {
        var count = view.subviews.count
        for subview in view.subviews {
            count += countTotalSubviews(subview)
        }
        return count
    }
    
    private func calculateMaxDepth(_ view: NSView) -> Int {
        if view.subviews.isEmpty {
            return 0
        }
        
        var maxDepth = 0
        for subview in view.subviews {
            maxDepth = max(maxDepth, calculateMaxDepth(subview))
        }
        
        return maxDepth + 1
    }
    
    private func formatRect(_ rect: NSRect) -> String {
        return "(\(Int(rect.origin.x)), \(Int(rect.origin.y)), \(Int(rect.size.width)), \(Int(rect.size.height)))"
    }
}

// MARK: - 便捷扩展

extension NSView {
    /// 生成UI分析报告
    /// - Parameters:
    ///   - title: 报告标题
    ///   - expectedLayout: 期望布局描述
    /// - Returns: 分析报告
    public func generateUIAnalysisReport(title: String? = nil, expectedLayout: String = "") -> UIAnalysisReport {
        let reportTitle = title ?? "UI Analysis - \(String(describing: type(of: self)))"
        return UIInspector.shared.generateUIAnalysisReport(self, title: reportTitle, expectedLayout: expectedLayout)
    }
    
    /// 生成并保存UI分析报告
    /// - Parameters:
    ///   - title: 报告标题
    ///   - expectedLayout: 期望布局描述
    ///   - filename: 文件名（可选）
    public func analyzeAndSaveUIReport(title: String? = nil, expectedLayout: String = "", filename: String? = nil) {
        let report = generateUIAnalysisReport(title: title, expectedLayout: expectedLayout)
        UIInspector.shared.saveReport(report, filename: filename)
    }
}
