//
//  InterfaceDefinitionManager.swift
//  JMSProtocolHandler
//
//  Created by JMS Protocol Handler on 2025-08-12.
//

import Foundation

/// 界面定义管理器 - 负责管理所有界面的定义和配置
class InterfaceDefinitionManager {
    
    // MARK: - Singleton
    
    static let shared = InterfaceDefinitionManager()
    
    private init() {}
    
    // MARK: - Interface Definitions
    
    /// 获取所有界面定义
    func getAllInterfaceDefinitions() -> [GlobalGUIChecker.InterfaceDefinition] {
        return [
            createRDPQualityConfigDefinition(),
            createMainMenuDefinition(),
            createAboutDialogDefinition(),
            createErrorDialogDefinition(),
            createNotificationDefinition()
        ]
    }
    
    /// 根据标识符获取界面定义
    func getInterfaceDefinition(by identifier: String) -> GlobalGUIChecker.InterfaceDefinition? {
        return getAllInterfaceDefinitions().first { $0.identifier == identifier }
    }
    
    // MARK: - Private Interface Definitions
    
    /// RDP质量配置界面定义
    private func createRDPQualityConfigDefinition() -> GlobalGUIChecker.InterfaceDefinition {
        let expectedComponents: [GlobalGUIChecker.InterfaceDefinition.ExpectedComponent] = [
            // 标题标签
            GlobalGUIChecker.InterfaceDefinition.ExpectedComponent(
                type: "NSTextField",
                identifier: "title_label",
                isRequired: true,
                expectedContent: GlobalGUIChecker.InterfaceDefinition.ExpectedComponent.ExpectedContent(
                    text: "RDP质量配置",
                    title: nil,
                    placeholder: nil,
                    options: nil,
                    valueRange: nil
                ),
                expectedState: GlobalGUIChecker.InterfaceDefinition.ExpectedComponent.ExpectedState(
                    isEnabled: true,
                    isVisible: true,
                    selectedIndex: nil,
                    checkState: nil
                )
            ),
            
            // 预设配置分段控件
            GlobalGUIChecker.InterfaceDefinition.ExpectedComponent(
                type: "NSSegmentedControl",
                identifier: "preset_selector",
                isRequired: true,
                expectedContent: nil,
                expectedState: GlobalGUIChecker.InterfaceDefinition.ExpectedComponent.ExpectedState(
                    isEnabled: true,
                    isVisible: true,
                    selectedIndex: 1, // 默认选中平衡模式
                    checkState: nil
                )
            ),
            
            // 压缩级别滑块
            GlobalGUIChecker.InterfaceDefinition.ExpectedComponent(
                type: "NSSlider",
                identifier: "compression_slider",
                isRequired: true,
                expectedContent: GlobalGUIChecker.InterfaceDefinition.ExpectedComponent.ExpectedContent(
                    text: nil,
                    title: nil,
                    placeholder: nil,
                    options: nil,
                    valueRange: (min: 0.0, max: 2.0)
                ),
                expectedState: GlobalGUIChecker.InterfaceDefinition.ExpectedComponent.ExpectedState(
                    isEnabled: true,
                    isVisible: true,
                    selectedIndex: nil,
                    checkState: nil
                )
            ),
            
            // 下拉框组件
            GlobalGUIChecker.InterfaceDefinition.ExpectedComponent(
                type: "NSPopUpButton",
                identifier: "popup_buttons",
                isRequired: true,
                expectedContent: nil,
                expectedState: GlobalGUIChecker.InterfaceDefinition.ExpectedComponent.ExpectedState(
                    isEnabled: true,
                    isVisible: true,
                    selectedIndex: nil,
                    checkState: nil
                )
            ),
            
            // 复选框组件
            GlobalGUIChecker.InterfaceDefinition.ExpectedComponent(
                type: "NSButton",
                identifier: "checkboxes",
                isRequired: true,
                expectedContent: nil,
                expectedState: GlobalGUIChecker.InterfaceDefinition.ExpectedComponent.ExpectedState(
                    isEnabled: true,
                    isVisible: true,
                    selectedIndex: nil,
                    checkState: nil
                )
            ),
            
            // 操作按钮
            GlobalGUIChecker.InterfaceDefinition.ExpectedComponent(
                type: "NSButton",
                identifier: "action_buttons",
                isRequired: true,
                expectedContent: nil,
                expectedState: GlobalGUIChecker.InterfaceDefinition.ExpectedComponent.ExpectedState(
                    isEnabled: true,
                    isVisible: true,
                    selectedIndex: nil,
                    checkState: nil
                )
            )
        ]
        
        let layoutRules: [GlobalGUIChecker.InterfaceDefinition.LayoutRule] = [
            // 最小尺寸检查
            GlobalGUIChecker.InterfaceDefinition.LayoutRule(
                type: .minimumSize,
                description: "界面尺寸应该至少为600x500",
                validator: { componentTree in
                    return componentTree.frame.width >= 600 && componentTree.frame.height >= 500
                }
            ),
            
            // 组件对齐检查
            GlobalGUIChecker.InterfaceDefinition.LayoutRule(
                type: .componentAlignment,
                description: "主要组件应该左对齐",
                validator: { componentTree in
                    let leftMargin: CGFloat = 20
                    let tolerance: CGFloat = 10
                    
                    func checkAlignment(_ component: UIComponentInfo) -> Bool {
                        if component.type == "NSTextField" || component.type == "NSSegmentedControl" {
                            return abs(component.frame.origin.x - leftMargin) <= tolerance
                        }
                        return true
                    }
                    
                    return Self.checkAllComponents(componentTree, with: checkAlignment)
                }
            ),
            
            // 无重叠检查
            GlobalGUIChecker.InterfaceDefinition.LayoutRule(
                type: .noOverlap,
                description: "组件不应该重叠",
                validator: { componentTree in
                    let components = Self.getAllComponentsFlat(componentTree)
                    return Self.findOverlappingComponents(components).isEmpty
                }
            )
        ]
        
        let loadingRequirements = GlobalGUIChecker.InterfaceDefinition.LoadingRequirement(
            maxLoadTime: 1.0,
            requiredResources: ["NSSegmentedControl", "NSSlider", "NSPopUpButton"],
            criticalComponents: ["preset_selector", "action_buttons"]
        )
        
        return GlobalGUIChecker.InterfaceDefinition(
            name: "RDP质量配置界面",
            identifier: "rdp_quality_config",
            expectedComponents: expectedComponents,
            layoutRules: layoutRules,
            loadingRequirements: loadingRequirements,
            creator: {
                // 这里不创建具体的视图控制器，由测试代码负责
                return nil
            }
        )
    }
    
