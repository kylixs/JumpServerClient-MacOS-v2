import Foundation

/// Base64解码和JSON解析服务
public class PayloadDecoder {
    
    public init() {}
    
    /// 解码Base64编码的payload并解析JSON
    /// - Parameter encodedPayload: Base64编码的字符串
    /// - Returns: 解析后的JMS配置
    /// - Throws: JMSError.decodingFailed 或 JMSError.jsonParsingFailed
    public func decodePayload(_ encodedPayload: String) throws -> JMSConfig {
        // 1. Base64解码
        let decodedData = try decodeBase64(encodedPayload)
        
        // 2. JSON解析
        let jsonObject = try parseJSON(decodedData)
        
        // 3. 提取配置信息
        return try extractConfig(from: jsonObject)
    }
    
    /// 仅进行Base64解码
    /// - Parameter encodedString: Base64编码的字符串
    /// - Returns: 解码后的数据
    /// - Throws: JMSError.decodingFailed
    public func decodeBase64(_ encodedString: String) throws -> Data {
        // 清理Base64字符串（移除空白字符和换行符）
        let cleanedString = encodedString
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\t", with: "")
        
        // 处理URL安全的Base64编码
        let base64String = cleanedString
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // 添加必要的填充
        let paddedString = addBase64Padding(base64String)
        
        guard let data = Data(base64Encoded: paddedString) else {
            throw JMSError.decodingFailed("无法解码Base64字符串: \(encodedString)")
        }
        
        return data
    }
    
    /// 解析JSON数据
    /// - Parameter data: JSON数据
    /// - Returns: 解析后的字典
    /// - Throws: JMSError.jsonParsingFailed
    public func parseJSON(_ data: Data) throws -> [String: Any] {
        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw JMSError.jsonParsingFailed("JSON根对象不是字典类型")
            }
            return jsonObject
        } catch let error as JMSError {
            throw error
        } catch {
            throw JMSError.jsonParsingFailed("JSON解析错误: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    private func addBase64Padding(_ base64String: String) -> String {
        let remainder = base64String.count % 4
        if remainder > 0 {
            return base64String + String(repeating: "=", count: 4 - remainder)
        }
        return base64String
    }
    
    private func extractConfig(from jsonObject: [String: Any]) throws -> JMSConfig {
        guard let protocolType = jsonObject["protocol"] as? String else {
            throw JMSError.jsonParsingFailed("缺少必需的 'protocol' 字段")
        }
        
        let config = jsonObject["config"] as? String
        let token = jsonObject["token"] as? String
        
        return JMSConfig(
            protocolType: protocolType,
            config: config,
            token: token,
            rawData: jsonObject
        )
    }
}
