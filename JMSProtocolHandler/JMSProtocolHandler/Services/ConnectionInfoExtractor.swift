import Foundation

/// 连接信息提取器实现类，负责从JMS配置中提取远程桌面连接信息
class ConnectionInfoExtractor: ConnectionInfoExtractorProtocol {
    
    /// 从JMS配置中提取连接信息
    /// - Parameter config: JMS配置对象
    /// - Returns: 提取的连接信息
    /// - Throws: JMSError.missingConnectionInfo 如果缺少必要的连接信息
    func extractConnectionInfo(from config: JMSConfig) throws -> ConnectionInfo {
        // 首先验证配置的有效性
        try config.validate()
        
        // 解析配置字符串
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
        
        // 创建连接信息对象
        let connectionInfo = ConnectionInfo(
            fullAddress: fullAddress,
            username: username,
            sessionBpp: sessionBpp,
            audioMode: audioMode,
            smartSizing: smartSizing,
            screenModeId: screenModeId,
            additionalConfig: additionalConfig
        )
        
        // 验证连接信息的完整性
        try connectionInfo.validate()
        
        return connectionInfo
    }
    
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