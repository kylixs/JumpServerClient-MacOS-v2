import XCTest
@testable import JMSProtocolHandler

class JMSErrorTests: XCTestCase {
    
    func testJMSErrorDescriptions() {
        // Test all error cases have proper descriptions
        let testCases: [(JMSError, String)] = [
            (.invalidURL, "URL格式错误"),
            (.decodingFailed, "解码失败"),
            (.jsonParsingFailed, "配置信息格式错误"),
            (.missingConnectionInfo, "连接信息不完整"),
            (.remoteDesktopNotFound, "未找到Microsoft Remote Desktop应用程序"),
            (.remoteDesktopLaunchFailed, "启动Microsoft Remote Desktop失败"),
            (.configParsingFailed, "配置解析失败"),
            (.missingRequiredField("test"), "缺少必要字段: test")
        ]
        
        for (error, expectedDescription) in testCases {
            XCTAssertEqual(error.errorDescription, expectedDescription)
        }
    }
    
    func testJMSErrorFailureReasons() {
        // Test all error cases have proper failure reasons
        let testCases: [(JMSError, String)] = [
            (.invalidURL, "提供的URL不是有效的jms://协议格式"),
            (.decodingFailed, "无法对base64编码的内容进行解码"),
            (.jsonParsingFailed, "JSON配置信息格式不正确或包含无效数据"),
            (.missingConnectionInfo, "配置中缺少必要的连接信息"),
            (.remoteDesktopNotFound, "系统中未安装Microsoft Remote Desktop应用程序"),
            (.remoteDesktopLaunchFailed, "无法启动Microsoft Remote Desktop应用程序"),
            (.configParsingFailed, "无法解析配置字符串中的参数"),
            (.missingRequiredField("username"), "配置中缺少必要的字段: username")
        ]
        
        for (error, expectedReason) in testCases {
            XCTAssertEqual(error.failureReason, expectedReason)
        }
    }
    
    func testJMSErrorRecoverySuggestions() {
        // Test all error cases have proper recovery suggestions
        let testCases: [(JMSError, String)] = [
            (.invalidURL, "请检查URL格式是否正确，确保以jms://开头"),
            (.decodingFailed, "请检查URL中的编码内容是否为有效的base64格式"),
            (.jsonParsingFailed, "请检查配置信息是否为有效的JSON格式"),
            (.missingConnectionInfo, "请确保配置中包含完整的连接信息"),
            (.remoteDesktopNotFound, "请从Mac App Store安装Microsoft Remote Desktop应用程序"),
            (.remoteDesktopLaunchFailed, "请检查Microsoft Remote Desktop是否正确安装并可以正常启动"),
            (.configParsingFailed, "请检查配置字符串格式是否正确"),
            (.missingRequiredField("token"), "请确保配置包含所有必要的字段")
        ]
        
        for (error, expectedSuggestion) in testCases {
            XCTAssertEqual(error.recoverySuggestion, expectedSuggestion)
        }
    }
    
    func testJMSErrorEquality() {
        // Test error equality
        XCTAssertEqual(JMSError.invalidURL, JMSError.invalidURL)
        XCTAssertEqual(JMSError.decodingFailed, JMSError.decodingFailed)
        XCTAssertEqual(JMSError.missingRequiredField("test"), JMSError.missingRequiredField("test"))
        
        // Test error inequality
        XCTAssertNotEqual(JMSError.invalidURL, JMSError.decodingFailed)
        XCTAssertNotEqual(JMSError.missingRequiredField("test1"), JMSError.missingRequiredField("test2"))
    }
    
    func testJMSErrorLocalizedError() {
        // Test that JMSError conforms to LocalizedError
        let error: LocalizedError = JMSError.invalidURL
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.failureReason)
        XCTAssertNotNil(error.recoverySuggestion)
    }
}