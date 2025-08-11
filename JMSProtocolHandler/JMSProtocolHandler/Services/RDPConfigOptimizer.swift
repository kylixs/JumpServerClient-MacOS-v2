//
//  RDPConfigOptimizer.swift
//  JMSProtocolHandler
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import Foundation

/// RDP配置优化器实现
class RDPConfigOptimizer: RDPConfigOptimizerProtocol {
    
    // MARK: - Public Methods
    
    /// 根据显示器特性优化RDP配置
    func optimizeForDisplay(_ display: DisplayConfiguration) -> RDPDisplaySettings {
        // 根据显示器特性计算最优设置
        let desktopWidth = calculateOptimalWidth(for: display)
        let desktopHeight = calculateOptimalHeight(for: display)
        
        // HiDPI显示器优化
        let desktopScaleFactor = calculateScaleFactor(for: display)
        let sessionBpp = calculateColorDepth(for: display)
        
        // 使用全局配置的质量设置
        let compression = display.isRetina ? 0 : 1 // Retina显示器使用无压缩
        let smartSizing = true // 启用智能调整
        let allowFontSmoothing = display.isRetina // Retina显示器启用字体平滑
        
        return RDPDisplaySettings(
            desktopWidth: desktopWidth,
            desktopHeight: desktopHeight,
            sessionBpp: sessionBpp,
            desktopScaleFactor: desktopScaleFactor,
            smartSizing: smartSizing,
            compression: compression,
            bitmapCachePersistEnable: true,
            disableWallpaper: false, // 保持完整桌面体验
            allowFontSmoothing: allowFontSmoothing,
            screenModeId: 2 // 全屏模式
        )
    }
    
    /// 根据质量配置文件优化RDP配置
    func optimizeForProfile(_ profile: DisplayQualityProfile, display: DisplayConfiguration) -> RDPDisplaySettings {
        let baseSettings = optimizeForDisplay(display)
        
        switch profile {
        case .performance:
            return RDPDisplaySettings(
                desktopWidth: min(baseSettings.desktopWidth, 1920),
                desktopHeight: min(baseSettings.desktopHeight, 1080),
                sessionBpp: 16,
                desktopScaleFactor: baseSettings.desktopScaleFactor,
                smartSizing: true,
                compression: 2,
                bitmapCachePersistEnable: false,
                disableWallpaper: true,
                allowFontSmoothing: false,
                screenModeId: 1
            )
        case .balanced:
            return baseSettings
        case .quality:
            return RDPDisplaySettings(
                desktopWidth: baseSettings.desktopWidth,
                desktopHeight: baseSettings.desktopHeight,
                sessionBpp: 32,
                desktopScaleFactor: baseSettings.desktopScaleFactor,
                smartSizing: true,
                compression: 0,
                bitmapCachePersistEnable: true,
                disableWallpaper: false,
                allowFontSmoothing: true,
                screenModeId: 2
            )
        case .custom:
            return baseSettings
        }
    }
    
    /// 生成完整的RDP配置文件内容
    func generateRDPConfigString(_ settings: RDPDisplaySettings, connectionInfo: RDPConnectionInfo) -> String {
        var config = """
        full address:s:\(connectionInfo.fullAddress)
        username:s:\(connectionInfo.username)
        desktopwidth:i:\(settings.desktopWidth)
        desktopheight:i:\(settings.desktopHeight)
        session bpp:i:\(settings.sessionBpp)
        desktopscalefactor:i:\(settings.desktopScaleFactor)
        smart sizing:i:\(settings.smartSizing ? 1 : 0)
        compression:i:\(settings.compression)
        bitmapcachepersistenable:i:\(settings.bitmapCachePersistEnable ? 1 : 0)
        disable wallpaper:i:\(settings.disableWallpaper ? 1 : 0)
        allow font smoothing:i:\(settings.allowFontSmoothing ? 1 : 0)
        screen mode id:i:\(settings.screenModeId)
        """
        
        // 添加连接优化参数
        config += """
        
        connection type:i:6
        networkautodetect:i:1
        bandwidthautodetect:i:1
        displayconnectionbar:i:1
        enableworkspacereconnect:i:0
        disable full window drag:i:\(settings.compression > 0 ? 1 : 0)
        disable menu anims:i:\(settings.compression > 1 ? 1 : 0)
        disable themes:i:\(settings.compression > 1 ? 1 : 0)
        disable cursor setting:i:0
        bitmapcachesize:i:1500
        """
        
        // 添加音频和重定向设置
        config += """
        
        audiomode:i:0
        audiocapturemode:i:0
        videoplaybackmode:i:1
        redirectclipboard:i:1
        redirectprinters:i:1
        redirectcomports:i:0
        redirectsmartcards:i:1
        redirectdrives:i:0
        """
        
        // 添加其他配置参数
        for (key, value) in connectionInfo.additionalConfig {
            config += "\n\(key):\(value)"
        }
        
        return config
    }
    
    /// 验证RDP设置的有效性
    func validateRDPSettings(_ settings: RDPDisplaySettings) -> Bool {
        // 验证分辨率范围
        guard settings.desktopWidth >= 640 && settings.desktopWidth <= 7680 else { return false }
        guard settings.desktopHeight >= 480 && settings.desktopHeight <= 4320 else { return false }
        
        // 验证颜色深度
        guard [16, 24, 32].contains(settings.sessionBpp) else { return false }
        
        // 验证缩放因子
        guard settings.desktopScaleFactor >= 100 && settings.desktopScaleFactor <= 500 else { return false }
        
        // 验证压缩级别
        guard settings.compression >= 0 && settings.compression <= 2 else { return false }
        
        // 验证屏幕模式
        guard [1, 2].contains(settings.screenModeId) else { return false }
        
        return true
    }
    
    // MARK: - Private Methods
    
    /// 计算最优宽度
    private func calculateOptimalWidth(for display: DisplayConfiguration) -> Int {
        // 限制最大4K分辨率，考虑性能和带宽
        let maxWidth = 3840
        let optimalWidth = min(display.width, maxWidth)
        
        // 确保宽度是16的倍数（视频编码优化）
        return (optimalWidth / 16) * 16
    }
    
    /// 计算最优高度
    private func calculateOptimalHeight(for display: DisplayConfiguration) -> Int {
        // 限制最大4K分辨率
        let maxHeight = 2160
        let optimalHeight = min(display.height, maxHeight)
        
        // 确保高度是16的倍数（视频编码优化）
        return (optimalHeight / 16) * 16
    }
    
    /// 计算缩放因子
    private func calculateScaleFactor(for display: DisplayConfiguration) -> Int {
        if display.isRetina {
            // HiDPI显示器使用实际缩放因子
            let scaleFactor = Int(display.scaleFactor * 100)
            // 限制在合理范围内
            return min(max(scaleFactor, 100), 300)
        } else {
            return 100
        }
    }
    
    /// 计算颜色深度
    private func calculateColorDepth(for display: DisplayConfiguration) -> Int {
        // 根据显示器颜色深度和性能考虑选择最优值
        if display.colorDepth >= 32 {
            return display.isRetina ? 32 : 24 // Retina显示器使用32位以获得最佳质量
        } else if display.colorDepth >= 24 {
            return 24
        } else {
            return 16
        }
    }
}
