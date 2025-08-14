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
2. WHEN 接收到jms://协议请求 THEN 系统 SHALL 重新加载最新的RDP配置文件参数
3. WHEN 重新加载RDP配置 THEN 系统 SHALL 使用用户在RDP设置界面中保存的最新配置（包括HiDPI、分辨率、质量设置等）
4. WHEN Microsoft Remote Desktop启动 THEN 系统 SHALL 创建新的RDP连接配置
5. WHEN 创建RDP连接配置 THEN 系统 SHALL 使用提取的地址和用户名，并应用最新的RDP参数设置
6. WHEN RDP连接配置创建完成 THEN 系统 SHALL 自动发起远程桌面连接
7. IF Microsoft Remote Desktop未安装 THEN 系统 SHALL 显示错误提示信息

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

### Requirement 8

**User Story:** 作为使用高分辨率显示器和多显示器设置的用户，我希望RDP连接能够提供清晰的显示效果，自动适配我的显示器配置，这样我就能获得最佳的远程桌面体验。

#### Acceptance Criteria - 显示器检测和配置

1. WHEN 建立RDP连接 THEN 系统 SHALL 自动检测当前主显示器的分辨率和DPI设置
2. WHEN 检测到HiDPI显示器（Retina） THEN 系统 SHALL 启用高DPI感知模式
3. WHEN 检测到多显示器环境 THEN 系统 SHALL 使用主显示器的配置作为RDP显示基准
4. WHEN 显示器分辨率超过4K THEN 系统 SHALL 智能调整RDP分辨率以平衡性能和清晰度
5. WHEN 显示器DPI缩放比例不是100% THEN 系统 SHALL 相应调整RDP的DPI设置

#### Acceptance Criteria - RDP显示参数优化

1. WHEN 配置RDP连接 THEN 系统 SHALL 根据显示器特性设置最优的颜色深度
2. WHEN HiDPI显示器被检测到 THEN 系统 SHALL 设置`desktopscalefactor:i:` 参数匹配系统缩放
3. WHEN 建立RDP连接 THEN 系统 SHALL 启用`smart sizing:i:1` 以支持动态分辨率调整
4. WHEN 显示器支持高刷新率 THEN 系统 SHALL 优化RDP显示刷新设置
5. WHEN 用户使用外接显示器 THEN 系统 SHALL 检测并使用外接显示器的原生分辨率

#### Acceptance Criteria - 动态配置调整

1. WHEN 用户在RDP会话中调整窗口大小 THEN 系统 SHALL 支持动态分辨率调整
2. WHEN 检测到显示器配置变化 THEN 系统 SHALL 提供重新连接选项以应用新设置
3. WHEN RDP连接质量下降 THEN 系统 SHALL 自动调整显示参数以维持流畅体验
4. WHEN 用户切换显示器 THEN 系统 SHALL 检测新的显示器配置并相应调整
5. IF 显示器检测失败 THEN 系统 SHALL 使用安全的默认高质量配置

### Requirement 9

**User Story:** 作为开发者和系统管理员，我希望能够根据不同的使用场景自定义RDP显示配置，这样我就能在性能和质量之间找到最佳平衡。

#### Acceptance Criteria - 配置文件增强

1. WHEN 生成RDP配置文件 THEN 系统 SHALL 包含完整的显示优化参数集
2. WHEN 用户需要最佳性能 THEN 系统 SHALL 提供性能优化的配置选项
3. WHEN 用户需要最佳质量 THEN 系统 SHALL 提供质量优化的配置选项
4. WHEN 配置RDP参数 THEN 系统 SHALL 支持自定义显示配置的扩展
5. WHEN 应用程序启动 THEN 系统 SHALL 使用全局配置的压缩和质量参数

### Requirement 10

**User Story:** 作为开发者和测试人员，我希望能够自动验证RDP设置GUI界面的正确性，包括界面组件的层级结构、位置布局、内容显示等，这样我就能确保用户界面的质量和一致性。

#### Acceptance Criteria - GUI组件层级树生成

1. WHEN 启动RDP设置界面 THEN 系统 SHALL 能够生成完整的界面组件层级树
2. WHEN 生成组件层级树 THEN 系统 SHALL 包含每个组件的类型、位置、大小、zIndex等属性信息
3. WHEN 组件层级树生成完成 THEN 系统 SHALL 包含所有控件的内容信息（文本、标签、状态等）
4. WHEN 界面组件发生变化 THEN 系统 SHALL 能够检测并更新组件层级树信息
5. WHEN 组件层级树导出 THEN 系统 SHALL 以结构化格式（JSON/XML）保存到临时文件

#### Acceptance Criteria - GUI自动化验证和测试

