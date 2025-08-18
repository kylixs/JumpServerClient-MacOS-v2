import Foundation
import AppKit

/// 协议注册服务错误类型
public enum ProtocolRegistrationError: Error, LocalizedError {
    case scriptNotFound
    case registrationFailed(String)
    case cleanupFailed(String)
    case permissionDenied
    case userCancelled
    case systemError(String)
    
    public var errorDescription: String? {
        switch self {
        case .scriptNotFound:
            return "协议注册脚本未找到"
        case .registrationFailed(let message):
            return "协议注册失败: \(message)"
        case .cleanupFailed(let message):
            return "协议清理失败: \(message)"
        case .permissionDenied:
            return "权限不足，无法注册协议"
        case .userCancelled:
            return "用户取消了权限授权"
        case .systemError(let message):
            return "系统错误: \(message)"
        }
    }
}

/// 协议注册进度回调
public typealias RegistrationProgressCallback = (String, Double) -> Void

/// JMS协议注册服务
public class ProtocolRegistrationService: @unchecked Sendable {
    
    /// 单例实例
    public static let shared = ProtocolRegistrationService()
    
    /// 注册脚本路径
    private let registrationScriptPath: String
    
    /// 当前应用路径
    private let currentAppPath: String
    
    private init() {
        // 查找注册脚本
        let bundle = Bundle.main
        if let scriptPath = bundle.path(forResource: "register_jms_protocol", ofType: "sh") {
            self.registrationScriptPath = scriptPath
        } else {
            // 备用路径
            self.registrationScriptPath = bundle.bundlePath + "/Contents/Resources/scripts/deployment/register_jms_protocol.sh"
        }
        
        self.currentAppPath = bundle.bundlePath
    }
    
