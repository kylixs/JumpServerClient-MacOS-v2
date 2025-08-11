import Foundation

/// Remote Desktop集成器协议，定义与Microsoft Remote Desktop应用程序集成的接口
protocol RemoteDesktopIntegratorProtocol {
    /// 启动Microsoft Remote Desktop并建立连接（支持显示优化和质量配置）
    /// - Parameter connectionInfo: RDP连接信息
    /// - Throws: JMSError.remoteDesktopNotFound 如果应用程序未安装
    ///          JMSError.remoteDesktopLaunchFailed 如果启动失败
    ///          JMSError.displayDetectionFailed 如果显示器检测失败
    func launchRemoteDesktop(with connectionInfo: RDPConnectionInfo) throws
    
    /// 启动Microsoft Remote Desktop并建立优化连接
    /// - Parameters:
    ///   - connectionInfo: RDP连接信息
    ///   - displaySettings: 显示优化设置
    /// - Throws: JMSError相关错误
    func launchOptimizedRemoteDesktop(with connectionInfo: RDPConnectionInfo, displaySettings: RDPDisplaySettings) throws
    
    /// 检查Microsoft Remote Desktop是否可用
    /// - Returns: 如果应用程序已安装且可用则返回true
    func checkRemoteDesktopAvailability() -> Bool
    
    /// 创建临时RDP配置文件
    /// - Parameter connectionInfo: RDP连接信息
    /// - Returns: 临时文件的URL
    /// - Throws: JMSError.remoteDesktopLaunchFailed 如果文件创建失败
    func createTemporaryRDPFile(with connectionInfo: RDPConnectionInfo) throws -> URL
    
    /// 创建优化的临时RDP配置文件
    /// - Parameters:
    ///   - connectionInfo: RDP连接信息
    ///   - displaySettings: 显示优化设置
    /// - Returns: 临时文件的URL
    /// - Throws: JMSError相关错误
    func createOptimizedRDPFile(with connectionInfo: RDPConnectionInfo, displaySettings: RDPDisplaySettings) throws -> URL
    
    /// 清理临时文件
    /// - Parameter fileURL: 要清理的文件URL
    func cleanupTemporaryFile(at fileURL: URL)
    
    /// 检测显示器并生成优化的RDP设置
    /// - Returns: 优化的RDP显示设置
    /// - Throws: JMSError.displayDetectionFailed 如果显示器检测失败
    func detectAndOptimizeDisplay() throws -> RDPDisplaySettings
    
    // MARK: - Quality Configuration Methods
    
    /// 快速切换质量配置
    /// - Parameter profile: 要切换到的质量配置文件
    func switchQualityProfile(_ profile: DisplayQualityProfile)
    
    /// 获取当前质量配置的性能分析
    /// - Returns: 当前配置的性能分析结果
    func getCurrentQualityAnalysis() -> PerformanceAnalysis
    
    /// 根据网络条件推荐质量配置
    /// - Parameter networkType: 网络类型
    /// - Returns: 推荐的质量配置文件
    func recommendQualityProfile(for networkType: NetworkOptimization) -> DisplayQualityProfile
    
    /// 创建包含质量配置的RDP文件
    /// - Parameters:
    ///   - connectionInfo: RDP连接信息
    ///   - qualitySettings: 质量设置
    /// - Returns: 临时RDP文件的URL
    /// - Throws: 如果创建文件失败
    func createRDPFileWithQuality(
        connectionInfo: RDPConnectionInfo,
        qualitySettings: RDPQualitySettings
    ) throws -> URL
}