    /// 主菜单界面定义
    private func createMainMenuDefinition() -> GlobalGUIChecker.InterfaceDefinition {
        let expectedComponents: [GlobalGUIChecker.InterfaceDefinition.ExpectedComponent] = [
            GlobalGUIChecker.InterfaceDefinition.ExpectedComponent(
                type: "NSMenu",
                identifier: "main_menu",
                isRequired: true,
                expectedContent: nil,
                expectedState: GlobalGUIChecker.InterfaceDefinition.ExpectedComponent.ExpectedState(
                    isEnabled: true,
                    isVisible: true,
                    selectedIndex: nil,
                    checkState: nil
                )
            )
        ]
        
        let layoutRules: [GlobalGUIChecker.InterfaceDefinition.LayoutRule] = []
        
        let loadingRequirements = GlobalGUIChecker.InterfaceDefinition.LoadingRequirement(
            maxLoadTime: 0.5,
            requiredResources: ["NSMenu", "NSMenuItem"],
            criticalComponents: ["main_menu"]
        )
        
        return GlobalGUIChecker.InterfaceDefinition(
            name: "主菜单",
            identifier: "main_menu",
            expectedComponents: expectedComponents,
            layoutRules: layoutRules,
            loadingRequirements: loadingRequirements,
            creator: { return nil }
        )
    }
    
    /// 关于对话框界面定义
    private func createAboutDialogDefinition() -> GlobalGUIChecker.InterfaceDefinition {
        let expectedComponents: [GlobalGUIChecker.InterfaceDefinition.ExpectedComponent] = [
            GlobalGUIChecker.InterfaceDefinition.ExpectedComponent(
                type: "NSAlert",
                identifier: "about_dialog",
                isRequired: true,
                expectedContent: GlobalGUIChecker.InterfaceDefinition.ExpectedComponent.ExpectedContent(
                    text: "JMS Protocol Handler v1.2.0",
                    title: nil,
                    placeholder: nil,
                    options: nil,
                    valueRange: nil
                ),
                expectedState: GlobalGUIChecker.InterfaceDefinition.ExpectedComponent.ExpectedState(
                    isEnabled: true,
                    isVisible: true,
                    selectedIndex: nil,
                    checkState: nil
                )
            )
        ]
        
        let layoutRules: [GlobalGUIChecker.InterfaceDefinition.LayoutRule] = []
        
        let loadingRequirements = GlobalGUIChecker.InterfaceDefinition.LoadingRequirement(
            maxLoadTime: 0.3,
            requiredResources: ["NSAlert"],
            criticalComponents: ["about_dialog"]
        )
        
        return GlobalGUIChecker.InterfaceDefinition(
            name: "关于对话框",
            identifier: "about_dialog",
            expectedComponents: expectedComponents,
            layoutRules: layoutRules,
            loadingRequirements: loadingRequirements,
            creator: { return nil }
        )
    }
    
