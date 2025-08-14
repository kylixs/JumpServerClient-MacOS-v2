import XCTest
@testable import JMSCore
@testable import JMSRDPModule

/// RDP参数验证测试
/// 验证RDP连接使用正确的HiDPI、分辨率等参数
class RDPParameterValidationTest: XCTestCase {
    
    var rdpConfigManager: RDPConfigManager!
    var rdpSettingsManager: RDPSettingsManager!
    var displayDetector: DisplayDetector!
    
    override func setUp() {
        super.setUp()
        rdpConfigManager = RDPConfigManager(forTesting: true)
        rdpSettingsManager = RDPSettingsManager()
        displayDetector = DisplayDetector()
    }
    
    override func tearDown() {
        rdpConfigManager = nil
        rdpSettingsManager = nil
        displayDetector = nil
        super.tearDown()
    }
    
    // MARK: - HiDPI参数验证测试
    
    func testHiDPIParameterApplication() {
        print("🧪 测试HiDPI参数正确应用")
        
        // 创建HiDPI配置
        let hiDPISettings = RDPSettings(
            profileName: "HiDPI测试配置",
            resolution: ResolutionSettings(width: 2560, height: 1600),
            hiDPI: HiDPISettings(enabled: true, scaleFactor: 2.0),
            colorDepth: 32,
            compressionLevel: 0,
            enableFontSmoothing: true
        )
        
        // 应用配置
        let qualityProfile = RDPConfigManager.convertToQualityProfile(hiDPISettings)
        rdpConfigManager.setQualityProfile(qualityProfile)
        
        // 创建测试连接信息
        let connectionInfo = RDPConnectionInfo(
            serverAddress: "hidpi.test.com:3389",
            username: "hidpiuser",
            additionalConfig: nil
        )
        
        // 生成RDP配置
        do {
            let configContent = try rdpConfigManager.generateOptimizedConfig(for: connectionInfo)
            
            // 验证HiDPI相关参数
            XCTAssertTrue(configContent.contains("desktopwidth:i:2560"), "应该包含正确的HiDPI分辨率宽度")
            XCTAssertTrue(configContent.contains("desktopheight:i:1600"), "应该包含正确的HiDPI分辨率高度")
            XCTAssertTrue(configContent.contains("session bpp:i:32"), "HiDPI应该使用32位颜色深度")
            XCTAssertTrue(configContent.contains("font smoothing:i:1"), "HiDPI应该启用字体平滑")
            XCTAssertTrue(configContent.contains("compression:i:0"), "HiDPI应该使用最低压缩以保证质量")
            
            // 检查是否包含HiDPI特定的缩放参数
            if configContent.contains("desktopscalefactor") {
                XCTAssertTrue(configContent.contains("desktopscalefactor:i:200"), "应该包含正确的缩放因子(200%)")
            }
            
            print("✅ HiDPI参数验证通过")
            print("📊 生成的HiDPI配置:")
            print(configContent)
            
        } catch {
            XCTFail("HiDPI配置生成失败: \(error)")
        }
    }
    
    func testNonHiDPIParameterApplication() {
        print("🧪 测试非HiDPI参数正确应用")
        
        // 创建标准分辨率配置
        let standardSettings = RDPSettings(
            profileName: "标准分辨率配置",
            resolution: ResolutionSettings(width: 1920, height: 1080),
            hiDPI: HiDPISettings(enabled: false, scaleFactor: 1.0),
            colorDepth: 24,
            compressionLevel: 1,
            enableFontSmoothing: false
        )
        
        // 应用配置
        let qualityProfile = RDPConfigManager.convertToQualityProfile(standardSettings)
        rdpConfigManager.setQualityProfile(qualityProfile)
        
        // 创建测试连接信息
        let connectionInfo = RDPConnectionInfo(
            serverAddress: "standard.test.com:3389",
            username: "standarduser",
            additionalConfig: nil
        )
        
        // 生成RDP配置
        do {
            let configContent = try rdpConfigManager.generateOptimizedConfig(for: connectionInfo)
            
            // 验证标准分辨率参数
            XCTAssertTrue(configContent.contains("desktopwidth:i:1920"), "应该包含正确的标准分辨率宽度")
            XCTAssertTrue(configContent.contains("desktopheight:i:1080"), "应该包含正确的标准分辨率高度")
            XCTAssertTrue(configContent.contains("session bpp:i:24"), "标准配置应该使用24位颜色深度")
            XCTAssertTrue(configContent.contains("font smoothing:i:0"), "标准配置应该禁用字体平滑")
            XCTAssertTrue(configContent.contains("compression:i:1"), "标准配置应该使用中等压缩")
            
            print("✅ 标准分辨率参数验证通过")
            print("📊 生成的标准配置:")
            print(configContent)
            
        } catch {
            XCTFail("标准配置生成失败: \(error)")
        }
    }
    
    // MARK: - 分辨率参数验证测试
    
