import Foundation

/// JMS配置数据模型，用于解析从URL中解码的JSON配置信息
struct JMSConfig: Codable {
    let filename: String
    let `protocol`: String
    let username: String
    let token: String
    let config: String
    
    enum CodingKeys: String, CodingKey {
        case filename, `protocol`, username, token, config
    }
    
    /// 验证配置是否包含必要的字段
    /// - Throws: JMSError.missingRequiredField 如果缺少必要字段
    func validate() throws {
        if filename.isEmpty {
            throw JMSError.missingRequiredField("filename")
        }
        if `protocol`.isEmpty {
            throw JMSError.missingRequiredField("protocol")
        }
        if username.isEmpty {
            throw JMSError.missingRequiredField("username")
        }
        if token.isEmpty {
            throw JMSError.missingRequiredField("token")
        }
        if config.isEmpty {
            throw JMSError.missingRequiredField("config")
        }
    }
    
    /// 检查是否为RDP协议
    var isRDPProtocol: Bool {
        return `protocol`.lowercased() == "rdp"
    }
}

