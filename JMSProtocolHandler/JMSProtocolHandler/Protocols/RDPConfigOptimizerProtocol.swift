//
//  RDPConfigOptimizerProtocol.swift
//  JMSProtocolHandler
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import Foundation

/// 网络条件枚举
enum NetworkCondition {
    case highSpeed      // > 100 Mbps
    case mediumSpeed    // 10-100 Mbps  
    case lowSpeed       // < 10 Mbps
    case unknown
}

/// 显示质量配置文件
enum DisplayQualityProfile {
    case performance    // 优先性能
    case balanced      // 平衡模式
    case quality       // 优先质量
    case custom        // 自定义配置
}

/// RDP配置优化器协议
protocol RDPConfigOptimizerProtocol {
    /// 根据显示器特性优化RDP配置
    func optimizeForDisplay(_ display: DisplayConfiguration) -> RDPDisplaySettings
    
    /// 根据网络条件优化RDP配置
    func optimizeForNetwork(_ networkCondition: NetworkCondition) -> RDPDisplaySettings
    
    /// 根据质量配置文件优化RDP配置
    func optimizeForProfile(_ profile: DisplayQualityProfile, display: DisplayConfiguration) -> RDPDisplaySettings
    
    /// 生成完整的RDP配置文件内容
    func generateRDPConfigString(_ settings: RDPDisplaySettings, connectionInfo: RDPConnectionInfo) -> String
    
    /// 检测网络条件
    func detectNetworkCondition() -> NetworkCondition
    
    /// 验证RDP设置的有效性
    func validateRDPSettings(_ settings: RDPDisplaySettings) -> Bool
}
