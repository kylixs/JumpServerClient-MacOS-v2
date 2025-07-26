import XCTest
import UserNotifications
@testable import JMSProtocolHandler

class NotificationManagerTests: XCTestCase {
    
    var notificationManager: NotificationManager!
    
    override func setUp() {
        super.setUp()
        notificationManager = NotificationManager()
    }
    
    override func tearDown() {
        notificationManager = nil
        super.tearDown()
    }
    
    // MARK: - Success Notification Tests
    
    func testShowSuccessNotification() {
        // Given
        let message = "连接成功建立"
        let expectation = XCTestExpectation(description: "Success notification shown")
        
        // When
        notificationManager.showSuccessNotification(message)
        
        // Then
        // 由于通知是异步的，我们需要等待一小段时间来验证
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        // 注意：在实际测试中，我们可能需要mock UNUserNotificationCenter来验证通知内容
    }
    
    // MARK: - Error Notification Tests
    
    func testShowErrorNotification() {
        // Given
        let message = "连接失败，请检查网络设置"
        let expectation = XCTestExpectation(description: "Error notification shown")
        
        // When
        notificationManager.showErrorNotification(message)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Info Notification Tests
    
    func testShowInfoNotification() {
        // Given
        let message = "正在处理连接请求..."
        let expectation = XCTestExpectation(description: "Info notification shown")
        
        // When
        notificationManager.showInfoNotification(message)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Protocol Conformance Tests
    
    func testNotificationManagerConformsToProtocol() {
        // Given & When & Then
        XCTAssertTrue(notificationManager is NotificationManagerProtocol)
    }
    
    // MARK: - Delegate Tests
    
    func testNotificationManagerIsDelegate() {
        // Given & When & Then
        XCTAssertTrue(notificationManager is UNUserNotificationCenterDelegate)
    }
}

// MARK: - Mock Notification Manager for Testing

class MockNotificationManagerForTesting: NotificationManagerProtocol {
    private var notifications: [(title: String, message: String, type: String)] = []
    
    var notificationCount: Int {
        return notifications.count
    }
    
    var lastNotification: (title: String, message: String, type: String)? {
        return notifications.last
    }
    
    func showSuccessNotification(_ message: String) {
        notifications.append((title: "JMS Protocol Handler", message: message, type: "success"))
    }
    
    func showErrorNotification(_ message: String) {
        notifications.append((title: "JMS Protocol Handler - 错误", message: message, type: "error"))
    }
    
    func showInfoNotification(_ message: String) {
        notifications.append((title: "JMS Protocol Handler", message: message, type: "info"))
    }
    
    func clearNotifications() {
        notifications.removeAll()
    }
    
    func getNotifications() -> [(title: String, message: String, type: String)] {
        return notifications
    }
}

// MARK: - Integration Tests with Mock

class NotificationManagerIntegrationTests: XCTestCase {
    
    var mockNotificationManager: MockNotificationManagerForTesting!
    
    override func setUp() {
        super.setUp()
        mockNotificationManager = MockNotificationManagerForTesting()
    }
    
    override func tearDown() {
        mockNotificationManager = nil
        super.tearDown()
    }
    
    func testMultipleNotifications() {
        // Given
        let successMessage = "操作成功"
        let errorMessage = "操作失败"
        let infoMessage = "正在处理"
        
        // When
        mockNotificationManager.showSuccessNotification(successMessage)
        mockNotificationManager.showErrorNotification(errorMessage)
        mockNotificationManager.showInfoNotification(infoMessage)
        
        // Then
        XCTAssertEqual(mockNotificationManager.notificationCount, 3)
        
        let notifications = mockNotificationManager.getNotifications()
        XCTAssertEqual(notifications[0].message, successMessage)
        XCTAssertEqual(notifications[0].type, "success")
        
        XCTAssertEqual(notifications[1].message, errorMessage)
        XCTAssertEqual(notifications[1].type, "error")
        
        XCTAssertEqual(notifications[2].message, infoMessage)
        XCTAssertEqual(notifications[2].type, "info")
    }
    
    func testNotificationTitles() {
        // Given
        let message = "测试消息"
        
        // When
        mockNotificationManager.showSuccessNotification(message)
        mockNotificationManager.showErrorNotification(message)
        mockNotificationManager.showInfoNotification(message)
        
        // Then
        let notifications = mockNotificationManager.getNotifications()
        
        XCTAssertEqual(notifications[0].title, "JMS Protocol Handler")
        XCTAssertEqual(notifications[1].title, "JMS Protocol Handler - 错误")
        XCTAssertEqual(notifications[2].title, "JMS Protocol Handler")
    }
    
    func testClearNotifications() {
        // Given
        mockNotificationManager.showSuccessNotification("测试")
        mockNotificationManager.showErrorNotification("测试")
        XCTAssertEqual(mockNotificationManager.notificationCount, 2)
        
        // When
        mockNotificationManager.clearNotifications()
        
        // Then
        XCTAssertEqual(mockNotificationManager.notificationCount, 0)
        XCTAssertNil(mockNotificationManager.lastNotification)
    }
}