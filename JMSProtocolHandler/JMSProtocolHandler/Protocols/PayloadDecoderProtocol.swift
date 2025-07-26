import Foundation

/// 负载解码器协议，定义base64解码和JSON解析的接口
protocol PayloadDecoderProtocol {
    /// 解码base64编码的负载
    /// - Parameter payload: base64编码的字符串
    /// - Returns: 解码后的数据
    /// - Throws: JMSError.decodingFailed 如果解码失败
    func decodeBase64Payload(_ payload: String) throws -> Data
    
    /// 解析JSON配置信息
    /// - Parameter data: JSON数据
    /// - Returns: 解析后的JMS配置对象
    /// - Throws: JMSError.jsonParsingFailed 如果JSON解析失败
    func parseJSONConfig(_ data: Data) throws -> JMSConfig
    
    /// 完整的解码和解析流程
    /// - Parameter payload: base64编码的JSON字符串
    /// - Returns: 解析后的JMS配置对象
    /// - Throws: JMSError.decodingFailed 或 JMSError.jsonParsingFailed
    func decodeAndParsePayload(_ payload: String) throws -> JMSConfig
}