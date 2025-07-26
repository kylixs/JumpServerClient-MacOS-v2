import XCTest
@testable import JMSProtocolHandler

class ErrorHandlerTests: XCTestCase {
    
    var errorHandler: ErrorHandler!
    var mockNotificationManager: MockNotificationManager!
    var mockLogger: MockLogger!
    
    override func setUp() {
        super.setUp()
        mockNotificationManager = MockNotificationManager()
        mockLogger = MockLogger()
        errorHandler = ErrorHandler(notificationManager: mockNotificationManager, logger: mockLogger)
    }
    
    override func tearDown() {
        errorHandler = nil
        mockNotificationManager = nil
        mockLogger = nil
        super.tearDown()
    }
    
    // MARK: - handleError Tests
    
    func testHandleError_InvalidURL() {
        // Given
        let error = JMSError.invalidURL
        
        // When
        errorHandler.handleError(error)
        
        // Then
        XCTAssertTrue(mockLogger.errorCalled)
        XCTAssertTrue(mockNotificationManager.showErrorNotificationCalled)
        XCTAssertEqual(mockNotificationManager.lastErrorMessage?.contains("URL格式错误"), true)
    }
    
    func testHandleError_DecodingFailed() {
        // Given
        let error = JMSError.decodingFailed
        
        // When
        errorHandler.handleError(error)
        
        // Then
        XCTAssertTrue(mockLogger.errorCalled)
        XCTAssertTrue(mockNotificationManager.showErrorNotificationCalled)
        XCTAssertEqual(mockNotificationManager.lastErrorMessage?.contains("解码失败"), true)
    }
    
    func testHandleError_JSONParsingFailed() {
        // Given
        let error = JMSError.jsonParsingFailed
        
        // When
        errorHandler.handleError(error)
        
        // Then
        XCTAssertTrue(mockLogger.errorCalled)
        XCTAssertTrue(mockNotificationManager.showErrorNotificationCalled)
        XCTAssertEqual(mockNotificationManager.lastErrorMessage?.contains("配置信息格式错误"), true)
    }
    
    func testHandleError_MissingConnectionInfo() {
        // Given
        let error = JMSError.missingConnectionInfo
        
        // When
        errorHandler.handleError(error)
        
        // Then
        XCTAssertTrue(mockLogger.errorCalled)
        XCTAssertTrue(mockNotificationManager.showErrorNotificationCalled)
        XCTAssertEqual(mockNotificationManager.lastErrorMessage?.contains("连接信息不完整"), true)
    }
    
    func testHandleError_RemoteDesktopNotFound() {
        // Given
        let error = JMSError.remoteDesktopNotFound
        
        // When
        errorHandler.handleError(error)
        
        // Then
        XCTAssertTrue(mockLogger.errorCalled)
        XCTAssertTrue(mockNotificationManager.showErrorNotificationCalled)
        XCTAssertEqual(mockNotificationManager.lastErrorMessage?.contains("未找到Microsoft Remote Desktop"), true)
        XCTAssertEqual(mockNotificationManager.lastErrorMessage?.contains("请从Mac App Store安装"), true)
    }
    
    func testHandleError_RemoteDesktopLaunchFailed() {
        // Given
        let error = JMSError.remoteDesktopLaunchFailed
        
        // When
        errorHandler.handleError(error)
        
        // Then
        XCTAssertTrue(mockLogger.errorCalled)
        XCTAssertTrue(mockNotificationManager.showErrorNotificationCalled)
        XCTAssertEqual(mockNotificationManager.lastErrorMessage?.contains("启动Microsoft Remote Desktop失败"), true)
    }
    
    func testHandleError_MissingRequiredField() {
        // Given
        let fieldName = "username"
        let error = JMSError.missingRequiredField(fieldName)
        
        // When
        errorHandler.handleError(error)
        
        // Then
        XCTAssertTrue(mockLogger.errorCalled)
        XCTAssertTrue(mockNotificationManager.showErrorNotificationCalled)
        XCTAssertEqual(mockNotificationManager.lastErrorMessage?.contains("缺少必要字段: \(fieldName)"), true)
    }
    
