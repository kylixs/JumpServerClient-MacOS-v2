import Foundation

/// 连接信息提取器实现类，负责从JMS配置中提取RDP和SSH连接信息
class ConnectionInfoExtractor: ConnectionInfoExtractorProtocol {
    
    /// 从JMS配置中提取连接信息
    /// - Parameter config: JMS配置对象
    /// - Returns: 提取的连接信息（RDP或SSH）
    /// - Throws: JMSError 如果缺少必要的连接信息或协议不支持
    func extractConnectionInfo(from config: JMSConfig) throws -> ConnectionInfo {
        // 首先验证配置的有效性
        try config.validate()
        
        // 根据协议类型提取相应的连接信息
        switch config.protocol.lowercased() {
        case "rdp":
            return try extractRDPConnectionInfo(from: config)
        case "ssh":
            return try extractSSHConnectionInfo(from: config)
        default:
            throw JMSError.unsupportedProtocol
        }
    }
    
    // MARK: - RDP Connection Info Extraction
    
    /// 从JMS配置中提取RDP连接信息
    /// - Parameter config: JMS配置对象
    /// - Returns: RDP连接信息
    /// - Throws: JMSError 如果缺少必要的连接信息
    private func extractRDPConnectionInfo(from config: JMSConfig) throws -> ConnectionInfo {
        // 解析RDP配置字符串
        let configParams = try parseConfigString(config.config)
        
        // 提取必要的连接信息
        guard let fullAddress = extractValue(for: "full address", from: configParams),
              !fullAddress.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
        
        guard let username = extractValue(for: "username", from: configParams),
              !username.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
        
        // 提取可选的配置参数
        let sessionBpp = extractIntValue(for: "session bpp", from: configParams)
        let audioMode = extractIntValue(for: "audiomode", from: configParams)
        let smartSizing = extractBoolValue(for: "smart sizing", from: configParams)
        let screenModeId = extractIntValue(for: "screen mode id", from: configParams)
        
        // 收集其他配置参数
        var additionalConfig: [String: String] = [:]
        let knownKeys = Set(["full address", "username", "session bpp", "audiomode", "smart sizing", "screen mode id"])
        
        for (key, value) in configParams {
            if !knownKeys.contains(key) {
                additionalConfig[key] = value
            }
        }
        
        // 创建RDP连接信息对象
        let rdpConnectionInfo = RDPConnectionInfo(
            fullAddress: fullAddress,
            username: username,
            sessionBpp: sessionBpp,
            audioMode: audioMode,
            smartSizing: smartSizing,
            screenModeId: screenModeId,
            additionalConfig: additionalConfig
        )
        
        // 验证连接信息的完整性
        try rdpConnectionInfo.validate()
        
        return .rdp(rdpConnectionInfo)
    }
    
    // MARK: - SSH Connection Info Extraction
    
    /// 从JMS配置中提取SSH连接信息
    /// - Parameter config: JMS配置对象
    /// - Returns: SSH连接信息
    /// - Throws: JMSError 如果缺少必要的连接信息或token解析失败
    private func extractSSHConnectionInfo(from config: JMSConfig) throws -> ConnectionInfo {
        // SSH协议的连接信息在token字段中
        guard !config.token.isEmpty else {
            throw JMSError.missingConnectionInfo
        }
        
        // 解析token中的JSON数据
        let sshToken = try parseSSHToken(config.token)
        
        // 创建SSH连接信息对象
        let sshConnectionInfo = SSHConnectionInfo(
            ip: sshToken.ip,
            port: sshToken.port,
            username: sshToken.username,
            password: sshToken.password,
            filename: config.filename
        )
        
        // 验证连接信息的完整性
        try sshConnectionInfo.validate()
        
        return .ssh(sshConnectionInfo)
    }
    
