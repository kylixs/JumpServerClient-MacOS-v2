# Technology Stack

## Core Technologies
- **Language**: Swift 6.1.2+
- **Platform**: macOS 10.15+ (Catalina)
- **Architecture**: Universal Binary (ARM64 + Intel x86_64)
- **Build System**: Xcode 16.4+ with custom build paths
- **Package Manager**: Swift Package Manager

## Frameworks & Dependencies
- **Cocoa**: Native macOS UI framework
- **Foundation**: Core Swift/Objective-C framework
- **NSWorkspace**: Application launching and file operations
- **NSAppleScript**: Terminal automation via AppleScript
- **NSUserNotification**: System notifications

## External Dependencies
- **Microsoft Remote Desktop**: RDP connection handling
- **Terminal/iTerm2**: SSH session management
- **expect**: Optional tool for automatic SSH password input

## Build System

### Xcode Build
```bash
# Standard Xcode build
cd JMSProtocolHandler
xcodebuild -project JMSProtocolHandler.xcodeproj -scheme JMSProtocolHandler -configuration Release build

# Custom build paths (recommended)
./scripts/build/build-with-custom-paths.sh
```

### Swift Package Manager
```bash
# Build with SPM
cd JMSProtocolHandler
swift build -c release
```

### Custom Build Scripts
```bash
# Configure build paths (first time setup)
./scripts/build/configure-build-paths.sh

# Build with custom paths
./scripts/build/build-with-custom-paths.sh

# Compile individual Swift files
./scripts/build/compile-swift-files.sh

# Clean build artifacts
./scripts/build/clean.sh
```

## Testing
```bash
# Run integration tests
swift tests/integration/test_integration_e2e_complete.swift

# Run performance tests
swift tests/integration/test_performance_compatibility.swift

# Test protocol registration
./scripts/test/test_jms_protocol.sh
```

## Deployment
```bash
# Register JMS protocol
./scripts/deployment/register_jms_protocol.sh

# Create DMG installer
./scripts/build/create_dmg.sh

# Create PKG installer
./scripts/build/create_pkg.sh
```

## Build Configuration
- Uses custom build paths to organize build artifacts
- Supports both Debug and Release configurations
- Universal binary compilation for Apple Silicon + Intel
- Custom xcconfig files for build path management