//
//  RDPQualityConfigManagerProtocol.swift
//  JMSProtocolHandler
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import Foundation

/// RDP质量配置管理器协议
protocol RDPQualityConfigManagerProtocol {
    
    // MARK: - Profile Management
    
    /// 获取当前质量配置文件
    func getCurrentQualityProfile() -> DisplayQualityProfile
    
    /// 设置质量配置文件
    /// - Parameter profile: 要设置的质量配置文件
    func setQualityProfile(_ profile: DisplayQualityProfile)
    
    /// 获取质量配置文件的设置
    /// - Parameter profile: 质量配置文件
    /// - Returns: 对应的质量设置
    func getQualityProfileSettings(_ profile: DisplayQualityProfile) -> RDPQualitySettings
    
    // MARK: - Custom Configuration Management
    
    /// 获取当前自定义配置
    /// - Returns: 自定义配置，如果当前不是自定义配置则返回nil
    func getCustomConfiguration() -> RDPCustomConfiguration?
    
    /// 保存自定义配置
    /// - Parameter config: 要保存的自定义配置
    func saveCustomConfiguration(_ config: RDPCustomConfiguration)
    
    /// 获取所有自定义配置
    /// - Returns: 所有自定义配置的数组
    func getAllCustomConfigurations() -> [RDPCustomConfiguration]
    
    /// 删除指定名称的自定义配置
    /// - Parameter name: 要删除的配置名称
    func deleteCustomConfiguration(named name: String)
    
    // MARK: - Configuration Validation
    
    /// 验证配置的有效性
    /// - Parameter config: 要验证的配置
    /// - Returns: 验证结果
    func validateConfiguration(_ config: RDPCustomConfiguration) -> ValidationResult
    
    // MARK: - Configuration Reset
    
    /// 重置到默认配置
    func resetToDefaultConfiguration()
    
    // MARK: - Import/Export
    
    /// 导出配置为JSON字符串
    /// - Returns: 配置的JSON字符串，失败时返回nil
    func exportConfiguration() -> String?
    
    /// 从JSON字符串导入配置
    /// - Parameter configString: 配置的JSON字符串
    /// - Returns: 导入是否成功
    func importConfiguration(_ configString: String) -> Bool
}
