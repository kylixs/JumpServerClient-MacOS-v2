import Foundation

/// 连接信息提取器协议，定义从配置中提取连接信息的接口
protocol ConnectionInfoExtractorProtocol {
    /// 从JMS配置中提取连接信息
    /// - Parameter config: JMS配置对象
    /// - Returns: 提取的连接信息
    /// - Throws: JMSError.missingConnectionInfo 如果缺少必要的连接信息
    func extractConnectionInfo(from config: JMSConfig) throws -> ConnectionInfo
    
    /// 解析配置字符串中的参数
    /// - Parameter configString: 配置字符串
    /// - Returns: 解析后的参数字典
    /// - Throws: JMSError.configParsingFailed 如果解析失败
    func parseConfigString(_ configString: String) throws -> [String: String]
    
    /// 从配置参数中提取特定的值
    /// - Parameters:
    ///   - key: 要提取的键
    ///   - configParams: 配置参数字典
    /// - Returns: 提取的值，如果不存在则返回nil
    func extractValue(for key: String, from configParams: [String: String]) -> String?
}