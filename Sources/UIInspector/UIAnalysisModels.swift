import Foundation
import AppKit

// MARK: - UI分析报告主体

/// UI分析报告
public class UIAnalysisReport {
    public let title: String
    public let version: Int
    public let timestamp: Date
    public let expectedLayout: String
    
    public var basicInfo: BasicInfo!
    public var viewHierarchy: ViewHierarchyNode!
    public var layoutIssues: [LayoutIssue] = []
    public var spaceUtilization: SpaceUtilizationAnalysis!
    public var constraintAnalysis: ConstraintAnalysis!
    public var improvementSuggestions: [ImprovementSuggestion] = []
    
    public init(title: String, version: Int, timestamp: Date, expectedLayout: String) {
        self.title = title
        self.version = version
        self.timestamp = timestamp
        self.expectedLayout = expectedLayout
    }
}

// MARK: - 基本信息

/// 基本信息
public class BasicInfo {
    public var rootViewType: String = ""
    public var rootViewFrame: NSRect = .zero
    public var rootViewBounds: NSRect = .zero
    public var totalSubviews: Int = 0
    public var maxDepth: Int = 0
    public var windowFrame: NSRect?
    public var windowTitle: String?
    
    public init() {}
}

// MARK: - 视图层级结构

/// 视图层级节点
public class ViewHierarchyNode {
    public var className: String = ""
    public var frame: NSRect = .zero
    public var bounds: NSRect = .zero
    public var isHidden: Bool = false
    public var alpha: CGFloat = 1.0
    public var level: Int = 0
    public var hasConstraints: Bool = false
    public var usesAutoLayout: Bool = false
    public var specialProperties: [String: String] = [:]
    public var children: [ViewHierarchyNode] = []
    
    public init() {}
}

// MARK: - 布局问题

/// 布局问题类型
public enum LayoutIssueType: String, CaseIterable {
    case invalidSize = "InvalidSize"
    case hiddenWithSubviews = "HiddenWithSubviews"
    case transparentWithSubviews = "TransparentWithSubviews"
    case emptyStackView = "EmptyStackView"
    case inconsistentStackView = "InconsistentStackView"
    case missingDocumentView = "MissingDocumentView"
    case missingConstraints = "MissingConstraints"
    case subviewOutOfBounds = "SubviewOutOfBounds"
}

/// 问题严重程度
public enum IssueSeverity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

/// 布局问题
public struct LayoutIssue {
    public let type: LayoutIssueType
    public let severity: IssueSeverity
    public let path: String
    public let description: String
    public let suggestion: String
    
    public init(type: LayoutIssueType, severity: IssueSeverity, path: String, description: String, suggestion: String) {
        self.type = type
        self.severity = severity
        self.path = path
        self.description = description
        self.suggestion = suggestion
    }
}

// MARK: - 空间利用分析

/// 空间利用效率
public enum SpaceUtilizationEfficiency: String, CaseIterable {
    case poor = "Poor"
    case fair = "Fair"
    case good = "Good"
}

/// 空间利用分析
public class SpaceUtilizationAnalysis {
    public var totalArea: CGFloat = 0
    public var coveredArea: CGFloat = 0
    public var emptyArea: CGFloat = 0
    public var utilizationRatio: CGFloat = 0
    public var visibleSubviewsCount: Int = 0
    public var hiddenSubviewsCount: Int = 0
    public var efficiency: SpaceUtilizationEfficiency = .fair
    public var recommendation: String = ""
    
    public init() {}
}

// MARK: - 约束分析

/// 约束分析
public class ConstraintAnalysis {
    public var totalViews: Int = 0
    public var frameBasedViews: Int = 0
    public var autoLayoutViews: Int = 0
    public var totalConstraints: Int = 0
    public var inactiveConstraints: Int = 0
    public var recommendation: String = ""
    
    public init() {}
}

// MARK: - 改进建议

/// 建议类别
public enum SuggestionCategory: String, CaseIterable {
    case layout = "Layout"
    case performance = "Performance"
    case accessibility = "Accessibility"
    case architecture = "Architecture"
    case bugFix = "BugFix"
}

/// 建议优先级
public enum SuggestionPriority: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

