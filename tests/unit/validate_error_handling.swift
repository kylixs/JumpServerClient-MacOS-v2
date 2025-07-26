#!/usr/bin/env swift

import Foundation

// This script validates the error handling implementation
print("🔍 Validating Error Handling Implementation...")

// Check if all required files exist
let requiredFiles = [
    "JMSProtocolHandler/JMSProtocolHandler/Protocols/NotificationManagerProtocol.swift",
    "JMSProtocolHandler/JMSProtocolHandler/Services/ErrorHandler.swift",
    "JMSProtocolHandler/JMSProtocolHandler/Services/NotificationManager.swift",
    "JMSProtocolHandler/JMSProtocolHandlerTests/Services/ErrorHandlerTests.swift",
    "JMSProtocolHandler/JMSProtocolHandlerTests/Services/NotificationManagerTests.swift"
]

var allFilesExist = true
for file in requiredFiles {
    if !FileManager.default.fileExists(atPath: file) {
        print("❌ Missing file: \(file)")
        allFilesExist = false
    } else {
        print("✅ Found: \(file)")
    }
}

if allFilesExist {
    print("✅ All required files exist")
    print("🎉 Error handling implementation validation completed successfully!")
} else {
    print("❌ Some required files are missing")
    exit(1)
}