//
//  ConfigurationViewControllerProtocol.swift
//  JMSProtocolHandler
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import Foundation

/// 配置界面控制器协议
protocol ConfigurationViewControllerProtocol {
    
    // MARK: - Display Methods
    
    /// 显示质量配置面板
    func showQualityConfigurationPanel()
    
    /// 显示质量配置文件选项
    func displayQualityProfiles()
    
    /// 显示自定义配置编辑器
    func showCustomConfigurationEditor()
    
    // MARK: - Configuration Methods
    
    /// 预览配置
    /// - Parameter config: 要预览的质量设置
    func previewConfiguration(_ config: RDPQualitySettings)
    
    /// 应用配置
    /// - Parameter profile: 要应用的质量配置文件
    func applyConfiguration(_ profile: DisplayQualityProfile)
    
    /// 重置配置到默认值
    func resetConfiguration()
    
    // MARK: - Import/Export Methods
    
    /// 导出配置为字符串
    /// - Returns: 配置的字符串表示，失败时返回nil
    func exportConfiguration() -> String?
    
    /// 从字符串导入配置
    /// - Parameter configString: 配置字符串
    /// - Returns: 导入是否成功
    func importConfiguration(_ configString: String) -> Bool
}
