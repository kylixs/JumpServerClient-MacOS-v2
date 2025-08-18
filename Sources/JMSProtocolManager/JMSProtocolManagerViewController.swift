import Cocoa
import Foundation
import JMSCore

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
    private let logger = LogManager.shared
    
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
        
        logger.info("✅ JMS协议管理视图已加载")
    }
    
    private func setupStatusSection() {
        // 状态标题 - 向上移动
        let statusTitleLabel = NSTextField(labelWithString: "📡 协议状态")
        statusTitleLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        statusTitleLabel.frame = NSRect(x: 20, y: 190, width: 200, height: 20)
        view.addSubview(statusTitleLabel)
        
        // 状态信息 - 向上移动
        statusLabel = NSTextField(labelWithString: "正在检查协议状态...")
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.textColor = NSColor.secondaryLabelColor
        statusLabel.frame = NSRect(x: 20, y: 170, width: 460, height: 16)
        view.addSubview(statusLabel)
    }
    
    private func setupHandlersList() {
        // 创建滚动视图 - 向上移动，增加高度
        scrollView = NSScrollView(frame: NSRect(x: 20, y: 70, width: 460, height: 90))
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
        
        // 设置堆栈视图的约束
        handlersListView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.documentView = handlersListView
        view.addSubview(scrollView)
        
        logger.info("✅ 处理器列表视图已设置")
    }
    
    private func setupActionButtons() {
        // 去掉操作标题，直接放置按钮在同一行
        
        // 检查状态按钮
        checkStatusButton = NSButton(title: "检查协议状态", target: self, action: #selector(checkStatusButtonClicked))
        checkStatusButton.bezelStyle = .rounded
        checkStatusButton.frame = NSRect(x: 20, y: 20, width: 120, height: 30)
        view.addSubview(checkStatusButton)
        
        // 重新注册按钮
        reregisterButton = NSButton(title: "重新注册协议", target: self, action: #selector(reregisterButtonClicked))
        reregisterButton.bezelStyle = .rounded
        reregisterButton.frame = NSRect(x: 160, y: 20, width: 120, height: 30)
        view.addSubview(reregisterButton)
        
        // 关闭按钮 - 移到右侧
        closeButton = NSButton(title: "关闭", target: self, action: #selector(closeButtonClicked))
        closeButton.bezelStyle = .rounded
        closeButton.frame = NSRect(x: 420, y: 20, width: 60, height: 30)
        view.addSubview(closeButton)
    }
    
    private func setupProgressIndicator() {
        progressIndicator = NSProgressIndicator()
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0.0
        progressIndicator.maxValue = 1.0
        progressIndicator.doubleValue = 0.0
        progressIndicator.frame = NSRect(x: 300, y: 30, width: 100, height: 6)
        progressIndicator.isHidden = true
        view.addSubview(progressIndicator)
    }
    
    // MARK: - 数据更新
    private func updateHandlersList() {
        logger.info("🔄 更新处理器列表，共有 \(handlers.count) 个处理器")
        
        // 确保在主线程执行UI更新
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 清空现有视图
            self.handlersListView.arrangedSubviews.forEach { view in
                self.handlersListView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
            
            if self.handlers.isEmpty {
                self.logger.warning("⚠️ 处理器列表为空，显示空状态")
                let emptyLabel = NSTextField(labelWithString: "未找到任何jms://协议处理器")
                emptyLabel.font = NSFont.systemFont(ofSize: 12)
                emptyLabel.textColor = NSColor.secondaryLabelColor
                emptyLabel.alignment = .center
                emptyLabel.translatesAutoresizingMaskIntoConstraints = false
                
                self.handlersListView.addArrangedSubview(emptyLabel)
                
                // 设置约束确保标签居中显示
                NSLayoutConstraint.activate([
                    emptyLabel.widthAnchor.constraint(equalToConstant: 440),
                    emptyLabel.heightAnchor.constraint(equalToConstant: 20)
                ])
                
                self.logger.info("📝 已显示空状态标签")
                return
            }
            
            // 添加处理器信息
            for (index, handler) in self.handlers.enumerated() {
                self.logger.info("📱 添加处理器 \(index + 1): \(handler.appName) at \(handler.appPath) (状态: \(handler.statusText))")
                let handlerView = self.createHandlerView(for: handler)
                self.handlersListView.addArrangedSubview(handlerView)
                
                // 设置视图约束
                NSLayoutConstraint.activate([
                    handlerView.widthAnchor.constraint(equalToConstant: 440),
                    handlerView.heightAnchor.constraint(equalToConstant: 40)
                ])
            }
            
            // 强制更新布局
            self.handlersListView.needsLayout = true
            self.handlersListView.layoutSubtreeIfNeeded()
            self.scrollView.needsDisplay = true
            
            // 更新状态标签
            let currentAppCount = self.handlers.filter { $0.status == .currentApp }.count
            let otherAppCount = self.handlers.filter { $0.status == .otherApp }.count
            let invalidCount = self.handlers.filter { $0.status == .invalid }.count
            
            let statusText = "jms://协议处理器 (共\(self.handlers.count)个): 当前应用\(currentAppCount)个, 其他应用\(otherAppCount)个, 无效\(invalidCount)个"
            self.statusLabel.stringValue = statusText
            self.logger.info("📊 状态更新: \(statusText)")
            
            self.logger.info("✅ 界面更新完成，堆栈视图子视图数量: \(self.handlersListView.arrangedSubviews.count)")
        }
    }
    
    private func createHandlerView(for handler: ProtocolHandlerModel) -> NSView {
        logger.debug("🎨 创建处理器视图: \(handler.appName)")
        
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.controlColor.cgColor
        containerView.layer?.cornerRadius = 4
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 状态图标和应用名称
        var titleText = "\(handler.statusIcon) \(handler.appName) (\(handler.statusText))"
        if handler.isDefault {
            titleText += " [默认]"
        }
        
        let titleLabel = NSTextField(labelWithString: titleText)
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.isBezeled = false
        titleLabel.isEditable = false
        titleLabel.backgroundColor = NSColor.clear
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 应用路径
        let pathLabel = NSTextField(labelWithString: handler.appPath)
        pathLabel.font = NSFont.systemFont(ofSize: 10)
        pathLabel.textColor = NSColor.secondaryLabelColor
        pathLabel.isBezeled = false
        pathLabel.isEditable = false
        pathLabel.backgroundColor = NSColor.clear
        pathLabel.lineBreakMode = .byTruncatingMiddle
        pathLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(pathLabel)
        
        // 使用Auto Layout约束
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            titleLabel.heightAnchor.constraint(equalToConstant: 16),
            
            pathLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            pathLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            pathLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            pathLabel.heightAnchor.constraint(equalToConstant: 14),
            pathLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4)
        ])
        
        // 添加边框以便调试
        containerView.layer?.borderWidth = 0.5
        containerView.layer?.borderColor = NSColor.separatorColor.cgColor
        
        logger.debug("✅ 处理器视图创建完成: \(titleText)")
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
        logger.info("🔍 开始检查协议状态...")
        setUIEnabled(false)
        statusLabel.stringValue = "正在检查协议状态..."
        
        delegate?.protocolCheckDidStart()
        
        Task {
            do {
                logger.info("📡 调用协议检测服务...")
                let detectedHandlers = try await detectionService.detectAllHandlers()
                logger.info("✅ 检测完成，获得 \(detectedHandlers.count) 个处理器")
                
                await MainActor.run {
                    logger.info("🔄 在主线程更新UI...")
                    self.handlers = detectedHandlers
                    self.updateHandlersList()
                    self.setUIEnabled(true)
                    self.delegate?.protocolCheckDidComplete(handlers: detectedHandlers)
                    logger.info("✅ UI更新完成")
                }
            } catch {
                logger.error("❌ 协议检测失败: \(error)")
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
        
        logger.info("🔄 开始重新注册协议...")
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
                        self?.logger.info("📊 注册进度: \(message) (\(Int(progress * 100))%)")
                    }
                }
                
                await MainActor.run {
                    self.progressIndicator.isHidden = true
                    self.setUIEnabled(true)
                    
                    if success {
                        self.statusLabel.stringValue = "协议注册成功"
                        self.logger.info("✅ 协议注册成功")
                        self.checkProtocolStatus() // 重新检查状态
                    } else {
                        self.statusLabel.stringValue = "协议注册失败"
                        self.logger.error("❌ 协议注册失败")
                    }
                    
                    self.delegate?.protocolRegistrationDidComplete(success: success)
                }
            } catch {
                logger.error("❌ 协议注册异常: \(error)")
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
