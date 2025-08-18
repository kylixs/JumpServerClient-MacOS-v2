# DMG 程序包构建说明

## 🚀 快速构建

```bash
# 在项目根目录执行
./create_dmg.sh
```

## 📦 生成的DMG包内容

```
JMS-Protocol-Handler-v1.2.0.dmg
├── JMSProtocolHandler.app          # 主应用程序
├── Applications (快捷方式)          # 安装目标文件夹
├── Scripts/                        # JMS协议管理脚本
│   ├── register_jms_protocol.sh    # 注册协议处理器
│   ├── check_jms_protocol.py       # 检查协议状态
│   ├── cleanup_jms_handlers.py     # 清理无效处理器
│   └── 卸载脚本.sh                  # 完全卸载程序
├── 使用说明.txt                     # 详细使用指南
└── README.md                       # 项目说明
```

## 🔧 构建流程

1. **应用程序构建**: 使用现有 `build.sh --clean` 构建app
2. **目录结构创建**: 创建DMG临时目录结构
3. **文件复制**: 复制app、脚本和文档
4. **权限设置**: 设置脚本执行权限
5. **DMG创建**: 使用hdiutil创建压缩DMG文件
6. **清理**: 删除临时文件

## 📊 构建结果

- **DMG文件**: `JMS-Protocol-Handler-v1.2.0.dmg`
- **文件大小**: ~372KB (高度压缩)
- **包含内容**: 应用程序 + 脚本 + 文档
- **构建时间**: ~15秒

## 💡 使用场景

### 开发测试
```bash
./create_dmg.sh
# 生成DMG用于本地测试
```

### 正式发布
```bash
./create_dmg.sh
# 生成DMG用于分发给用户
```

## 🎯 用户安装流程

1. **挂载DMG**: 双击 `JMS-Protocol-Handler-v1.2.0.dmg`
2. **安装应用**: 拖拽 `JMSProtocolHandler.app` 到 `Applications` 文件夹
3. **注册协议**: 运行 `Scripts/register_jms_protocol.sh`
4. **验证安装**: 运行 `python3 Scripts/check_jms_protocol.py`

## 🔍 技术细节

### 依赖项
- 现有的 `build.sh` 脚本
- `hdiutil` 工具 (macOS自带)
- JMS协议脚本 (scripts/deployment/)

### 自动化特性
- 自动使用现有构建系统
- 自动复制所有必要文件
- 自动设置脚本权限
- 自动创建使用文档
- 自动清理临时文件

### 错误处理
- 检查构建脚本存在性
- 验证应用程序构建成功
- 处理脚本文件缺失情况
- 提供详细的错误信息

## 📋 维护说明

### 更新版本号
编辑 `create_dmg.sh` 中的版本信息：
```bash
VERSION="1.2.0"  # 更新这里
```

### 添加新脚本
将新脚本放入 `scripts/deployment/` 目录，构建脚本会自动包含。

### 修改文档
编辑 `create_dmg.sh` 中的文档模板部分。

---

**简单 • 高效 • 专业** 🚀
