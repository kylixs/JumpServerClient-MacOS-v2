import Foundation

/// URL解析器协议，定义URL解析的接口
protocol URLParserProtocol {
    /// 解析JMS协议URL
    /// - Parameter url: 要解析的URL
    /// - Returns: 解析后的URL组件
    /// - Throws: JMSError.invalidURL 如果URL格式不正确
    func parseJMSURL(_ url: URL) throws -> JMSURLComponents
    
    /// 验证URL是否为有效的JMS协议格式
    /// - Parameter url: 要验证的URL
    /// - Returns: 如果是有效的JMS URL则返回true
    func isValidJMSURL(_ url: URL) -> Bool
}