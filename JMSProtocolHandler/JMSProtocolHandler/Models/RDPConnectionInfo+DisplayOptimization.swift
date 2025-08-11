//
//  RDPConnectionInfo+DisplayOptimization.swift
//  JMSProtocolHandler
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import Foundation

/// RDPConnectionInfo扩展，支持显示优化参数
extension RDPConnectionInfo {
    
    /// 创建支持显示优化的RDP连接信息
    /// - Parameters:
    ///   - fullAddress: 完整的服务器地址
    ///   - username: 用户名
    ///   - displaySettings: 显示优化设置
    ///   - additionalConfig: 其他配置参数
    /// - Returns: 包含显示优化参数的RDP连接信息
    static func withDisplayOptimization(
        fullAddress: String,
        username: String,
        displaySettings: RDPDisplaySettings,
        additionalConfig: [String: String] = [:]
    ) -> RDPConnectionInfo {
        
        var config = additionalConfig
        
        // 添加显示优化参数到配置中
        config["desktopwidth:i"] = String(displaySettings.desktopWidth)
        config["desktopheight:i"] = String(displaySettings.desktopHeight)
        config["session bpp:i"] = String(displaySettings.sessionBpp)
        config["desktopscalefactor:i"] = String(displaySettings.desktopScaleFactor)
        config["smart sizing:i"] = displaySettings.smartSizing ? "1" : "0"
        config["compression:i"] = String(displaySettings.compression)
        config["bitmapcachepersistenable:i"] = displaySettings.bitmapCachePersistEnable ? "1" : "0"
        config["disable wallpaper:i"] = displaySettings.disableWallpaper ? "1" : "0"
        config["allow font smoothing:i"] = displaySettings.allowFontSmoothing ? "1" : "0"
        config["screen mode id:i"] = String(displaySettings.screenModeId)
        
        // 添加连接优化参数
        config["connection type:i"] = "6"
        config["networkautodetect:i"] = "1"
        config["bandwidthautodetect:i"] = "1"
        config["displayconnectionbar:i"] = "1"
        config["enableworkspacereconnect:i"] = "0"
        config["disable full window drag:i"] = displaySettings.compression > 0 ? "1" : "0"
        config["disable menu anims:i"] = displaySettings.compression > 1 ? "1" : "0"
        config["disable themes:i"] = displaySettings.compression > 1 ? "1" : "0"
        config["disable cursor setting:i"] = "0"
        config["bitmapcachesize:i"] = "1500"
        
        // 添加音频和重定向设置
        config["audiomode:i"] = "0"
        config["audiocapturemode:i"] = "0"
        config["videoplaybackmode:i"] = "1"
        config["redirectclipboard:i"] = "1"
        config["redirectprinters:i"] = "1"
        config["redirectcomports:i"] = "0"
        config["redirectsmartcards:i"] = "1"
        config["redirectdrives:i"] = "0"
        
        return RDPConnectionInfo(
            fullAddress: fullAddress,
            username: username,
            sessionBpp: displaySettings.sessionBpp,
            audioMode: 0,
            smartSizing: displaySettings.smartSizing,
            screenModeId: displaySettings.screenModeId,
            additionalConfig: config
        )
    }
    
    /// 生成优化的RDP配置文件内容
    /// - Parameter displaySettings: 显示优化设置
    /// - Returns: 完整的RDP配置文件内容
    func generateOptimizedRDPContent(with displaySettings: RDPDisplaySettings) -> String {
        let optimizer = RDPConfigOptimizer()
        return optimizer.generateRDPConfigString(displaySettings, connectionInfo: self)
    }
    
    /// 从当前连接信息提取显示设置
    /// - Returns: 当前的显示设置，如果没有则返回默认设置
    func extractDisplaySettings() -> RDPDisplaySettings? {
        guard let desktopWidth = additionalConfig["desktopwidth:i"].flatMap(Int.init),
              let desktopHeight = additionalConfig["desktopheight:i"].flatMap(Int.init) else {
            return nil
        }
        
        let sessionBpp = self.sessionBpp ?? 24
        let desktopScaleFactor = additionalConfig["desktopscalefactor:i"].flatMap(Int.init) ?? 100
        let smartSizing = self.smartSizing ?? true
        let compression = additionalConfig["compression:i"].flatMap(Int.init) ?? 1
        let bitmapCachePersistEnable = additionalConfig["bitmapcachepersistenable:i"] == "1"
        let disableWallpaper = additionalConfig["disable wallpaper:i"] == "1"
        let allowFontSmoothing = additionalConfig["allow font smoothing:i"] == "1"
        let screenModeId = self.screenModeId ?? 2
        
        return RDPDisplaySettings(
            desktopWidth: desktopWidth,
            desktopHeight: desktopHeight,
            sessionBpp: sessionBpp,
            desktopScaleFactor: desktopScaleFactor,
            smartSizing: smartSizing,
            compression: compression,
            bitmapCachePersistEnable: bitmapCachePersistEnable,
            disableWallpaper: disableWallpaper,
            allowFontSmoothing: allowFontSmoothing,
            screenModeId: screenModeId
        )
    }
    
    /// 检查是否包含显示优化参数
    var hasDisplayOptimization: Bool {
        return additionalConfig.keys.contains { key in
            key.hasPrefix("desktopwidth:") || 
            key.hasPrefix("desktopheight:") || 
            key.hasPrefix("desktopscalefactor:")
        }
    }
    
    /// 获取显示配置摘要
    var displayConfigSummary: String {
        if let settings = extractDisplaySettings() {
            return "\(settings.desktopWidth)x\(settings.desktopHeight) @\(settings.desktopScaleFactor)% (\(settings.sessionBpp)bit)"
        } else {
            return "默认配置"
        }
    }
}
