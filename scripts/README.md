# 🔧 JMS Protocol Handler 脚本

本目录包含 JMS Protocol Handler 项目的所有脚本文件。

## 📁 目录结构

### 🏗️ build/ - 构建脚本
用于构建和打包应用程序的脚本。

**文件列表**:
- `create_dmg.sh` - 创建 DMG 安装包
- `create_pkg.sh` - 创建 PKG 安装包
- `clean.sh` - 清理构建文件和缓存

### 🚀 deployment/ - 部署脚本
用于部署、安装和配置应用程序的脚本。

**文件列表**:
- `register_jms_protocol.sh` - 注册 jms:// 协议处理程序
- `deploy_package.swift` - 应用程序打包和部署准备
- `卸载脚本.sh` - 卸载应用程序和清理系统

### 🧪 test/ - 测试脚本
用于测试和验证应用程序功能的脚本。

**文件列表**:
- `test_jms_protocol.sh` - 测试 jms:// 协议注册和功能

## 🔧 脚本使用指南

### 构建应用程序
```bash
# 创建 DMG 安装包
./scripts/build/create_dmg.sh

# 创建 PKG 安装包
./scripts/build/create_pkg.sh

# 清理构建文件
./scripts/build/clean.sh
```

### 部署应用程序
```bash
# 注册 jms:// 协议
./scripts/deployment/register_jms_protocol.sh

# 准备部署包
swift scripts/deployment/deploy_package.swift
```

### 测试功能
```bash
# 测试协议注册
./scripts/test/test_jms_protocol.sh
```

### 卸载应用程序
```bash
# 卸载应用程序
./scripts/deployment/卸载脚本.sh
```

## 📋 脚本详细说明

### register_jms_protocol.sh
**功能**: 在 macOS 系统上注册 jms:// 协议处理程序
**用法**: `./register_jms_protocol.sh`
**要求**: 应用程序已安装到 /Applications/ 目录

**主要功能**:
- 检查应用程序安装状态
- 使用 lsregister 注册协议
- 验证注册结果
- 提供故障排除建议

### test_jms_protocol.sh
**功能**: 测试 jms:// 协议是否正确注册和工作
**用法**: `./test_jms_protocol.sh`

**测试内容**:
- 生成测试 URL
- 检查协议处理程序
- 自动测试协议功能
- 验证应用程序启动

### deploy_package.swift
**功能**: 准备应用程序部署包
**用法**: `swift deploy_package.swift`

**主要功能**:
- 检查开发环境
- 配置应用程序签名
- 创建安装包脚本
- 生成用户文档

### 卸载脚本.sh
**功能**: 完全卸载应用程序和清理系统
**用法**: `./卸载脚本.sh`

**清理内容**:
- 删除应用程序文件
- 清理用户数据
- 清理临时文件
- 重置协议处理程序

## ⚠️ 使用注意事项

### 权限要求
- 某些脚本可能需要管理员权限
- 协议注册需要系统级权限
- 建议在执行前检查脚本内容

### 系统兼容性
- 所有脚本针对 macOS 10.15+ 设计
- 在不同系统版本上可能需要调整
- Apple Silicon 和 Intel 架构都支持

### 安全考虑
- 脚本会修改系统设置
- 建议在测试环境中先验证
- 保留系统备份以防意外

## 🔍 故障排除

### 脚本执行失败
```bash
# 检查脚本权限
ls -la scripts/

# 添加执行权限
chmod +x scripts/**/*.sh

# 检查系统兼容性
sw_vers
```

### 协议注册失败
```bash
# 手动重新注册
sudo ./scripts/deployment/register_jms_protocol.sh

# 重建 Launch Services 数据库
sudo /System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -kill -r -domain local -domain system -domain user
```

### 测试失败
```bash
# 检查应用程序状态
ps aux | grep JMSProtocolHandler

# 检查协议注册
defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers | grep jms
```

## 📝 脚本维护

### 添加新脚本
1. 选择合适的子目录 (build/deployment/test)
2. 添加适当的文档注释
3. 设置正确的执行权限
4. 更新此 README 文件

### 修改现有脚本
1. 保持向后兼容性
2. 更新相关文档
3. 进行充分测试
4. 更新版本信息

---
**脚本版本**: 1.0  
**最后更新**: 2025-07-25  
**兼容性**: macOS 10.15+
