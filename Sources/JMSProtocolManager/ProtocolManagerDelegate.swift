import Foundation

/// 协议管理器委托协议
public protocol ProtocolManagerDelegate: AnyObject {
    /// 协议状态检查开始
    func protocolCheckDidStart()
    
    /// 协议状态检查完成
    /// - Parameter handlers: 检测到的处理器列表
    func protocolCheckDidComplete(handlers: [ProtocolHandlerModel])
    
    /// 协议状态检查失败
    /// - Parameter error: 错误信息
    func protocolCheckDidFail(error: Error)
    
    /// 协议注册开始
    func protocolRegistrationDidStart()
    
    /// 协议注册进度更新
    /// - Parameters:
    ///   - message: 进度消息
    ///   - progress: 进度值 (0.0-1.0)
    func protocolRegistrationDidProgress(message: String, progress: Double)
    
    /// 协议注册完成
    /// - Parameter success: 是否成功
    func protocolRegistrationDidComplete(success: Bool)
    
    /// 协议注册失败
    /// - Parameter error: 错误信息
    func protocolRegistrationDidFail(error: Error)
}

/// 协议管理器委托协议的默认实现
public extension ProtocolManagerDelegate {
    func protocolCheckDidStart() {
        print("🔍 协议状态检查开始")
    }
    
    func protocolCheckDidComplete(handlers: [ProtocolHandlerModel]) {
        print("✅ 协议状态检查完成，找到 \(handlers.count) 个处理器")
    }
    
    func protocolCheckDidFail(error: Error) {
        print("❌ 协议状态检查失败: \(error.localizedDescription)")
    }
    
    func protocolRegistrationDidStart() {
        print("🔧 协议注册开始")
    }
    
    func protocolRegistrationDidProgress(message: String, progress: Double) {
        print("📊 协议注册进度: \(message) (\(Int(progress * 100))%)")
    }
    
    func protocolRegistrationDidComplete(success: Bool) {
        print(success ? "✅ 协议注册成功" : "❌ 协议注册失败")
    }
    
    func protocolRegistrationDidFail(error: Error) {
        print("❌ 协议注册失败: \(error.localizedDescription)")
    }
}
