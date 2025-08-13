# JMS Protocol Handler 构建指南

## 📋 概述

本项目提供了完整的构建脚本系统，支持多种构建方式和目标平台。所有构建产物都按照规范的目录结构组织。

## 🚀 快速开始

### 方式一：使用主构建脚本（推荐）

```bash
# 在项目根目录执行
./build.sh

# 或者直接指定构建类型
./build.sh macos-app          # 规范macOS应用程序构建
./build.sh universal-app      # 通用二进制构建
```

### 方式二：直接使用专用脚本

```bash
# 规范macOS应用程序构建
./scripts/build/build-macos-app.sh --clean

# 通用二进制构建
./scripts/build/build-macos-app.sh --arch universal --clean
```

## 🏗️ 构建脚本架构

### 主要脚本

1. **`build.sh`** - 主构建脚本（项目根目录）
   - 用户友好的交互式界面
   - 快速访问所有构建选项
   - 自动调用相应的专用脚本

2. **`build-macos-app.sh`** - 规范macOS应用程序构建脚本 🆕
   - 规范的目录结构管理
   - 支持单架构和通用二进制构建
   - 完整的应用程序包创建
   - 代码签名支持

3. **`unified-build.sh`** - 统一构建脚本
   - 整合Swift Package和Xcode项目构建
   - 支持测试和打包功能

4. **`swift-compile.sh`** - Swift可执行文件编译
   - 生成命令行可执行文件
   - 支持多架构构建

## 📁 规范目录结构

新的构建系统采用规范的目录结构：

```
build/
├── temp/                    # 临时构建文件 (可删除)
│   ├── swift-build/         # Swift Package构建缓存
│   └── app-build/           # 应用程序构建临时文件
├── Release/                 # 最终发布文件
│   └── JMSProtocolHandler.app
├── Debug/                   # Debug构建文件 (如果使用debug配置)
│   └── JMSProtocolHandler.app
└── logs/                    # 构建日志
    ├── swift-build.log
    ├── swift-build.log.arm64
    └── swift-build.log.x86_64
```

## 🔧 构建选项

### 规范macOS应用程序构建

```bash
# 基本构建
./scripts/build/build-macos-app.sh

# 清理后构建
./scripts/build/build-macos-app.sh --clean

# 通用二进制构建
./scripts/build/build-macos-app.sh --arch universal

# Debug构建
./scripts/build/build-macos-app.sh --configuration debug

# 代码签名构建
./scripts/build/build-macos-app.sh --sign

# 详细输出
./scripts/build/build-macos-app.sh --verbose

# 组合使用
./scripts/build/build-macos-app.sh --clean --arch universal --sign --verbose
```

### 支持的架构

- `arm64` - Apple Silicon (M1/M2/M3)
- `x86_64` - Intel处理器
- `universal` - 通用二进制文件 (同时支持ARM64和x86_64)

### 构建配置

- `release` - 发布版本 (默认)
- `debug` - 调试版本

## 📊 构建产物

### 单架构构建

- **ARM64**: `build/Release/JMSProtocolHandler.app` (~428KB)
- **x86_64**: `build/Release/JMSProtocolHandler.app` (~432KB)

### 通用二进制构建

- **Universal**: `build/Release/JMSProtocolHandler.app` (~828KB)
- 包含ARM64和x86_64两种架构
- 在任何Mac上都能运行

## 🧪 验证构建结果

### 检查应用程序包结构

```bash
# 查看应用程序包内容
ls -la build/Release/JMSProtocolHandler.app/Contents/

# 验证二进制文件架构
lipo -info build/Release/JMSProtocolHandler.app/Contents/MacOS/JMSProtocolHandler

# 检查应用程序信息
plutil -p build/Release/JMSProtocolHandler.app/Contents/Info.plist
```

### 测试应用程序

```bash
# 直接运行
open build/Release/JMSProtocolHandler.app

# 测试协议处理
open 'jms://rdp://user:pass@host:3389'
open 'jms://ssh://user:pass@host:22'
```

## 🔄 构建流程

### 规范macOS应用程序构建流程

1. **清理阶段** (如果指定 --clean)
   - 清理临时目录
   - 清理Swift Package缓存
   - 清理输出目录

2. **目录创建阶段**
   - 创建规范目录结构
   - 设置临时文件路径
   - 准备日志目录

3. **Swift Package构建阶段**
   - 编译Swift源代码
   - 生成二进制文件
   - 支持多架构构建

4. **应用程序包创建阶段**
   - 创建.app目录结构
   - 复制可执行文件
   - 创建Info.plist
   - 复制资源文件

5. **代码签名阶段** (如果指定 --sign)
   - 查找开发者证书
   - 签名应用程序
   - 验证签名

6. **最终化阶段**
   - 移动到最终输出目录
   - 生成构建摘要
   - 清理建议

## 🛠️ 故障排除

### 常见问题

1. **构建失败**
   ```bash
   # 查看详细日志
   ./scripts/build/build-macos-app.sh --verbose
   
   # 检查构建日志
   cat build/logs/swift-build.log
   ```

2. **权限问题**
   ```bash
   # 设置脚本执行权限
   chmod +x ./scripts/build/build-macos-app.sh
   chmod +x ./build.sh
   ```

3. **磁盘空间不足**
   ```bash
   # 清理临时文件
   rm -rf build/temp
   rm -rf .build
   ```

4. **架构不匹配**
   ```bash
   # 检查当前系统架构
   uname -m
   
   # 构建通用二进制文件
   ./scripts/build/build-macos-app.sh --arch universal
   ```

### 调试模式

```bash
# 启用详细输出
./scripts/build/build-macos-app.sh --verbose

# Debug构建
./scripts/build/build-macos-app.sh --configuration debug

# 保留临时文件进行调试
# (不要使用 --clean 选项)
```

## 📈 性能优化

### 构建性能

- **增量构建**: 不使用 --clean 选项可以利用缓存
- **单架构构建**: 比通用二进制构建更快
- **并行构建**: Swift编译器自动使用多核

### 产物大小

- **单架构**: ~428KB
- **通用二进制**: ~828KB (约2倍大小)
- **压缩后**: 可减少约60-70%

## 🚀 最佳实践

### 日常开发

```bash
# 快速构建和测试
./build.sh 11  # 规范macOS应用程序构建

# 或者
./scripts/build/build-macos-app.sh
```

### 发布准备

```bash
# 完整的发布构建
./scripts/build/build-macos-app.sh --clean --arch universal --sign

# 验证构建结果
lipo -info build/Release/JMSProtocolHandler.app/Contents/MacOS/JMSProtocolHandler
codesign --verify --verbose build/Release/JMSProtocolHandler.app
```

### 持续集成

```bash
# CI/CD脚本示例
./scripts/build/build-macos-app.sh --clean --arch universal --verbose
```

## 📝 更新日志

### v1.2.0 (2025-08-13)
- ✅ 新增规范macOS应用程序构建脚本
- ✅ 规范化目录结构管理
- ✅ 支持通用二进制文件构建
- ✅ 集成代码签名功能
- ✅ 完善的构建日志系统
- ✅ 用户友好的构建摘要

### 历史版本
- v1.1.x: 基础Swift编译脚本
- v1.0.x: 初始构建支持

## 📞 支持

如果遇到构建问题：

1. 查看构建日志: `build/logs/`
2. 使用 `--verbose` 选项获取详细信息
3. 检查系统要求和依赖
4. 确保有足够的磁盘空间

---

**让构建变得简单而规范！** 🚀
