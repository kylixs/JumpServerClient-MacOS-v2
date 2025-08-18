import Foundation
import AppKit

// MARK: - 坐标信息

/// 坐标信息结构
public struct CoordinateInfo {
    /// 相对坐标（相对于父容器）
    public let relativeFrame: NSRect
    /// 绝对坐标（相对于窗口）
    public let absoluteFrame: NSRect
    /// 父容器Frame
    public let parentFrame: NSRect?
    /// 坐标转换是否成功
    public let conversionSuccessful: Bool
    
    public init(relativeFrame: NSRect, absoluteFrame: NSRect, parentFrame: NSRect?, conversionSuccessful: Bool) {
        self.relativeFrame = relativeFrame
        self.absoluteFrame = absoluteFrame
        self.parentFrame = parentFrame
        self.conversionSuccessful = conversionSuccessful
    }
}

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
    public var coordinateAnalysis: CoordinateAnalysis!
    
    public init(title: String, version: Int, timestamp: Date, expectedLayout: String) {
        self.title = title
        self.version = version
        self.timestamp = timestamp
        self.expectedLayout = expectedLayout
    }
}

// MARK: - 坐标分析

/// 坐标分析结果
public class CoordinateAnalysis {
    /// 坐标不一致的视图数量
    public var inconsistentCoordinates: Int = 0
    /// 超出父容器边界的视图数量
    public var viewsOutOfParentBounds: Int = 0
    /// 超出窗口边界的视图数量
    public var viewsOutOfWindowBounds: Int = 0
    /// 坐标转换失败的视图数量
    public var coordinateConversionFailures: Int = 0
    /// 详细的坐标问题列表
    public var coordinateIssues: [CoordinateIssue] = []
    
    public init() {}
}

/// 坐标问题
public struct CoordinateIssue {
    public let viewPath: String
    public let issueType: CoordinateIssueType
    public let description: String
    public let relativeFrame: NSRect
    public let absoluteFrame: NSRect
    public let parentFrame: NSRect?
    public let suggestion: String
    
    public init(viewPath: String, issueType: CoordinateIssueType, description: String, 
                relativeFrame: NSRect, absoluteFrame: NSRect, parentFrame: NSRect?, suggestion: String) {
        self.viewPath = viewPath
        self.issueType = issueType
        self.description = description
        self.relativeFrame = relativeFrame
        self.absoluteFrame = absoluteFrame
        self.parentFrame = parentFrame
        self.suggestion = suggestion
    }
}

/// 坐标问题类型
public enum CoordinateIssueType: String, CaseIterable {
    case outOfParentBounds = "OutOfParentBounds"
    case outOfWindowBounds = "OutOfWindowBounds"
    case coordinateInconsistency = "CoordinateInconsistency"
    case conversionFailure = "ConversionFailure"
    case negativeCoordinates = "NegativeCoordinates"
    case unexpectedPosition = "UnexpectedPosition"
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
    
    // 新增坐标信息
    public var coordinateInfo: CoordinateInfo!
    public var viewPath: String = ""
    
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
    case coordinates = "Coordinates"
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
        
        // 比较坐标问题
        let beforeCoordIssues = beforeReport.coordinateAnalysis.coordinateIssues.count
        let afterCoordIssues = afterReport.coordinateAnalysis.coordinateIssues.count
        
        if afterCoordIssues < beforeCoordIssues {
            improvements.append("坐标问题减少: \(beforeCoordIssues) → \(afterCoordIssues)")
        } else if afterCoordIssues > beforeCoordIssues {
            regressions.append("坐标问题增加: \(beforeCoordIssues) → \(afterCoordIssues)")
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
        lines.append("📍 坐标问题: \(coordinateAnalysis.coordinateIssues.count)个")
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
    
    /// 获取坐标相关问题
    public var coordinateIssues: [CoordinateIssue] {
        return coordinateAnalysis.coordinateIssues
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
        return viewPath.isEmpty ? className : viewPath
    }
}

// MARK: - 坐标工具函数

extension NSRect {
    /// 格式化为字符串
    public var formattedString: String {
        return "(\(Int(origin.x)), \(Int(origin.y)), \(Int(size.width)), \(Int(size.height)))"
    }
    
    /// 检查是否包含另一个矩形
    public func fullyContains(_ rect: NSRect) -> Bool {
        return self.contains(rect.origin) && 
               self.contains(NSPoint(x: rect.maxX, y: rect.maxY))
    }
    
    /// 计算与另一个矩形的重叠面积
    public func overlapArea(with rect: NSRect) -> CGFloat {
        let intersection = self.intersection(rect)
        return intersection.width * intersection.height
    }
}
