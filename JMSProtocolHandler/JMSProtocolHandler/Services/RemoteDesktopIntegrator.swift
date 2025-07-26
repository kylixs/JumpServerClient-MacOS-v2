import Foundation
import Cocoa

/// Microsoft Remote Desktop集成器实现类
class RemoteDesktopIntegrator: RemoteDesktopIntegratorProtocol {
    
    // MARK: - Constants
    
    /// Microsoft Remote Desktop应用程序的Bundle ID
    private static let remoteDesktopBundleID = "com.microsoft.rdc.macos"
    
    /// Microsoft Remote Desktop应用程序的可能路径
    private static let remoteDesktopPaths = [
        "/Applications/Microsoft Remote Desktop.app",
        "/Applications/Microsoft Remote Desktop 10.app",
        "~/Applications/Microsoft Remote Desktop.app",
        "~/Applications/Microsoft Remote Desktop 10.app"
    ]
    
    /// 临时文件目录
    private let temporaryDirectory: URL
    
    // MARK: - Initialization
    
    init() {
        // 创建临时目录用于存储RDP文件
        self.temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("JMSProtocolHandler", isDirectory: true)
        
        // 确保临时目录存在
        try? FileManager.default.createDirectory(at: temporaryDirectory, 
                                               withIntermediateDirectories: true, 
                                               attributes: nil)
    }
    
    // MARK: - RemoteDesktopIntegratorProtocol Implementation
    
    func checkRemoteDesktopAvailability() -> Bool {
        // 方法1: 通过Bundle ID检查应用程序是否已安装
        if let _ = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.remoteDesktopBundleID) {
            return true
        }
        
        // 方法2: 检查常见的安装路径
        for path in Self.remoteDesktopPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expandedPath) {
                return true
            }
        }
        
        return false
    }
    
    func createTemporaryRDPFile(with connectionInfo: RDPConnectionInfo) throws -> URL {
        // 验证连接信息
        try connectionInfo.validate()
        
        // 生成唯一的文件名
        let fileName = "jms_connection_\(UUID().uuidString).rdp"
        let fileURL = temporaryDirectory.appendingPathComponent(fileName)
        
        // 生成RDP文件内容
        let rdpContent = connectionInfo.generateRDPContent()
        
        do {
            // 写入RDP文件
            try rdpContent.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // 设置文件权限（只有当前用户可读写）
            try FileManager.default.setAttributes([.posixPermissions: 0o600], 
                                                ofItemAtPath: fileURL.path)
            
            return fileURL
        } catch {
            throw JMSError.remoteDesktopLaunchFailed
        }
    }
    
    func launchRemoteDesktop(with connectionInfo: RDPConnectionInfo) throws {
        // 检查Microsoft Remote Desktop是否可用
        guard checkRemoteDesktopAvailability() else {
            throw JMSError.remoteDesktopNotFound
        }
        
        // 创建临时RDP文件
        let rdpFileURL = try createTemporaryRDPFile(with: connectionInfo)
        
        do {
            // 方法1: 尝试使用Bundle ID启动应用程序
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.remoteDesktopBundleID) {
                try NSWorkspace.shared.open([rdpFileURL], 
                                          withApplicationAt: appURL, 
                                          configuration: NSWorkspace.OpenConfiguration())
            } else {
                // 方法2: 使用系统默认方式打开RDP文件
                let success = NSWorkspace.shared.open(rdpFileURL)
                if !success {
                    throw JMSError.remoteDesktopLaunchFailed
                }
            }
            
            // 延迟清理临时文件（给应用程序足够时间读取文件）
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.cleanupTemporaryFile(at: rdpFileURL)
            }
            
        } catch {
            // 清理临时文件
            cleanupTemporaryFile(at: rdpFileURL)
            throw JMSError.remoteDesktopLaunchFailed
        }
    }
    
    func cleanupTemporaryFile(at fileURL: URL) {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            // 静默处理清理错误，不影响主要功能
            print("Warning: Failed to cleanup temporary file at \(fileURL.path): \(error)")
        }
    }
    
    // MARK: - Additional Helper Methods
    
    /// 清理所有临时文件
    func cleanupAllTemporaryFiles() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: temporaryDirectory, 
                                                                     includingPropertiesForKeys: nil)
            for fileURL in contents where fileURL.pathExtension == "rdp" {
                cleanupTemporaryFile(at: fileURL)
            }
        } catch {
            print("Warning: Failed to cleanup temporary directory: \(error)")
        }
    }
    
    /// 获取Microsoft Remote Desktop的版本信息
    func getRemoteDesktopVersion() -> String? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.remoteDesktopBundleID) else {
            return nil
        }
        
        guard let bundle = Bundle(url: appURL) else {
            return nil
        }
        
        return bundle.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    /// 验证RDP文件内容格式
    private func validateRDPContent(_ content: String) -> Bool {
        // 检查必要的字段是否存在
        let requiredFields = ["full address:s:", "username:s:"]
        
        for field in requiredFields {
            if !content.contains(field) {
                return false
            }
        }
        
        return true
    }
}