    func testCustomResolutionApplication() {
        print("🧪 测试自定义分辨率参数应用")
        
        let customResolutions = [
            (width: 1366, height: 768),   // 常见笔记本分辨率
            (width: 2560, height: 1440),  // 2K分辨率
            (width: 3840, height: 2160),  // 4K分辨率
            (width: 3440, height: 1440),  // 超宽屏分辨率
        ]
        
        for (width, height) in customResolutions {
            print("📝 测试分辨率: \(width)×\(height)")
            
            let customSettings = RDPSettings(
                profileName: "自定义分辨率\(width)×\(height)",
                resolution: ResolutionSettings(width: width, height: height),
                hiDPI: HiDPISettings(enabled: width >= 2560, scaleFactor: width >= 2560 ? 2.0 : 1.0),
                colorDepth: 32,
                compressionLevel: width >= 3840 ? 0 : 1  // 4K使用无压缩
            )
            
            let qualityProfile = RDPConfigManager.convertToQualityProfile(customSettings)
            rdpConfigManager.setQualityProfile(qualityProfile)
            
            let connectionInfo = RDPConnectionInfo(
                serverAddress: "resolution.test.com:3389",
                username: "resolutionuser",
                additionalConfig: nil
            )
            
            do {
                let configContent = try rdpConfigManager.generateOptimizedConfig(for: connectionInfo)
                
                // 验证分辨率参数
                XCTAssertTrue(configContent.contains("desktopwidth:i:\(width)"), "应该包含正确的宽度: \(width)")
                XCTAssertTrue(configContent.contains("desktopheight:i:\(height)"), "应该包含正确的高度: \(height)")
                
                // 验证基于分辨率的优化参数
                if width >= 3840 {
                    XCTAssertTrue(configContent.contains("compression:i:0"), "4K分辨率应该使用无压缩")
                }
                
                print("✅ 分辨率 \(width)×\(height) 参数验证通过")
                
            } catch {
                XCTFail("分辨率 \(width)×\(height) 配置生成失败: \(error)")
            }
        }
    }
    
    // MARK: - 质量配置参数验证测试
    
    func testQualityProfileParameterApplication() {
        print("🧪 测试质量配置参数应用")
        
        let qualityProfiles: [(QualityProfile, String)] = [
            (.performance, "性能优先"),
            (.balanced, "平衡模式"),
            (.quality, "质量优先")
        ]
        
        let connectionInfo = RDPConnectionInfo(
            serverAddress: "quality.test.com:3389",
            username: "qualityuser",
            additionalConfig: nil
        )
        
        for (profile, profileName) in qualityProfiles {
            print("📝 测试质量配置: \(profileName)")
            
            rdpConfigManager.setQualityProfile(profile)
            
            do {
                let configContent = try rdpConfigManager.generateOptimizedConfig(for: connectionInfo)
                let settings = rdpConfigManager.currentSettings
                
                // 验证质量配置参数
                XCTAssertTrue(configContent.contains("compression:i:\(settings.compressionLevel)"), 
                             "应该包含正确的压缩级别: \(settings.compressionLevel)")
                XCTAssertTrue(configContent.contains("session bpp:i:\(settings.colorDepth)"), 
                             "应该包含正确的颜色深度: \(settings.colorDepth)")
                
                // 验证特定质量配置的参数
                switch profile {
                case .performance:
                    XCTAssertEqual(settings.compressionLevel, 2, "性能优先应该使用最高压缩")
                    XCTAssertEqual(settings.colorDepth, 16, "性能优先应该使用16位颜色")
                case .balanced:
                    XCTAssertEqual(settings.compressionLevel, 1, "平衡模式应该使用中等压缩")
                    XCTAssertEqual(settings.colorDepth, 24, "平衡模式应该使用24位颜色")
                case .quality:
                    XCTAssertEqual(settings.compressionLevel, 0, "质量优先应该使用无压缩")
                    XCTAssertEqual(settings.colorDepth, 32, "质量优先应该使用32位颜色")
                case .custom:
                    break // 自定义配置不在此测试范围
                }
                
                print("✅ 质量配置 \(profileName) 参数验证通过")
                
            } catch {
                XCTFail("质量配置 \(profileName) 生成失败: \(error)")
            }
        }
    }
    
    // MARK: - 显示器优化参数验证测试
    
