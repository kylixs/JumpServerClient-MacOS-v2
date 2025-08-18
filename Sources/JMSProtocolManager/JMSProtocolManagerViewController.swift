import Cocoa
import Foundation

/// JMS协议管理视图控制器
public class JMSProtocolManagerViewController: NSViewController {
    
    // MARK: - UI组件
    private var scrollView: NSScrollView!
    private var handlersListView: NSStackView!
    private var checkStatusButton: NSButton!
    private var reregisterButton: NSButton!
    private var closeButton: NSButton!
    private var statusLabel: NSTextField!
    private var progressIndicator: NSProgressIndicator!
    
    // MARK: - 服务
    private let detectionService = ProtocolDetectionService.shared
    private let registrationService = ProtocolRegistrationService.shared
    
    // MARK: - 数据
    private var handlers: [ProtocolHandlerModel] = []
    
    // MARK: - 委托
    public weak var delegate: ProtocolManagerDelegate?
    
    // MARK: - 生命周期
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkProtocolStatus()
    }
    
    // MARK: - UI设置
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        setupStatusSection()
        setupHandlersList()
        setupActionButtons()
        setupProgressIndicator()
        
        print("✅ JMS协议管理视图已加载")
    }
    
    private func setupStatusSection() {
        // 状态标题
        let statusTitleLabel = NSTextField(labelWithString: "📡 协议状态")
        statusTitleLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        statusTitleLabel.frame = NSRect(x: 20, y: 240, width: 200, height: 20)
        view.addSubview(statusTitleLabel)
        
        // 状态信息
        statusLabel = NSTextField(labelWithString: "正在检查协议状态...")
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.textColor = NSColor.secondaryLabelColor
        statusLabel.frame = NSRect(x: 20, y: 220, width: 360, height: 16)
        view.addSubview(statusLabel)
    }
    
    private func setupHandlersList() {
        // 创建滚动视图
        scrollView = NSScrollView(frame: NSRect(x: 20, y: 120, width: 360, height: 90))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .bezelBorder
        scrollView.backgroundColor = NSColor.controlBackgroundColor
        
        // 创建堆栈视图
        handlersListView = NSStackView()
        handlersListView.orientation = .vertical
        handlersListView.alignment = .leading
        handlersListView.spacing = 8
        handlersListView.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        scrollView.documentView = handlersListView
        view.addSubview(scrollView)
    }
    
    private func setupActionButtons() {
        // 操作标题
        let actionTitleLabel = NSTextField(labelWithString: "🔧 协议操作")
        actionTitleLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        actionTitleLabel.frame = NSRect(x: 20, y: 90, width: 200, height: 20)
        view.addSubview(actionTitleLabel)
        
        // 检查状态按钮
        checkStatusButton = NSButton(title: "检查协议状态", target: self, action: #selector(checkStatusButtonClicked))
        checkStatusButton.bezelStyle = .rounded
        checkStatusButton.frame = NSRect(x: 20, y: 50, width: 120, height: 30)
        view.addSubview(checkStatusButton)
        
        // 重新注册按钮
        reregisterButton = NSButton(title: "重新注册协议", target: self, action: #selector(reregisterButtonClicked))
        reregisterButton.bezelStyle = .rounded
        reregisterButton.frame = NSRect(x: 160, y: 50, width: 120, height: 30)
        view.addSubview(reregisterButton)
        
        // 关闭按钮
        closeButton = NSButton(title: "关闭", target: self, action: #selector(closeButtonClicked))
        closeButton.bezelStyle = .rounded
        closeButton.frame = NSRect(x: 320, y: 20, width: 60, height: 30)
        view.addSubview(closeButton)
    }
    
    private func setupProgressIndicator() {
        progressIndicator = NSProgressIndicator()
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0.0
        progressIndicator.maxValue = 1.0
        progressIndicator.doubleValue = 0.0
        progressIndicator.frame = NSRect(x: 20, y: 20, width: 280, height: 6)
        progressIndicator.isHidden = true
        view.addSubview(progressIndicator)
    }
    
    // MARK: - 数据更新
    private func updateHandlersList() {
        // 清空现有视图
        handlersListView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if handlers.isEmpty {
            let emptyLabel = NSTextField(labelWithString: "未找到任何jms://协议处理器")
            emptyLabel.font = NSFont.systemFont(ofSize: 12)
            emptyLabel.textColor = NSColor.secondaryLabelColor
            emptyLabel.alignment = .center
            handlersListView.addArrangedSubview(emptyLabel)
            return
        }
        
        // 添加处理器信息
        for handler in handlers {
            let handlerView = createHandlerView(for: handler)
            handlersListView.addArrangedSubview(handlerView)
        }
        
        // 更新状态标签
        let currentAppCount = handlers.filter { $0.status == .currentApp }.count
        let otherAppCount = handlers.filter { $0.status == .otherApp }.count
        let invalidCount = handlers.filter { $0.status == .invalid }.count
        
        statusLabel.stringValue = "jms://协议处理器 (共\(handlers.count)个): 当前应用\(currentAppCount)个, 其他应用\(otherAppCount)个, 无效\(invalidCount)个"
    }
    
    private func createHandlerView(for handler: ProtocolHandlerModel) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.controlColor.cgColor
        containerView.layer?.cornerRadius = 4
        
        // 状态图标和应用名称
        let titleLabel = NSTextField(labelWithString: "\(handler.statusIcon) \(handler.appName) (\(handler.statusText))")
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.isBezeled = false
        titleLabel.isEditable = false
        titleLabel.backgroundColor = NSColor.clear
        titleLabel.frame = NSRect(x: 8, y: 20, width: 320, height: 16)
        
        // 应用路径
        let pathLabel = NSTextField(labelWithString: handler.appPath)
        pathLabel.font = NSFont.systemFont(ofSize: 10)
        pathLabel.textColor = NSColor.secondaryLabelColor
        pathLabel.isBezeled = false
        pathLabel.isEditable = false
        pathLabel.backgroundColor = NSColor.clear
        pathLabel.lineBreakMode = .byTruncatingMiddle
        pathLabel.frame = NSRect(x: 8, y: 4, width: 320, height: 14)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(pathLabel)
        
        // 设置容器视图大小
        containerView.frame = NSRect(x: 0, y: 0, width: 340, height: 40)
        
        return containerView
    }
    
    // MARK: - 按钮事件
    @objc private func checkStatusButtonClicked() {
        checkProtocolStatus()
    }
    
    @objc private func reregisterButtonClicked() {
        reregisterProtocol()
    }
    
    @objc private func closeButtonClicked() {
        view.window?.orderOut(nil)
    }
    
    // MARK: - 协议操作
    private func checkProtocolStatus() {
        setUIEnabled(false)
        statusLabel.stringValue = "正在检查协议状态..."
        
        delegate?.protocolCheckDidStart()
        
        Task {
            do {
                let detectedHandlers = try await detectionService.detectAllHandlers()
                
                await MainActor.run {
                    self.handlers = detectedHandlers
                    self.updateHandlersList()
                    self.setUIEnabled(true)
                    self.delegate?.protocolCheckDidComplete(handlers: detectedHandlers)
                }
            } catch {
                await MainActor.run {
                    self.statusLabel.stringValue = "协议状态检查失败: \(error.localizedDescription)"
                    self.setUIEnabled(true)
                    self.delegate?.protocolCheckDidFail(error: error)
                }
            }
        }
    }
    
    private func reregisterProtocol() {
        // 显示确认对话框
        let alert = NSAlert()
        alert.messageText = "重新注册协议"
        alert.informativeText = "此操作将清理所有现有的jms://协议注册，并重新注册当前应用。是否继续？"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "继续")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }
        
        setUIEnabled(false)
        progressIndicator.isHidden = false
        progressIndicator.doubleValue = 0.0
        
        delegate?.protocolRegistrationDidStart()
        
        Task {
            do {
                let success = try await registrationService.reregisterProtocol { [weak self] message, progress in
                    DispatchQueue.main.async {
                        self?.statusLabel.stringValue = message
                        self?.progressIndicator.doubleValue = progress
                        self?.delegate?.protocolRegistrationDidProgress(message: message, progress: progress)
                    }
                }
                
                await MainActor.run {
                    self.progressIndicator.isHidden = true
                    self.setUIEnabled(true)
                    
                    if success {
                        self.statusLabel.stringValue = "协议注册成功"
                        self.checkProtocolStatus() // 重新检查状态
                    } else {
                        self.statusLabel.stringValue = "协议注册失败"
                    }
                    
                    self.delegate?.protocolRegistrationDidComplete(success: success)
                }
            } catch {
                await MainActor.run {
                    self.progressIndicator.isHidden = true
                    self.statusLabel.stringValue = "协议注册失败: \(error.localizedDescription)"
                    self.setUIEnabled(true)
                    self.delegate?.protocolRegistrationDidFail(error: error)
                }
            }
        }
    }
    
    private func setUIEnabled(_ enabled: Bool) {
        checkStatusButton.isEnabled = enabled
        reregisterButton.isEnabled = enabled
    }
}
