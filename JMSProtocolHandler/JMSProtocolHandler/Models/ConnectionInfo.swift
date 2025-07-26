import Foundation

/// 连接信息枚举，支持RDP和SSH两种协议类型
enum ConnectionInfo {
    /// RDP远程桌面连接信息
    case rdp(RDPConnectionInfo)
    
    /// SSH终端连接信息
    case ssh(SSHConnectionInfo)
    
    /// 获取协议类型字符串
    var protocolType: String {
        switch self {
        case .rdp:
            return "rdp"
        case .ssh:
            return "ssh"
        }
    }
    
    /// 获取连接描述信息
    var description: String {
        switch self {
        case .rdp(let rdpInfo):
            return "RDP连接: \(rdpInfo.username)@\(rdpInfo.fullAddress)"
        case .ssh(let sshInfo):
            return "SSH连接: \(sshInfo.username)@\(sshInfo.ip):\(sshInfo.port)"
        }
    }
    
    /// 验证连接信息是否有效
    /// - Throws: JMSError.missingConnectionInfo 如果缺少必要的连接信息
    func validate() throws {
        switch self {
        case .rdp(let rdpInfo):
            try rdpInfo.validate()
        case .ssh(let sshInfo):
            try sshInfo.validate()
        }
    }
}

/// RDP连接信息数据模型
struct RDPConnectionInfo {
    /// 完整的服务器地址（包含端口）
    let fullAddress: String
    
    /// 用户名
    let username: String
    
    /// 会话颜色深度
    let sessionBpp: Int?
    
    /// 音频模式
    let audioMode: Int?
    
    /// 智能调整大小
    let smartSizing: Bool?
    
    /// 屏幕模式ID
    let screenModeId: Int?
    
    /// 其他RDP配置参数
    let additionalConfig: [String: String]
    
    /// 初始化RDP连接信息
    /// - Parameters:
    ///   - fullAddress: 完整的服务器地址
    ///   - username: 用户名
    ///   - sessionBpp: 会话颜色深度
    ///   - audioMode: 音频模式
    ///   - smartSizing: 智能调整大小
    ///   - screenModeId: 屏幕模式ID
    ///   - additionalConfig: 其他配置参数
    init(fullAddress: String, 
         username: String, 
         sessionBpp: Int? = nil, 
         audioMode: Int? = nil, 
         smartSizing: Bool? = nil, 
         screenModeId: Int? = nil, 
         additionalConfig: [String: String] = [:]) {
        self.fullAddress = fullAddress
        self.username = username
        self.sessionBpp = sessionBpp
        self.audioMode = audioMode
        self.smartSizing = smartSizing
        self.screenModeId = screenModeId
        self.additionalConfig = additionalConfig
    }
    
    /// 验证RDP连接信息是否包含必要的字段
    /// - Throws: JMSError.missingConnectionInfo 如果缺少必要的连接信息
    func validate() throws {
        guard !fullAddress.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
        
        guard !username.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
        
        // 验证地址格式（应该包含主机名，可选端口）
        guard fullAddress.contains(":") || !fullAddress.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
    }
    
    /// 提取主机名（不包含端口）
    var hostname: String {
        return fullAddress.components(separatedBy: ":").first ?? fullAddress
    }
    
    /// 提取端口号，如果没有指定则返回默认RDP端口3389
    var port: Int {
        let components = fullAddress.components(separatedBy: ":")
        if components.count > 1, let port = Int(components[1]) {
            return port
        }
        return 3389 // 默认RDP端口
    }
    
    /// 生成RDP配置文件内容
    func generateRDPContent() -> String {
        var rdpContent = [
            "full address:s:\(fullAddress)",
            "username:s:\(username)"
        ]
        
        if let sessionBpp = sessionBpp {
            rdpContent.append("session bpp:i:\(sessionBpp)")
        }
        
        if let audioMode = audioMode {
            rdpContent.append("audiomode:i:\(audioMode)")
        }
        
        if let smartSizing = smartSizing {
            rdpContent.append("smart sizing:i:\(smartSizing ? 1 : 0)")
        }
        
        if let screenModeId = screenModeId {
            rdpContent.append("screen mode id:i:\(screenModeId)")
        }
        
        // 添加其他配置参数
        for (key, value) in additionalConfig {
            rdpContent.append("\(key):\(value)")
        }
        
        return rdpContent.joined(separator: "\n")
    }
}

/// SSH连接信息数据模型
struct SSHConnectionInfo {
    /// 服务器IP地址
    let ip: String
    
    /// SSH端口号
    let port: String
    
    /// 用户名
    let username: String
    
    /// 密码
    let password: String
    
    /// 连接文件名（用于标识）
    let filename: String
    
    /// 初始化SSH连接信息
    /// - Parameters:
    ///   - ip: 服务器IP地址
    ///   - port: SSH端口号
    ///   - username: 用户名
    ///   - password: 密码
    ///   - filename: 连接文件名
    init(ip: String, port: String, username: String, password: String, filename: String) {
        self.ip = ip
        self.port = port
        self.username = username
        self.password = password
        self.filename = filename
    }
    
    /// 验证SSH连接信息是否包含必要的字段
    /// - Throws: JMSError.missingConnectionInfo 如果缺少必要的连接信息
    func validate() throws {
        guard !ip.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
        
        guard !port.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
        
        guard !username.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
        
        guard !password.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
        
        // 验证端口号格式
        guard Int(port) != nil else {
            throw JMSError.missingConnectionInfo
        }
    }
    
    /// 获取端口号的整数值
    var portNumber: Int {
        return Int(port) ?? 22 // 默认SSH端口
    }
    
    /// 生成SSH连接字符串
    var connectionString: String {
        return "\(username)@\(ip):\(port)"
    }
}

extension RDPConnectionInfo: Equatable {
    static func == (lhs: RDPConnectionInfo, rhs: RDPConnectionInfo) -> Bool {
        return lhs.fullAddress == rhs.fullAddress &&
               lhs.username == rhs.username &&
               lhs.sessionBpp == rhs.sessionBpp &&
               lhs.audioMode == rhs.audioMode &&
               lhs.smartSizing == rhs.smartSizing &&
               lhs.screenModeId == rhs.screenModeId &&
               lhs.additionalConfig == rhs.additionalConfig
    }
}

extension SSHConnectionInfo: Equatable {
    static func == (lhs: SSHConnectionInfo, rhs: SSHConnectionInfo) -> Bool {
        return lhs.ip == rhs.ip &&
               lhs.port == rhs.port &&
               lhs.username == rhs.username &&
               lhs.password == rhs.password &&
               lhs.filename == rhs.filename
    }
}

extension ConnectionInfo: Equatable {
    static func == (lhs: ConnectionInfo, rhs: ConnectionInfo) -> Bool {
        switch (lhs, rhs) {
        case (.rdp(let lhsRDP), .rdp(let rhsRDP)):
            return lhsRDP == rhsRDP
        case (.ssh(let lhsSSH), .ssh(let rhsSSH)):
            return lhsSSH == rhsSSH
        default:
            return false
        }
    }
}

extension SSHConnectionInfo: CustomStringConvertible {
    var description: String {
        return "SSH连接: \(username)@\(ip):\(port) (文件: \(filename))"
    }
}

extension RDPConnectionInfo: CustomStringConvertible {
    var description: String {
        return "RDP连接: \(username)@\(fullAddress)"
    }
}
