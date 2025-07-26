# JMS:// 协议注册指南

## 概述
本指南将帮助您在 macOS 系统上正确注册 `jms://` 协议，使其能够被 JMSProtocolHandler 应用程序处理。

## 前提条件
- macOS 10.15 (Catalina) 或更高版本
- JMSProtocolHandler.app 已安装到 `/Applications/` 目录
- 管理员权限（某些操作可能需要）

## 方法1：自动注册（推荐）

### 步骤1：安装应用程序
```bash
# 将应用程序复制到Applications目录
cp -R JMSProtocolHandler.app /Applications/

# 或者拖拽DMG中的应用程序到Applications文件夹
open JMS-Protocol-Handler-v1.0.0.dmg
```

### 步骤2：首次运行
```bash
# 首次运行应用程序（这会自动注册协议）
open /Applications/JMSProtocolHandler.app
```

### 步骤3：使用注册脚本
```bash
# 运行自动注册脚本
./register_jms_protocol.sh
```

## 方法2：手动注册

### 步骤1：使用 lsregister 命令
```bash
# 注册应用程序和协议
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R -trusted /Applications/JMSProtocolHandler.app
```

### 步骤2：重建 Launch Services 数据库
```bash
# 重建数据库
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -kill -r -domain local -domain system -domain user
```

### 步骤3：设置默认处理程序
```bash
# 添加协议处理程序配置
defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerURLScheme=jms;LSHandlerRoleAll=com.jms.protocolhandler;}'
```

## 方法3：通过系统偏好设置

### 步骤1：打开系统偏好设置
1. 点击 Apple 菜单 → 系统偏好设置
2. 选择"通用"
3. 找到"默认网页浏览器"附近的设置

### 步骤2：设置协议处理程序
1. 创建一个测试 jms:// 链接
2. 在浏览器中访问该链接
3. 系统会提示选择应用程序
4. 选择 JMSProtocolHandler 并设为默认

## 验证注册状态

### 检查协议注册
```bash
# 查看当前注册的协议处理程序
defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers | grep -A 5 -B 5 jms
```

### 测试协议功能
```bash
# 运行测试脚本
./test_jms_protocol.sh

# 或手动测试
open "jms://eyJjb25maWciOiJ0ZXN0In0="
```

### 检查应用程序状态
```bash
# 检查应用程序是否在运行
ps aux | grep JMSProtocolHandler | grep -v grep
```

## 常见问题和解决方案

### 问题1：协议未注册
**症状**: 点击 jms:// 链接时没有反应或提示找不到应用程序

**解决方案**:
```bash
# 重新注册应用程序
./register_jms_protocol.sh

# 重启系统
sudo reboot
```

### 问题2：协议注册到错误的应用程序
**症状**: jms:// 链接被其他应用程序处理

**解决方案**:
```bash
# 强制重新设置处理程序
defaults delete com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers
defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerURLScheme=jms;LSHandlerRoleAll=com.jms.protocolhandler;}'

# 重建Launch Services数据库
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -kill -r -domain local -domain system -domain user
```

### 问题3：权限问题
**症状**: 注册命令执行失败或权限被拒绝

**解决方案**:
```bash
# 使用管理员权限
sudo ./register_jms_protocol.sh

# 或者给应用程序添加执行权限
chmod +x /Applications/JMSProtocolHandler.app/Contents/MacOS/JMSProtocolHandler
```

### 问题4：应用程序无法启动
**症状**: 协议注册成功但应用程序无法启动

**解决方案**:
```bash
# 检查应用程序完整性
codesign -v /Applications/JMSProtocolHandler.app

# 重新安装应用程序
rm -rf /Applications/JMSProtocolHandler.app
cp -R JMSProtocolHandler.app /Applications/

# 重新注册
./register_jms_protocol.sh
```

## 测试协议注册

### 创建测试URL
```bash
# 生成测试URL
TEST_CONFIG='{"config":"full address:s:test.server.com:3389\nusername:s:testuser"}'
TEST_URL="jms://$(echo -n "$TEST_CONFIG" | base64)"
echo $TEST_URL
```

### 测试方法
1. **浏览器测试**: 在浏览器地址栏输入测试URL
2. **命令行测试**: 使用 `open` 命令打开URL
3. **脚本测试**: 运行 `./test_jms_protocol.sh`

### 预期结果
1. 系统提示选择应用程序打开jms://链接
2. 选择JMSProtocolHandler后应用程序启动
3. 应用程序解析URL并显示连接信息
4. 如果安装了Microsoft Remote Desktop，尝试启动连接

## 故障排除步骤

### 1. 基本检查
```bash
# 检查应用程序是否存在
ls -la /Applications/JMSProtocolHandler.app

# 检查应用程序信息
defaults read /Applications/JMSProtocolHandler.app/Contents/Info.plist CFBundleIdentifier
```

### 2. 重新注册
```bash
# 完全重新注册
./register_jms_protocol.sh
```

### 3. 系统重启
```bash
# 重启系统以确保所有更改生效
sudo reboot
```

### 4. 手动设置
如果自动方法都失败，可以尝试：
1. 在Finder中右键点击jms://链接
2. 选择"打开方式" → "其他"
3. 选择JMSProtocolHandler.app
4. 勾选"始终以此方式打开"

## 高级配置

### 自定义协议处理
如果需要自定义协议处理行为，可以修改应用程序的Info.plist文件：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>JMS Protocol Handler</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>jms</string>
        </array>
        <key>LSHandlerRank</key>
        <string>Owner</string>
        <key>CFBundleTypeRole</key>
        <string>Viewer</string>
    </dict>
</array>
```

### 批量部署
对于企业环境的批量部署：

```bash
#!/bin/bash
# 批量部署脚本

# 安装应用程序
cp -R JMSProtocolHandler.app /Applications/

# 注册协议
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R -trusted /Applications/JMSProtocolHandler.app

# 设置默认处理程序
defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerURLScheme=jms;LSHandlerRoleAll=com.jms.protocolhandler;}'

echo "JMS协议注册完成"
```

## 支持和帮助

如果遇到问题，请：
1. 查看应用程序日志
2. 运行诊断脚本
3. 检查系统兼容性
4. 联系技术支持

---
**注意**: 某些操作可能需要管理员权限，请确保您有足够的权限执行这些命令。
