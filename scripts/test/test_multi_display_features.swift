#!/usr/bin/env swift

import Foundation
import CoreGraphics

// 测试多显示器和自定义缩放因子功能
func testMultiDisplayFeatures() {
    print("🧪 开始多显示器和自定义缩放因子功能测试...")
    
    // 测试1: 多显示器检测
    print("\n📱 测试1: 多显示器检测")
    testMultiDisplayDetection()
    
    // 测试2: 显示器类型识别
    print("\n🔍 测试2: 显示器类型识别")
    testDisplayTypeDetection()
    
    // 测试3: 自定义缩放因子验证
    print("\n📐 测试3: 自定义缩放因子验证")
    testCustomScaleFactorValidation()
    
    // 测试4: 智能推荐算法
    print("\n🎯 测试4: 智能推荐算法")
    testSmartRecommendations()
    
    print("\n✅ 多显示器和自定义缩放因子功能测试完成")
}

func testMultiDisplayDetection() {
    // 获取所有显示器
    let maxDisplays: UInt32 = 32
    var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
    var displayCount: UInt32 = 0
    
    let result = CGGetActiveDisplayList(maxDisplays, &displayIDs, &displayCount)
    
    if result == .success {
        print("✅ 检测到 \(displayCount) 个显示器")
        
        for i in 0..<Int(displayCount) {
            let displayID = displayIDs[i]
            let bounds = CGDisplayBounds(displayID)
            let isMain = displayID == CGMainDisplayID()
            
            print("   显示器\(i + 1): \(Int(bounds.width))×\(Int(bounds.height))\(isMain ? " (主显示器)" : "")")
        }
    } else {
        print("❌ 显示器检测失败: \(result)")
    }
}

func testDisplayTypeDetection() {
    let mainDisplayID = CGMainDisplayID()
    let bounds = CGDisplayBounds(mainDisplayID)
    let width = Int(bounds.width)
    let height = Int(bounds.height)
    
    // 模拟显示器类型检测逻辑
    let aspectRatio = Double(width) / Double(height)
    let isMain = true
    
    var displayType: String
    
    if aspectRatio >= 2.0 {
        displayType = "超宽显示器"
    } else if isMain && width >= 2560 {
        displayType = "内置Retina显示器"
    } else if width >= 3840 && height >= 2160 {
        displayType = "外接4K显示器"
    } else if width >= 1920 && height >= 1080 {
        displayType = "外接HD显示器"
    } else {
        displayType = "未知类型"
    }
    
    print("✅ 主显示器类型: \(displayType)")
    print("   分辨率: \(width)×\(height)")
    print("   宽高比: \(String(format: "%.2f", aspectRatio))")
}

func testCustomScaleFactorValidation() {
    let testValues: [Double] = [0.25, 0.50, 1.00, 1.25, 1.50, 2.00, 2.33, 3.00, 5.00, 6.00]
    
    for value in testValues {
        let isValid = value >= 0.50 && value <= 5.00
        let clampedValue = max(0.50, min(5.00, value))
        let roundedValue = round(value * 100) / 100 // 保留两位小数
        
        let status = isValid ? "✅" : "❌"
        print("\(status) 缩放因子 \(value): 有效=\(isValid), 限制后=\(clampedValue), 精度=\(roundedValue)")
    }
}

func testSmartRecommendations() {
    // 模拟不同DPI的推荐算法
    let testCases: [(dpi: Double, expected: Double, description: String)] = [
        (96.0, 1.0, "标准DPI"),
        (120.0, 1.25, "中等DPI"),
        (150.0, 1.5, "高DPI"),
        (200.0, 2.0, "超高DPI"),
        (250.0, 2.5, "Retina级别"),
        (300.0, 3.0, "超Retina级别")
    ]
    
    for testCase in testCases {
        let recommended = getRecommendedScaleFactor(for: testCase.dpi)
        let matches = abs(recommended - testCase.expected) < 0.1
        let status = matches ? "✅" : "❌"
        
        print("\(status) DPI \(testCase.dpi) (\(testCase.description)): 推荐=\(recommended), 期望=\(testCase.expected)")
    }
}

func getRecommendedScaleFactor(for dpi: Double) -> Double {
    switch dpi {
    case ..<120:
        return 1.0
    case 120..<150:
        return 1.25
    case 150..<200:
        return 1.5
    case 200..<250:
        return 2.0
    case 250..<300:
        return 2.5
    default:
        return 3.0
    }
}

// 运行测试
testMultiDisplayFeatures()
