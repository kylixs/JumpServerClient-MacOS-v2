import Foundation

/// 连接信息提取服务
public class ConnectionInfoExtractor {
    
    public init() {}
    
    /// 从JMS配置中提取连接信息
    /// - Parameter config: JMS配置对象
    /// - Returns: 提取的连接信息
    /// - Throws: JMSError.missingConnectionInfo 或 JMSError.unsupportedProtocol
    public func extractConnectionInfo(from config: JMSConfig) throws -> ConnectionInfo {
        switch config.protocolType.lowercased() {
        case "rdp":
            return .rdp(try extractRDPInfo(from: config))
        case "ssh":
            return .ssh(try extractSSHInfo(from: config))
        default:
            throw JMSError.unsupportedProtocol(config.protocolType)
        }
    }
    
    // MARK: - RDP信息提取
    
    private func extractRDPInfo(from config: JMSConfig) throws -> RDPConnectionInfo {
        guard let configString = config.config else {
            throw JMSError.missingConnectionInfo("RDP配置字符串为空")
        }
        
        // 解析RDP配置字符串
        let configLines = configString.components(separatedBy: .newlines)
        var fullAddress = ""
        var username = ""
        var additionalParams: [String: String] = [:]
        
        for line in configLines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty { continue }
            
            // 处理不同的分隔符格式
            if let colonRange = trimmedLine.range(of: ":") {
                let key = String(trimmedLine[..<colonRange.lowerBound])
                let remainingPart = String(trimmedLine[colonRange.upperBound...])
                
                // 进一步解析值部分
                let value: String
                if let secondColonRange = remainingPart.range(of: ":") {
                    value = String(remainingPart[secondColonRange.upperBound...])
                } else {
                    value = remainingPart
                }
                
                switch key {
                case "full address":
                    fullAddress = value
                case "username":
                    username = value
                default:
                    additionalParams[key] = value
                }
            }
        }
        
        guard !fullAddress.isEmpty else {
            throw JMSError.missingConnectionInfo("缺少RDP服务器地址")
        }
        
        guard !username.isEmpty else {
            throw JMSError.missingConnectionInfo("缺少RDP用户名")
        }
        
        return RDPConnectionInfo(
            fullAddress: fullAddress,
            username: username,
            config: configString,
            additionalParams: additionalParams
        )
    }
    
    // MARK: - SSH信息提取
    
    private func extractSSHInfo(from config: JMSConfig) throws -> SSHConnectionInfo {
        guard let tokenString = config.token else {
            throw JMSError.missingConnectionInfo("SSH token为空")
        }
        
        // 解析SSH token (JSON格式)
        guard let tokenData = tokenString.data(using: .utf8) else {
            throw JMSError.missingConnectionInfo("SSH token编码错误")
        }
        
        do {
            guard let tokenObject = try JSONSerialization.jsonObject(with: tokenData) as? [String: Any] else {
                throw JMSError.missingConnectionInfo("SSH token不是有效的JSON格式")
            }
            
            guard let ip = tokenObject["ip"] as? String, !ip.isEmpty else {
                throw JMSError.missingConnectionInfo("缺少SSH服务器IP地址")
            }
            
            guard let username = tokenObject["username"] as? String, !username.isEmpty else {
                throw JMSError.missingConnectionInfo("缺少SSH用户名")
            }
            
            let port = tokenObject["port"] as? Int ?? 22
            let password = tokenObject["password"] as? String
            
            // 提取其他参数
            var additionalParams: [String: String] = [:]
            for (key, value) in tokenObject {
                if !["ip", "port", "username", "password"].contains(key) {
                    additionalParams[key] = "\(value)"
                }
            }
            
            return SSHConnectionInfo(
                ip: ip,
                port: port,
                username: username,
                password: password,
                additionalParams: additionalParams
            )
            
        } catch let error as JMSError {
            throw error
        } catch {
            throw JMSError.missingConnectionInfo("SSH token解析失败: \(error.localizedDescription)")
        }
    }
}
