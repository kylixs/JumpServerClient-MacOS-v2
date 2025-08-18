import Foundation

/// JMS Protocol Handler 全局设置
public struct JMSSettings {
    
    // MARK: - UI分析配置
    
    /// UI分析功能开关
    /// - 默认关闭以提高性能
    /// - 开发调试时可设置为true
    public static let enableUIAnalysis = false
    
    /// 布局日志开关
    /// - 默认关闭以减少日志噪音
    /// - 调试布局问题时可设置为true
    public static let enableLayoutLogging = false
    
    // MARK: - 性能配置
    
    /// 协议检测缓存刷新间隔（秒）
    public static let protocolCacheRefreshInterval: TimeInterval = 0.1
    
    /// 重新注册后的状态检查延迟（秒）
    public static let reregistrationCheckDelay: TimeInterval = 0.3
    
    // MARK: - 日志配置
    
    /// 详细日志模式
    /// - 默认关闭，只输出关键信息
    /// - 调试时可设置为true
    public static let enableVerboseLogging = false
    
    /// 性能指标日志
    /// - 默认关闭
    /// - 性能分析时可设置为true
    public static let enablePerformanceLogging = false
    
    // MARK: - 开发配置
    
    /// 开发模式
    /// - 开发环境设置为true
    /// - 生产环境设置为false
    #if DEBUG
    public static let isDevelopmentMode = true
    #else
    public static let isDevelopmentMode = false
    #endif
    
    /// 测试模式
    /// - 单元测试时设置为true
    public static let isTestMode = false
    
    // MARK: - 功能开关
    
    /// 自动协议注册
    /// - 默认启用
    public static let enableAutoProtocolRegistration = true
    
    /// 智能显示优化
    /// - 默认启用
    public static let enableSmartDisplayOptimization = true
    
    /// 自动密码输入（SSH）
    /// - 默认启用
    public static let enableAutoPasswordInput = true
    
    // MARK: - 配置验证
    
    /// 验证配置的有效性
    public static func validateConfiguration() -> [String] {
        var warnings: [String] = []
        
        if enableUIAnalysis && !isDevelopmentMode {
            warnings.append("⚠️ UI分析功能在生产环境中启用，可能影响性能")
        }
        
        if enableLayoutLogging && !isDevelopmentMode {
            warnings.append("⚠️ 布局日志在生产环境中启用，可能产生大量日志")
        }
        
        if enableVerboseLogging && !isDevelopmentMode {
            warnings.append("⚠️ 详细日志在生产环境中启用，可能影响性能")
        }
        
        return warnings
    }
    
    // MARK: - 配置信息
    
    /// 获取当前配置摘要
    public static var configurationSummary: String {
        return """
        JMS Protocol Handler 配置摘要:
        
        🔧 功能开关:
        - UI分析: \(enableUIAnalysis ? "启用" : "禁用")
        - 布局日志: \(enableLayoutLogging ? "启用" : "禁用")
        - 详细日志: \(enableVerboseLogging ? "启用" : "禁用")
        - 性能日志: \(enablePerformanceLogging ? "启用" : "禁用")
        
        ⚡ 性能配置:
        - 缓存刷新间隔: \(protocolCacheRefreshInterval)秒
        - 重注册检查延迟: \(reregistrationCheckDelay)秒
        
        🎯 环境配置:
        - 开发模式: \(isDevelopmentMode ? "是" : "否")
        - 测试模式: \(isTestMode ? "是" : "否")
        
        ✨ 功能特性:
        - 自动协议注册: \(enableAutoProtocolRegistration ? "启用" : "禁用")
        - 智能显示优化: \(enableSmartDisplayOptimization ? "启用" : "禁用")
        - 自动密码输入: \(enableAutoPasswordInput ? "启用" : "禁用")
        """
    }
}
