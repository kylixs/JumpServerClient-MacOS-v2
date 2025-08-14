#!/usr/bin/env swift

import Foundation

// 模拟DateFormatter扩展
extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

// 模拟logMessage方法
func logMessage(_ message: String) {
    let logFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_jms_log.txt")
    
    let timestamp = DateFormatter.logFormatter.string(from: Date())
    let logEntry = "[\(timestamp)] \(message)\n"
    
    // 同时输出到控制台和文件
    print(message)
    
    // 写入日志文件
    if let data = logEntry.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logFileURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: logFileURL)
        }
    }
    
    print("📝 日志已写入: \(logFileURL.path)")
}

// 测试logMessage功能
print("🧪 测试logMessage功能")
print("=" * 30)

logMessage("🚀 JMS Protocol Handler 已启动")
logMessage("📋 启动时间: \(Date())")
logMessage("🔗 注册Apple Events URL处理器...")
logMessage("✅ Apple Events URL处理器注册完成")

let logFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_jms_log.txt")

print("\n📄 日志文件内容:")
print("-" * 40)

if let logContent = try? String(contentsOf: logFileURL) {
    print(logContent)
} else {
    print("❌ 无法读取日志文件")
}

print("-" * 40)
print("✅ 测试完成！")
print("📁 日志文件位置: \(logFileURL.path)")
