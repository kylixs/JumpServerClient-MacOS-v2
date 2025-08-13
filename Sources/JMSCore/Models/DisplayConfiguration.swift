import Foundation
import CoreGraphics

/// 显示器配置信息
public struct DisplayConfiguration {
    public let width: Int
    public let height: Int
    public let scaleFactor: Double
    public let colorDepth: Int
    public let isHiDPI: Bool
    public let refreshRate: Double
    public let displayID: CGDirectDisplayID
    
    // 新增属性
    public let displayName: String?          // 显示器名称
    public let isBuiltIn: Bool              // 是否内置显示器
    public let physicalSize: CGSize?        // 物理尺寸（毫米）
    public let dpi: Double?                 // DPI值
    public let recommendedScaleFactor: Double // 推荐缩放因子
    public let displayType: DisplayType     // 显示器类型
    
    public init(
        width: Int, 
        height: Int, 
        scaleFactor: Double = 1.0, 
        colorDepth: Int = 32, 
        isHiDPI: Bool = false, 
        refreshRate: Double = 60.0, 
        displayID: CGDirectDisplayID = 0,
        displayName: String? = nil,
        isBuiltIn: Bool = false,
        physicalSize: CGSize? = nil,
        dpi: Double? = nil,
        recommendedScaleFactor: Double? = nil,
        displayType: DisplayType = .unknown
    ) {
        self.width = width
        self.height = height
        self.scaleFactor = scaleFactor
        self.colorDepth = colorDepth
        self.isHiDPI = isHiDPI
        self.refreshRate = refreshRate
        self.displayID = displayID
        self.displayName = displayName
        self.isBuiltIn = isBuiltIn
        self.physicalSize = physicalSize
        self.dpi = dpi
        self.recommendedScaleFactor = recommendedScaleFactor ?? (isHiDPI ? 2.0 : 1.0)
        self.displayType = displayType
    }
    
    /// 获取分辨率字符串
    public var resolutionString: String {
        return "\(width)x\(height)"
    }
    
    /// 获取像素密度类型
    public var densityType: DisplayDensityType {
        if isHiDPI {
            return scaleFactor >= 2.0 ? .retina : .hiDPI
        } else {
            return .standard
        }
    }
    
    /// 获取推荐的RDP颜色深度
    public var recommendedColorDepth: Int {
        switch colorDepth {
        case 16:
            return 16
        case 24:
            return 24
        case 32:
            return 32
        default:
            return 24 // 默认24位
        }
    }
    
    /// 是否为4K显示器
    public var is4K: Bool {
        return width >= 3840 && height >= 2160
    }
    
    /// 是否为超宽屏
    public var isUltraWide: Bool {
        let aspectRatio = Double(width) / Double(height)
        return aspectRatio >= 2.0
    }
    
    /// 获取显示器描述
    public var displayDescription: String {
        let hiDPIText = isHiDPI ? " HiDPI" : ""
        let builtInText = isBuiltIn ? " (内置)" : ""
        return "\(width)×\(height)\(hiDPIText)\(builtInText)"
    }
    
    /// 获取DPI描述
    public var dpiDescription: String {
        guard let dpi = dpi else { return "未知DPI" }
        return String(format: "%.0f DPI", dpi)
    }
    
    /// 获取推荐配置描述
    public var recommendationDescription: String {
        let scaleText = String(format: "%.2f", recommendedScaleFactor)
        return "推荐缩放: \(scaleText)x"
    }
}

/// 显示器类型
public enum DisplayType {
    case builtInRetina      // 内置Retina显示器
    case external4K         // 外接4K显示器
    case externalHD         // 外接HD显示器
    case ultraWide          // 超宽显示器
    case unknown            // 未知类型
    
    public var description: String {
        switch self {
        case .builtInRetina:
            return "内置Retina显示器"
        case .external4K:
            return "外接4K显示器"
        case .externalHD:
            return "外接HD显示器"
        case .ultraWide:
            return "超宽显示器"
        case .unknown:
            return "未知类型"
        }
    }
    
    /// 获取推荐的缩放因子
    public var recommendedScaleFactor: Double {
        switch self {
        case .builtInRetina:
            return 2.0
        case .external4K:
            return 1.5
        case .externalHD:
            return 1.0
        case .ultraWide:
            return 1.25
        case .unknown:
            return 1.0
        }
    }
}

/// 显示器密度类型
public enum DisplayDensityType {
    case standard   // 标准密度
    case hiDPI      // 高密度
    case retina     // Retina显示器
    
    public var description: String {
        switch self {
        case .standard:
            return "标准显示器"
        case .hiDPI:
            return "高密度显示器"
        case .retina:
            return "Retina显示器"
        }
    }
}
