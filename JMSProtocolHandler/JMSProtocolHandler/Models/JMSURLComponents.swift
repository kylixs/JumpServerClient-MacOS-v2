import Foundation

/// JMS URL解析后的组件结构
struct JMSURLComponents {
    /// URL协议方案，应该始终为"jms"
    let scheme: String
    
    /// base64编码的payload内容
    let encodedPayload: String
    
    /// 原始URL（可选）
    let originalURL: URL?
    
    /// 初始化JMS URL组件
    /// - Parameters:
    ///   - scheme: URL协议方案
    ///   - encodedPayload: base64编码的payload
    ///   - originalURL: 原始URL（可选）
    init(scheme: String, encodedPayload: String, originalURL: URL? = nil) {
        self.scheme = scheme
        self.encodedPayload = encodedPayload
        self.originalURL = originalURL
    }
    
    /// 验证URL组件是否有效
    /// - Throws: JMSError.invalidURL 如果URL组件无效
    func validate() throws {
        guard scheme.lowercased() == "jms" else {
            throw JMSError.invalidURL
        }
        
        guard !encodedPayload.isEmpty else {
            throw JMSError.invalidURL
        }
    }
}

// MARK: - Equatable
extension JMSURLComponents: Equatable {
    static func == (lhs: JMSURLComponents, rhs: JMSURLComponents) -> Bool {
        return lhs.scheme == rhs.scheme &&
               lhs.encodedPayload == rhs.encodedPayload &&
               lhs.originalURL == rhs.originalURL
    }
}

// MARK: - CustomStringConvertible
extension JMSURLComponents: CustomStringConvertible {
    var description: String {
        let urlString = originalURL?.absoluteString ?? "nil"
        return "JMSURLComponents(scheme: \(scheme), payload: \(encodedPayload.prefix(20))..., url: \(urlString))"
    }
}