    // MARK: - showUserNotification Tests
    
    func testShowUserNotification() {
        // Given
        let message = "测试通知消息"
        
        // When
        errorHandler.showUserNotification(message)
        
        // Then
        XCTAssertTrue(mockNotificationManager.showInfoNotificationCalled)
        XCTAssertEqual(mockNotificationManager.lastInfoMessage, message)
    }
    
    // MARK: - showErrorNotification Tests
    
    func testShowErrorNotification() {
        // Given
        let error = JMSError.invalidURL
        
        // When
        errorHandler.showErrorNotification(error)
        
        // Then
        XCTAssertTrue(mockNotificationManager.showErrorNotificationCalled)
        XCTAssertEqual(mockNotificationManager.lastErrorMessage?.contains("URL格式错误"), true)
        XCTAssertEqual(mockNotificationManager.lastErrorMessage?.contains("请检查URL格式是否正确"), true)
    }
    
    // MARK: - logError Tests
    
    func testLogError_WithoutContext() {
        // Given
        let error = JMSError.decodingFailed
        
        // When
        errorHandler.logError(error, context: nil)
        
        // Then
        XCTAssertTrue(mockLogger.errorCalled)
        XCTAssertEqual(mockLogger.lastErrorMessage?.contains("JMSError: 解码失败"), true)
        XCTAssertEqual(mockLogger.lastErrorMessage?.contains("无法对base64编码的内容进行解码"), true)
    }
    
    func testLogError_WithContext() {
        // Given
        let error = JMSError.jsonParsingFailed
        let context = "处理URL: jms://example"
        
        // When
        errorHandler.logError(error, context: context)
        
        // Then
        XCTAssertTrue(mockLogger.errorCalled)
        XCTAssertEqual(mockLogger.lastErrorMessage?.contains("JMSError: 配置信息格式错误"), true)
        XCTAssertEqual(mockLogger.lastErrorMessage?.contains("Context: \(context)"), true)
    }
    
    // MARK: - Integration Tests
    
    func testErrorHandling_CompleteFlow() {
        // Given
        let error = JMSError.remoteDesktopNotFound
        
        // When
        errorHandler.handleError(error)
        
        // Then
        // 验证日志记录
        XCTAssertTrue(mockLogger.errorCalled)
        XCTAssertEqual(mockLogger.lastErrorMessage?.contains("未找到Microsoft Remote Desktop"), true)
        
        // 验证通知显示
        XCTAssertTrue(mockNotificationManager.showErrorNotificationCalled)
        XCTAssertEqual(mockNotificationManager.lastErrorMessage?.contains("未找到Microsoft Remote Desktop"), true)
        XCTAssertEqual(mockNotificationManager.lastErrorMessage?.contains("请从Mac App Store安装"), true)
    }
}

// MARK: - Mock Classes

class MockNotificationManager: NotificationManagerProtocol {
    var showSuccessNotificationCalled = false
    var showErrorNotificationCalled = false
    var showInfoNotificationCalled = false
    
    var lastSuccessMessage: String?
    var lastErrorMessage: String?
    var lastInfoMessage: String?
    
    func showSuccessNotification(_ message: String) {
        showSuccessNotificationCalled = true
        lastSuccessMessage = message
    }
    
    func showErrorNotification(_ message: String) {
        showErrorNotificationCalled = true
        lastErrorMessage = message
    }
    
    func showInfoNotification(_ message: String) {
        showInfoNotificationCalled = true
        lastInfoMessage = message
    }
}

class MockLogger: LoggerProtocol {
    var errorCalled = false
    var infoCalled = false
    
    var lastErrorMessage: String?
    var lastInfoMessage: String?
    
    func error(_ message: String) {
        errorCalled = true
        lastErrorMessage = message
    }
    
    func info(_ message: String) {
        infoCalled = true
        lastInfoMessage = message
    }
}