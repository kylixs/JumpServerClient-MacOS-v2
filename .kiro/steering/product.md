# JMS Protocol Handler

A macOS application that handles `jms://` protocol links for seamless remote connections.

## Core Functionality
- **RDP Protocol**: Automatically parses connection info and launches Microsoft Remote Desktop for remote desktop connections
- **SSH Protocol**: Establishes SSH sessions through local terminal (Terminal or iTerm2) with automatic password input support

## Key Features
- Dual protocol support (RDP + SSH)
- Smart protocol detection and routing
- Seamless Microsoft Remote Desktop integration
- Intelligent terminal integration (iTerm2 preferred, Terminal fallback)
- Automatic password input via expect scripts
- Error handling with user-friendly notifications
- High performance (0.184s startup, 0.000009s URL processing)
- Universal binary (ARM64 + x86_64)

## Target Platform
- macOS 10.15 (Catalina) or higher
- Apple Silicon and Intel architectures
- Dependencies: Microsoft Remote Desktop, Terminal/iTerm2, optional expect tool

## Architecture
Protocol-based architecture with clear separation between URL parsing, payload decoding, connection info extraction, and protocol-specific integrators.