# JMS Protocol Handler v1.2.0

专业的 macOS 应用程序，用于处理 `jms://` 协议链接，支持 RDP 和 SSH 连接。

## 🚀 快速安装

### 1. 安装应用程序
将 `JMSProtocolHandler.app` 拖拽到 `Applications` 文件夹

### 2. 注册协议处理器
```bash
cd Scripts
./register_jms_protocol.sh
```

### 3. 验证安装
```bash
python3 Scripts/check_jms_protocol.py
```

## ✨ 主要功能

- **🖥️ RDP连接**: 智能显示优化，支持HiDPI显示器
- **🔗 SSH连接**: 自动密码输入，智能终端集成  
- **⚡ 高性能**: 启动时间 < 0.2秒
- **🛡️ 安全**: macOS原生权限处理

## 📋 脚本说明

| 脚本 | 功能 | 用法 |
|------|------|------|
| `register_jms_protocol.sh` | 注册协议处理器 | `./register_jms_protocol.sh` |
| `check_jms_protocol.py` | 检查协议状态 | `python3 check_jms_protocol.py` |
| `cleanup_jms_handlers.py` | 清理无效处理器 | `python3 cleanup_jms_handlers.py` |
| `卸载脚本.sh` | 完全卸载程序 | `./卸载脚本.sh` |

## 📋 系统要求

- **操作系统**: macOS 10.15+
- **RDP依赖**: Microsoft Remote Desktop
- **SSH依赖**: Terminal/iTerm2
- **架构**: Apple Silicon + Intel

## 🔍 故障排除

### 协议未注册
```bash
./Scripts/register_jms_protocol.sh
python3 Scripts/check_jms_protocol.py
```

### 权限问题
```bash
sudo ./Scripts/register_jms_protocol.sh
```

### 测试协议
```bash
open "jms://test"
```

## 📞 技术信息

- **版本**: 1.2.0
- **构建**: 2025-08-18
- **支持协议**: RDP + SSH
- **性能**: 启动 < 0.2秒，处理 > 100K URLs/秒

---
**让 JMS 协议连接变得简单高效！** 🚀