    /// 解析SSH Token中的JSON数据
    /// - Parameter tokenString: token字符串
    /// - Returns: 解析后的SSH Token对象
    /// - Throws: JMSError.sshTokenParsingFailed 如果解析失败
    private func parseSSHToken(_ tokenString: String) throws -> SSHToken {
        guard let tokenData = tokenString.data(using: .utf8) else {
            throw JMSError.sshTokenParsingFailed
        }
        
        do {
            let decoder = JSONDecoder()
            let sshToken = try decoder.decode(SSHToken.self, from: tokenData)
            return sshToken
        } catch {
            print("SSH Token解析错误: \(error)")
            throw JMSError.sshTokenParsingFailed
        }
    }
    
    // MARK: - RDP Config Parsing Methods
    
    /// 解析配置字符串中的参数
    /// - Parameter configString: 配置字符串
    /// - Returns: 解析后的参数字典
    /// - Throws: JMSError.configParsingFailed 如果解析失败
    func parseConfigString(_ configString: String) throws -> [String: String] {
        var configParams: [String: String] = [:]
        
        // 按行分割配置字符串
        let lines = configString.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳过空行
            if trimmedLine.isEmpty {
                continue
            }
            
            // 解析格式为 "key:type:value" 的配置行
            if let colonIndex = trimmedLine.firstIndex(of: ":") {
                let keyPart = String(trimmedLine[..<colonIndex])
                let remainingPart = String(trimmedLine[trimmedLine.index(after: colonIndex)...])
                
                // 查找第二个冒号来分离类型和值
                if let secondColonIndex = remainingPart.firstIndex(of: ":") {
                    let type = String(remainingPart[..<secondColonIndex])
                    let value = String(remainingPart[remainingPart.index(after: secondColonIndex)...])
                    
                    // 验证类型格式
                    if isValidConfigType(type) {
                        configParams[keyPart] = value
                    } else {
                        // 如果类型无效，也是格式错误
                        throw JMSError.configParsingFailed
                    }
                } else {
                    // 如果没有找到第二个冒号，可能是格式错误
                    throw JMSError.configParsingFailed
                }
            } else {
                // 如果没有找到冒号，也是格式错误
                throw JMSError.configParsingFailed
            }
        }
        
        return configParams
    }
    
    /// 从配置参数中提取特定的值
    /// - Parameters:
    ///   - key: 要提取的键
    ///   - configParams: 配置参数字典
    /// - Returns: 提取的值，如果不存在则返回nil
    func extractValue(for key: String, from configParams: [String: String]) -> String? {
        return configParams[key]
    }
    
    // MARK: - Private Helper Methods
    
    /// 提取整数值
    /// - Parameters:
    ///   - key: 配置键
    ///   - configParams: 配置参数字典
    /// - Returns: 整数值，如果不存在或无法转换则返回nil
    private func extractIntValue(for key: String, from configParams: [String: String]) -> Int? {
        guard let stringValue = configParams[key] else { return nil }
        return Int(stringValue)
    }
    
    /// 提取布尔值
    /// - Parameters:
    ///   - key: 配置键
    ///   - configParams: 配置参数字典
    /// - Returns: 布尔值，如果不存在或无法转换则返回nil
    private func extractBoolValue(for key: String, from configParams: [String: String]) -> Bool? {
        guard let stringValue = configParams[key] else { return nil }
        
        // RDP配置中布尔值通常用0/1表示
        if let intValue = Int(stringValue) {
            return intValue != 0
        }
        
        // 也支持true/false字符串
        switch stringValue.lowercased() {
        case "true", "yes", "1":
            return true
        case "false", "no", "0":
            return false
        default:
            return nil
        }
    }
    
    /// 验证配置类型是否有效
    /// - Parameter type: 配置类型字符串
    /// - Returns: 是否为有效的配置类型
    private func isValidConfigType(_ type: String) -> Bool {
        let validTypes = ["s", "i", "b"] // s=string, i=integer, b=binary/boolean
        return validTypes.contains(type)
    }
}

// MARK: - SSH Token Model

/// SSH Token数据模型（用于解析token字段中的JSON）
struct SSHToken: Codable {
    /// 服务器IP地址
    let ip: String
    
    /// SSH端口号
    let port: String
    
    /// 用户名
    let username: String
    
    /// 密码
    let password: String
    
    enum CodingKeys: String, CodingKey {
        case ip, port, username, password
    }
}
