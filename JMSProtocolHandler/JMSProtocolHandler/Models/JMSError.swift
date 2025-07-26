import Foundation

/// JMS协议处理器的错误类型枚举
enum JMSError: LocalizedError {
    case invalidURL
    case decodingFailed
    case jsonParsingFailed
    case missingConnectionInfo
    case remoteDesktopNotFound
    case remoteDesktopLaunchFailed
    case configParsingFailed
    case missingRequiredField(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL格式错误"
        case .decodingFailed:
            return "解码失败"
        case .jsonParsingFailed:
            return "配置信息格式错误"
        case .missingConnectionInfo:
            return "连接信息不完整"
        case .remoteDesktopNotFound:
            return "未找到Microsoft Remote Desktop应用程序"
        case .remoteDesktopLaunchFailed:
            return "启动Microsoft Remote Desktop失败"
        case .configParsingFailed:
            return "配置解析失败"
        case .missingRequiredField(let field):
            return "缺少必要字段: \(field)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidURL:
            return "提供的URL不是有效的jms://协议格式"
        case .decodingFailed:
            return "无法对base64编码的内容进行解码"
        case .jsonParsingFailed:
            return "JSON配置信息格式不正确或包含无效数据"
        case .missingConnectionInfo:
            return "配置中缺少必要的连接信息"
        case .remoteDesktopNotFound:
            return "系统中未安装Microsoft Remote Desktop应用程序"
        case .remoteDesktopLaunchFailed:
            return "无法启动Microsoft Remote Desktop应用程序"
        case .configParsingFailed:
            return "无法解析配置字符串中的参数"
        case .missingRequiredField(let field):
            return "配置中缺少必要的字段: \(field)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "请检查URL格式是否正确，确保以jms://开头"
        case .decodingFailed:
            return "请检查URL中的编码内容是否为有效的base64格式"
        case .jsonParsingFailed:
            return "请检查配置信息是否为有效的JSON格式"
        case .missingConnectionInfo:
            return "请确保配置中包含完整的连接信息"
        case .remoteDesktopNotFound:
            return "请从Mac App Store安装Microsoft Remote Desktop应用程序"
        case .remoteDesktopLaunchFailed:
            return "请检查Microsoft Remote Desktop是否正确安装并可以正常启动"
        case .configParsingFailed:
            return "请检查配置字符串格式是否正确"
        case .missingRequiredField:
            return "请确保配置包含所有必要的字段"
        }
    }
}