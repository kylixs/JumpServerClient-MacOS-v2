#!/usr/bin/env swift

import Foundation
import CoreGraphics

// 简化的显示器检测测试
func testDisplayDetection() {
    print("🔍 开始显示器检测测试...")
    
    // 获取主显示器ID
    let mainDisplayID = CGMainDisplayID()
    print("📱 主显示器ID: \(mainDisplayID)")
    
    // 方法1: 获取逻辑分辨率 (系统返回的缩放后分辨率)
    let logicalBounds = CGDisplayBounds(mainDisplayID)
    let logicalWidth = Int(logicalBounds.width)
    let logicalHeight = Int(logicalBounds.height)
    print("📏 逻辑分辨率: \(logicalWidth) × \(logicalHeight)")
    
    // 方法2: 获取当前显示模式
    if let currentMode = CGDisplayCopyDisplayMode(mainDisplayID) {
        let currentWidth = Int(currentMode.width)
        let currentHeight = Int(currentMode.height)
        let refreshRate = currentMode.refreshRate
        print("🖥️ 当前模式: \(currentWidth) × \(currentHeight) @ \(refreshRate)Hz")
    }
    
    // 方法3: 获取所有可用模式，找到最高分辨率 (通常是物理分辨率)
    if let modes = CGDisplayCopyAllDisplayModes(mainDisplayID, nil) {
        let modeCount = CFArrayGetCount(modes)
        var maxWidth = 0
        var maxHeight = 0
        var nativeRefreshRate = 0.0
        
        print("📋 可用显示模式:")
        for i in 0..<modeCount {
            if let mode = CFArrayGetValueAtIndex(modes, i) {
                let displayMode = Unmanaged<CGDisplayMode>.fromOpaque(mode).takeUnretainedValue()
                let width = Int(displayMode.width)
                let height = Int(displayMode.height)
                let refresh = displayMode.refreshRate
                
                print("   - \(width) × \(height) @ \(refresh)Hz")
                
                // 找到最高分辨率
                if width * height > maxWidth * maxHeight {
                    maxWidth = width
                    maxHeight = height
                    nativeRefreshRate = refresh
                }
            }
        }
        
        print("🎯 最高分辨率 (可能的物理分辨率): \(maxWidth) × \(maxHeight) @ \(nativeRefreshRate)Hz")
        
        // 计算缩放因子
        if logicalWidth > 0 && logicalHeight > 0 {
            let scaleX = Double(maxWidth) / Double(logicalWidth)
            let scaleY = Double(maxHeight) / Double(logicalHeight)
            let scaleFactor = max(scaleX, scaleY)
            
            print("📐 计算的缩放因子: \(String(format: "%.2f", scaleFactor))")
            print("🔍 HiDPI检测: \(scaleFactor > 1.5 ? "是" : "否")")
        }
    }
    
    // 方法4: 获取物理尺寸和DPI
    let physicalSize = CGDisplayScreenSize(mainDisplayID)
    if physicalSize.width > 0 && physicalSize.height > 0 {
        let dpiX = Double(logicalWidth) / (physicalSize.width / 25.4)
        let dpiY = Double(logicalHeight) / (physicalSize.height / 25.4)
        let averageDPI = (dpiX + dpiY) / 2.0
        
        print("📏 物理尺寸: \(String(format: "%.1f", physicalSize.width))mm × \(String(format: "%.1f", physicalSize.height))mm")
        print("🎯 DPI: \(String(format: "%.1f", averageDPI)) (X: \(String(format: "%.1f", dpiX)), Y: \(String(format: "%.1f", dpiY)))")
        print("🔍 HiDPI (DPI > 150): \(averageDPI > 150 ? "是" : "否")")
    }
    
    print("✅ 显示器检测测试完成")
}

// 运行测试
testDisplayDetection()
