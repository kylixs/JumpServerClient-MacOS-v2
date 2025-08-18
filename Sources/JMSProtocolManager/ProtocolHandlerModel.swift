import Foundation

/// JMS协议处理器状态枚举
public enum ProtocolHandlerStatus {
    case currentApp     // 当前应用
    case otherApp       // 其他应用
    case invalid        // 无效路径
    case checking       // 检查中
}

/// JMS协议处理器数据模型
public struct ProtocolHandlerModel {
    /// 应用名称
    public let appName: String
    
    /// 应用路径
    public let appPath: String
    
    /// 处理器状态
    public let status: ProtocolHandlerStatus
    
    /// 是否为默认处理器
    public let isDefault: Bool
    
    /// 注册时间（如果可获取）
    public let registrationDate: Date?
    
    public init(appName: String, appPath: String, status: ProtocolHandlerStatus, isDefault: Bool = false, registrationDate: Date? = nil) {
        self.appName = appName
        self.appPath = appPath
        self.status = status
        self.isDefault = isDefault
        self.registrationDate = registrationDate
    }
}

// MARK: - 扩展方法
extension ProtocolHandlerModel {
    /// 获取状态显示文本
    public var statusText: String {
        switch status {
        case .currentApp:
            return "当前应用"
        case .otherApp:
            return "其他应用"
        case .invalid:
            return "无效路径"
        case .checking:
            return "检查中..."
        }
    }
    
    /// 获取状态图标
    public var statusIcon: String {
        switch status {
        case .currentApp:
            return "✅"
        case .otherApp:
            return "⚠️"
        case .invalid:
            return "❌"
        case .checking:
            return "🔄"
        }
    }
    
    /// 检查路径是否有效
    public var isPathValid: Bool {
        return FileManager.default.fileExists(atPath: appPath)
    }
    
    /// 获取应用Bundle标识符
    public var bundleIdentifier: String? {
        guard let bundle = Bundle(path: appPath) else { return nil }
        return bundle.bundleIdentifier
    }
}

// MARK: - Equatable
extension ProtocolHandlerModel: Equatable {
    public static func == (lhs: ProtocolHandlerModel, rhs: ProtocolHandlerModel) -> Bool {
        return lhs.appPath == rhs.appPath && lhs.status == rhs.status
    }
}

// MARK: - Hashable
extension ProtocolHandlerModel: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(appPath)
        hasher.combine(status)
    }
}
