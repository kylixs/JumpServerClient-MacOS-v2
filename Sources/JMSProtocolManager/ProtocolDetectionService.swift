import Foundation
import AppKit

/// 协议检测服务错误类型
public enum ProtocolDetectionError: Error, LocalizedError {
    case systemError(String)
    case noHandlersFound
    case invalidPath(String)
    
    public var errorDescription: String? {
        switch self {
        case .systemError(let message):
            return "系统错误: \(message)"
        case .noHandlersFound:
            return "未找到任何jms://协议处理器"
        case .invalidPath(let path):
            return "无效路径: \(path)"
        }
    }
}

/// JMS协议检测服务
public class ProtocolDetectionService: @unchecked Sendable {
    
    /// 单例实例
    public static let shared = ProtocolDetectionService()
    
    /// 当前应用的Bundle路径
    private let currentAppPath: String
    
    /// 当前应用的Bundle标识符
    private let currentBundleId: String
    
    private init() {
        // 先初始化Bundle ID
        self.currentBundleId = Bundle.main.bundleIdentifier ?? "com.jumpserver.JMSProtocolHandler"
        
        // 在测试环境中，Bundle.main可能指向测试运行器
        // 我们需要智能检测实际的JMSProtocolHandler路径
        let bundlePath = Bundle.main.bundlePath
        
        if bundlePath.contains("JMSProtocolHandler.app") {
            // 如果Bundle路径包含JMSProtocolHandler.app，直接使用
            self.currentAppPath = bundlePath
        } else {
            // 否则，尝试查找可能的JMSProtocolHandler.app路径
            self.currentAppPath = Self.findJMSProtocolHandlerPath() ?? bundlePath
        }
        
        print("🔍 ProtocolDetectionService初始化:")
        print("   Bundle路径: \(bundlePath)")
        print("   当前应用路径: \(currentAppPath)")
        print("   Bundle ID: \(currentBundleId)")
    }
    
    /// 查找JMSProtocolHandler.app的可能路径
    /// - Returns: JMSProtocolHandler.app的路径，如果找不到则返回nil
    private static func findJMSProtocolHandlerPath() -> String? {
        let possiblePaths = [
            "/Applications/JMSProtocolHandler.app",
            NSHomeDirectory() + "/Applications/JMSProtocolHandler.app",
            // 构建输出目录
            Bundle.main.bundlePath.replacingOccurrences(of: "/usr/bin", with: "") + "/build/Release/JMSProtocolHandler.app",
            // 项目根目录的构建输出
            Bundle.main.bundlePath.components(separatedBy: "/").dropLast(4).joined(separator: "/") + "/build/Release/JMSProtocolHandler.app"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                print("✅ 找到JMSProtocolHandler.app: \(path)")
                return path
            }
        }
        