/// 改进建议
public struct ImprovementSuggestion {
    public let category: SuggestionCategory
    public let priority: SuggestionPriority
    public let title: String
    public let description: String
    public let actionItems: [String]
    
    public init(category: SuggestionCategory, priority: SuggestionPriority, title: String, description: String, actionItems: [String]) {
        self.category = category
        self.priority = priority
        self.title = title
        self.description = description
        self.actionItems = actionItems
    }
}

// MARK: - 报告比较

/// 报告比较结果
public class ReportComparison {
    public let beforeReport: UIAnalysisReport
    public let afterReport: UIAnalysisReport
    public var improvements: [String] = []
    public var regressions: [String] = []
    public var newIssues: [LayoutIssue] = []
    public var resolvedIssues: [LayoutIssue] = []
    
    public init(beforeReport: UIAnalysisReport, afterReport: UIAnalysisReport) {
        self.beforeReport = beforeReport
        self.afterReport = afterReport
        analyzeChanges()
    }
    
    private func analyzeChanges() {
        // 比较空间利用率
        let beforeUtilization = beforeReport.spaceUtilization.utilizationRatio
        let afterUtilization = afterReport.spaceUtilization.utilizationRatio
        
        if afterUtilization > beforeUtilization {
            improvements.append("空间利用率提升: \(Int(beforeUtilization * 100))% → \(Int(afterUtilization * 100))%")
        } else if afterUtilization < beforeUtilization {
            regressions.append("空间利用率下降: \(Int(beforeUtilization * 100))% → \(Int(afterUtilization * 100))%")
        }
        
        // 比较问题数量
        let beforeIssueCount = beforeReport.layoutIssues.count
        let afterIssueCount = afterReport.layoutIssues.count
        
        if afterIssueCount < beforeIssueCount {
            improvements.append("布局问题减少: \(beforeIssueCount) → \(afterIssueCount)")
        } else if afterIssueCount > beforeIssueCount {
            regressions.append("布局问题增加: \(beforeIssueCount) → \(afterIssueCount)")
        }
        
        // 分析具体问题变化
        let beforeIssueTypes = Set(beforeReport.layoutIssues.map { $0.type })
        let afterIssueTypes = Set(afterReport.layoutIssues.map { $0.type })
        
        // 新增问题
        let newIssueTypes = afterIssueTypes.subtracting(beforeIssueTypes)
        newIssues = afterReport.layoutIssues.filter { newIssueTypes.contains($0.type) }
        
        // 已解决问题
        let resolvedIssueTypes = beforeIssueTypes.subtracting(afterIssueTypes)
        resolvedIssues = beforeReport.layoutIssues.filter { resolvedIssueTypes.contains($0.type) }
    }
}

// MARK: - 扩展方法

extension UIAnalysisReport {
    /// 生成摘要
    public var summary: String {
        var lines: [String] = []
        
        lines.append("📊 \(title) - v\(version)")
        lines.append("🕒 \(timestamp)")
        lines.append("📐 根视图: \(basicInfo.rootViewType)")
        lines.append("📱 子视图总数: \(basicInfo.totalSubviews)")
        lines.append("🔍 布局问题: \(layoutIssues.count)个")
        lines.append("📈 空间利用率: \(Int(spaceUtilization.utilizationRatio * 100))%")
        lines.append("💡 改进建议: \(improvementSuggestions.count)个")
        
        return lines.joined(separator: "\n")
    }
    
    /// 获取高优先级问题
    public var highPriorityIssues: [LayoutIssue] {
        return layoutIssues.filter { $0.severity == .high }
    }
    
    /// 获取高优先级建议
    public var highPrioritySuggestions: [ImprovementSuggestion] {
        return improvementSuggestions.filter { $0.priority == .high }
    }
}

extension ViewHierarchyNode {
    /// 查找特定类型的节点
    public func findNodes(ofType className: String) -> [ViewHierarchyNode] {
        var results: [ViewHierarchyNode] = []
        
        if self.className == className {
            results.append(self)
        }
        
        for child in children {
            results.append(contentsOf: child.findNodes(ofType: className))
        }
        
        return results
    }
    
    /// 获取节点路径
    public func getPath() -> String {
        // 这里需要从根节点开始构建路径，简化实现
        return className
    }
}