1. WHEN 执行GUI验证测试 THEN 系统 SHALL 自动启动配置界面并生成组件层级树
2. WHEN 组件层级树生成 THEN 系统 SHALL 验证关键UI组件的存在性、布局正确性和内容准确性
3. WHEN 验证RDP设置界面 THEN 系统 SHALL 检查设置选项和控件的正确性
4. WHEN 运行单元测试 THEN 系统 SHALL 包含完整的GUI验证自动化测试用例并生成详细验证报告
5. WHEN 发现UI问题或测试失败 THEN 系统 SHALL 记录具体错误信息、失败原因和修复建议
### Requirement 11

**User Story:** 作为用户，我希望在RDP设置界面中能够手动配置分辨率和HiDPI选项，包括多显示器支持和精确的缩放因子控制，这样我就能根据不同的使用场景、网络条件和显示器环境自定义最适合的显示设置。

#### Acceptance Criteria - 分辨率设置选项

1. WHEN 打开RDP设置界面 THEN 系统 SHALL 显示分辨率配置选项区域
2. WHEN 用户查看分辨率选项 THEN 系统 SHALL 提供以下预设分辨率选择：
   - 1920×1080 (Full HD)
   - 2560×1440 (2K)
   - 3840×2160 (4K)
   - 自定义分辨率
3. WHEN 用户选择"自定义分辨率" THEN 系统 SHALL 显示宽度和高度输入框
4. WHEN 用户输入自定义分辨率 THEN 系统 SHALL 验证输入值的有效性（范围：800×600 到 7680×4320）
5. WHEN 分辨率设置变更 THEN 系统 SHALL 实时显示预计的显示效果和带宽需求
6. WHEN 用户点击"自动检测" THEN 系统 SHALL 检测当前选定显示器的分辨率并自动填入

#### Acceptance Criteria - 多显示器支持

1. WHEN RDP设置界面加载 THEN 系统 SHALL 自动检测所有连接的显示器并显示显示器列表
2. WHEN 检测到多个显示器 THEN 系统 SHALL 提供显示器选择下拉菜单，包含以下信息：
   - 显示器编号和名称（如：显示器1 - 内置Retina显示器）
   - 显示器分辨率和类型（如：3024×1964 HiDPI）
   - 当前缩放设置（如：缩放 2.0x）
3. WHEN 用户选择不同的显示器 THEN 系统 SHALL 自动执行以下操作：
   - 更新分辨率设置为该显示器的原生分辨率
   - 自动设置该显示器的HiDPI缩放因子
   - 更新显示器信息显示
   - 刷新推荐配置
4. WHEN 显示器配置发生变化（连接/断开显示器）THEN 系统 SHALL 自动重新检测并更新显示器列表
5. WHEN 用户点击"刷新显示器" THEN 系统 SHALL 重新扫描所有显示器并更新列表

#### Acceptance Criteria - HiDPI/缩放设置选项

1. WHEN 打开RDP设置界面 THEN 系统 SHALL 显示HiDPI和缩放配置选项
2. WHEN 用户查看HiDPI选项 THEN 系统 SHALL 提供以下设置：
   - HiDPI支持开关（启用/禁用）
   - 预设缩放因子选择（100%, 125%, 150%, 175%, 200%, 250%, 300%）
   - 自定义缩放因子输入框（支持精确到0.01的小数值）
   - DPI感知模式（系统DPI感知/每显示器DPI感知/DPI不感知）
3. WHEN 用户选择"自定义缩放因子" THEN 系统 SHALL 显示数值输入框，支持以下功能：
   - 输入范围：0.50 到 5.00
   - 精度：支持两位小数（如：1.25, 2.33）
   - 实时验证：输入时即时验证数值有效性
   - 智能建议：根据显示器DPI提供推荐值
4. WHEN 检测到Retina显示器 THEN 系统 SHALL 默认启用HiDPI支持并推荐合适的缩放因子
5. WHEN 用户启用HiDPI支持 THEN 系统 SHALL 显示相关的高级选项（字体平滑、子像素渲染等）
6. WHEN HiDPI设置变更 THEN 系统 SHALL 自动调整相关的RDP参数（desktopscalefactor等）
7. WHEN 用户输入自定义缩放因子 THEN 系统 SHALL 实时显示以下信息：
   - 等效百分比（如：1.25 = 125%）
   - 预计显示效果（如：文字大小、界面缩放）
   - 兼容性提示（如：推荐用于高DPI显示器）

#### Acceptance Criteria - 显示器检测和推荐

1. WHEN RDP设置界面加载 THEN 系统 SHALL 自动检测当前显示器配置并显示检测结果
2. WHEN 显示器检测完成 THEN 系统 SHALL 显示以下信息：
   - 当前选定显示器的分辨率和DPI
   - 是否为HiDPI显示器
   - 当前系统缩放设置
   - 推荐的RDP配置
