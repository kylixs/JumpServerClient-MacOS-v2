# JMS Protocol Handler v1.0.0

## 概述
JMS Protocol Handler 是一个 macOS 应用程序，用于处理 `jms://` 协议链接，自动解析连接信息并启动 Microsoft Remote Desktop 建立远程桌面连接。

## 系统要求
- macOS 10.15 (Catalina) 或更高版本
- Microsoft Remote Desktop 应用程序（从 Mac App Store 安装）
- Apple Silicon (M1/M2/M4) 或 Intel 处理器

## 安装方法

### 方法1: 手动安装（推荐）
1. 将 `JMSProtocolHandler.app` 拖拽到 `/Applications` 文件夹
2. 首次运行时，右键点击应用程序选择"打开"
3. 在安全提示中点击"打开"

### 方法2: 命令行安装
```bash
cp -R JMSProtocolHandler.app /Applications/
```

## 使用方法
1. 确保已安装 Microsoft Remote Desktop
2. 点击包含 `jms://` 协议的链接
3. 应用程序将自动：
   - 解析连接信息
   - 创建 RDP 配置文件
   - 启动 Microsoft Remote Desktop
   - 建立远程桌面连接

## 功能特性
- ✅ 自动 jms:// 协议处理
- ✅ Base64 解码和 JSON 解析
- ✅ RDP 配置文件生成
- ✅ Microsoft Remote Desktop 集成
- ✅ 智能错误处理和用户通知
- ✅ 临时文件自动清理
- ✅ Apple Silicon 原生支持

## 性能指标
- **启动时间**: < 0.2秒
- **URL处理**: < 0.001秒
- **内存使用**: < 10MB 增长
- **支持架构**: ARM64 + x86_64

## 支持的配置参数
- 服务器地址和端口
- 用户名
- 会话颜色深度 (session bpp)
- 音频模式 (audiomode)
- 智能调整大小 (smart sizing)
- 屏幕模式 (screen mode id)

## 故障排除
如果遇到问题，请查看相关文档。

常见问题：
1. **应用程序无法启动**: 检查 macOS 版本，确保为 10.15+
2. **JMS 链接无法处理**: 重新启动应用程序
3. **Remote Desktop 未找到**: 从 Mac App Store 安装 Microsoft Remote Desktop
4. **连接失败**: 检查网络连接和服务器地址

## 卸载
手动删除应用程序：
```bash
rm -rf /Applications/JMSProtocolHandler.app
```

## 技术信息
- 版本: 1.0.0
- 构建日期: 2025-07-25
- 兼容性: macOS 10.15+
- 架构: Universal (ARM64 + x86_64)

---
© 2025 JMS Protocol Handler. All rights reserved.
