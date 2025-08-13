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
        // 获取物理分辨率和缩放信息
        let (physicalWidth, physicalHeight, scaleFactor, isHiDPI) = try getPhysicalResolutionAndScale(displayID: displayID)
        
        // 获取刷新率
        let refreshRate = getRefreshRate(displayID: displayID)
        
        // 检测颜色深度
        let colorDepth = detectColorDepth(displayID: displayID)
        
        return DisplayConfiguration(
            width: physicalWidth,
            height: physicalHeight,
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
    
    /// 获取物理分辨率和缩放因子
    /// - Parameter displayID: 显示器ID
    /// - Returns: (物理宽度, 物理高度, 缩放因子, 是否HiDPI)
    /// - Throws: JMSError.displayDetectionFailed
    private func getPhysicalResolutionAndScale(displayID: CGDirectDisplayID) throws -> (Int, Int, Double, Bool) {
        // 方法1: 尝试获取原生分辨率
        if let nativeMode = getNativeDisplayMode(displayID: displayID) {
            let nativeWidth = Int(nativeMode.width)
            let nativeHeight = Int(nativeMode.height)
            
            // 获取当前逻辑分辨率
            let logicalBounds = CGDisplayBounds(displayID)
            let logicalWidth = Int(logicalBounds.width)
            let logicalHeight = Int(logicalBounds.height)
            
            // 计算缩放因子
            let scaleX = Double(nativeWidth) / Double(logicalWidth)
            let scaleY = Double(nativeHeight) / Double(logicalHeight)
            let scaleFactor = max(scaleX, scaleY)
            
            // 判断是否为HiDPI (缩放因子 > 1.5)
            let isHiDPI = scaleFactor > 1.5
            
            print("🔍 显示器检测 - 原生: \(nativeWidth)×\(nativeHeight), 逻辑: \(logicalWidth)×\(logicalHeight), 缩放: \(scaleFactor)")
            
            return (nativeWidth, nativeHeight, scaleFactor, isHiDPI)
        }
        
        // 方法2: 使用DPI计算 (备用方法)
        return try getResolutionByDPI(displayID: displayID)
    }
    
    /// 获取显示器的原生模式
    /// - Parameter displayID: 显示器ID
    /// - Returns: 原生显示模式
    private func getNativeDisplayMode(displayID: CGDirectDisplayID) -> CGDisplayMode? {
        // 获取所有可用的显示模式
        guard let modes = CGDisplayCopyAllDisplayModes(displayID, nil) else {
            return nil
        }
        
        let modeCount = CFArrayGetCount(modes)
        var nativeMode: CGDisplayMode?
        var maxPixels = 0
        
        // 查找像素数最高的模式（通常是原生分辨率）
        for i in 0..<modeCount {
            if let mode = CFArrayGetValueAtIndex(modes, i) {
                let displayMode = Unmanaged<CGDisplayMode>.fromOpaque(mode).takeUnretainedValue()
                let pixels = Int(displayMode.width * displayMode.height)
                
                // 选择像素数最高且刷新率合理的模式
                if pixels > maxPixels && displayMode.refreshRate > 0 {
                    maxPixels = pixels
                    nativeMode = displayMode
                }
            }
        }
        
        return nativeMode
    }
    
    /// 通过DPI计算分辨率 (备用方法)
    /// - Parameter displayID: 显示器ID
    /// - Returns: (物理宽度, 物理高度, 缩放因子, 是否HiDPI)
    /// - Throws: JMSError.displayDetectionFailed
    private func getResolutionByDPI(displayID: CGDirectDisplayID) throws -> (Int, Int, Double, Bool) {
        // 获取当前显示模式
        guard let mode = CGDisplayCopyDisplayMode(displayID) else {
            throw JMSError.displayDetectionFailed("无法获取显示器模式")
        }
        
        // 获取物理尺寸
        let physicalSize = CGDisplayScreenSize(displayID)
        guard physicalSize.width > 0 && physicalSize.height > 0 else {
            throw JMSError.displayDetectionFailed("无法获取显示器物理尺寸")
        }
        
        let logicalWidth = Int(mode.width)
        let logicalHeight = Int(mode.height)
        
        // 计算DPI
        let dpiX = Double(logicalWidth) / (physicalSize.width / 25.4) // 转换为英寸
        let dpiY = Double(logicalHeight) / (physicalSize.height / 25.4)
        let averageDPI = (dpiX + dpiY) / 2.0
        
        // 判断是否为HiDPI
        let isHiDPI = averageDPI > 150.0
        
        // 计算物理分辨率和缩放因子
        let scaleFactor: Double
        let physicalWidth: Int
        let physicalHeight: Int
        
        if isHiDPI {
            // 对于HiDPI显示器，物理分辨率通常是逻辑分辨率的2倍或更高
            scaleFactor = round(averageDPI / 96.0 * 10) / 10 // 保留一位小数
            physicalWidth = Int(Double(logicalWidth) * scaleFactor)
            physicalHeight = Int(Double(logicalHeight) * scaleFactor)
        } else {
            scaleFactor = 1.0
            physicalWidth = logicalWidth
            physicalHeight = logicalHeight
        }
        
        print("🔍 显示器检测 (DPI) - 逻辑: \(logicalWidth)×\(logicalHeight), 物理: \(physicalWidth)×\(physicalHeight), DPI: \(Int(averageDPI)), 缩放: \(scaleFactor)")
        
        return (physicalWidth, physicalHeight, scaleFactor, isHiDPI)
    }
    
    /// 获取刷新率
    /// - Parameter displayID: 显示器ID
    /// - Returns: 刷新率
    private func getRefreshRate(displayID: CGDirectDisplayID) -> Double {
        guard let mode = CGDisplayCopyDisplayMode(displayID) else {
            return 60.0 // 默认60Hz
        }
        
        let refreshRate = mode.refreshRate
        return refreshRate > 0 ? refreshRate : 60.0
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
