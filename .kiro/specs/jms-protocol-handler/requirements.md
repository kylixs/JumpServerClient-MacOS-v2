# Requirements Document

## Introduction

本功能旨在创建一个macOS应用程序，用于处理Chrome浏览器的自定义协议URL（jms://），自动解码URL内容，提取连接信息，并根据协议类型启动相应的连接方式：
- RDP协议：启动Microsoft Remote Desktop进行远程桌面连接
- SSH协议：通过本地终端（Terminal或iTerm2）建立SSH会话连接

整个流程需要完全自动化，避免用户手动操作。

## Requirements

### Requirement 1

**User Story:** 作为一个需要频繁远程连接的用户，我希望能够通过点击jms://协议链接自动启动相应的远程连接（RDP或SSH），这样我就不需要手动输入连接信息和选择连接工具。

#### Acceptance Criteria

1. WHEN 用户点击jms://协议的URL THEN 系统 SHALL 自动启动协议处理程序
2. WHEN 协议处理程序接收到jms://URL THEN 系统 SHALL 对URL中的base64编码内容进行解码
3. WHEN 解码完成 THEN 系统 SHALL 解析JSON格式的配置信息
4. WHEN 解析配置信息 THEN 系统 SHALL 识别协议类型（"protocol"字段：rdp或ssh）
5. WHEN 协议类型为"rdp" THEN 系统 SHALL 提取"full address:s:"后的连接地址和"username:s:"后的用户名
6. WHEN 协议类型为"ssh" THEN 系统 SHALL 解析"token"字段中的JSON格式连接信息
7. WHEN 解析token内容 THEN 系统 SHALL 提取ip、port、username、password等SSH连接参数

### Requirement 2

**User Story:** 作为用户，我希望程序能够根据协议类型自动选择合适的连接方式，支持RDP远程桌面和SSH终端连接，这样我就能够处理不同类型的远程访问需求。

#### Acceptance Criteria - RDP协议

1. WHEN 解析的协议类型为"rdp" THEN 系统 SHALL 自动启动Microsoft Remote Desktop应用程序
2. WHEN Microsoft Remote Desktop启动 THEN 系统 SHALL 创建新的RDP连接配置
3. WHEN 创建RDP连接配置 THEN 系统 SHALL 使用提取的地址和用户名
4. WHEN RDP连接配置创建完成 THEN 系统 SHALL 自动发起远程桌面连接
5. IF Microsoft Remote Desktop未安装 THEN 系统 SHALL 显示错误提示信息

#### Acceptance Criteria - SSH协议

1. WHEN 解析的协议类型为"ssh" THEN 系统 SHALL 解析token字段中的SSH连接信息
2. WHEN 解析SSH连接信息 THEN 系统 SHALL 提取ip、port、username、password字段
3. WHEN SSH信息提取完成 THEN 系统 SHALL 检测可用的终端应用程序（Terminal、iTerm2等）
4. WHEN 终端应用程序确定 THEN 系统 SHALL 构建SSH连接命令
5. WHEN SSH命令构建完成 THEN 系统 SHALL 通过AppleScript或命令行启动终端并执行SSH连接
6. IF 终端应用程序不可用 THEN 系统 SHALL 使用系统默认Terminal应用程序

### Requirement 3

**User Story:** 作为macOS用户，我希望程序能够正确注册为jms://协议的默认处理程序，这样系统就能够自动调用我的程序处理这类链接。

#### Acceptance Criteria

1. WHEN 程序首次运行 THEN 系统 SHALL 注册jms://协议处理程序
2. WHEN 协议注册完成 THEN 系统 SHALL 在macOS系统中设置为jms://的默认处理程序
3. WHEN 用户在浏览器中点击jms://链接 THEN 系统 SHALL 自动调用注册的处理程序
4. WHEN 程序被系统调用 THEN 系统 SHALL 接收完整的URL参数

### Requirement 4

**User Story:** 作为用户，我希望程序能够处理各种异常情况并提供清晰的错误信息，这样我就能够了解连接失败的原因。

#### Acceptance Criteria

1. WHEN URL格式不正确 THEN 系统 SHALL 显示"URL格式错误"的提示信息
2. WHEN base64解码失败 THEN 系统 SHALL 显示"解码失败"的错误信息
3. WHEN JSON解析失败 THEN 系统 SHALL 显示"配置信息格式错误"的提示
4. WHEN 无法提取必要的连接信息 THEN 系统 SHALL 显示"连接信息不完整"的错误
5. WHEN Microsoft Remote Desktop启动失败 THEN 系统 SHALL 显示相应的错误信息并提供解决建议

### Requirement 5

**User Story:** 作为macOS M4芯片用户，我希望程序能够在我的设备上高效运行，并且兼容最新的macOS系统。

#### Acceptance Criteria

1. WHEN 程序运行在macOS M4芯片设备上 THEN 系统 SHALL 正常执行所有功能
2. WHEN 程序启动 THEN 系统 SHALL 在3秒内完成初始化
3. WHEN 处理URL THEN 系统 SHALL 在1秒内完成解码和解析
4. WHEN 启动Remote Desktop THEN 系统 SHALL 在5秒内完成应用程序启动
### Requirement 6

**User Story:** 作为macOS用户，我希望程序能够智能选择和配置终端应用程序来建立SSH连接，支持多种终端工具并提供良好的用户体验。

#### Acceptance Criteria

1. WHEN 需要建立SSH连接 THEN 系统 SHALL 按优先级检测可用终端：iTerm2 > Terminal
2. WHEN 检测到iTerm2 THEN 系统 SHALL 优先使用iTerm2建立SSH会话
3. WHEN iTerm2不可用且检测到Terminal THEN 系统 SHALL 使用系统默认Terminal
4. WHEN 构建SSH命令 THEN 系统 SHALL 包含自动密码输入功能（使用expect或sshpass）
5. WHEN SSH连接建立 THEN 系统 SHALL 在终端窗口中显示连接状态
6. WHEN SSH连接失败 THEN 系统 SHALL 在终端中显示错误信息和重试选项
7. IF 所有终端应用程序都不可用 THEN 系统 SHALL 显示"无法找到可用终端"错误信息

### Requirement 7

**User Story:** 作为用户，我希望SSH连接能够自动处理密码认证，避免手动输入密码的繁琐过程。

#### Acceptance Criteria

1. WHEN SSH连接包含密码信息 THEN 系统 SHALL 使用expect脚本自动输入密码
2. WHEN 构建expect脚本 THEN 系统 SHALL 包含连接超时处理
3. WHEN 密码认证成功 THEN 系统 SHALL 建立交互式SSH会话
4. WHEN 密码认证失败 THEN 系统 SHALL 显示认证错误信息
5. WHEN SSH连接超时 THEN 系统 SHALL 显示连接超时错误并提供重试选项
6. IF expect工具不可用 THEN 系统 SHALL 提示用户手动输入密码