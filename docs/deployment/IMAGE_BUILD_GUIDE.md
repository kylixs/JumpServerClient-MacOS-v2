# JMS Protocol Handler 镜像构建指南

本指南详细说明如何构建 JMS Protocol Handler 的各种镜像格式，包括 DMG 安装包和 Docker 开发环境镜像。

## 📋 目录

- [概述](#概述)
- [构建环境要求](#构建环境要求)
- [DMG 镜像构建](#dmg-镜像构建)
- [Docker 镜像构建](#docker-镜像构建)
- [配置文件说明](#配置文件说明)
- [故障排除](#故障排除)

## 🎯 概述

JMS Protocol Handler 支持多种镜像格式：

- **DMG 安装包**: macOS 应用程序分发格式
- **Docker 镜像**: 开发环境容器化
- **PKG 安装包**: macOS 系统级安装包（可选）

## 🛠️ 构建环境要求

### 基本要求
- **操作系统**: macOS 10.15 (Catalina) 或更高版本
- **Xcode**: 16.4 或更高版本
- **Swift**: 6.1.2 或更高版本
- **磁盘空间**: 至少 2GB 可用空间

### 可选工具
- **Docker**: 用于构建开发环境镜像
- **Homebrew**: 用于安装额外工具
- **create-dmg**: 高级 DMG 创建工具

```bash
# 安装可选工具
brew install create-dmg
brew install --cask docker
```

## 📦 DMG 镜像构建

### 快速构建

使用一键构建脚本：

```bash
# 构建所有镜像（推荐）
./scripts/build/build-images.sh

# 仅构建 DMG
./scripts/build/build-images.sh dmg
```

### 手动构建步骤

1. **构建应用程序**
   ```bash
   cd JMSProtocolHandler
   xcodebuild -project JMSProtocolHandler.xcodeproj \
              -scheme JMSProtocolHandler \
              -configuration Release \
              build
   ```

2. **创建 DMG**
   ```bash
   # 使用内置脚本
   ./scripts/build/create_dmg.sh
   
   # 或使用镜像构建脚本
   ./scripts/build/build-images.sh dmg
   ```

### DMG 配置

DMG 构建配置位于 `scripts/build/dmg-config.json`：

```json
{
  "dmg": {
    "title": "JMS Protocol Handler",
    "version": "1.0.0",
    "filename": "JMS-Protocol-Handler-v1.0.0.dmg",
    "window": {
      "width": 600,
      "height": 400
    },
    "icon_size": 80,
    "format": "UDZO",
    "compression": "zlib"
  }
}
```

### DMG 特性

- **拖拽安装**: 支持拖拽到 Applications 文件夹
- **自定义背景**: 专业的安装界面
- **压缩优化**: 使用 zlib 压缩，文件大小约 51KB
- **完整性验证**: 内置校验和验证

## 🐳 Docker 镜像构建

### 快速开始

```bash
# 构建开发环境
docker-compose -f docker/docker-compose.yml up --build

# 或使用构建脚本
./scripts/build/build-images.sh docker
```

### 开发环境使用

```bash
# 启动开发容器
docker-compose -f docker/docker-compose.yml up -d jms-protocol-handler-dev

# 进入开发环境
docker exec -it jms-protocol-handler-dev bash

# 在容器中构建项目
swift build

# 运行测试
swift test
```

### 测试环境

```bash
# 运行测试容器
docker-compose -f docker/docker-compose.yml up jms-protocol-handler-test

# 查看测试结果
docker-compose -f docker/docker-compose.yml logs jms-protocol-handler-test
```

## 📄 配置文件说明

### 1. DMG 配置 (`scripts/build/dmg-config.json`)

控制 DMG 安装包的外观和行为：

- `title`: DMG 卷标题
- `version`: 版本号
- `filename`: 输出文件名
- `window`: 安装窗口尺寸
- `icon_size`: 图标大小
- `format`: 压缩格式 (UDZO/UDRO/UDBZ)
- `compression`: 压缩算法

### 2. Docker 配置 (`docker/Dockerfile`)

定义开发环境容器：

- 基于 Swift 官方镜像
- 安装必要的系统依赖
- 配置构建环境
- 设置工作目录和环境变量

### 3. Docker Compose (`docker/docker-compose.yml`)

编排多个容器服务：

- `jms-protocol-handler-dev`: 开发环境
- `jms-protocol-handler-test`: 测试环境
- 共享卷和网络配置

### 4. Docker 忽略 (`docker/.dockerignore`)

控制哪些文件不被复制到容器：

- 排除构建产物和临时文件
- 保留必要的源代码和配置
- 优化镜像大小

## 🔧 高级配置

### 自定义构建路径

项目使用自定义构建路径避免污染项目根目录：

```bash
# 配置构建路径
./scripts/build/configure-build-paths.sh

# 使用自定义路径构建
./scripts/build/build-with-custom-paths.sh
```

### 签名和公证

对于生产环境，可以配置代码签名：

```json
{
  "signing": {
    "enabled": true,
    "identity": "Developer ID Application: Your Name",
    "entitlements": "JMSProtocolHandler/JMSProtocolHandler.entitlements"
  },
  "notarization": {
    "enabled": true,
    "apple_id": "your-apple-id@example.com",
    "team_id": "YOUR_TEAM_ID",
    "app_password": "@keychain:AC_PASSWORD"
  }
}
```

### 多架构支持

构建通用二进制文件：

```bash
# 构建 Universal Binary (ARM64 + x86_64)
xcodebuild -project JMSProtocolHandler.xcodeproj \
           -scheme JMSProtocolHandler \
           -configuration Release \
           -arch arm64 -arch x86_64 \
           build
```

## 📊 构建验证

### 验证 DMG

```bash
# 验证 DMG 完整性
hdiutil verify JMS-Protocol-Handler-v1.0.0.dmg

# 检查 DMG 内容
hdiutil attach JMS-Protocol-Handler-v1.0.0.dmg -readonly
ls -la "/Volumes/JMS Protocol Handler Installer/"
hdiutil detach "/Volumes/JMS Protocol Handler Installer/"
```

### 验证应用程序

```bash
# 检查应用程序结构
ls -la JMSProtocolHandler.app/Contents/

# 验证代码签名
codesign -dv JMSProtocolHandler.app

# 检查架构支持
lipo -info JMSProtocolHandler.app/Contents/MacOS/JMSProtocolHandler
```

### 验证 Docker 镜像

```bash
# 列出构建的镜像
docker images | grep jms-protocol-handler

# 检查镜像详情
docker inspect jms-protocol-handler:1.0.0

# 测试镜像运行
docker run --rm jms-protocol-handler:1.0.0 swift --version
```

## 🚨 故障排除

### 常见问题

1. **Xcode 构建失败**
   ```bash
   # 清理构建缓存
   ./scripts/build/clean.sh
   
   # 重新配置构建路径
   ./scripts/build/configure-build-paths.sh
   ```

2. **DMG 创建失败**
   ```bash
   # 检查磁盘空间
   df -h
   
   # 清理临时文件
   rm -rf temp_dmg temp-*.dmg
   ```

3. **Docker 构建失败**
   ```bash
   # 清理 Docker 缓存
   docker system prune -f
   
   # 重新构建镜像
   docker-compose build --no-cache
   ```

### 调试技巧

1. **启用详细日志**
   ```bash
   # 构建时显示详细信息
   ./scripts/build/build-images.sh 2>&1 | tee build.log
   ```

2. **检查构建产物**
   ```bash
   # 验证所有镜像
   ./scripts/build/build-images.sh verify
   ```

3. **手动测试**
   ```bash
   # 手动测试 DMG 安装
   open JMS-Protocol-Handler-v1.0.0.dmg
   
   # 手动测试应用程序
   open JMSProtocolHandler.app
   ```

## 📈 性能优化

### 构建速度优化

- 使用并行构建: `xcodebuild -jobs $(sysctl -n hw.ncpu)`
- 启用构建缓存: 配置 DerivedData 路径
- 使用增量构建: 避免每次清理所有文件

### 镜像大小优化

- **DMG 压缩**: 使用 UDZO 格式和 zlib-level=9
- **Docker 多阶段构建**: 分离构建和运行环境
- **文件排除**: 使用 .dockerignore 排除不必要文件

## 🔄 持续集成

### GitHub Actions 示例

```yaml
name: Build Images
on: [push, pull_request]

jobs:
  build-dmg:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build DMG
        run: ./scripts/build/build-images.sh dmg
      - name: Upload DMG
        uses: actions/upload-artifact@v3
        with:
          name: dmg-installer
          path: "*.dmg"
```

## 📚 相关文档

- [部署指南](DEPLOYMENT_GUIDE.md)
- [用户安装说明](../user-guide/安装说明.txt)
- [项目结构说明](../PROJECT_STRUCTURE.md)
- [构建脚本文档](../../scripts/build/README.md)

---

**构建愉快！** 🚀

如有问题，请查看故障排除部分或联系开发团队。
