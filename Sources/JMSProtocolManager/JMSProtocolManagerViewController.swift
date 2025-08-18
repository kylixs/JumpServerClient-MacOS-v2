import Cocoa
import Foundation
import JMSCore

/// JMS协议管理视图控制器
public class JMSProtocolManagerViewController: NSViewController {
    
    // MARK: - UI组件
    private var scrollView: NSScrollView!
    private var handlersListView: NSView!  // 改为普通NSView，手动管理布局
    private var checkStatusButton: NSButton!
    private var reregisterButton: NSButton!
    private var closeButton: NSButton!
    private var statusLabel: NSTextField!
    private var progressIndicator: NSProgressIndicator!
    
    // 新增：Auto Layout相关属性
    private var statusTitleLabel: NSTextField!
    private var buttonContainer: NSView!
    
    // 新增：手动布局管理
    private var handlerViewConstraints: [NSLayoutConstraint] = []
    
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
        
        // 设置首选内容大小，确保窗口默认高度为300
        preferredContentSize = NSSize(width: 520, height: 300)
        
        setupUI()
        
        // 生成初始UI分析报告
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            self.generateUIAnalysisReport(phase: "初始加载")
        }
        
        checkProtocolStatus(forceRefresh: false) // 初始加载使用快速模式
    }
    
    // MARK: - UI设置
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 设置视图使用Auto Layout
        view.translatesAutoresizingMaskIntoConstraints = false
        
        setupStatusSection()
        setupHandlersList()
        setupActionButtons()
        setupProgressIndicator()
        setupConstraints()  // 新增：设置Auto Layout约束
        
        logger.info("✅ JMS协议管理视图已加载")
    }
    
    private func setupStatusSection() {
        // 状态标题 - 使用Auto Layout
        let statusTitleLabel = NSTextField(labelWithString: "📡 协议状态")
        statusTitleLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        statusTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        statusTitleLabel.isEditable = false
        statusTitleLabel.isBordered = false
        statusTitleLabel.backgroundColor = NSColor.clear
        view.addSubview(statusTitleLabel)
        self.statusTitleLabel = statusTitleLabel  // 保存引用
        
        // 状态信息 - 使用Auto Layout
        statusLabel = NSTextField(labelWithString: "正在检查协议状态...")
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.textColor = NSColor.secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.isEditable = false
        statusLabel.isBordered = false
        statusLabel.backgroundColor = NSColor.clear
        view.addSubview(statusLabel)
        
        logger.info("✅ 状态区域设置完成")
    }
    
    // MARK: - Flipped Container View
    
    /// 自定义的翻转坐标系统视图，确保子视图从顶部开始布局
    private class FlippedContainerView: NSView {
        override var isFlipped: Bool {
            return true  // 翻转坐标系统，y=0在顶部
        }
    }
    
    private func setupHandlersList() {
        // 创建滚动视图 - 使用Auto Layout
        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .bezelBorder
        scrollView.backgroundColor = NSColor.controlBackgroundColor
        scrollView.autohidesScrollers = true  // macOS风格：自动隐藏滚动条
        
        // 最终解决方案：使用flipped坐标系统的容器视图
        let flippedContainer = FlippedContainerView()
        flippedContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 在flipped容器中创建普通NSView作为内容容器
        handlersListView = NSView()
        handlersListView.translatesAutoresizingMaskIntoConstraints = false
        handlersListView.wantsLayer = true
        handlersListView.layer?.backgroundColor = NSColor.clear.cgColor
        
        flippedContainer.addSubview(handlersListView)
        
        // 设置handlersListView在flipped容器中的约束
        NSLayoutConstraint.activate([
            handlersListView.topAnchor.constraint(equalTo: flippedContainer.topAnchor),
            handlersListView.leadingAnchor.constraint(equalTo: flippedContainer.leadingAnchor),
            handlersListView.trailingAnchor.constraint(equalTo: flippedContainer.trailingAnchor),
            handlersListView.bottomAnchor.constraint(equalTo: flippedContainer.bottomAnchor)
        ])
        
        // 设置flipped容器为文档视图
        scrollView.documentView = flippedContainer
        view.addSubview(scrollView)
        
        logger.info("✅ 处理器列表视图已设置 - 使用flipped坐标系统确保从顶部到底部排列")
    }
    
    private func setupActionButtons() {
        // 创建按钮容器视图
        let buttonContainer = NSView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonContainer)
        self.buttonContainer = buttonContainer  // 保存引用
        
        // 检查状态按钮
        checkStatusButton = NSButton(title: "检查协议状态", target: self, action: #selector(checkStatusButtonClicked))
        checkStatusButton.bezelStyle = .rounded
        checkStatusButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(checkStatusButton)
        
        // 重新注册按钮
        reregisterButton = NSButton(title: "重新注册协议", target: self, action: #selector(reregisterButtonClicked))
        reregisterButton.bezelStyle = .rounded
        reregisterButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(reregisterButton)
        
        // 关闭按钮
        closeButton = NSButton(title: "关闭", target: self, action: #selector(closeButtonClicked))
        closeButton.bezelStyle = .rounded
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(closeButton)
        
        logger.info("✅ 按钮区域设置完成")
    }
    
    private func setupProgressIndicator() {
        progressIndicator = NSProgressIndicator()
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0.0
        progressIndicator.maxValue = 1.0
        progressIndicator.doubleValue = 0.0
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.isHidden = true
        view.addSubview(progressIndicator)
    }
    
    // MARK: - Auto Layout约束设置
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 状态标题 - 顶部对齐，左边距20
            statusTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            statusTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // 状态信息 - 紧跟标题下方
            statusLabel.topAnchor.constraint(equalTo: statusTitleLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // 滚动视图 - 占据中间大部分空间
            scrollView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: buttonContainer.topAnchor, constant: -12),
            
            // 按钮容器 - 底部对齐
            buttonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            buttonContainer.heightAnchor.constraint(equalToConstant: 32),
            
            // 按钮容器内的按钮布局
            checkStatusButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
            checkStatusButton.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor),
            checkStatusButton.widthAnchor.constraint(equalToConstant: 120),
            
            reregisterButton.leadingAnchor.constraint(equalTo: checkStatusButton.trailingAnchor, constant: 12),
            reregisterButton.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor),
            reregisterButton.widthAnchor.constraint(equalToConstant: 120),
            
            closeButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 60),
            
            // 进度条 - 位于按钮右侧
            progressIndicator.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -12),
            progressIndicator.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor),
            progressIndicator.widthAnchor.constraint(equalToConstant: 120),
            progressIndicator.heightAnchor.constraint(equalToConstant: 6)
        ])
        
        logger.info("✅ Auto Layout约束设置完成")
    }
    
    // MARK: - 数据更新
    private func updateHandlersList() {
        logger.info("🔄 更新处理器列表，共有 \(handlers.count) 个处理器")
        
        // 确保在主线程执行UI更新
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 清空现有视图和约束
            self.handlerViewConstraints.forEach { $0.isActive = false }
            self.handlerViewConstraints.removeAll()
            
            self.handlersListView.subviews.forEach { $0.removeFromSuperview() }
            
            if self.handlers.isEmpty {
                self.logger.warning("⚠️ 处理器列表为空，显示空状态")
                let emptyLabel = NSTextField(labelWithString: "未找到任何jms://协议处理器")
                emptyLabel.font = NSFont.systemFont(ofSize: 12)
                emptyLabel.textColor = NSColor.secondaryLabelColor
                emptyLabel.alignment = .center
                emptyLabel.translatesAutoresizingMaskIntoConstraints = false
                emptyLabel.isEditable = false
                emptyLabel.isBordered = false
                emptyLabel.backgroundColor = NSColor.clear
                
                self.handlersListView.addSubview(emptyLabel)
                
                // 居中显示空状态标签
                let constraints = [
                    emptyLabel.centerXAnchor.constraint(equalTo: self.handlersListView.centerXAnchor),
                    emptyLabel.topAnchor.constraint(equalTo: self.handlersListView.topAnchor, constant: 20),
                    emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.handlersListView.leadingAnchor, constant: 20),
                    emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.handlersListView.trailingAnchor, constant: -20)
                ]
                NSLayoutConstraint.activate(constraints)
                self.handlerViewConstraints.append(contentsOf: constraints)
                
                self.logger.info("📝 已显示空状态标签")
            } else {
                // 手动布局处理器视图 - 从顶部到底部排列
                var previousView: NSView? = nil
                let margin: CGFloat = 8
                let spacing: CGFloat = 4
                
                for (index, handler) in self.handlers.enumerated() {
                    self.logger.info("📱 添加处理器 \(index + 1): \(handler.appName) at \(handler.appPath) (状态: \(handler.statusText))")
                    let handlerView = self.createHandlerView(for: handler)
                    
                    self.handlersListView.addSubview(handlerView)
                    
                    // 手动设置约束 - 确保从顶部开始排列
                    var constraints: [NSLayoutConstraint] = []
                    
                    if let previous = previousView {
                        // 不是第一个视图，放在前一个视图下方
                        constraints.append(handlerView.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: spacing))
                    } else {
                        // 第一个视图，放在容器顶部
                        constraints.append(handlerView.topAnchor.constraint(equalTo: self.handlersListView.topAnchor, constant: margin))
                    }
                    
                    // 设置左右边距
                    constraints.append(handlerView.leadingAnchor.constraint(equalTo: self.handlersListView.leadingAnchor, constant: margin))
                    constraints.append(handlerView.trailingAnchor.constraint(equalTo: self.handlersListView.trailingAnchor, constant: -margin))
                    
                    NSLayoutConstraint.activate(constraints)
                    self.handlerViewConstraints.append(contentsOf: constraints)
                    
                    previousView = handlerView
                }
                
                // 设置最后一个视图到容器底部的约束（可选，用于确定容器高度）
                if let lastView = previousView {
                    let bottomConstraint = lastView.bottomAnchor.constraint(lessThanOrEqualTo: self.handlersListView.bottomAnchor, constant: -margin)
                    bottomConstraint.priority = NSLayoutConstraint.Priority(999)  // 稍低优先级
                    bottomConstraint.isActive = true
                    self.handlerViewConstraints.append(bottomConstraint)
                }
                
                if JMSSettings.enableLayoutLogging {
                    self.logger.info("📐 已手动布局 \(self.handlers.count) 个处理器视图")
                }
            }
            
            // 强制更新布局
            self.handlersListView.needsLayout = true
            self.handlersListView.layoutSubtreeIfNeeded()
            self.scrollView.needsDisplay = true
            
            // 滚动到顶部
            self.scrollView.documentView?.scroll(NSPoint.zero)
            
            // 更新状态标签
            let currentAppCount = self.handlers.filter { $0.status == .currentApp }.count
            let otherAppCount = self.handlers.filter { $0.status == .otherApp }.count
            let invalidCount = self.handlers.filter { $0.status == .invalid }.count
            
            let statusText = "jms://协议处理器 (共\(self.handlers.count)个): 当前应用\(currentAppCount)个, 其他应用\(otherAppCount)个, 无效\(invalidCount)个"
            self.statusLabel.stringValue = statusText
            self.logger.info("📊 状态更新: \(statusText)")
            
            if JMSSettings.enableLayoutLogging {
                self.logger.info("✅ 界面更新完成，手动布局子视图数量: \(self.handlersListView.subviews.count)")
                self.logger.info("📐 列表项排列: 手动布局确保从顶部到底部排列")
            }
            
            // 生成更新后的UI分析报告
            self.generateUIAnalysisReport(phase: "数据更新后")
        }
    }
    
    private func createHandlerView(for handler: ProtocolHandlerModel) -> NSView {
        logger.debug("🎨 创建处理器视图: \(handler.appName)")
        
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.controlColor.cgColor
        containerView.layer?.cornerRadius = 4
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 关键：设置容器视图的布局优先级，确保它在垂直方向上不会拉伸
        containerView.setContentHuggingPriority(NSLayoutConstraint.Priority(1000), for: .vertical)  // 高优先级，不拉伸
        containerView.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1000), for: .vertical)  // 高优先级，不压缩
        
        // 水平方向上允许拉伸以填充宽度
        containerView.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .horizontal)  // 低优先级，允许拉伸
        containerView.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1000), for: .horizontal)  // 高优先级，不压缩
        
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
        
        // 设置标题标签的布局优先级
        titleLabel.setContentHuggingPriority(NSLayoutConstraint.Priority(1000), for: .vertical)
        titleLabel.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1000), for: .vertical)
        
        // 应用路径
        let pathLabel = NSTextField(labelWithString: handler.appPath)
        pathLabel.font = NSFont.systemFont(ofSize: 10)
        pathLabel.textColor = NSColor.secondaryLabelColor
        pathLabel.isBezeled = false
        pathLabel.isEditable = false
        pathLabel.backgroundColor = NSColor.clear
        pathLabel.lineBreakMode = .byTruncatingMiddle
        pathLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置路径标签的布局优先级
        pathLabel.setContentHuggingPriority(NSLayoutConstraint.Priority(1000), for: .vertical)
        pathLabel.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1000), for: .vertical)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(pathLabel)
        
        // 使用Auto Layout约束 - 确保固定高度和正确的内部布局
        NSLayoutConstraint.activate([
            // 容器视图固定高度 - 关键：确保每个项目高度一致
            containerView.heightAnchor.constraint(equalToConstant: 36),
            
            // 标题标签 - 顶部对齐，填充宽度
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            // 路径标签 - 紧跟标题下方，填充宽度
            pathLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            pathLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            pathLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            pathLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -4)
        ])
        
        // 添加边框
        containerView.layer?.borderWidth = 0.5
        containerView.layer?.borderColor = NSColor.separatorColor.cgColor
        
        logger.debug("✅ 处理器视图创建完成: \(titleText) (固定高度36pt)")
        return containerView
    }
    
    // MARK: - 按钮事件
    @objc private func checkStatusButtonClicked() {
        logger.info("🔘 用户点击检查协议状态按钮 - 使用强制刷新模式")
        
        // 清空当前数据，强制重新检测
        handlers.removeAll()
        updateHandlersList()
        
        checkProtocolStatus(forceRefresh: true)
    }
    
    @objc private func reregisterButtonClicked() {
        reregisterProtocol()
    }
    
    @objc private func closeButtonClicked() {
        view.window?.orderOut(nil)
    }
    
    // MARK: - 协议操作
    private func checkProtocolStatus(forceRefresh: Bool = false) {
        logger.info("🔍 开始检查协议状态... (强制刷新: \(forceRefresh))")
        setUIEnabled(false)
        statusLabel.stringValue = "正在检查协议状态..."
        
        delegate?.protocolCheckDidStart()
        
        Task {
            do {
                logger.info("📡 调用协议检测服务...")
                
                // 根据参数决定是否强制刷新缓存
                let detectedHandlers = try await detectionService.detectAllHandlers(forceRefresh: forceRefresh)
                logger.info("✅ 检测完成，获得 \(detectedHandlers.count) 个处理器")
                
                await MainActor.run {
                    logger.info("🔄 在主线程更新UI...")
                    
                    // 强制清空旧数据
                    self.handlers.removeAll()
                    
                    // 设置新数据
                    self.handlers = detectedHandlers
                    
                    // 强制更新UI
                    self.updateHandlersList()
                    self.setUIEnabled(true)
                    
                    self.delegate?.protocolCheckDidComplete(handlers: detectedHandlers)
                    logger.info("✅ UI更新完成，当前显示 \(self.handlers.count) 个处理器")
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
                logger.info("🔄 开始协议注册任务...")
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
                        self.statusLabel.stringValue = "协议注册成功，正在刷新状态..."
                        self.logger.info("✅ 协议注册成功，准备刷新状态")
                        
                        // 减少延迟时间，现代系统更新很快
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.logger.info("🔄 快速检查协议状态...")
                            self.checkProtocolStatus(forceRefresh: false) // 重新注册后不需要强制刷新
                        }
                    } else {
                        self.statusLabel.stringValue = "协议注册失败"
                        self.logger.error("❌ 协议注册失败")
                    }
                    
                    self.delegate?.protocolRegistrationDidComplete(success: success)
                }
            } catch {
                logger.error("❌ 协议注册异常: \(error)")
                logger.error("❌ 错误类型: \(type(of: error))")
                
                await MainActor.run {
                    self.progressIndicator.isHidden = true
                    self.setUIEnabled(true)
                    
                    // 根据错误类型提供不同的处理
                    if let registrationError = error as? ProtocolRegistrationError {
                        self.logger.info("🔍 检测到协议注册错误: \(registrationError)")
                        switch registrationError {
                        case .permissionDenied:
                            self.logger.info("🔒 权限不足，显示权限提升对话框")
                            self.showPermissionDeniedAlert()
                        case .userCancelled:
                            self.statusLabel.stringValue = "用户取消了权限授权"
                            self.logger.info("ℹ️ 用户取消了权限授权")
                        default:
                            self.statusLabel.stringValue = "协议注册失败: \(registrationError.localizedDescription)"
                            self.logger.error("❌ 其他注册错误: \(registrationError)")
                        }
                    } else {
                        self.logger.error("❌ 未知错误类型: \(error)")
                        self.statusLabel.stringValue = "协议注册失败: \(error.localizedDescription)"
                    }
                    
                    self.delegate?.protocolRegistrationDidFail(error: error)
                }
            }
        }
    }
    
    /// 显示权限不足的提示对话框
    private func showPermissionDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "权限不足"
        alert.informativeText = """
        注册jms://协议需要管理员权限来修改系统设置。
        
        请选择以下操作：
        • 点击"使用管理员权限"重试（推荐）
        • 点击"手动注册"查看手动操作步骤
        • 点击"取消"放弃注册
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "使用管理员权限")
        alert.addButton(withTitle: "手动注册")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            // 用户选择使用管理员权限重试
            logger.info("🔐 用户选择使用管理员权限重试")
            reregisterProtocolWithElevation()
        case .alertSecondButtonReturn:
            // 用户选择查看手动注册步骤
            logger.info("📖 用户选择查看手动注册步骤")
            showManualRegistrationGuide()
        default:
            // 用户取消
            logger.info("❌ 用户取消了权限提升")
            statusLabel.stringValue = "协议注册已取消"
        }
    }
    
    /// 使用管理员权限重新注册协议
    private func reregisterProtocolWithElevation() {
        logger.info("🔐 开始使用管理员权限重新注册协议...")
        setUIEnabled(false)
        progressIndicator.isHidden = false
        progressIndicator.doubleValue = 0.0
        statusLabel.stringValue = "正在请求管理员权限..."
        
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
                        self.statusLabel.stringValue = "协议注册成功（使用管理员权限）"
                        self.logger.info("✅ 协议注册成功（使用管理员权限）")
                        self.checkProtocolStatus(forceRefresh: false) // 重新检查状态，使用快速模式
                    } else {
                        self.statusLabel.stringValue = "协议注册失败"
                        self.logger.error("❌ 协议注册失败（即使使用管理员权限）")
                    }
                    
                    self.delegate?.protocolRegistrationDidComplete(success: success)
                }
            } catch {
                logger.error("❌ 管理员权限注册异常: \(error)")
                await MainActor.run {
                    self.progressIndicator.isHidden = true
                    self.setUIEnabled(true)
                    self.statusLabel.stringValue = "管理员权限注册失败: \(error.localizedDescription)"
                    self.delegate?.protocolRegistrationDidFail(error: error)
                }
            }
        }
    }
    
    /// 显示手动注册指南
    private func showManualRegistrationGuide() {
        let alert = NSAlert()
        alert.messageText = "手动注册jms://协议"
        alert.informativeText = """
        如果自动注册失败，您可以手动执行以下步骤：
        
        1. 打开"终端"应用程序
        2. 执行以下命令：
           sudo /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "\(Bundle.main.bundlePath)"
        3. 输入管理员密码
        4. 重启应用程序
        
        或者运行项目中的注册脚本：
        ./scripts/deployment/register_jms_protocol.sh
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "复制命令")
        alert.addButton(withTitle: "关闭")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // 复制命令到剪贴板
            let command = "sudo /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f \"\(Bundle.main.bundlePath)\""
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(command, forType: .string)
            
            statusLabel.stringValue = "命令已复制到剪贴板"
            logger.info("📋 手动注册命令已复制到剪贴板")
        }
    }
    
    private func setUIEnabled(_ enabled: Bool) {
        checkStatusButton.isEnabled = enabled
        reregisterButton.isEnabled = enabled
    }
    
    // MARK: - UI分析报告
    
    /// 生成UI分析报告
    /// - Parameter phase: 分析阶段描述
    private func generateUIAnalysisReport(phase: String) {
        // 只在启用UI分析时执行
        guard JMSSettings.enableUIAnalysis else { return }
        
        // 动态导入UIInspector以避免编译时依赖
        guard NSClassFromString("UIInspector.UIInspector") != nil else {
            logger.warning("⚠️ UIInspector模块未找到，跳过UI分析")
            return
        }
        
        // 由于UI分析功能已禁用，直接返回
        logger.info("📊 UI分析功能已禁用 (enableUIAnalysis = false)")
        
        /*
        let report = view.generateUIAnalysisReport(title: reportTitle, expectedLayout: expectedLayout)
        
        // 输出报告摘要到日志
        logger.info("📊 UI分析报告生成完成:")
        logger.info(report.summary)
        
        // 输出高优先级问题
        let highPriorityIssues = report.highPriorityIssues
        if !highPriorityIssues.isEmpty {
            logger.warning("🔴 发现\(highPriorityIssues.count)个高优先级布局问题:")
            for issue in highPriorityIssues {
                logger.warning("  - [\(issue.type.rawValue)] \(issue.description)")
                logger.warning("    建议: \(issue.suggestion)")
            }
        }
        
        // 输出高优先级建议
        let highPrioritySuggestions = report.highPrioritySuggestions
        if !highPrioritySuggestions.isEmpty {
            logger.info("💡 高优先级改进建议:")
            for suggestion in highPrioritySuggestions {
                logger.info("  - [\(suggestion.category.rawValue)] \(suggestion.title)")
                logger.info("    \(suggestion.description)")
            }
        }
        
        // 保存详细报告到文件
        UIInspector.shared.saveReport(report, filename: "JMS_Protocol_Manager_\(phase)_Analysis.txt")
        
        // 如果是数据更新后的报告，进行对比分析
        if phase == "数据更新后", let initialReport = self.initialReport {
            let comparison = ReportComparison(beforeReport: initialReport, afterReport: report)
            
            if !comparison.improvements.isEmpty {
                logger.info("📈 界面改进:")
                for improvement in comparison.improvements {
                    logger.info("  ✅ \(improvement)")
                }
            }
            
            if !comparison.regressions.isEmpty {
                logger.warning("📉 界面退化:")
                for regression in comparison.regressions {
                    logger.warning("  ❌ \(regression)")
                }
            }
        */
    }
    
    /// 存储初始报告用于对比 - 仅在启用UI分析时使用
    private var initialReport: Any? // 使用Any类型避免UIInspector依赖
}
