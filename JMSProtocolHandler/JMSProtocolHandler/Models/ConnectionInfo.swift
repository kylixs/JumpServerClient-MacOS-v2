import Foundation

/// 连接信息数据模型，包含从配置中提取的远程桌面连接参数
struct ConnectionInfo {
    let fullAddress: String      // "develop-jumpserver.jlcops.com:3389"
    let username: String         // "gongdewei|923dbe1e-874a-4512-8a9a-6e8f7744bf53"
    let sessionBpp: Int?         // 会话颜色深度
    let audioMode: Int?          // 音频模式
    let smartSizing: Bool?       // 智能调整大小
    let screenModeId: Int?       // 屏幕模式
    
    // 从config字符串解析的其他RDP参数
    let additionalConfig: [String: String]
    
    init(fullAddress: String, username: String, sessionBpp: Int? = nil, 
         audioMode: Int? = nil, smartSizing: Bool? = nil, 
         screenModeId: Int? = nil, additionalConfig: [String: String] = [:]) {
        self.fullAddress = fullAddress
        self.username = username
        self.sessionBpp = sessionBpp
        self.audioMode = audioMode
        self.smartSizing = smartSizing
        self.screenModeId = screenModeId
        self.additionalConfig = additionalConfig
    }
    
    /// 验证连接信息是否包含必要的字段
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