    /// 重新注册协议（清理并重新注册）
    /// - Parameter progressCallback: 进度回调
    /// - Returns: 注册结果
    /// - Throws: ProtocolRegistrationError
    public func reregisterProtocol(progressCallback: RegistrationProgressCallback? = nil) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    DispatchQueue.main.async {
                        continuation.resume(throwing: ProtocolRegistrationError.systemError("Service instance was deallocated"))
                    }
                    return
                }
                
                do {
                    // 步骤1: 清理现有注册
                    progressCallback?("正在清理现有协议注册...", 0.2)
                    try self.cleanupExistingRegistrations()
                    
                    // 步骤2: 重新注册当前应用
                    progressCallback?("正在注册当前应用...", 0.6)
                    try self.registerCurrentApp()
                    
                    // 步骤3: 验证注册结果
                    progressCallback?("正在验证注册结果...", 0.9)
                    let success = self.verifyRegistration()
                    
                    progressCallback?("注册完成", 1.0)
                    
                    DispatchQueue.main.async {
                        continuation.resume(returning: success)
                    }
                } catch {
                    DispatchQueue.main.async {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    /// 清理现有的协议注册
    /// - Throws: ProtocolRegistrationError
    private func cleanupExistingRegistrations() throws {
        do {
            // 首先尝试普通权限清理
            try runCommand("/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister", 
                          arguments: ["-kill", "-r", "-domain", "local", "-domain", "system", "-domain", "user"])
        } catch ProtocolRegistrationError.permissionDenied {
            // 如果权限不足，尝试使用管理员权限
            print("⚠️ 普通权限清理失败，尝试使用管理员权限...")
            try runCommand("/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister", 
                          arguments: ["-kill", "-r", "-domain", "local", "-domain", "system", "-domain", "user"],
                          requiresElevation: true)
        }
        
        // 清理Launch Services数据库中的jms协议条目
        try cleanupLaunchServicesDatabase()
    }
    
    /// 清理Launch Services数据库
    /// - Throws: ProtocolRegistrationError
    private func cleanupLaunchServicesDatabase() throws {
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["delete", "com.apple.LaunchServices/com.apple.launchservices.secure", "LSHandlers"]
        
        let pipe = Pipe()
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus != 0 {
                let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "未知错误"
                print("⚠️ 清理Launch Services数据库警告: \(errorMessage)")
                // 不抛出错误，因为这个操作可能会失败但不影响后续注册
            }
        } catch {
            print("⚠️ 清理Launch Services数据库失败: \(error)")
            // 不抛出错误，继续执行
        }
    }
    
    /// 注册当前应用
    /// - Throws: ProtocolRegistrationError
    private func registerCurrentApp() throws {
        // 方法1: 使用脚本注册
        if FileManager.default.fileExists(atPath: registrationScriptPath) {
            try runRegistrationScript()
        } else {
            // 方法2: 直接使用系统API注册
            try registerUsingSystemAPI()
        }
    }
    
    /// 运行注册脚本
    /// - Throws: ProtocolRegistrationError
    private func runRegistrationScript() throws {
        guard FileManager.default.fileExists(atPath: registrationScriptPath) else {
            throw ProtocolRegistrationError.scriptNotFound
        }
        
        try runCommand("/bin/bash", arguments: [registrationScriptPath])
    }
    
    /// 使用系统API注册
    /// - Throws: ProtocolRegistrationError
    private func registerUsingSystemAPI() throws {
        do {
            // 首先尝试普通权限注册
            try runCommand("/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister", 
                          arguments: ["-f", currentAppPath])
        } catch ProtocolRegistrationError.permissionDenied {
            // 如果权限不足，尝试使用管理员权限
            print("⚠️ 普通权限注册失败，尝试使用管理员权限...")
            try runCommand("/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister", 
                          arguments: ["-f", currentAppPath],
                          requiresElevation: true)
        }
        
        // 设置为默认处理器 - 兼容不同macOS版本
        if #available(macOS 12.0, *) {
            let workspace = NSWorkspace.shared
            workspace.setDefaultApplication(at: URL(fileURLWithPath: currentAppPath), 
                                          toOpenURLsWithScheme: "jms") { error in
                if let error = error {
                    print("⚠️ 设置默认处理器警告: \(error.localizedDescription)")
                }
            }
        } else {
            // 对于较旧的macOS版本，使用lsregister应该足够
            print("ℹ️ 在macOS 12.0以下版本，依赖lsregister进行协议注册")
        }
    }
    
    /// 验证注册结果
    /// - Returns: 是否注册成功
    private func verifyRegistration() -> Bool {
        let workspace = NSWorkspace.shared
        guard let url = workspace.urlForApplication(toOpen: URL(string: "jms://test")!) else {
            return false
        }
        
        return url.path == currentAppPath
    }
    
    /// 运行系统命令
    /// - Parameters:
    ///   - command: 命令路径
    ///   - arguments: 命令参数
    /// - Throws: ProtocolRegistrationError
    /// 运行命令，支持权限提升
    /// - Parameters:
    ///   - command: 命令路径
    ///   - arguments: 命令参数
    ///   - requiresElevation: 是否需要管理员权限
    /// - Throws: ProtocolRegistrationError
    private func runCommand(_ command: String, arguments: [String], requiresElevation: Bool = false) throws {
        if requiresElevation {
            try runCommandWithElevation(command, arguments: arguments)
        } else {
            try runCommandNormally(command, arguments: arguments)
        }
    }
    
    /// 正常运行命令
    private func runCommandNormally(_ command: String, arguments: [String]) throws {
        let task = Process()
        task.launchPath = command
        task.arguments = arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus != 0 {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "未知错误"
                
                if errorMessage.contains("permission") || errorMessage.contains("Permission") || 
                   errorMessage.contains("Operation not permitted") {
                    throw ProtocolRegistrationError.permissionDenied
                } else {
                    throw ProtocolRegistrationError.systemError("命令执行失败: \(errorMessage)")
                }
            }
            
            // 记录成功输出
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: outputData, encoding: .utf8), !output.isEmpty {
                print("✅ 命令执行成功: \(output)")
            }
            
        } catch let error as ProtocolRegistrationError {
            throw error
        } catch {
            throw ProtocolRegistrationError.systemError("命令执行异常: \(error.localizedDescription)")
        }
    }
    
    /// 使用管理员权限运行命令（macOS风格）
    private func runCommandWithElevation(_ command: String, arguments: [String]) throws {
        // 创建AppleScript来请求管理员权限
        let script = """
        do shell script "\(command) \(arguments.joined(separator: " "))" with administrator privileges
        """
        
        let appleScript = NSAppleScript(source: script)
        var errorDict: NSDictionary?
        
        let result = appleScript?.executeAndReturnError(&errorDict)
        
        if let error = errorDict {
            let errorMessage = error["NSAppleScriptErrorMessage"] as? String ?? "未知错误"
            if errorMessage.contains("User canceled") || errorMessage.contains("用户取消") {
                throw ProtocolRegistrationError.userCancelled
            } else {
                throw ProtocolRegistrationError.systemError("权限提升失败: \(errorMessage)")
            }
        }
        
        if result == nil {
            throw ProtocolRegistrationError.systemError("命令执行失败")
        }
        
        print("✅ 管理员权限命令执行成功")
    }
    
    /// 检查注册脚本是否存在
    /// - Returns: 脚本是否存在
    public func isRegistrationScriptAvailable() -> Bool {
        return FileManager.default.fileExists(atPath: registrationScriptPath)
    }
    
    /// 获取注册脚本路径
    /// - Returns: 脚本路径
    public func getRegistrationScriptPath() -> String {
        return registrationScriptPath
    }
}
