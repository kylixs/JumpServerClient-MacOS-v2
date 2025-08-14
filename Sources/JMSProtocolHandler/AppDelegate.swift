import Foundation
import Cocoa
import JMSCore
import JMSRDPModule
import JMSSSHModule

/// 应用程序委托
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // GUI组件
    private var statusItem: NSStatusItem?
    private var rdpSettingsWindow: NSWindow?
    private var rdpSettingsViewController: RDPSettingsViewController?
    
    // URL处理标志
    private var hasProcessedURL = false
    
    // 服务组件
    private let urlParser = URLParser()
    private let payloadDecoder = PayloadDecoder()
    private let connectionInfoExtractor = ConnectionInfoExtractor()
    private let rdpIntegrator = RemoteDesktopIntegrator()
    private let sshIntegrator = SSHTerminalIntegrator()
    private let errorHandler = ErrorHandler.shared
    private let rdpConfigManager = RDPConfigManager.shared
    private let rdpSettingsManager = RDPSettingsManager.shared
    
    // MARK: - 应用程序生命周期
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 使用新的日志组件记录应用启动
        LogManager.shared.logAppStart()
        
        // 设置应用程序为普通应用，显示在Dock中
        NSApp.setActivationPolicy(.regular)
        
        // 创建状态栏项目
        setupStatusBarItem()
        
        // 设置主菜单
        setupMainMenu()
        
        // 注册URL事件处理
        logInfo("🔗 注册Apple Events URL处理器...")
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        logInfo("✅ Apple Events URL处理器注册完成")
        
        // 检查是否有命令行参数传入的URL
        logDebug("🔍 开始检查命令行参数...")
        handleCommandLineArguments()
        
        // 确保应用程序激活
        DispatchQueue.main.async {
            // 只有在处理URL时才激活应用程序
            let arguments = CommandLine.arguments
            let hasURLArgument = arguments.contains { $0.hasPrefix("jms://") }
            
            logDebug("🎯 检查是否需要激活应用程序: hasURLArgument=\(hasURLArgument)")
            if hasURLArgument {
                logDebug("🎯 激活应用程序...")
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        logInfo("JMS Protocol Handler 正在退出")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 不要在最后一个窗口关闭时退出应用程序
        return false
    }
    
    // MARK: - GUI设置
    
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "JMS"
            button.toolTip = "JMS Protocol Handler - 当前配置: \(rdpSettingsManager.currentSettings.profileName)"
        }
        
        // 创建状态栏菜单
        let menu = NSMenu()
        
        // RDP设置菜单项
        let rdpSettingsItem = NSMenuItem(title: "RDP设置...", action: #selector(showRDPSettings), keyEquivalent: ",")
        rdpSettingsItem.target = self
        menu.addItem(rdpSettingsItem)
        
        // RDP质量配置子菜单
        let qualityMenuItem = NSMenuItem(title: "快速切换质量", action: nil, keyEquivalent: "")
        let qualitySubmenu = NSMenu()
        
        for (index, preset) in RDPSettings.allPresets.enumerated() {
            let keyEquivalent = String(index + 1)
            let item = NSMenuItem(title: preset.profileName, action: #selector(selectRDPQualityPreset(_:)), keyEquivalent: keyEquivalent)
            item.target = self
            item.representedObject = preset
            
            // 标记当前选中的配置
            if preset.profileName == rdpSettingsManager.currentSettings.profileName {
                item.state = .on
            }
            
            qualitySubmenu.addItem(item)
        }
        
        qualityMenuItem.submenu = qualitySubmenu
        menu.addItem(qualityMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 关于菜单项
        let aboutItem = NSMenuItem(title: "关于 JMS Protocol Handler", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        // 退出菜单项
        let quitItem = NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func setupMainMenu() {
        // 创建主菜单栏
        let mainMenu = NSMenu()
        
        // 1. 应用程序菜单
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "JMSProtocolHandler")
        
        // 关于菜单项
        let aboutItem = NSMenuItem(title: "关于 JMSProtocolHandler", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        appMenu.addItem(aboutItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // RDP设置菜单项
        let preferencesItem = NSMenuItem(title: "RDP设置...", action: #selector(showRDPSettings), keyEquivalent: ",")
        preferencesItem.target = self
        appMenu.addItem(preferencesItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // 服务菜单
        let servicesItem = NSMenuItem(title: "服务", action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu(title: "服务")
        servicesItem.submenu = servicesMenu
        appMenu.addItem(servicesItem)
        NSApp.servicesMenu = servicesMenu
        
        appMenu.addItem(NSMenuItem.separator())
        
        // 隐藏应用程序
        let hideItem = NSMenuItem(title: "隐藏 JMSProtocolHandler", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(hideItem)
        
        // 隐藏其他应用程序
        let hideOthersItem = NSMenuItem(title: "隐藏其他", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)
        
        // 显示所有
        let showAllItem = NSMenuItem(title: "显示全部", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(showAllItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // 退出应用程序
        let quitItem = NSMenuItem(title: "退出 JMSProtocolHandler", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitItem)
        
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // 2. RDP菜单
        let rdpMenuItem = NSMenuItem(title: "RDP", action: nil, keyEquivalent: "")
        let rdpMenu = NSMenu(title: "RDP")
        
        // 质量配置子菜单
        for (index, preset) in RDPSettings.allPresets.enumerated() {
            let keyEquivalent = String(index + 1)
            let item = NSMenuItem(title: preset.profileName, action: #selector(selectRDPQualityPreset(_:)), keyEquivalent: keyEquivalent)
            item.target = self
            item.representedObject = preset
            
            // 标记当前选中的配置
            if preset.profileName == rdpSettingsManager.currentSettings.profileName {
                item.state = .on
            }
            
            rdpMenu.addItem(item)
        }
        
        rdpMenu.addItem(NSMenuItem.separator())
        
        // 打开设置窗口
        let settingsItem = NSMenuItem(title: "打开RDP设置...", action: #selector(showRDPSettings), keyEquivalent: "")
        settingsItem.target = self
        rdpMenu.addItem(settingsItem)
        
        // 重置设置
        let resetItem = NSMenuItem(title: "重置为默认设置", action: #selector(resetToDefaults), keyEquivalent: "")
        resetItem.target = self
        rdpMenu.addItem(resetItem)
        
        rdpMenuItem.submenu = rdpMenu
        mainMenu.addItem(rdpMenuItem)
        
        // 3. 窗口菜单
        let windowMenuItem = NSMenuItem(title: "窗口", action: nil, keyEquivalent: "")
        let windowMenu = NSMenu(title: "窗口")
        
        // 最小化
        let minimizeItem = NSMenuItem(title: "最小化", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(minimizeItem)
        
        // 缩放
        let zoomItem = NSMenuItem(title: "缩放", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(zoomItem)
        
        windowMenu.addItem(NSMenuItem.separator())
        
        // 前置所有窗口
        let bringAllToFrontItem = NSMenuItem(title: "前置所有窗口", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        windowMenu.addItem(bringAllToFrontItem)
        
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        NSApp.windowsMenu = windowMenu
        
        // 4. 帮助菜单
        let helpMenuItem = NSMenuItem(title: "帮助", action: nil, keyEquivalent: "")
        let helpMenu = NSMenu(title: "帮助")
        
        // JMSProtocolHandler帮助
        let helpItem = NSMenuItem(title: "JMSProtocolHandler 帮助", action: #selector(showHelp), keyEquivalent: "?")
        helpItem.target = self
        helpMenu.addItem(helpItem)
        
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)
        NSApp.helpMenu = helpMenu
        
        // 设置主菜单
        NSApp.mainMenu = mainMenu
        
        print("✅ 主菜单栏已设置")
    }
    
    // MARK: - GUI动作
    
    @objc private func showRDPSettings() {
        if rdpSettingsWindow == nil {
            createRDPSettingsWindow()
        }
        
        rdpSettingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        print("📱 显示RDP设置窗口")
    }
    
    private func createRDPSettingsWindow() {
        // 创建RDP设置视图控制器
        rdpSettingsViewController = RDPSettingsViewController()
        rdpSettingsViewController?.delegate = self
        
        // 创建RDP设置窗口
        let windowRect = NSRect(x: 0, y: 0, width: 500, height: 450)
        rdpSettingsWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        rdpSettingsWindow?.title = "RDP质量设置"
        rdpSettingsWindow?.center()
        rdpSettingsWindow?.contentViewController = rdpSettingsViewController
        
        // 设置窗口关闭时的行为
        rdpSettingsWindow?.delegate = self
        
        print("✅ RDP设置窗口创建完成")
    }
    
    @objc private func selectRDPQualityPreset(_ sender: NSMenuItem) {
        guard let preset = sender.representedObject as? RDPSettings else { return }
        
        // 更新设置管理器
        rdpSettingsManager.updateSettings(preset)
        
        // 如果设置窗口已打开，更新界面
        rdpSettingsViewController?.applySettings(preset)
        
        // 更新菜单状态
        updateMenuStates()
        
        // 更新状态栏工具提示
        if let button = statusItem?.button {
            button.toolTip = "JMS Protocol Handler - 当前配置: \(preset.profileName)"
        }
        
        // 显示通知
        showNotification(title: "RDP配置已切换", message: "已切换到\(preset.profileName)模式")
        
        print("🔄 切换到RDP配置: \(preset.profileName)")
    }
    
    @objc private func resetToDefaults() {
        do {
            try rdpSettingsManager.resetToDefault()
            
            // 如果设置窗口已打开，刷新界面
            rdpSettingsViewController?.refreshUI()
            
            // 更新菜单状态
            updateMenuStates()
            
            // 更新状态栏工具提示
            if let button = statusItem?.button {
                button.toolTip = "JMS Protocol Handler - 当前配置: \(rdpSettingsManager.currentSettings.profileName)"
            }
            
            showNotification(title: "设置已重置", message: "所有RDP配置已重置为默认值")
            
            print("🔄 RDP设置已重置为默认")
        } catch {
            showAlert("重置失败", message: error.localizedDescription)
        }
    }
    
    @objc private func showHelp() {
        let alert = NSAlert()
        alert.messageText = "JMS Protocol Handler 帮助"
        alert.informativeText = """
        JMS Protocol Handler v1.2.0
        
        功能说明:
        • 处理 jms:// 协议链接
        • 支持RDP和SSH连接
        • 智能显示器优化
        • 质量配置管理
        
        使用方法:
        1. 点击 jms:// 协议链接自动启动连接
        2. 使用菜单栏 "RDP" → "打开RDP设置..." 配置连接质量
        3. 使用快捷键 Cmd+1/2/3 快速切换质量模式
        
        支持的协议:
        • jms://rdp://user:pass@host:port - RDP远程桌面
        • jms://ssh://user:pass@host:port - SSH终端连接
        
        更多信息请查看应用程序文档。
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "JMS Protocol Handler"
        alert.informativeText = """
        版本: 1.2.0
        
        功能特性:
        • 支持RDP和SSH协议
        • 智能显示器优化
        • 质量配置管理
        • HiDPI/Retina支持
        • 完整的GUI设置界面
        
        当前RDP配置: \(rdpSettingsManager.currentSettings.profileName)
        
        © 2025 JumpServer Team
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    private func updateMenuStates() {
        let currentProfileName = rdpSettingsManager.currentSettings.profileName
        
        // 更新状态栏菜单
        if let menu = statusItem?.menu {
            updateQualityMenuStates(in: menu, currentProfile: currentProfileName)
        }
        
        // 更新主菜单
        if let mainMenu = NSApp.mainMenu {
            updateQualityMenuStates(in: mainMenu, currentProfile: currentProfileName)
        }
    }
    
    private func updateQualityMenuStates(in menu: NSMenu, currentProfile: String) {
        for item in menu.items {
            if let submenu = item.submenu {
                updateQualityMenuStates(in: submenu, currentProfile: currentProfile)
            }
            
            if let preset = item.representedObject as? RDPSettings {
                item.state = (preset.profileName == currentProfile) ? .on : .off
            }
        }
    }
    
    private func showNotification(title: String, message: String) {
        NotificationManager.shared.showInfoNotification(title: title, message: message)
    }
    
    private func showAlert(_ title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    // MARK: - URL事件处理
    
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        logInfo("🎯 handleURLEvent() 被调用")
        logDebug("📅 事件时间: \(Date())")
        logDebug("📋 事件描述: \(event)")
        
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue else {
            logError("❌ 无法从Apple Event中获取URL参数")
            errorHandler.handleJMSError(.invalidURL("无法获取URL参数"))
            return
        }
        
        logInfo("✅ 从Apple Event接收到URL: \(urlString)")
        processJMSURL(urlString)
    }
    
    private func handleCommandLineArguments() {
        let arguments = CommandLine.arguments
        logDebug("🔍 handleCommandLineArguments() 开始执行")
        logDebug("📝 当前命令行参数: \(arguments)")
        
        // 查找URL参数
        var foundJMSURL = false
        for (index, argument) in arguments.enumerated() {
            logDebug("🔍 检查参数[\(index)]: \(argument)")
            if argument.hasPrefix("jms://") {
                logInfo("✅ 发现JMS URL参数: \(argument)")
                foundJMSURL = true
                processJMSURL(argument)
                return
            }
        }
        
        if !foundJMSURL {
            logDebug("❌ 未发现JMS URL参数")
        }
        
        // 如果没有URL参数，显示状态信息
        if arguments.count <= 1 {
            logDebug("📊 参数数量 <= 1，显示状态信息")
            showStatusInfo()
        } else {
            logDebug("📊 参数数量 > 1 但无JMS URL，不显示状态信息")
        }
    }
    
    // MARK: - JMS URL处理
    
    private func processJMSURL(_ urlString: String) {
        LogManager.shared.logURLProcessing(urlString, step: "开始处理")
        
        do {
            // 1. 解析URL
            logInfo("🔍 步骤1: 解析URL...")
            let urlComponents = try urlParser.parseURL(urlString)
            logInfo("✅ URL解析成功: \(urlComponents.scheme)://...")
            
            // 2. 解码payload
            logInfo("🔍 步骤2: 解码payload...")
            let config = try payloadDecoder.decodePayload(urlComponents.encodedPayload)
            logInfo("✅ Payload解码成功，协议类型: \(config.protocolType)")
            
            // 3. 提取连接信息
            logInfo("🔍 步骤3: 提取连接信息...")
            let connectionInfo = try connectionInfoExtractor.extractConnectionInfo(from: config)
            logInfo("✅ 连接信息提取成功")
            
            // 4. 根据协议类型启动相应的连接
            logInfo("🔍 步骤4: 启动连接...")
            switch connectionInfo {
            case .rdp(let rdpInfo):
                logInfo("🖥️ 启动RDP连接...")
                try handleRDPConnection(rdpInfo)
            case .ssh(let sshInfo):
                logInfo("💻 启动SSH连接...")
                try handleSSHConnection(sshInfo)
            }
            
            logInfo("🎉 JMS URL处理完成")
            
        } catch {
            logError("❌ JMS URL处理失败: \(error)")
            // 按需求文档要求：直接处理错误，不显示弹框提示
            errorHandler.handleError(error, context: "处理JMS URL: \(urlString)", showAlert: false)
        }
    }
    
    private func handleRDPConnection(_ connectionInfo: RDPConnectionInfo) throws {
        LogManager.shared.logConnectionStart(type: "RDP", server: connectionInfo.serverAddress, username: connectionInfo.username)
        
        do {
            // 使用当前质量配置启动RDP连接
            try rdpIntegrator.launchRDPConnection(connectionInfo)
            LogManager.shared.logConnectionSuccess(type: "RDP")
        } catch {
            LogManager.shared.logConnectionFailure(type: "RDP", error: error.localizedDescription)
            throw error
        }
        
        // 按需求文档要求：直接处理，不显示弹框提示
    }
    
    private func handleSSHConnection(_ connectionInfo: SSHConnectionInfo) throws {
        LogManager.shared.logConnectionStart(type: "SSH", server: "\(connectionInfo.ip):\(connectionInfo.port)", username: connectionInfo.username)
        
        do {
            // 启动SSH连接
            try sshIntegrator.launchSSHConnection(connectionInfo)
            LogManager.shared.logConnectionSuccess(type: "SSH")
        } catch {
            LogManager.shared.logConnectionFailure(type: "SSH", error: error.localizedDescription)
            throw error
        }
        
        // 按需求文档要求：直接处理，不显示弹框提示
    }
    
    // MARK: - 状态信息
    
    private func showStatusInfo() {
        let currentSettings = rdpSettingsManager.currentSettings
        
        print("""
        JMS Protocol Handler v1.2.0 已启动
        
        状态: 等待 jms:// 协议链接
        当前RDP配置: \(currentSettings.profileName)
        
        使用方法:
        1. 点击 jms:// 协议链接自动启动
        2. 使用菜单栏图标访问设置
        3. 命令行: open "jms://encoded_payload"
        4. 快捷键: Cmd+, 打开RDP设置
        
        应用程序已在后台运行，可通过菜单栏 "JMS" 图标访问功能。
        """)
    }
}

// MARK: - RDPSettingsViewControllerDelegate

extension AppDelegate: RDPSettingsViewControllerDelegate {
    
    func settingsDidChange(_ settings: RDPSettings) {
        print("🔄 RDP设置已更改: \(settings.profileName)")
        
        // 更新菜单状态
        updateMenuStates()
        
        // 更新状态栏工具提示
        if let button = statusItem?.button {
            button.toolTip = "JMS Protocol Handler - 当前配置: \(settings.profileName)"
        }
    }
    
    func settingsDidSave(_ settings: RDPSettings) {
        print("💾 RDP设置已保存: \(settings.profileName)")
        
        showNotification(
            title: "设置已保存",
            message: "RDP配置 \(settings.profileName) 已保存到本地"
        )
        
        // 更新菜单状态
        updateMenuStates()
    }
    
    func settingsDidReset() {
        print("🔄 RDP设置已重置")
        
        showNotification(
            title: "设置已重置",
            message: "RDP配置已重置为默认值"
        )
        
        // 更新菜单状态
        updateMenuStates()
        
        // 更新状态栏工具提示
        if let button = statusItem?.button {
            button.toolTip = "JMS Protocol Handler - 当前配置: \(rdpSettingsManager.currentSettings.profileName)"
        }
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == rdpSettingsWindow {
            print("📱 RDP设置窗口即将关闭")
        }
    }
}
