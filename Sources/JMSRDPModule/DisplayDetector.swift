import Foundation
import CoreGraphics
import JMSCore

/// 显示器检测服务
public class DisplayDetector {
    
    public init() {}
    
    /// 检测主显示器配置
    /// - Returns: 主显示器的配置信息
    /// - Throws: JMSError.displayDetectionFailed
    public func detectPrimaryDisplay() throws -> DisplayConfiguration {
        guard let mainDisplayID = getMainDisplayID() else {
            throw JMSError.displayDetectionFailed("无法获取主显示器ID")
        }
        
        return try detectDisplay(displayID: mainDisplayID)
    }
    
    /// 检测所有显示器配置
    /// - Returns: 所有显示器的配置信息数组
    /// - Throws: JMSError.displayDetectionFailed
    public func detectAllDisplays() throws -> [DisplayConfiguration] {
        let maxDisplays: UInt32 = 32
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
        var displayCount: UInt32 = 0
        
        let result = CGGetActiveDisplayList(maxDisplays, &displayIDs, &displayCount)
        guard result == .success else {
            throw JMSError.displayDetectionFailed("无法获取显示器列表: \(result)")
        }
        
        var configurations: [DisplayConfiguration] = []
        
        for i in 0..<Int(displayCount) {
            do {
                let config = try detectDisplay(displayID: displayIDs[i])
                configurations.append(config)
            } catch {
                // 跳过检测失败的显示器，继续检测其他显示器
                print("跳过显示器 \(displayIDs[i]): \(error.localizedDescription)")
            }
        }
        
        guard !configurations.isEmpty else {
            throw JMSError.displayDetectionFailed("未检测到任何有效的显示器")
        }
        
        return configurations
    }
    
    /// 检测指定显示器的配置
    /// - Parameter displayID: 显示器ID
    /// - Returns: 显示器配置信息
    /// - Throws: JMSError.displayDetectionFailed
    public func detectDisplay(displayID: CGDirectDisplayID) throws -> DisplayConfiguration {
        // 获取显示器模式
        guard let mode = CGDisplayCopyDisplayMode(displayID) else {
            throw JMSError.displayDetectionFailed("无法获取显示器模式")
        }
        
        // 获取基本信息
        let width = Int(mode.width)
        let height = Int(mode.height)
        let refreshRate = mode.refreshRate
        
        // 检测缩放因子和HiDPI
        let (scaleFactor, isHiDPI) = detectScaleFactorAndHiDPI(displayID: displayID)
        
        // 检测颜色深度
        let colorDepth = detectColorDepth(displayID: displayID)
        
        return DisplayConfiguration(
            width: width,
            height: height,
            scaleFactor: scaleFactor,
            colorDepth: colorDepth,
            isHiDPI: isHiDPI,
            refreshRate: refreshRate,
            displayID: displayID
        )
    }
    
    // MARK: - Private Methods
    
    private func getMainDisplayID() -> CGDirectDisplayID? {
        let mainDisplayID = CGMainDisplayID()
        return mainDisplayID != kCGNullDirectDisplay ? mainDisplayID : nil
    }
    
    private func detectScaleFactorAndHiDPI(displayID: CGDirectDisplayID) -> (Double, Bool) {
        // 获取显示器的物理尺寸和像素尺寸
        let physicalSize = CGDisplayScreenSize(displayID)
        guard let mode = CGDisplayCopyDisplayMode(displayID) else {
            return (1.0, false)
        }
        
        let pixelWidth = mode.width
        let pixelHeight = mode.height
        
        // 计算DPI
        let dpiX = Double(pixelWidth) / (physicalSize.width / 25.4) // 转换为英寸
        let dpiY = Double(pixelHeight) / (physicalSize.height / 25.4)
        let averageDPI = (dpiX + dpiY) / 2.0
        
        // 判断是否为HiDPI
        let isHiDPI = averageDPI > 150.0
        
        // 计算缩放因子
        let scaleFactor: Double
        if isHiDPI {
            // 对于HiDPI显示器，通常缩放因子为2.0或更高
            scaleFactor = round(averageDPI / 96.0 * 10) / 10 // 保留一位小数
        } else {
            scaleFactor = 1.0
        }
        
        return (scaleFactor, isHiDPI)
    }
    
    private func detectColorDepth(displayID: CGDirectDisplayID) -> Int {
        // 对于现代macOS系统，大多数显示器支持32位颜色深度
        // 我们使用简化的检测逻辑
        
        // 获取显示器的颜色空间
        let colorSpace = CGDisplayCopyColorSpace(displayID)
        let model = colorSpace.model
        
        // 根据颜色空间模型推断颜色深度
        switch model {
        case .rgb:
            return 32 // RGB通常是32位
        case .monochrome:
            return 8  // 单色通常是8位
        case .cmyk:
            return 32 // CMYK通常是32位
        case .lab:
            return 24 // Lab通常是24位
        default:
            return 24 // 默认24位
        }
    }
}
