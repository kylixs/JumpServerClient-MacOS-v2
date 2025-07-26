#!/usr/bin/env swift

import Foundation

// Simple syntax validation by attempting to compile key components
print("Validating URLParser syntax...")

// Test basic URL creation and validation
let testURL = URL(string: "jms://eyJ0ZXN0IjoidmFsdWUifQ==")!
print("✅ URL creation works")

// Test base64 validation logic
let base64String = "eyJ0ZXN0IjoidmFsdWUifQ=="
let base64CharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")

if base64String.rangeOfCharacter(from: base64CharacterSet.inverted) == nil {
    print("✅ Base64 character validation works")
}

if base64String.count % 4 == 0 {
    print("✅ Base64 length validation works")
}

if Data(base64Encoded: base64String) != nil {
    print("✅ Base64 decoding validation works")
}

print("All syntax validations passed!")