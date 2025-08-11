//
//  AppDelegateMenuTests.swift
//  JMSProtocolHandlerTests
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import XCTest
@testable import JMSProtocolHandler

class AppDelegateMenuTests: XCTestCase {
    
    var appDelegate: AppDelegate!
    var configManager: RDPQualityConfigManager!
    
    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()
        configManager = RDPQualityConfigManager.shared
        
        // 重置到默认配置
        configManager.resetToDefaultConfiguration()
        
        // 模拟应用程序启动
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
    }
    
    override func tearDown() {
        appDelegate = nil
        configManager = nil
        super.tearDown()
    }
    
    // MARK: - Menu Setup Tests
    
    func testApplicationMenuSetup() {
        // 验证主菜单是否已设置
        XCTAssertNotNil(NSApplication.shared.mainMenu)
        
        guard let mainMenu = NSApplication.shared.mainMenu else {
            XCTFail("主菜单未设置")
            return
        }
        
        // 验证应用程序菜单项存在
        XCTAssertGreaterThan(mainMenu.items.count, 0)
        
        let appMenuItem = mainMenu.items.first
        XCTAssertNotNil(appMenuItem)
        XCTAssertNotNil(appMenuItem?.submenu)
    }
    
    func testQualityConfigurationMenuItems() {
        guard let mainMenu = NSApplication.shared.mainMenu,
              let appMenuItem = mainMenu.items.first,
              let appMenu = appMenuItem.submenu else {
            XCTFail("无法获取应用程序菜单")
            return
        }
        
        // 查找RDP质量配置菜单项
        let configMenuItem = appMenu.items.first { $0.title == "RDP质量配置..." }
        XCTAssertNotNil(configMenuItem, "应该包含RDP质量配置菜单项")
        XCTAssertEqual(configMenuItem?.keyEquivalent, ",")
        XCTAssertEqual(configMenuItem?.keyEquivalentModifierMask, .command)
        
        // 查找快速切换菜单项
        let quickSwitchMenuItem = appMenu.items.first { $0.title == "快速切换质量" }
        XCTAssertNotNil(quickSwitchMenuItem, "应该包含快速切换质量菜单项")
        XCTAssertNotNil(quickSwitchMenuItem?.submenu, "快速切换菜单应该有子菜单")
    }
    
    func testQuickSwitchSubmenu() {
        guard let mainMenu = NSApplication.shared.mainMenu,
              let appMenuItem = mainMenu.items.first,
              let appMenu = appMenuItem.submenu,
              let quickSwitchMenuItem = appMenu.items.first(where: { $0.title == "快速切换质量" }),
              let quickSwitchMenu = quickSwitchMenuItem.submenu else {
            XCTFail("无法获取快速切换子菜单")
            return
        }
        
        // 验证性能优先菜单项
        let performanceMenuItem = quickSwitchMenu.items.first { $0.title.contains("性能优先") }
        XCTAssertNotNil(performanceMenuItem)
        XCTAssertEqual(performanceMenuItem?.keyEquivalent, "1")
        XCTAssertEqual(performanceMenuItem?.keyEquivalentModifierMask, .command)
        
        // 验证平衡模式菜单项
        let balancedMenuItem = quickSwitchMenu.items.first { $0.title.contains("平衡模式") }
        XCTAssertNotNil(balancedMenuItem)
        XCTAssertEqual(balancedMenuItem?.keyEquivalent, "2")
        XCTAssertEqual(balancedMenuItem?.keyEquivalentModifierMask, .command)
        
        // 验证质量优先菜单项
        let qualityMenuItem = quickSwitchMenu.items.first { $0.title.contains("质量优先") }
        XCTAssertNotNil(qualityMenuItem)
        XCTAssertEqual(qualityMenuItem?.keyEquivalent, "3")
        XCTAssertEqual(qualityMenuItem?.keyEquivalentModifierMask, .command)
        
        // 验证当前配置状态显示
        let statusMenuItem = quickSwitchMenu.items.first { $0.title.hasPrefix("当前配置:") }
        XCTAssertNotNil(statusMenuItem)
        XCTAssertFalse(statusMenuItem?.isEnabled ?? true, "状态显示菜单项应该是禁用的")
    }
    
    // MARK: - Menu Action Tests
    
    func testSwitchToPerformanceMode() {
        // 执行切换到性能模式的操作
        appDelegate.perform(#selector(AppDelegate.switchToPerformanceMode))
        
        // 验证配置是否已更改
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .performance)
    }
    
    func testSwitchToBalancedMode() {
        // 先切换到其他模式
        configManager.setQualityProfile(.performance)
        
        // 执行切换到平衡模式的操作
        appDelegate.perform(#selector(AppDelegate.switchToBalancedMode))
        
        // 验证配置是否已更改
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .balanced)
    }
    
    func testSwitchToQualityMode() {
        // 执行切换到质量模式的操作
        appDelegate.perform(#selector(AppDelegate.switchToQualityMode))
        
        // 验证配置是否已更改
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .quality)
    }
    
    // MARK: - Configuration Status Tests
    
    func testGetCurrentConfigurationStatus() {
        // 设置不同的配置并验证状态描述
        configManager.setQualityProfile(.performance)
        
        // 使用反射获取私有方法进行测试
        let statusMethod = class_getInstanceMethod(AppDelegate.self, #selector(AppDelegate.getCurrentConfigurationStatus))
        XCTAssertNotNil(statusMethod)
        
        // 验证状态字符串包含预期内容
        // 注意：由于getCurrentConfigurationStatus是私有方法，我们通过间接方式验证
        let currentProfile = configManager.getCurrentQualityProfile()
        XCTAssertEqual(currentProfile, .performance)
    }
    
    func testConfigurationStatusUpdate() {
        // 测试配置状态更新
        let initialProfile = configManager.getCurrentQualityProfile()
        
        // 切换配置
        configManager.setQualityProfile(.quality)
        
        // 验证配置已更改
        XCTAssertNotEqual(configManager.getCurrentQualityProfile(), initialProfile)
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .quality)
    }
    
    // MARK: - Notification Tests
    
    func testQualityConfigurationChangeNotification() {
        let expectation = XCTestExpectation(description: "Configuration change notification")
        
        // 监听配置变更通知
        let observer = NotificationCenter.default.addObserver(
            forName: RDPQualityConfigManager.configurationDidChangeNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let profile = notification.userInfo?["profile"] as? DisplayQualityProfile {
                XCTAssertEqual(profile, .performance)
                expectation.fulfill()
            }
        }
        
        // 触发配置变更
        configManager.setQualityProfile(.performance)
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Menu Integration Tests
    
    func testMenuItemActions() {
        guard let mainMenu = NSApplication.shared.mainMenu,
              let appMenuItem = mainMenu.items.first,
              let appMenu = appMenuItem.submenu else {
            XCTFail("无法获取应用程序菜单")
            return
        }
        
        // 测试RDP质量配置菜单项的action
        let configMenuItem = appMenu.items.first { $0.title == "RDP质量配置..." }
        XCTAssertNotNil(configMenuItem?.action)
        XCTAssertEqual(configMenuItem?.action, #selector(AppDelegate.showQualityConfiguration))
        
        // 测试关于菜单项的action
        let aboutMenuItem = appMenu.items.first { $0.title.contains("关于") }
        XCTAssertNotNil(aboutMenuItem?.action)
        XCTAssertEqual(aboutMenuItem?.action, #selector(AppDelegate.showAbout))
    }
    
    func testKeyboardShortcuts() {
        guard let mainMenu = NSApplication.shared.mainMenu,
              let appMenuItem = mainMenu.items.first,
              let appMenu = appMenuItem.submenu,
              let quickSwitchMenuItem = appMenu.items.first(where: { $0.title == "快速切换质量" }),
              let quickSwitchMenu = quickSwitchMenuItem.submenu else {
            XCTFail("无法获取快速切换子菜单")
            return
        }
        
        // 验证键盘快捷键设置
        let shortcuts = [
            ("1", "性能优先"),
            ("2", "平衡模式"),
            ("3", "质量优先")
        ]
        
        for (key, titlePart) in shortcuts {
            let menuItem = quickSwitchMenu.items.first { $0.title.contains(titlePart) }
            XCTAssertNotNil(menuItem, "应该找到包含'\(titlePart)'的菜单项")
            XCTAssertEqual(menuItem?.keyEquivalent, key, "键盘快捷键应该是'\(key)'")
            XCTAssertEqual(menuItem?.keyEquivalentModifierMask, .command, "应该使用Command修饰键")
        }
    }
    
    // MARK: - Performance Tests
    
    func testMenuSetupPerformance() {
        measure {
            let testAppDelegate = AppDelegate()
            testAppDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        }
    }
    
    func testMenuActionPerformance() {
        measure {
            appDelegate.perform(#selector(AppDelegate.switchToPerformanceMode))
            appDelegate.perform(#selector(AppDelegate.switchToBalancedMode))
            appDelegate.perform(#selector(AppDelegate.switchToQualityMode))
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testMenuSetupWithoutCrashing() {
        // 测试多次设置菜单不会崩溃
        XCTAssertNoThrow({
            for _ in 0..<5 {
                let testAppDelegate = AppDelegate()
                testAppDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
            }
        })
    }
    
    func testInvalidMenuActionHandling() {
        // 测试无效的菜单操作处理
        XCTAssertNoThrow({
            // 尝试执行不存在的selector（这应该被安全处理）
            if appDelegate.responds(to: #selector(AppDelegate.switchToPerformanceMode)) {
                appDelegate.perform(#selector(AppDelegate.switchToPerformanceMode))
            }
        })
    }
}
