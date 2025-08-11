# Project Structure & Organization

## Root Directory Layout
```
jumpserver-client/
├── JMSProtocolHandler/           # Main Xcode project
├── docs/                         # Documentation
├── scripts/                      # Build & deployment scripts
├── tests/                        # Test files
├── build/                        # Custom build artifacts
├── JMSProtocolHandler.app        # Built application
├── JMS-Protocol-Handler-Distribution/  # Distribution package
└── JMS-Protocol-Handler-v1.1.0.dmg    # Installer
```

## Main Project Structure
```
JMSProtocolHandler/
├── JMSProtocolHandler/           # Source code
│   ├── Models/                   # Data models
│   ├── Services/                 # Service implementations
│   ├── Protocols/                # Protocol definitions
│   ├── Utilities/                # Utility classes
│   ├── AppDelegate.swift         # Main app controller
│   ├── Info.plist               # App configuration
│   └── Assets.xcassets          # App resources
├── JMSProtocolHandlerTests/      # Unit tests
├── Tests/                        # SPM tests
├── Sources/                      # SPM source structure
└── JMSProtocolHandler.xcodeproj  # Xcode project
```

## Architecture Patterns

### Protocol-Based Design
- **Protocols/**: Interface definitions for all major components
- **Services/**: Concrete implementations of protocols
- **Models/**: Data structures and business logic

### Key Components
- `URLParserProtocol` → `URLParser`: URL parsing and validation
- `PayloadDecoderProtocol` → `PayloadDecoder`: Base64 decoding
- `ConnectionInfoExtractorProtocol` → `ConnectionInfoExtractor`: Connection data extraction
- `RemoteDesktopIntegratorProtocol` → `RemoteDesktopIntegrator`: RDP integration
- `SSHTerminalIntegratorProtocol` → `SSHTerminalIntegrator`: SSH integration
- `ErrorHandlerProtocol` → `ErrorHandler`: Error management
- `NotificationManagerProtocol` → `NotificationManager`: User notifications

### Data Models
- `ConnectionInfo`: Enum for RDP/SSH connection types
- `RDPConnectionInfo`: RDP-specific connection data
- `SSHConnectionInfo`: SSH-specific connection data
- `JMSURLComponents`: Parsed URL components
- `JMSError`: Comprehensive error definitions

## Build Organization
```
build/
├── objects/          # Compiled object files (.o)
├── temp/            # Temporary build files
├── artifacts/       # Final build products
├── xcode/           # Xcode build outputs
└── derived-data/    # DerivedData cache
```

## Documentation Structure
```
docs/
├── implementation/   # Technical implementation docs
├── user-guide/      # End-user documentation
├── testing/         # Test documentation
└── deployment/      # Deployment guides
```

## Scripts Organization
```
scripts/
├── build/           # Build automation scripts
├── deployment/      # Deployment & installation scripts
└── test/           # Testing scripts
```

## Testing Structure
```
tests/
├── unit/           # Unit tests for individual components
├── integration/    # Integration tests for workflows
└── e2e/           # End-to-end user scenario tests
```

## Naming Conventions
- **Files**: PascalCase for Swift files (`ConnectionInfo.swift`)
- **Classes/Structs**: PascalCase (`URLParser`, `RDPConnectionInfo`)
- **Protocols**: PascalCase with "Protocol" suffix (`URLParserProtocol`)
- **Variables/Functions**: camelCase (`parseJMSURL`, `connectionInfo`)
- **Constants**: camelCase or UPPER_CASE for static constants
- **Enums**: PascalCase with lowercase cases (`ConnectionInfo.rdp`)

## File Organization Rules
- One class/struct/protocol per file
- Group related functionality in folders (Models, Services, Protocols)
- Keep AppDelegate.swift as the main entry point
- Separate test files mirror source structure
- Use `.gitkeep` files to maintain empty directories