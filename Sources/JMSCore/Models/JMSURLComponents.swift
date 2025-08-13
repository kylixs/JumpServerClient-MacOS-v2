import Foundation

/// JMS URL组件结构
public struct JMSURLComponents {
    public let scheme: String
    public let encodedPayload: String
    public let originalURL: String
    
    public init(scheme: String, encodedPayload: String, originalURL: String) {
        self.scheme = scheme
        self.encodedPayload = encodedPayload
        self.originalURL = originalURL
    }
    
    /// 验证URL格式是否正确
    public var isValid: Bool {
        return scheme.lowercased() == "jms" && !encodedPayload.isEmpty
    }
    
    /// 获取解码后的payload长度
    public var payloadLength: Int {
        return encodedPayload.count
    }
}

/// JMS配置信息结构
public struct JMSConfig {
    public let protocolType: String
    public let config: String?
    public let token: String?
    public let rawData: [String: Any]
    
    public init(protocolType: String, config: String? = nil, token: String? = nil, rawData: [String: Any] = [:]) {
        self.protocolType = protocolType
        self.config = config
        self.token = token
        self.rawData = rawData
    }
    
    /// 验证配置是否有效
    public var isValid: Bool {
        let supportedProtocols = ["rdp", "ssh"]
        return supportedProtocols.contains(protocolType.lowercased())
    }
}
