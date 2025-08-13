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
        
        // 获取显示器名称
        let displayName = getDisplayName(displayID: displayID)
        
        // 检测是否为内置显示器
        let isBuiltIn = isBuiltInDisplay(displayID)
        
        // 获取物理尺寸
        let physicalSize = CGDisplayScreenSize(displayID)
        
        // 计算DPI
        let dpi = calculateDPI(displayID: displayID, physicalSize: physicalSize, width: physicalWidth, height: physicalHeight)
        
        // 确定显示器类型
        let displayType = determineDisplayType(displayID: displayID, width: physicalWidth, height: physicalHeight, isBuiltIn: isBuiltIn, dpi: dpi)
        
        // 计算推荐缩放因子
        let recommendedScale = calculateRecommendedScaleFactor(displayType: displayType, dpi: dpi, isHiDPI: isHiDPI)
        
        return DisplayConfiguration(
            width: physicalWidth,
            height: physicalHeight,
            scaleFactor: scaleFactor,
            colorDepth: colorDepth,
            isHiDPI: isHiDPI,
            refreshRate: refreshRate,
            displayID: displayID,
            displayName: displayName,
            isBuiltIn: isBuiltIn,
            physicalSize: physicalSize.width > 0 ? physicalSize : nil,
            dpi: dpi,
            recommendedScaleFactor: recommendedScale,
            displayType: displayType
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
    
    /// 获取显示器名称
    /// - Parameter displayID: 显示器ID
    /// - Returns: 显示器名称
    private func getDisplayName(displayID: CGDirectDisplayID) -> String {
        // 尝试获取显示器名称（这在macOS中比较复杂，简化处理）
        if displayID == CGMainDisplayID() {
            return "内置显示器"
        } else {
            return "外接显示器"
        }
    }
    
    /// 检测是否为内置显示器
    /// - Parameter displayID: 显示器ID
    /// - Returns: 是否为内置显示器
    private func isBuiltInDisplay(_ displayID: CGDirectDisplayID) -> Bool {
        return displayID == CGMainDisplayID()
    }
    
    /// 计算DPI
    /// - Parameters:
    ///   - displayID: 显示器ID
    ///   - physicalSize: 物理尺寸
    ///   - width: 像素宽度
    ///   - height: 像素高度
    /// - Returns: DPI值
    private func calculateDPI(displayID: CGDirectDisplayID, physicalSize: CGSize, width: Int, height: Int) -> Double {
        guard physicalSize.width > 0 && physicalSize.height > 0 else {
            return 96.0 // 默认DPI
        }
        
        let dpiX = Double(width) / (physicalSize.width / 25.4) // 转换为英寸
        let dpiY = Double(height) / (physicalSize.height / 25.4)
        return (dpiX + dpiY) / 2.0
    }
    
    /// 确定显示器类型
    /// - Parameters:
    ///   - displayID: 显示器ID
    ///   - width: 像素宽度
    ///   - height: 像素高度
    ///   - isBuiltIn: 是否内置
    ///   - dpi: DPI值
    /// - Returns: 显示器类型
    private func determineDisplayType(displayID: CGDirectDisplayID, width: Int, height: Int, isBuiltIn: Bool, dpi: Double) -> DisplayType {
        // 检查是否为超宽屏
        let aspectRatio = Double(width) / Double(height)
        if aspectRatio >= 2.0 {
            return .ultraWide
        }
        
        // 检查是否为内置Retina
        if isBuiltIn && dpi > 200 {
            return .builtInRetina
        }
        
        // 检查是否为4K显示器
        if width >= 3840 && height >= 2160 {
            return .external4K
        }
        
        // 检查是否为外接HD显示器
        if !isBuiltIn && width >= 1920 && height >= 1080 {
            return .externalHD
        }
        
        return .unknown
    }
    
    /// 计算推荐缩放因子
    /// - Parameters:
    ///   - displayType: 显示器类型
    ///   - dpi: DPI值
    ///   - isHiDPI: 是否HiDPI
    /// - Returns: 推荐缩放因子
    private func calculateRecommendedScaleFactor(displayType: DisplayType, dpi: Double, isHiDPI: Bool) -> Double {
        // 首先基于显示器类型
        var recommendedScale = displayType.recommendedScaleFactor
        
        // 然后基于DPI微调
        switch dpi {
        case ..<120:
            recommendedScale = max(recommendedScale, 1.0)
        case 120..<150:
            recommendedScale = max(recommendedScale, 1.25)
        case 150..<200:
            recommendedScale = max(recommendedScale, 1.5)
        case 200..<250:
            recommendedScale = max(recommendedScale, 2.0)
        case 250..<300:
            recommendedScale = max(recommendedScale, 2.5)
        default:
            recommendedScale = max(recommendedScale, 3.0)
        }
        
        return recommendedScale
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