    func testDisplayOptimizationParameters() {
        print("🧪 测试显示器优化参数")
        
        // 创建测试配置
        let testSettings = RDPSettings(
            profileName: "显示器优化测试",
            resolution: ResolutionSettings(width: 2560, height: 1440),
            hiDPI: HiDPISettings(enabled: true, scaleFactor: 2.0),
            colorDepth: 32,
            compressionLevel: 1,
            enableFontSmoothing: true,
            enableWallpaper: false,
            enableMenuAnimations: false,
            enableThemes: true
        )
        
        let qualityProfile = RDPConfigManager.convertToQualityProfile(testSettings)
        rdpConfigManager.setQualityProfile(qualityProfile)
        
        let connectionInfo = RDPConnectionInfo(
            serverAddress: "display.test.com:3389",
            username: "displayuser",
            additionalConfig: nil
        )
        
        do {
            let configContent = try rdpConfigManager.generateOptimizedConfig(for: connectionInfo)
            
            // 验证显示器优化参数
            XCTAssertTrue(configContent.contains("smart sizing:i:1"), "应该启用智能调整")
            XCTAssertTrue(configContent.contains("screen mode id:i:2"), "应该使用全屏模式")
            XCTAssertTrue(configContent.contains("font smoothing:i:1"), "应该启用字体平滑")
            XCTAssertTrue(configContent.contains("disable wallpaper:i:1"), "应该禁用壁纸")
            XCTAssertTrue(configContent.contains("disable menu anims:i:1"), "应该禁用菜单动画")
            XCTAssertTrue(configContent.contains("disable themes:i:0"), "应该启用主题")
            
            print("✅ 显示器优化参数验证通过")
            print("📊 生成的优化配置:")
            print(configContent)
            
        } catch {
            XCTFail("显示器优化配置生成失败: \(error)")
        }
    }
    
    // MARK: - 音频参数验证测试
    
    func testAudioParameterApplication() {
        print("🧪 测试音频参数应用")
        
        let audioConfigs = [
            ("禁用", 2),
            ("低质量", 1),
            ("中等", 0),
            ("高质量", 0)
        ]
        
        for (audioQuality, expectedMode) in audioConfigs {
            print("📝 测试音频质量: \(audioQuality)")
            
            let audioSettings = RDPSettings(
                profileName: "音频测试配置",
                resolution: ResolutionSettings(width: 1920, height: 1080),
                hiDPI: HiDPISettings(enabled: false, scaleFactor: 1.0),
                colorDepth: 24,
                compressionLevel: 1,
                audioQuality: audioQuality
            )
            
            let qualityProfile = RDPConfigManager.convertToQualityProfile(audioSettings)
            rdpConfigManager.setQualityProfile(qualityProfile)
            
            let connectionInfo = RDPConnectionInfo(
                serverAddress: "audio.test.com:3389",
                username: "audiouser",
                additionalConfig: nil
            )
            
            do {
                let configContent = try rdpConfigManager.generateOptimizedConfig(for: connectionInfo)
                
                // 验证音频参数
                XCTAssertTrue(configContent.contains("audiomode:i:\(expectedMode)"), 
                             "音频质量 \(audioQuality) 应该对应模式 \(expectedMode)")
                
                print("✅ 音频质量 \(audioQuality) 参数验证通过")
                
            } catch {
                XCTFail("音频配置 \(audioQuality) 生成失败: \(error)")
            }
        }
    }
    
    // MARK: - 配置参数完整性验证
    
    func testCompleteConfigurationIntegrity() {
        print("🧪 测试配置参数完整性")
        
        // 创建包含所有参数的完整配置
        let completeSettings = RDPSettings(
            profileName: "完整配置测试",
            resolution: ResolutionSettings(width: 3024, height: 1964, isCustom: true),
            hiDPI: HiDPISettings(enabled: true, scaleFactor: 2.0),
            colorDepth: 32,
            compressionLevel: 0,
            audioQuality: "高质量",
            enableFontSmoothing: true,
            enableWallpaper: true,
            enableMenuAnimations: true,
            enableThemes: true
        )
        
        let qualityProfile = RDPConfigManager.convertToQualityProfile(completeSettings)
        rdpConfigManager.setQualityProfile(qualityProfile)
        
        let connectionInfo = RDPConnectionInfo(
            serverAddress: "complete.test.com:3389",
            username: "completeuser",
            additionalConfig: "session bpp:i:32\naudiomode:i:0"
        )
        
        do {
            let configContent = try rdpConfigManager.generateOptimizedConfig(for: connectionInfo)
            
            // 验证所有必需的参数都存在
            let requiredParameters = [
                "full address:s:complete.test.com:3389",
                "username:s:completeuser",
                "desktopwidth:i:3024",
                "desktopheight:i:1964",
                "session bpp:i:32",
                "compression:i:0",
                "font smoothing:i:1",
                "audiomode:i:0",
                "smart sizing:i:1",
                "screen mode id:i:2",
                "disable wallpaper:i:0",
                "disable menu anims:i:0",
                "disable themes:i:0"
            ]
            
            for parameter in requiredParameters {
                XCTAssertTrue(configContent.contains(parameter), "配置应该包含参数: \(parameter)")
            }
            
            print("✅ 配置参数完整性验证通过")
            print("📊 完整配置内容:")
            print(configContent)
            
        } catch {
            XCTFail("完整配置生成失败: \(error)")
        }
    }
}
