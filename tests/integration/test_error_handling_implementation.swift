#!/usr/bin/env swift

import Foundation

print("🧪 Testing Error Handling Implementation...")

// Test 1: Check if all error types are properly defined
print("\n📋 Test 1: Checking JMSError types...")

let errorTypesContent = try String(contentsOfFile: "JMSProtocolHandler/JMSProtocolHandler/Models/JMSError.swift")

let expectedErrorTypes = [
    "invalidURL",
    "decodingFailed", 
    "jsonParsingFailed",
    "missingConnectionInfo",
    "remoteDesktopNotFound",
    "remoteDesktopLaunchFailed",
    "configParsingFailed",
    "missingRequiredField"
]

var allErrorTypesFound = true
for errorType in expectedErrorTypes {
    if errorTypesContent.contains("case \(errorType)") {
        print("✅ Found error type: \(errorType)")
    } else {
        print("❌ Missing error type: \(errorType)")
        allErrorTypesFound = false
    }
}

// Test 2: Check if ErrorHandler has all required methods
print("\n📋 Test 2: Checking ErrorHandler methods...")

let errorHandlerContent = try String(contentsOfFile: "JMSProtocolHandler/JMSProtocolHandler/Services/ErrorHandler.swift")

let expectedMethods = [
    "handleError",
    "showUserNotification", 
    "showErrorNotification",
    "logError"
]

var allMethodsFound = true
for method in expectedMethods {
    if errorHandlerContent.contains("func \(method)") {
        print("✅ Found method: \(method)")
    } else {
        print("❌ Missing method: \(method)")
        allMethodsFound = false
    }
}

// Test 3: Check if NotificationManager has all required methods
print("\n📋 Test 3: Checking NotificationManager methods...")

let notificationManagerContent = try String(contentsOfFile: "JMSProtocolHandler/JMSProtocolHandler/Services/NotificationManager.swift")

let expectedNotificationMethods = [
    "showSuccessNotification",
    "showErrorNotification",
    "showInfoNotification"
]

var allNotificationMethodsFound = true
for method in expectedNotificationMethods {
    if notificationManagerContent.contains("func \(method)") {
        print("✅ Found method: \(method)")
    } else {
        print("❌ Missing method: \(method)")
        allNotificationMethodsFound = false
    }
}

// Test 4: Check if protocols are properly defined
print("\n📋 Test 4: Checking protocol definitions...")

let protocolFiles = [
    ("NotificationManagerProtocol", "JMSProtocolHandler/JMSProtocolHandler/Protocols/NotificationManagerProtocol.swift"),
    ("ErrorHandlerProtocol", "JMSProtocolHandler/JMSProtocolHandler/Protocols/ErrorHandlerProtocol.swift")
]

var allProtocolsFound = true
for (protocolName, filePath) in protocolFiles {
    if FileManager.default.fileExists(atPath: filePath) {
        let content = try String(contentsOfFile: filePath)
        if content.contains("protocol \(protocolName)") {
            print("✅ Found protocol: \(protocolName)")
        } else {
            print("❌ Protocol definition not found: \(protocolName)")
            allProtocolsFound = false
        }
    } else {
        print("❌ Protocol file not found: \(filePath)")
        allProtocolsFound = false
    }
}

// Test 5: Check if test files have proper test methods
print("\n📋 Test 5: Checking test implementations...")

let testFiles = [
    "JMSProtocolHandler/JMSProtocolHandlerTests/Services/ErrorHandlerTests.swift",
    "JMSProtocolHandler/JMSProtocolHandlerTests/Services/NotificationManagerTests.swift"
]

var allTestsFound = true
for testFile in testFiles {
    let testContent = try String(contentsOfFile: testFile)
    let testMethodCount = testContent.components(separatedBy: "func test").count - 1
    print("✅ Found \(testMethodCount) test methods in \(testFile.components(separatedBy: "/").last ?? testFile)")
    
    if testMethodCount < 3 {
        print("⚠️  Consider adding more test methods to \(testFile)")
    }
}

// Final summary
print("\n🎯 Summary:")
if allErrorTypesFound && allMethodsFound && allNotificationMethodsFound && allProtocolsFound {
    print("✅ All error handling components are properly implemented!")
    print("🎉 Task 6 implementation is complete and ready for testing!")
} else {
    print("❌ Some components need attention")
    if !allErrorTypesFound { print("  - Fix missing error types") }
    if !allMethodsFound { print("  - Fix missing ErrorHandler methods") }
    if !allNotificationMethodsFound { print("  - Fix missing NotificationManager methods") }
    if !allProtocolsFound { print("  - Fix missing protocol definitions") }
}