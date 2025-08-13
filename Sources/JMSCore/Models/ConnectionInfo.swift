import Foundation

/// 连接信息的枚举类型
public enum ConnectionInfo {
    case rdp(RDPConnectionInfo)
    case ssh(SSHConnectionInfo)
    
    /// 获取协议类型
    public var protocolType: String {
        switch self {
        case .rdp:
            return "rdp"
        case .ssh:
            return "ssh"
        }
    }
}

/// RDP连接信息
public struct RDPConnectionInfo {
    public let fullAddress: String
    public let username: String
    public let config: String
    public let additionalParams: [String: String]
    
    public init(fullAddress: String, username: String, config: String, additionalParams: [String: String] = [:]) {
        self.fullAddress = fullAddress
        self.username = username
        self.config = config
        self.additionalParams = additionalParams
    }
    
    /// 解析服务器地址和端口
    public var serverAddress: String {
        return fullAddress.components(separatedBy: ":").first ?? fullAddress
    }
    
    public var port: Int {
        let components = fullAddress.components(separatedBy: ":")
        if components.count > 1, let port = Int(components[1]) {
            return port
        }
        return 3389 // RDP默认端口
    }
}

/// SSH连接信息
public struct SSHConnectionInfo {
    public let ip: String
    public let port: Int
    public let username: String
    public let password: String?
    public let additionalParams: [String: String]
    
    public init(ip: String, port: Int = 22, username: String, password: String? = nil, additionalParams: [String: String] = [:]) {
        self.ip = ip
        self.port = port
        self.username = username
        self.password = password
        self.additionalParams = additionalParams
    }
    
    /// 生成SSH连接字符串
    public var connectionString: String {
        if port != 22 {
            return "\(username)@\(ip) -p \(port)"
        } else {
            return "\(username)@\(ip)"
        }
    }
}
