import Foundation

/// URL解析器实现类，负责解析和验证JMS协议URL
class URLParser: URLParserProtocol {
    
    /// JMS协议的scheme标识符
    private static let jmsScheme = "jms"
    
    /// 解析JMS协议URL
    /// - Parameter url: 要解析的URL
    /// - Returns: 解析后的URL组件
    /// - Throws: JMSError.invalidURL 如果URL格式不正确
    func parseJMSURL(_ url: URL) throws -> JMSURLComponents {
        // 验证URL是否为有效的JMS格式
        guard isValidJMSURL(url) else {
            throw JMSError.invalidURL
        }
        
        // 提取base64编码的payload
        let encodedPayload = try extractEncodedPayload(from: url)
        
        return JMSURLComponents(
            scheme: url.scheme ?? "",
            encodedPayload: encodedPayload,
            originalURL: url
        )
    }
    
    /// 验证URL是否为有效的JMS协议格式
    /// - Parameter url: 要验证的URL
    /// - Returns: 如果是有效的JMS URL则返回true
    func isValidJMSURL(_ url: URL) -> Bool {
        // 检查scheme是否为"jms"（不区分大小写）
        guard let scheme = url.scheme?.lowercased(),
              scheme == Self.jmsScheme else {
            return false
        }
        
        // 检查是否有host部分（即payload部分）
        guard let host = url.host, !host.isEmpty else {
            return false
        }
        
        // 验证payload是否为有效的base64格式
        return isValidBase64String(host)
    }
    
    // MARK: - Private Methods
    
    /// 从URL中提取base64编码的payload
    /// - Parameter url: 源URL
    /// - Returns: base64编码的payload字符串
    /// - Throws: JMSError.invalidURL 如果无法提取payload
    private func extractEncodedPayload(from url: URL) throws -> String {
        guard let host = url.host, !host.isEmpty else {
            throw JMSError.invalidURL
        }
        
        return host
    }
    
    /// 验证字符串是否为有效的base64格式
    /// - Parameter string: 要验证的字符串
    /// - Returns: 如果是有效的base64格式则返回true
    private func isValidBase64String(_ string: String) -> Bool {
        // 空字符串不是有效的base64
        guard !string.isEmpty else {
            return false
        }
        
        // Base64字符集：A-Z, a-z, 0-9, +, /, =
        let base64CharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
        
        // 检查字符串是否只包含base64字符
        guard string.rangeOfCharacter(from: base64CharacterSet.inverted) == nil else {
            return false
        }
        
        // 检查长度是否为4的倍数（base64编码的基本要求）
        guard string.count % 4 == 0 else {
            return false
        }
        
        // 检查padding字符'='的位置是否正确
        if let paddingIndex = string.firstIndex(of: "=") {
            let paddingPart = string[paddingIndex...]
            // padding只能在末尾，且只能是1个或2个'='
            guard paddingPart.allSatisfy({ $0 == "=" }) && paddingPart.count <= 2 else {
                return false
            }
        }
        
        // 尝试进行base64解码验证
        return Data(base64Encoded: string) != nil
    }
}