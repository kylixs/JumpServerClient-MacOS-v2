# JMS Protocol Handler v1.2.0

## 🚀 主要功能

### 📦 一键安装包
- **DMG安装包** - 包含应用程序、管理脚本和使用说明
- **拖拽安装** - 符合macOS用户习惯的安装方式
- **完整工具集** - 协议注册、状态检查、清理、卸载脚本

### 🔗 协议支持
- **RDP连接** - 智能显示优化，支持HiDPI显示器
- **SSH连接** - 自动密码输入，智能终端集成
- **协议处理** - 自动识别jms://链接并分发到相应处理器

### 🛡️ 权限处理
- **macOS原生权限处理** - 使用AppleScript进行权限提升
- **友好的权限对话框** - 清晰的操作说明和指导
- **手动注册支持** - 提供命令复制和详细指南

### ⚡ 性能特性
- **高速启动** - 应用启动时间小于0.2秒
- **智能缓存** - 协议状态检查和刷新优化
- **资源优化** - 默认关闭调试功能，专注核心性能

### 🎯 管理功能
- **协议状态检查** - 实时查看协议处理器注册状态
- **一键重新注册** - 快速修复协议处理问题
- **详细日志** - 完整的操作日志和错误诊断
- **界面管理** - 直观的图形界面管理协议设置

## 📋 系统要求
- **操作系统**: macOS 10.15 (Catalina) 或更高版本
- **架构**: Apple Silicon + Intel 通用版本
- **RDP功能**: Microsoft Remote Desktop
- **SSH功能**: Terminal 或 iTerm2
- **可选**: expect (自动密码输入)

## 🚀 快速开始
1. 下载 `JMS-Protocol-Handler-v1.2.0.dmg`
2. 双击挂载，拖拽应用到 Applications 文件夹
3. 运行 `Scripts/register_jms_protocol.sh` 注册协议
4. 测试: `open "jms://test"`

## 📖 使用说明
- 查看DMG中的 `README.md` 了解详细功能
- 运行 `Scripts/check_jms_protocol.py` 检查协议状态
- 使用 `Scripts/cleanup_jms_handlers.py` 清理无效处理器
- 运行 `Scripts/卸载脚本.sh` 完全卸载程序

---
**专业的macOS JMS协议处理器，让远程连接变得简单高效！** 🚀