3. WHEN 用户点击"应用推荐设置" THEN 系统 SHALL 自动配置最优的分辨率和HiDPI参数
4. WHEN 检测到多显示器 THEN 系统 SHALL 显示所有显示器信息并允许用户选择目标显示器
5. WHEN 显示器配置发生变化 THEN 系统 SHALL 提供"重新检测"按钮更新显示器信息
6. WHEN 用户切换显示器选择 THEN 系统 SHALL 自动应用该显示器的最佳配置

#### Acceptance Criteria - 智能配置建议

1. WHEN 系统检测到不同类型的显示器 THEN 系统 SHALL 提供相应的配置建议：
   - 内置Retina显示器：推荐2.0x缩放，启用HiDPI
   - 外接4K显示器：推荐1.5x-2.0x缩放，根据尺寸调整
   - 标准1080p显示器：推荐1.0x缩放，禁用HiDPI
   - 超宽显示器：推荐原生分辨率，1.0x-1.25x缩放
2. WHEN 用户选择不同的显示器 THEN 系统 SHALL 自动更新配置建议
3. WHEN 检测到显示器DPI THEN 系统 SHALL 计算并推荐最佳缩放因子：
   - DPI < 120：推荐1.0x缩放
   - DPI 120-150：推荐1.25x缩放
   - DPI 150-200：推荐1.5x缩放
   - DPI > 200：推荐2.0x或更高缩放

#### Acceptance Criteria - 高级显示选项

1. WHEN 用户展开高级选项 THEN 系统 SHALL 显示以下额外设置：
   - 颜色深度选择（16位/24位/32位）
   - 刷新率设置（30Hz/60Hz/自动）
   - 压缩级别（无压缩/低/中/高）
   - 显示优化选项（性能优先/平衡/质量优先）
2. WHEN 用户修改高级选项 THEN 系统 SHALL 显示每个选项对性能和质量的影响
3. WHEN 用户选择"性能优先" THEN 系统 SHALL 自动配置低延迟、高压缩的参数组合
4. WHEN 用户选择"质量优先" THEN 系统 SHALL 自动配置高质量、低压缩的参数组合
5. WHEN 用户选择"平衡模式" THEN 系统 SHALL 自动配置性能和质量平衡的参数组合

#### Acceptance Criteria - 用户体验优化

1. WHEN 用户进行任何显示器或缩放设置变更 THEN 系统 SHALL 提供实时预览功能：
   - 显示预计的桌面大小
   - 显示文字和界面元素的相对大小
   - 显示带宽需求变化
2. WHEN 用户输入无效的缩放因子 THEN 系统 SHALL 显示友好的错误提示和建议值
3. WHEN 系统检测到潜在的兼容性问题 THEN 系统 SHALL 显示警告信息和解决建议
4. WHEN 用户保存设置 THEN 系统 SHALL 验证所有参数的兼容性并提供确认对话框

### Requirement 12

**User Story:** 作为系统管理员，我希望RDP设置界面能够提供配置导入导出功能，这样我就能在多台设备间共享配置或为不同用户场景创建配置模板。

#### Acceptance Criteria - 配置管理功能

1. WHEN 用户在RDP设置界面中 THEN 系统 SHALL 提供"导出配置"和"导入配置"按钮
2. WHEN 用户点击"导出配置" THEN 系统 SHALL 将当前所有RDP设置（包括分辨率、HiDPI、高级选项）保存为JSON文件
3. WHEN 用户点击"导入配置" THEN 系统 SHALL 允许用户选择配置文件并加载设置
4. WHEN 导入配置文件 THEN 系统 SHALL 验证文件格式和参数有效性
5. WHEN 配置导入成功 THEN 系统 SHALL 更新界面显示并应用新的设置
6. WHEN 配置导入失败 THEN 系统 SHALL 显示详细的错误信息和修复建议

#### Acceptance Criteria - 配置模板和预设

1. WHEN RDP设置界面加载 THEN 系统 SHALL 提供内置的配置模板选择
2. WHEN 用户查看配置模板 THEN 系统 SHALL 提供以下预设模板：
   - "办公环境" - 平衡性能和质量，适合日常办公
   - "设计工作" - 高质量显示，适合图形设计工作
   - "移动网络" - 低带宽优化，适合移动网络环境
   - "高性能" - 最大性能优化，适合游戏或实时应用
3. WHEN 用户选择配置模板 THEN 系统 SHALL 自动应用相应的分辨率、HiDPI和高级参数设置
4. WHEN 用户修改模板设置 THEN 系统 SHALL 允许用户保存为自定义模板
5. WHEN 用户创建自定义模板 THEN 系统 SHALL 允许用户命名并保存配置供后续使用