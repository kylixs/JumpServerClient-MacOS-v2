//
//  DisplayDetector.swift
//  JMSProtocolHandler
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import Foundation
import AppKit
import CoreGraphics

/// 显示器检测器实现
class DisplayDetector: DisplayDetectorProtocol {
    
    /// 检测主显示器配置
    func detectPrimaryDisplay() throws -> DisplayConfiguration {
        guard let screen = NSScreen.main else {
            throw JMSError.displayDetectionFailed
        }
        
        let frame = screen.frame
        let scaleFactor = screen.backingScaleFactor
        let colorDepth = screen.depth.bitsPerPixel
        
        // 获取物理分辨率
        let physicalWidth = Int(frame.width * scaleFactor)
        let physicalHeight = Int(frame.height * scaleFactor)
        
        // 检测刷新率（默认60Hz，可通过Core Graphics API获取更精确值）
        let refreshRate = getDisplayRefreshRate(for: screen) ?? 60
        
        return DisplayConfiguration(
            width: physicalWidth,
            height: physicalHeight,
            scaleFactor: scaleFactor,
            colorDepth: colorDepth,
            refreshRate: refreshRate,
            isRetina: scaleFactor > 1.0,
            isExternal: screen != NSScreen.main
        )
    }
    
    /// 检测所有显示器配置
    func detectAllDisplays() throws -> [DisplayConfiguration] {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            throw JMSError.displayDetectionFailed
        }
        
        return screens.map { screen in
            let frame = screen.frame
            let scaleFactor = screen.backingScaleFactor
            let colorDepth = screen.depth.bitsPerPixel
            let refreshRate = getDisplayRefreshRate(for: screen) ?? 60
            
            return DisplayConfiguration(
                width: Int(frame.width * scaleFactor),
                height: Int(frame.height * scaleFactor),
                scaleFactor: scaleFactor,
                colorDepth: colorDepth,
                refreshRate: refreshRate,
                isRetina: scaleFactor > 1.0,
                isExternal: screen != NSScreen.main
            )
        }
    }
    
    /// 检查是否为HiDPI显示器
    func isHiDPIDisplay() -> Bool {
        return NSScreen.main?.backingScaleFactor ?? 1.0 > 1.0
    }
    
    /// 获取最优RDP设置
    func getOptimalRDPSettings() throws -> RDPDisplaySettings {
        let display = try detectPrimaryDisplay()
        let optimizer = RDPConfigOptimizer()
        return optimizer.optimizeForDisplay(display)
    }
    
    // MARK: - Private Methods
    
    /// 获取显示器刷新率
    private func getDisplayRefreshRate(for screen: NSScreen) -> Int? {
        // 使用Core Graphics API获取显示器信息
        let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
        guard let displayID = screenNumber else { return nil }
        
        // 获取显示模式
        guard let mode = CGDisplayCopyDisplayMode(displayID) else { return nil }
        
        return Int(mode.refreshRate)
    }
}
