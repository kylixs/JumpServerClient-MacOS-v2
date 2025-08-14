import Foundation

/// 日志级别
public enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    
    public var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

/// 日志管理器 - 统一的日志输出组件
public class LogManager {
    
    public static let shared = LogManager()
    
    private let dateFormatter: DateFormatter
    private let logFileURL: URL
    private let queue = DispatchQueue(label: "com.jumpserver.logmanager", qos: .utility)
    
    /// 是否启用控制台输出
    public var enableConsoleOutput: Bool = true
    
    /// 是否启用文件输出
    public var enableFileOutput: Bool = true
    
    /// 当前日志级别（只输出此级别及以上的日志）
    public var logLevel: LogLevel = .info
    
    private init() {
        // 设置日期格式器
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // 设置日志文件路径
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        logFileURL = documentsPath.appendingPathComponent("JMSProtocolHandler.log")
        
        // 创建日志文件目录
        createLogDirectoryIfNeeded()
    }
    
    // MARK: - 公共日志方法
    
    /// 输出调试日志
    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    /// 输出信息日志
    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    /// 输出警告日志
    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    /// 输出错误日志
    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    /// 通用日志方法
    public func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        // 检查日志级别
        guard shouldLog(level: level) else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        
        // 格式化日志消息
        let logMessage = "\(level.emoji) \(message)"
        let detailedLogEntry = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line)] \(function) - \(message)\n"
        
        // 异步处理日志输出
        queue.async { [weak self] in
            self?.writeLog(message: logMessage, detailedEntry: detailedLogEntry)
        }
    }
    
    // MARK: - 便捷方法
    
    /// 记录应用启动日志
    public func logAppStart() {
        info("🚀 JMS Protocol Handler 已启动")
        info("📋 启动时间: \(Date())")
        info("📁 日志文件位置: \(logFileURL.path)")
        
        // 记录命令行参数
        let arguments = CommandLine.arguments
        info("📝 命令行参数总数: \(arguments.count)")
        for (index, argument) in arguments.enumerated() {
            info("📝 参数[\(index)]: \(argument)")
        }
    }
    
    /// 记录URL处理日志
    public func logURLProcessing(_ urlString: String, step: String) {
        info("🔄 URL处理 - \(step): \(urlString)")
    }
    
    /// 记录连接启动日志
    public func logConnectionStart(type: String, server: String, username: String) {
        info("🔗 启动\(type)连接 - 服务器: \(server), 用户: \(username)")
    }
    
    /// 记录连接成功日志
    public func logConnectionSuccess(type: String) {
        info("✅ \(type)连接启动成功")
    }
    
    /// 记录连接失败日志
    public func logConnectionFailure(type: String, error: String) {
        self.error("❌ \(type)连接启动失败: \(error)")
    }
    
    /// 记录RDP配置日志
    public func logRDPConfig(server: String, username: String, filePath: String, configContent: String) {
        info("📋 RDP配置生成 - 服务器: \(server), 用户: \(username)")
        info("📄 RDP文件路径: \(filePath)")
        
        // 将详细配置直接写入主日志文件
        writeRDPConfigToMainLog(server: server, username: username, filePath: filePath, configContent: configContent)
    }
    
    // MARK: - 日志管理
    
    /// 清理日志文件
    public func clearLogs() {
        queue.async { [weak self] in
            guard let self = self else { return }
            try? FileManager.default.removeItem(at: self.logFileURL)
            self.createLogDirectoryIfNeeded()
            self.info("🧹 日志文件已清理")
        }
    }
    
    /// 获取日志文件内容
    public func getLogContent() -> String? {
        return try? String(contentsOf: logFileURL)
    }
    
    /// 获取日志文件大小
    public func getLogFileSize() -> Int64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: logFileURL.path) else {
            return 0
        }
        return attributes[.size] as? Int64 ?? 0
    }
    
    // MARK: - 私有方法
    
    private func shouldLog(level: LogLevel) -> Bool {
        let levels: [LogLevel] = [.debug, .info, .warning, .error]
        guard let currentIndex = levels.firstIndex(of: logLevel),
              let messageIndex = levels.firstIndex(of: level) else {
            return true
        }
        return messageIndex >= currentIndex
    }
    
    private func writeLog(message: String, detailedEntry: String) {
        // 控制台输出
        if enableConsoleOutput {
            print(message)
        }
        
        // 文件输出
        if enableFileOutput {
            writeToFile(detailedEntry)
        }
    }
    
    private func writeToFile(_ logEntry: String) {
        guard let data = logEntry.data(using: .utf8) else { return }
        
        if FileManager.default.fileExists(atPath: logFileURL.path) {
            // 文件存在，追加内容
            if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            // 文件不存在，创建新文件
            try? data.write(to: logFileURL)
        }
    }
    
    private func createLogDirectoryIfNeeded() {
        let logDirectory = logFileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: logDirectory.path) {
            try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    private func writeRDPConfigToMainLog(server: String, username: String, filePath: String, configContent: String) {
        // 构建RDP配置日志内容
        var logLines: [String] = []
        
        logLines.append("=== RDP配置参数详情 ===")
        logLines.append("服务器: \(server)")
        logLines.append("用户名: \(username)")
        logLines.append("RDP文件: \(filePath)")
        logLines.append("")
        
        // 解析配置参数
        let configLines = configContent.components(separatedBy: "\n")
        var displaySettings: [String: String] = [:]
        var performanceSettings: [String: String] = [:]
        var connectionSettings: [String: String] = [:]
        var otherSettings: [String: String] = [:]
        
        logLines.append("完整RDP配置:")
        logLines.append("----------------------------------------")
        
        for line in configLines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            logLines.append(trimmedLine)
            
            let parts = trimmedLine.components(separatedBy: ":")
            if parts.count >= 3 {
                let key = parts[0]
                let value = parts[2]
                
                // 分类配置参数
                switch key {
                case "desktopwidth", "desktopheight", "session bpp", "smart sizing", "screen mode id", "desktopscalefactor", "hidef color depth":
                    displaySettings[key] = value
                case "compression", "font smoothing", "disable wallpaper", "disable menu anims", "disable themes":
                    performanceSettings[key] = value
                case "full address", "username", "audiomode":
                    connectionSettings[key] = value
                default:
                    otherSettings[key] = value
                }
            }
        }
        
        logLines.append("----------------------------------------")
        logLines.append("")
        
        // 分类显示配置参数
        logLines.append("显示配置:")
        for (key, value) in displaySettings.sorted(by: { $0.key < $1.key }) {
            let description = getRDPParameterDescription(key: key, value: value)
            logLines.append("  \(key): \(value) \(description)")
        }
        logLines.append("")
        
        logLines.append("性能配置:")
        for (key, value) in performanceSettings.sorted(by: { $0.key < $1.key }) {
            let description = getRDPParameterDescription(key: key, value: value)
            logLines.append("  \(key): \(value) \(description)")
        }
        logLines.append("")
        
        logLines.append("连接配置:")
        for (key, value) in connectionSettings.sorted(by: { $0.key < $1.key }) {
            let description = getRDPParameterDescription(key: key, value: value)
            logLines.append("  \(key): \(value) \(description)")
        }
        
        if !otherSettings.isEmpty {
            logLines.append("")
            logLines.append("其他配置:")
            for (key, value) in otherSettings.sorted(by: { $0.key < $1.key }) {
                let description = getRDPParameterDescription(key: key, value: value)
                logLines.append("  \(key): \(value) \(description)")
            }
        }
        
        logLines.append("=== RDP配置记录结束 ===")
        
        // 将所有日志行写入主日志文件
        for line in logLines {
            log(line, level: .info)
        }
        
        info("📝 RDP配置已记录到日志")
    }
    
    private func getRDPParameterDescription(key: String, value: String) -> String {
        switch key {
        case "desktopwidth":
            return "(桌面宽度: \(value)像素)"
        case "desktopheight":
            return "(桌面高度: \(value)像素)"
        case "session bpp":
            let colorDesc = value == "32" ? "真彩色" : value == "24" ? "增强色" : value == "16" ? "高彩色" : "未知"
            return "(\(colorDesc), \(value)位)"
        case "desktopscalefactor":
            let scalePercent = Int(value) ?? 100
            return "(桌面缩放: \(scalePercent)%)"
        case "hidef color depth":
            let colorDesc = value == "32" ? "真彩色" : value == "24" ? "增强色" : value == "16" ? "高彩色" : "未知"
            return "(HiDPI颜色深度: \(colorDesc), \(value)位)"
        case "compression":
            let compDesc = value == "0" ? "无压缩" : value == "1" ? "中等压缩" : value == "2" ? "高压缩" : "未知"
            return "(\(compDesc))"
        case "font smoothing":
            return value == "1" ? "(启用字体平滑)" : "(禁用字体平滑)"
        case "disable wallpaper":
            return value == "1" ? "(禁用壁纸)" : "(启用壁纸)"
        case "disable menu anims":
            return value == "1" ? "(禁用菜单动画)" : "(启用菜单动画)"
        case "disable themes":
            return value == "1" ? "(禁用主题)" : "(启用主题)"
        case "smart sizing":
            return value == "1" ? "(启用智能缩放)" : "(禁用智能缩放)"
        case "screen mode id":
            let modeDesc = value == "2" ? "全屏模式" : value == "1" ? "窗口模式" : "未知模式"
            return "(\(modeDesc))"
        case "audiomode":
            let audioDesc = value == "0" ? "播放到本地" : value == "1" ? "播放到远程" : value == "2" ? "禁用音频" : "未知"
            return "(\(audioDesc))"
        case "full address":
            return "(RDP服务器地址)"
        case "username":
            return "(登录用户名)"
        default:
            return ""
        }
    }
}

// MARK: - 全局便捷函数

/// 全局日志函数 - 调试
public func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LogManager.shared.debug(message, file: file, function: function, line: line)
}

/// 全局日志函数 - 信息
public func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LogManager.shared.info(message, file: file, function: function, line: line)
}

/// 全局日志函数 - 警告
public func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LogManager.shared.warning(message, file: file, function: function, line: line)
}

/// 全局日志函数 - 错误
public func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LogManager.shared.error(message, file: file, function: function, line: line)
}
