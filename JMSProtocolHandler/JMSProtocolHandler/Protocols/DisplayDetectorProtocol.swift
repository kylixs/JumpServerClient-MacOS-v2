//
//  DisplayDetectorProtocol.swift
//  JMSProtocolHandler
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import Foundation
import CoreGraphics

/// 显示器配置信息
struct DisplayConfiguration {
    let width: Int              // 物理分辨率宽度
    let height: Int             // 物理分辨率高度
    let scaleFactor: CGFloat    // DPI缩放因子 (1.0, 2.0等)
    let colorDepth: Int         // 颜色深度
    let refreshRate: Int        // 刷新率
    let isRetina: Bool          // 是否为HiDPI显示器
    let isExternal: Bool        // 是否为外接显示器
}

/// RDP显示设置
struct RDPDisplaySettings {
    let desktopWidth: Int
    let desktopHeight: Int
    let sessionBpp: Int
    let desktopScaleFactor: Int
    let smartSizing: Bool
    let compression: Int
    let bitmapCachePersistEnable: Bool
    let disableWallpaper: Bool
    let allowFontSmoothing: Bool
    let screenModeId: Int
}

/// 显示器检测协议
protocol DisplayDetectorProtocol {
    /// 检测主显示器配置
    func detectPrimaryDisplay() throws -> DisplayConfiguration
    
    /// 检测所有显示器配置
    func detectAllDisplays() throws -> [DisplayConfiguration]
    
    /// 检查是否为HiDPI显示器
    func isHiDPIDisplay() -> Bool
    
    /// 获取最优RDP设置
    func getOptimalRDPSettings() throws -> RDPDisplaySettings
}