        print("⚠️ 未找到JMSProtocolHandler.app，使用Bundle路径")
        return nil
    }
    
    /// 检测所有已注册的jms://协议处理器
    /// - Returns: 协议处理器列表
    /// - Throws: ProtocolDetectionError
    public func detectAllHandlers() async throws -> [ProtocolHandlerModel] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    DispatchQueue.main.async {
                        continuation.resume(throwing: ProtocolDetectionError.systemError("Service instance was deallocated"))
                    }
                    return
                }
                
                do {
                    let handlers = try self.scanProtocolHandlers()
                    DispatchQueue.main.async {
                        continuation.resume(returning: handlers)
                    }
                } catch {
                    DispatchQueue.main.async {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    /// 检查当前应用是否为默认处理器
    /// - Returns: 是否为默认处理器
    public func isCurrentAppDefaultHandler() -> Bool {
        guard let defaultHandler = getDefaultHandler() else { return false }
        return defaultHandler.appPath == currentAppPath
    }
    
    /// 获取默认协议处理器
    /// - Returns: 默认处理器信息
    private func getDefaultHandler() -> ProtocolHandlerModel? {
        let workspace = NSWorkspace.shared
        guard let url = workspace.urlForApplication(toOpen: URL(string: "jms://test")!) else {
            return nil
        }
        
        let appPath = url.path
        let appName = url.lastPathComponent.replacingOccurrences(of: ".app", with: "")
        
        let status: ProtocolHandlerStatus = (appPath == currentAppPath) ? .currentApp : .otherApp
        
        return ProtocolHandlerModel(
            appName: appName,
            appPath: appPath,
            status: status,
            isDefault: true
        )
    }
    
    /// 扫描所有协议处理器
    /// - Returns: 处理器列表
    /// - Throws: ProtocolDetectionError
    private func scanProtocolHandlers() throws -> [ProtocolHandlerModel] {
        var handlers: [ProtocolHandlerModel] = []
        
        print("🔍 开始扫描JMS协议处理器...")
        
        // 方法1: 获取系统默认处理器（这是macOS系统决定的，我们不干预）
        if let defaultHandler = getDefaultHandler() {
            handlers.append(defaultHandler)
            print("✅ 系统默认处理器: \(defaultHandler.appName) at \(defaultHandler.appPath)")
        } else {
            print("⚠️ 系统中未注册jms://协议的默认处理器")
        }
        
        // 方法2: 扫描系统中所有可能的JMSProtocolHandler应用（仅用于信息展示）
        let knownPaths = [
            "/Applications/JMSProtocolHandler.app",
            NSHomeDirectory() + "/Applications/JMSProtocolHandler.app"
        ]
        
        for path in knownPaths {
            if FileManager.default.fileExists(atPath: path) {
                let appName = URL(fileURLWithPath: path).lastPathComponent.replacingOccurrences(of: ".app", with: "")
                
                let handler = ProtocolHandlerModel(
                    appName: appName,
                    appPath: path,
                    status: .otherApp, // 先标记为其他应用，后续验证时会正确分类
                    isDefault: false
                )
                
                // 避免重复添加
                if !handlers.contains(where: { $0.appPath == path }) {
                    handlers.append(handler)
                    print("✅ 发现JMSProtocolHandler应用: \(appName) at \(path)")
                }
            }
        }
        
        // 方法3: 使用Launch Services API获取所有注册的处理器
        let additionalHandlers = try scanLaunchServicesHandlers()
        
        // 合并处理器列表，去重
        let allHandlers = (handlers + additionalHandlers).uniqued()
        
        // 如果没有找到任何处理器，返回空列表
        if allHandlers.isEmpty {
            print("⚠️ 未找到任何jms://协议处理器")
            return []
        }
        
        let validatedHandlers = allHandlers.map { handler in
            validateHandler(handler)
        }
        
        print("📊 扫描完成，共找到 \(validatedHandlers.count) 个处理器")
        return validatedHandlers
    }
    
    /// 使用Launch Services扫描处理器
    /// - Returns: 处理器列表
    /// - Throws: ProtocolDetectionError
    private func scanLaunchServicesHandlers() throws -> [ProtocolHandlerModel] {
        var handlers: [ProtocolHandlerModel] = []
        
        // 尝试通过系统命令获取更多信息
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", "com.apple.LaunchServices/com.apple.launchservices.secure", "LSHandlers"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                handlers.append(contentsOf: parseHandlersFromOutput(output))
            }
        } catch {
            // 如果命令失败，不抛出错误，只是返回空列表
            print("⚠️ 无法通过Launch Services获取处理器信息: \(error)")
        }
        
        return handlers
    }
    
    /// 解析系统输出中的处理器信息
    /// - Parameter output: 系统命令输出
    /// - Returns: 处理器列表
    private func parseHandlersFromOutput(_ output: String) -> [ProtocolHandlerModel] {
        var handlers: [ProtocolHandlerModel] = []
        
        // 解析Launch Services输出，查找jms协议相关的条目
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // 查找包含jms协议的条目
            if trimmedLine.contains("jms") || trimmedLine.contains("JMS") {
                print("🔍 发现jms相关条目: \(trimmedLine)")
                
                // 尝试提取应用路径信息
                if trimmedLine.contains(".app") {
                    // 简单的路径提取逻辑
                    let components = trimmedLine.components(separatedBy: " ")
                    for component in components {
                        if component.contains(".app") && component.hasPrefix("/") {
                            let appPath = component.trimmingCharacters(in: CharacterSet(charactersIn: "\"';"))
                            let appName = URL(fileURLWithPath: appPath).lastPathComponent.replacingOccurrences(of: ".app", with: "")
                            
                            let status: ProtocolHandlerStatus = (appPath == currentAppPath) ? .currentApp : .otherApp
                            
                            let handler = ProtocolHandlerModel(
                                appName: appName,
                                appPath: appPath,
                                status: status,
                                isDefault: false
                            )
                            
                            handlers.append(handler)
                            print("✅ 从Launch Services解析到处理器: \(appName) at \(appPath)")
                            break
                        }
                    }
                }
            }
        }
        
        return handlers
    }
    
    /// 验证处理器有效性
    /// - Parameter handler: 原始处理器信息
    /// - Returns: 验证后的处理器信息
    private func validateHandler(_ handler: ProtocolHandlerModel) -> ProtocolHandlerModel {
        let isValid = FileManager.default.fileExists(atPath: handler.appPath)
        let status: ProtocolHandlerStatus
        
        if !isValid {
            status = .invalid
        } else {
            // 严格按照路径匹配判断当前应用
            // 在测试环境中，currentAppPath可能指向测试运行器，这是正常的
            if handler.appPath == currentAppPath {
                status = .currentApp
            } else {
                status = .otherApp
            }
        }
        
        let validatedHandler = ProtocolHandlerModel(
            appName: handler.appName,
            appPath: handler.appPath,
            status: status,
            isDefault: handler.isDefault,
            registrationDate: handler.registrationDate
        )
        
        print("🔍 验证处理器: \(handler.appName)")
        print("   路径: \(handler.appPath)")
        print("   有效: \(isValid)")
        print("   状态: \(status)")
        print("   当前应用路径: \(currentAppPath)")
        
        return validatedHandler
    }
}

// MARK: - Array扩展，用于去重
extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
