# 端到端测试 (E2E Tests)

本目录包含JMS Protocol Handler的端到端测试脚本，用于测试完整的用户场景和系统集成。

## 测试脚本

### 1. test_first_launch.sh
**第一次启动测试**

测试第一次点击jms链接时的URL处理机制，验证应用程序能否正确处理首次启动时的URL事件。

```bash
# 运行测试
./test_first_launch.sh

# 显示详细日志
./test_first_launch.sh --verbose
```

**测试内容：**
- 应用程序生命周期管理
- URL事件处理机制
- URL缓存和延迟处理
- RDP连接完整流程

**预期结果：**
- ✅ applicationWillFinishLaunching 被调用
- ✅ handleURLEvent 被调用
- ✅ URL缓存机制工作正常
- ✅ RDP连接启动成功

### 2. test_rdp_url_debug.sh
**RDP URL调试测试**

用于调试RDP URL处理的完整流程，检查每个处理步骤的状态。

```bash
# 运行调试测试
./test_rdp_url_debug.sh

# 显示详细日志
./test_rdp_url_debug.sh --verbose

# 显示配置文件内容
./test_rdp_url_debug.sh --show-config
```

**测试内容：**
- URL解析和解码
- 连接信息提取
- RDP配置生成
- Microsoft Remote Desktop集成
- 临时文件管理

**检查项目：**
- URL处理流程完整性
- RDP配置文件生成
- Microsoft Remote Desktop安装状态
- 错误处理和日志记录

## 使用方法

### 前置条件

1. **构建应用程序**
   ```bash
   cd /Users/gongdewei/work/projects/jumpserver-client
   ./build.sh
   ```

2. **测试URL文件**
   确保存在测试URL文件：`scripts/test/test_rdp_url.txt`

3. **权限设置**
   ```bash
   chmod +x tests/e2e/*.sh
   ```

### 运行测试

```bash
# 进入测试目录
cd tests/e2e

# 运行第一次启动测试
./test_first_launch.sh

# 运行RDP调试测试
./test_rdp_url_debug.sh
```

### 测试结果

测试脚本会输出详细的测试结果，包括：
- ✅ 成功的测试项目
- ❌ 失败的测试项目
- 📊 详细的状态信息
- 📄 相关日志内容

## 故障排除

### 常见问题

1. **应用程序未安装**
   ```bash
   # 重新构建并安装
   ./build.sh
   cp -R build/Release/JMSProtocolHandler.app /Applications/
   ```

2. **协议注册失败**
   ```bash
   # 重新注册协议
   /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f /Applications/JMSProtocolHandler.app
   ```

3. **Microsoft Remote Desktop未安装**
   - 从Mac App Store安装Microsoft Remote Desktop
   - 或者修改测试以跳过实际的RDP启动

### 日志文件

测试过程中的日志文件位置：
- 应用程序日志：`~/Documents/JMSProtocolHandler.log`
- RDP配置文件：`/tmp/JMSProtocolHandler/*.rdp`
- RDP设置文件：`~/Documents/JMSRDPSettings.json`

## 扩展测试

可以基于现有脚本创建更多测试场景：

1. **SSH连接测试**
2. **错误处理测试**
3. **性能测试**
4. **多URL并发测试**
5. **配置文件测试**

## 注意事项

- 测试脚本会清理之前的日志和临时文件
- 某些测试需要重启应用程序
- 测试过程中可能会看到应用程序在Dock中出现
- 建议在测试环境中运行，避免影响正常使用
