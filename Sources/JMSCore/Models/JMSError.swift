import Foundation

/// JMS协议处理过程中可能出现的错误类型
public enum JMSError: LocalizedError {
    case invalidURL(String)
    case decodingFailed(String)
    case jsonParsingFailed(String)
    case missingConnectionInfo(String)
    case unsupportedProtocol(String)
    case remoteDesktopNotFound
    case terminalNotFound
    case displayDetectionFailed(String)
    case configurationError(String)
    case fileOperationFailed(String)
    case networkError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "无效的URL格式: \(url)"
        case .decodingFailed(let reason):
            return "解码失败: \(reason)"
        case .jsonParsingFailed(let reason):
            return "JSON解析失败: \(reason)"
        case .missingConnectionInfo(let info):
            return "缺少连接信息: \(info)"
        case .unsupportedProtocol(let protocolName):
            return "不支持的协议类型: \(protocolName)"
        case .remoteDesktopNotFound:
            return "未找到Microsoft Remote Desktop应用程序"
        case .terminalNotFound:
            return "未找到可用的终端应用程序"
        case .displayDetectionFailed(let reason):
            return "显示器检测失败: \(reason)"
        case .configurationError(let reason):
            return "配置错误: \(reason)"
        case .fileOperationFailed(let reason):
            return "文件操作失败: \(reason)"
        case .networkError(let reason):
            return "网络错误: \(reason)"
        }
    }
    
    public var failureReason: String? {
        return errorDescription
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "请检查URL格式是否正确"
        case .decodingFailed:
            return "请检查URL中的编码内容"
        case .jsonParsingFailed:
            return "请检查配置信息格式"
        case .missingConnectionInfo:
            return "请确保连接信息完整"
        case .unsupportedProtocol:
            return "目前仅支持RDP和SSH协议"
        case .remoteDesktopNotFound:
            return "请从Mac App Store安装Microsoft Remote Desktop"
        case .terminalNotFound:
            return "请确保系统中有Terminal或iTerm2应用程序"
        case .displayDetectionFailed:
            return "请检查显示器连接状态"
        case .configurationError:
            return "请检查配置参数"
        case .fileOperationFailed:
            return "请检查文件权限和磁盘空间"
        case .networkError:
            return "请检查网络连接"
        }
    }
}
