//
//  RemoteDesktopIntegratorQualityTests.swift
//  JMSProtocolHandlerTests
//
//  Created by JMS Protocol Handler on 2025-08-11.
//

import XCTest
@testable import JMSProtocolHandler

class RemoteDesktopIntegratorQualityTests: XCTestCase {
    
    var integrator: RemoteDesktopIntegrator!
    var configManager: RDPQualityConfigManager!
    
    override func setUp() {
        super.setUp()
        integrator = RemoteDesktopIntegrator()
        configManager = RDPQualityConfigManager.shared
        
        // 重置到默认配置
        configManager.resetToDefaultConfiguration()
    }
    
    override func tearDown() {
        integrator = nil
        configManager = nil
        super.tearDown()
    }
    
    // MARK: - Quality Configuration Integration Tests
    
    func testQualityConfigurationIntegration() {
        // 设置不同的质量配置
        configManager.setQualityProfile(.performance)
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .performance)
        
        configManager.setQualityProfile(.balanced)
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .balanced)
        
        configManager.setQualityProfile(.quality)
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .quality)
    }
    
    func testSwitchQualityProfile() {
        // 测试快速切换质量配置
        integrator.switchQualityProfile(.performance)
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .performance)
        
        integrator.switchQualityProfile(.quality)
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .quality)
    }
    
    func testGetCurrentQualityAnalysis() {
        // 测试获取当前质量分析
        configManager.setQualityProfile(.performance)
        let performanceAnalysis = integrator.getCurrentQualityAnalysis()
        XCTAssertEqual(performanceAnalysis.performanceLevel, .low)
        
        configManager.setQualityProfile(.quality)
        let qualityAnalysis = integrator.getCurrentQualityAnalysis()
        XCTAssertEqual(qualityAnalysis.performanceLevel, .high)
    }
    
    func testRecommendQualityProfile() {
        // 测试网络条件推荐
        let modemRecommendation = integrator.recommendQualityProfile(for: .modem)
        XCTAssertEqual(modemRecommendation, .performance)
        
        let lanRecommendation = integrator.recommendQualityProfile(for: .lan)
        XCTAssertEqual(lanRecommendation, .quality)
        
        let broadbandRecommendation = integrator.recommendQualityProfile(for: .broadband)
        XCTAssertEqual(broadbandRecommendation, .balanced)
    }
    
    func testCreateRDPFileWithQuality() {
        // 创建测试连接信息
        let connectionInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser"
        )
        
        let qualitySettings = RDPQualitySettings.performanceOptimized
        
        // 测试创建包含质量配置的RDP文件
        XCTAssertNoThrow(try integrator.createRDPFileWithQuality(
            connectionInfo: connectionInfo,
            qualitySettings: qualitySettings
        ))
    }
    
    func testQualityProfileNotification() {
        // 测试质量配置变更通知
        let expectation = XCTestExpectation(description: "Quality profile change notification")
        
        let observer = NotificationCenter.default.addObserver(
            forName: Notification.Name("RDPQualityProfileChanged"),
            object: integrator,
            queue: .main
        ) { notification in
            if let profile = notification.userInfo?["profile"] as? DisplayQualityProfile {
                XCTAssertEqual(profile, .performance)
                expectation.fulfill()
            }
        }
        
        integrator.switchQualityProfile(.performance)
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - RDP File Creation with Quality Tests
    
    func testRDPFileCreationWithDifferentQualityProfiles() {
        let connectionInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser"
        )
        
        // 测试不同质量配置文件的RDP文件创建
        let profiles: [DisplayQualityProfile] = [.performance, .balanced, .quality]
        
        for profile in profiles {
            configManager.setQualityProfile(profile)
            
            XCTAssertNoThrow(try integrator.createTemporaryRDPFile(with: connectionInfo))
        }
    }
    
    func testCustomQualityConfiguration() {
        // 创建自定义质量配置
        let customSettings = RDPQualitySettings(
            compressionLevel: 1,
            colorDepth: 24,
            enableFontSmoothing: true,
            enableWallpaper: false,
            enableMenuAnimations: true,
            enableThemes: true,
            enableFullWindowDrag: false,
            bitmapCaching: true,
            audioQuality: .medium,
            networkOptimization: .broadband,
            estimatedBandwidth: "2 Mbps",
            performanceImpact: .medium,
            qualityLevel: .standard
        )
        
        let customConfig = RDPCustomConfiguration(
            name: "测试自定义配置",
            settings: customSettings
        )
        
        configManager.saveCustomConfiguration(customConfig)
        configManager.setQualityProfile(.custom)
        
        let connectionInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser"
        )
        
        // 测试使用自定义配置创建RDP文件
        XCTAssertNoThrow(try integrator.createRDPFileWithQuality(
            connectionInfo: connectionInfo,
            qualitySettings: customSettings
        ))
    }
    
    // MARK: - Performance Tests
    
    func testQualityConfigurationPerformance() {
        let connectionInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser"
        )
        
        measure {
            for profile in [DisplayQualityProfile.performance, .balanced, .quality] {
                configManager.setQualityProfile(profile)
                _ = try? integrator.createTemporaryRDPFile(with: connectionInfo)
            }
        }
    }
    
    func testQualityAnalysisPerformance() {
        measure {
            for _ in 0..<100 {
                _ = integrator.getCurrentQualityAnalysis()
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidConnectionInfoWithQuality() {
        let invalidConnectionInfo = RDPConnectionInfo(
            fullAddress: "", // 无效地址
            username: ""     // 无效用户名
        )
        
        let qualitySettings = RDPQualitySettings.balanced
        
        // 应该抛出错误
        XCTAssertThrowsError(try integrator.createRDPFileWithQuality(
            connectionInfo: invalidConnectionInfo,
            qualitySettings: qualitySettings
        ))
    }
    
    // MARK: - Integration Tests
    
    func testFullQualityIntegrationWorkflow() {
        // 完整的质量配置集成工作流程测试
        
        // 1. 设置质量配置
        integrator.switchQualityProfile(.performance)
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .performance)
        
        // 2. 获取性能分析
        let analysis = integrator.getCurrentQualityAnalysis()
        XCTAssertEqual(analysis.performanceLevel, .low)
        
        // 3. 创建连接信息
        let connectionInfo = RDPConnectionInfo(
            fullAddress: "test.example.com:3389",
            username: "testuser"
        )
        
        // 4. 创建RDP文件
        XCTAssertNoThrow(try integrator.createTemporaryRDPFile(with: connectionInfo))
        
        // 5. 切换到质量优先配置
        integrator.switchQualityProfile(.quality)
        XCTAssertEqual(configManager.getCurrentQualityProfile(), .quality)
        
        // 6. 验证分析结果变化
        let newAnalysis = integrator.getCurrentQualityAnalysis()
        XCTAssertEqual(newAnalysis.performanceLevel, .high)
        
        // 7. 再次创建RDP文件验证配置应用
        XCTAssertNoThrow(try integrator.createTemporaryRDPFile(with: connectionInfo))
    }
}