    /// 错误对话框界面定义
    private func createErrorDialogDefinition() -> GlobalGUIChecker.InterfaceDefinition {
        let expectedComponents: [GlobalGUIChecker.InterfaceDefinition.ExpectedComponent] = [
            GlobalGUIChecker.InterfaceDefinition.ExpectedComponent(
                type: "NSAlert",
                identifier: "error_dialog",
                isRequired: true,
                expectedContent: nil,
                expectedState: GlobalGUIChecker.InterfaceDefinition.ExpectedComponent.ExpectedState(
                    isEnabled: true,
                    isVisible: true,
                    selectedIndex: nil,
                    checkState: nil
                )
            )
        ]
        
        let layoutRules: [GlobalGUIChecker.InterfaceDefinition.LayoutRule] = []
        
        let loadingRequirements = GlobalGUIChecker.InterfaceDefinition.LoadingRequirement(
            maxLoadTime: 0.3,
            requiredResources: ["NSAlert"],
            criticalComponents: ["error_dialog"]
        )
        
        return GlobalGUIChecker.InterfaceDefinition(
            name: "错误对话框",
            identifier: "error_dialog",
            expectedComponents: expectedComponents,
            layoutRules: layoutRules,
            loadingRequirements: loadingRequirements,
            creator: { return nil }
        )
    }
    
    /// 通知界面定义
    private func createNotificationDefinition() -> GlobalGUIChecker.InterfaceDefinition {
        let expectedComponents: [GlobalGUIChecker.InterfaceDefinition.ExpectedComponent] = [
            GlobalGUIChecker.InterfaceDefinition.ExpectedComponent(
                type: "NSUserNotification",
                identifier: "system_notification",
                isRequired: true,
                expectedContent: GlobalGUIChecker.InterfaceDefinition.ExpectedComponent.ExpectedContent(
                    text: nil,
                    title: "JMS Protocol Handler",
                    placeholder: nil,
                    options: nil,
                    valueRange: nil
                ),
                expectedState: GlobalGUIChecker.InterfaceDefinition.ExpectedComponent.ExpectedState(
                    isEnabled: true,
                    isVisible: true,
                    selectedIndex: nil,
                    checkState: nil
                )
            )
        ]
        
        let layoutRules: [GlobalGUIChecker.InterfaceDefinition.LayoutRule] = []
        
        let loadingRequirements = GlobalGUIChecker.InterfaceDefinition.LoadingRequirement(
            maxLoadTime: 0.1,
            requiredResources: ["NSUserNotification"],
            criticalComponents: ["system_notification"]
        )
        
        return GlobalGUIChecker.InterfaceDefinition(
            name: "系统通知",
            identifier: "system_notification",
            expectedComponents: expectedComponents,
            layoutRules: layoutRules,
            loadingRequirements: loadingRequirements,
            creator: { return nil }
        )
    }
    
    // MARK: - Static Helper Methods
    
    /// 检查所有组件
    static func checkAllComponents(_ componentTree: UIComponentInfo, 
                                 with validator: (UIComponentInfo) -> Bool) -> Bool {
        if !validator(componentTree) {
            return false
        }
        
        for child in componentTree.children {
            if !checkAllComponents(child, with: validator) {
                return false
            }
        }
        
        return true
    }
    
    /// 获取所有组件（扁平化）
    static func getAllComponentsFlat(_ componentTree: UIComponentInfo) -> [UIComponentInfo] {
        var components = [componentTree]
        for child in componentTree.children {
            components.append(contentsOf: getAllComponentsFlat(child))
        }
        return components
    }
    
    /// 查找重叠的组件
    static func findOverlappingComponents(_ components: [UIComponentInfo]) -> [(UIComponentInfo, UIComponentInfo)] {
        var overlapping: [(UIComponentInfo, UIComponentInfo)] = []
        
        for i in 0..<components.count {
            for j in (i+1)..<components.count {
                let comp1 = components[i]
                let comp2 = components[j]
                
                if comp1.frame.intersects(comp2.frame) && 
                   !comp1.frame.isEmpty && !comp2.frame.isEmpty &&
                   !comp1.isHidden && !comp2.isHidden {
                    overlapping.append((comp1, comp2))
                }
            }
        }
        
        return overlapping
    }
}
