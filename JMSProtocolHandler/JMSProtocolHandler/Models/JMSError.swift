import Foundation

/// JMS协议处理器的错误类型枚举
enum JMSError: LocalizedError {
    case invalidURL
    case decodingFailed
    case jsonParsingFailed
    case missingConnectionInfo
    case unsupportedProtocol
    case remoteDesktopNotFound
    case remoteDesktopLaunchFailed
    case configParsingFailed
    case missingRequiredField(String)
    case sshTokenParsingFailed
    case terminalNotAvailable
    case sshConnectionFailed
    case expectToolNotFound
    case terminalLaunchFailed
    
    // 显示相关错误
    case displayDetectionFailed
    case unsupportedDisplayConfiguration
    case rdpConfigGenerationFailed
    case invalidDisplayParameters
    case hiDPIConfigurationFailed
    
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
        case .unsupportedProtocol:
            return "不支持的协议类型"
        case .remoteDesktopNotFound:
            return "未找到Microsoft Remote Desktop应用程序"
        case .remoteDesktopLaunchFailed:
            return "启动Microsoft Remote Desktop失败"
        case .configParsingFailed:
            return "配置解析失败"
        case .missingRequiredField(let field):
            return "缺少必要字段: \(field)"
        case .sshTokenParsingFailed:
            return "SSH Token解析失败"
        case .terminalNotAvailable:
            return "无法找到可用的终端应用程序"
        case .sshConnectionFailed:
            return "SSH连接失败"
        case .expectToolNotFound:
            return "未找到expect工具"
        case .terminalLaunchFailed:
            return "启动终端应用程序失败"
        case .displayDetectionFailed:
            return "显示器检测失败"
        case .unsupportedDisplayConfiguration:
            return "不支持的显示器配置"
        case .rdpConfigGenerationFailed:
            return "RDP配置生成失败"
        case .invalidDisplayParameters:
            return "无效的显示参数"
        case .hiDPIConfigurationFailed:
            return "HiDPI配置失败"
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
        case .unsupportedProtocol:
            return "协议类型不是rdp或ssh"
        case .remoteDesktopNotFound:
            return "系统中未安装Microsoft Remote Desktop应用程序"
        case .remoteDesktopLaunchFailed:
            return "无法启动Microsoft Remote Desktop应用程序"
        case .configParsingFailed:
            return "无法解析配置字符串中的参数"
        case .missingRequiredField(let field):
            return "配置中缺少必要的字段: \(field)"
        case .sshTokenParsingFailed:
            return "无法解析SSH token中的JSON数据"
        case .terminalNotAvailable:
            return "系统中没有可用的终端应用程序（Terminal或iTerm2）"
        case .sshConnectionFailed:
            return "无法建立SSH连接或执行SSH命令"
        case .expectToolNotFound:
            return "系统中未安装expect工具，无法自动输入密码"
        case .terminalLaunchFailed:
            return "无法启动终端应用程序或执行AppleScript"
        case .displayDetectionFailed:
            return "无法检测到系统显示器配置信息"
        case .unsupportedDisplayConfiguration:
            return "当前显示器配置不被支持或无法处理"
        case .rdpConfigGenerationFailed:
            return "无法生成优化的RDP配置文件"
        case .invalidDisplayParameters:
            return "显示器参数无效或超出支持范围"
        case .hiDPIConfigurationFailed:
            return "无法为HiDPI显示器生成正确的配置"
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
        case .unsupportedProtocol:
            return "目前仅支持rdp和ssh协议类型"
        case .remoteDesktopNotFound:
            return "请从Mac App Store安装Microsoft Remote Desktop应用程序"
        case .remoteDesktopLaunchFailed:
            return "请检查Microsoft Remote Desktop是否正确安装并可以正常启动"
        case .configParsingFailed:
            return "请检查配置字符串格式是否正确"
        case .missingRequiredField:
            return "请确保配置包含所有必要的字段"
        case .sshTokenParsingFailed:
            return "请检查SSH token字段是否包含有效的JSON格式连接信息"
        case .terminalNotAvailable:
            return "请确保系统中安装了Terminal应用程序，或安装iTerm2以获得更好的体验"
        case .sshConnectionFailed:
            return "请检查SSH服务器地址、端口和认证信息是否正确"
        case .expectToolNotFound:
            return "请安装expect工具：brew install expect，或手动输入SSH密码"
        case .terminalLaunchFailed:
            return "请检查终端应用程序权限设置，确保允许AppleScript控制"
        case .displayDetectionFailed:
            return "请检查显示器连接状态，确保至少有一个显示器正常工作"
        case .unsupportedDisplayConfiguration:
            return "请尝试使用标准的显示器分辨率和缩放设置"
        case .rdpConfigGenerationFailed:
            return "请检查显示器配置是否正常，或使用默认RDP设置"
        case .invalidDisplayParameters:
            return "请检查显示器设置，确保分辨率和缩放比例在合理范围内"
        case .hiDPIConfigurationFailed:
            return "请检查HiDPI显示器设置，或尝试调整系统显示缩放比例"
        }
    }
}