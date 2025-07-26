import Foundation

/// 负载解码器实现，负责base64解码和JSON解析
class PayloadDecoder: PayloadDecoderProtocol {
    
    /// 解码base64编码的负载
    /// - Parameter payload: base64编码的字符串
    /// - Returns: 解码后的数据
    /// - Throws: JMSError.decodingFailed 如果解码失败
    func decodeBase64Payload(_ payload: String) throws -> Data {
        // 清理payload字符串，移除可能的空白字符
        let cleanedPayload = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 尝试base64解码
        guard let decodedData = Data(base64Encoded: cleanedPayload) else {
            throw JMSError.decodingFailed
        }
        
        return decodedData
    }
    
    /// 解析JSON配置信息
    /// - Parameter data: JSON数据
    /// - Returns: 解析后的JMS配置对象
    /// - Throws: JMSError.jsonParsingFailed 如果JSON解析失败
    func parseJSONConfig(_ data: Data) throws -> JMSConfig {
        do {
            let decoder = JSONDecoder()
            let config = try decoder.decode(JMSConfig.self, from: data)
            
            // 验证配置的完整性
            try config.validate()
            
            return config
        } catch is DecodingError {
            throw JMSError.jsonParsingFailed
        } catch let error as JMSError {
            // 重新抛出JMSError
            throw error
        } catch {
            throw JMSError.jsonParsingFailed
        }
    }
    
    /// 完整的解码和解析流程
    /// - Parameter payload: base64编码的JSON字符串
    /// - Returns: 解析后的JMS配置对象
    /// - Throws: JMSError.decodingFailed 或 JMSError.jsonParsingFailed
    func decodeAndParsePayload(_ payload: String) throws -> JMSConfig {
        // 第一步：base64解码
        let decodedData = try decodeBase64Payload(payload)
        
        // 第二步：JSON解析
        let config = try parseJSONConfig(decodedData)
        
        return config
    }
}