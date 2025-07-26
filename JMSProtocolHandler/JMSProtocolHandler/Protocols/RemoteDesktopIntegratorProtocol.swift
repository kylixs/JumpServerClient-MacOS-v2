import Foundation

/// Remote Desktop集成器协议，定义与Microsoft Remote Desktop应用程序集成的接口
protocol RemoteDesktopIntegratorProtocol {
    /// 启动Microsoft Remote Desktop并建立连接
    /// - Parameter connectionInfo: 连接信息
    /// - Throws: JMSError.remoteDesktopNotFound 如果应用程序未安装
    ///          JMSError.remoteDesktopLaunchFailed 如果启动失败
    func launchRemoteDesktop(with connectionInfo: ConnectionInfo) throws
    
    /// 检查Microsoft Remote Desktop是否可用
    /// - Returns: 如果应用程序已安装且可用则返回true
    func checkRemoteDesktopAvailability() -> Bool
    
    /// 创建临时RDP配置文件
    /// - Parameter connectionInfo: 连接信息
    /// - Returns: 临时文件的URL
    /// - Throws: JMSError.remoteDesktopLaunchFailed 如果文件创建失败
    func createTemporaryRDPFile(with connectionInfo: ConnectionInfo) throws -> URL
    
    /// 清理临时文件
    /// - Parameter fileURL: 要清理的文件URL
    func cleanupTemporaryFile(at fileURL: URL)
}