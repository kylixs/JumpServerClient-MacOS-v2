import Foundation

/// URL解析服务
public class URLParser {
    
    public init() {}
    
    /// 解析JMS协议URL
    /// - Parameter urlString: 完整的URL字符串
    /// - Returns: 解析后的URL组件
    /// - Throws: JMSError.invalidURL 如果URL格式不正确
    public func parseURL(_ urlString: String) throws -> JMSURLComponents {
        guard let url = URL(string: urlString) else {
            throw JMSError.invalidURL("无法创建URL对象: \(urlString)")
        }
        
        guard url.scheme?.lowercased() == "jms" else {
            throw JMSError.invalidURL("不支持的协议: \(url.scheme ?? "unknown")")
        }
        
        // 提取编码的payload
        let encodedPayload = extractEncodedPayload(from: url)
        guard !encodedPayload.isEmpty else {
            throw JMSError.invalidURL("URL中缺少编码的payload")
        }
        
        return JMSURLComponents(
            scheme: url.scheme ?? "jms",
            encodedPayload: encodedPayload,
            originalURL: urlString
        )
    }
    
    /// 验证URL格式
    /// - Parameter urlString: URL字符串
    /// - Returns: 是否为有效的JMS URL
    public func isValidJMSURL(_ urlString: String) -> Bool {
        do {
            let components = try parseURL(urlString)
            return components.isValid
        } catch {
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func extractEncodedPayload(from url: URL) -> String {
        // 从URL中提取base64编码的payload
        // 支持多种URL格式:
        // jms://encoded_payload
        // jms:///encoded_payload
        // jms://host/encoded_payload
        
        if let host = url.host, !host.isEmpty {
            // 如果有host，payload在host中
            return host
        } else if !url.path.isEmpty {
            // 如果没有host，payload在path中
            let path = url.path
            return String(path.dropFirst()) // 移除开头的 "/"
        } else {
            // 其他情况，尝试从完整URL中提取
            let urlString = url.absoluteString
            if let range = urlString.range(of: "jms://") {
                return String(urlString[range.upperBound...])
            }
        }
        
        return ""
    }
}
