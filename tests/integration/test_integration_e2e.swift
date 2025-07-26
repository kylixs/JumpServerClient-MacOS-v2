#!/usr/bin/env swift

import Foundation
import Cocoa

print("=== JMS Protocol Handler 集成测试和端到端测试 ===\n")

// 测试框架基础类
class TestFramework {
    private var testResults: [String: Bool] = [:]
    private var testDetails: [String: String] = [:]
    private var totalTests = 0
    private var passedTests = 0
    
    func runTest(_ testName: String, test: () throws -> Void) {
        totalTests += 1
        print("🧪 运行测试: \(testName)")
        
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            try test()
            let endTime = CFAbsoluteTimeGetCurrent()
            let duration = endTime - startTime
            
            testResults[testName] = true
            testDetails[testName] = "✅ 通过 (\(String(format: "%.3f", duration))秒)"
            passedTests += 1
            print("   ✅ 测试通过 - 耗时: \(String(format: "%.3f", duration))秒")
        } catch {
            testResults[testName] = false
            testDetails[testName] = "❌ 失败: \(error.localizedDescription)"
            print("   ❌ 测试失败: \(error.localizedDescription)")
        }
        print()
    }
    
    func printSummary() {
        print("=" * 60)
        print("测试总结")
        print("=" * 60)
        print("总测试数: \(totalTests)")
        print("通过测试: \(passedTests)")
        print("失败测试: \(totalTests - passedTests)")
        print("通过率: \(String(format: "%.1f", Double(passedTests) / Double(totalTests) * 100))%")
        print()
        
        print("详细结果:")
        for (testName, result) in testDetails {
            print("  \(testName): \(result)")
        }
        
        if passedTests == totalTests {
            print("\n🎉 所有测试通过！")
        } else {
            print("\n⚠️ 有测试失败，请检查上述结果")
        }
    }
}

// 扩展String以支持重复操作
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// 测试用的错误类型
enum TestError: Error, LocalizedError {
    case testFailed(String)
    case assertionFailed(String)
    case unexpectedResult(String)
    
    var errorDescription: String? {
        switch self {
        case .testFailed(let message):
            return "测试失败: \(message)"
        case .assertionFailed(let message):
            return "断言失败: \(message)"
        case .unexpectedResult(let message):
            return "意外结果: \(message)"
        }
    }
}

// 测试断言函数
func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "") throws {
    if actual != expected {
        let errorMessage = message.isEmpty ? 
            "期望值: \(expected), 实际值: \(actual)" : 
            "\(message) - 期望值: \(expected), 实际值: \(actual)"
        throw TestError.assertionFailed(errorMessage)
    }
}

func assertTrue(_ condition: Bool, _ message: String = "") throws {
    if !condition {
        let errorMessage = message.isEmpty ? "条件应为true" : message
        throw TestError.assertionFailed(errorMessage)
    }
}

func assertFalse(_ condition: Bool, _ message: String = "") throws {
    if condition {
        let errorMessage = message.isEmpty ? "条件应为false" : message
        throw TestError.assertionFailed(errorMessage)
    }
}

func assertNotNil<T>(_ value: T?, _ message: String = "") throws {
    if value == nil {
        let errorMessage = message.isEmpty ? "值不应为nil" : message
        throw TestError.assertionFailed(errorMessage)
    }
}

func assertThrows<T>(_ expression: () throws -> T, _ message: String = "") throws {
    do {
        _ = try expression()
        let errorMessage = message.isEmpty ? "表达式应该抛出异常" : message
        throw TestError.assertionFailed(errorMessage)
    } catch {
        // 期望的行为，测试通过
    }
}

// 创建测试框架实例
let testFramework = TestFramework()

print("初始化测试环境...")
print("✅ 测试框架已准备就绪\n")
