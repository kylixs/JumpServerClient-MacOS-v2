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
    
    public init(width: Int, height: Int, scaleFactor: Double = 1.0, colorDepth: Int = 32, isHiDPI: Bool = false, refreshRate: Double = 60.0, displayID: CGDirectDisplayID = 0) {
        self.width = width
        self.height = height
        self.scaleFactor = scaleFactor
        self.colorDepth = colorDepth
        self.isHiDPI = isHiDPI
        self.refreshRate = refreshRate
        self.displayID = displayID
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
