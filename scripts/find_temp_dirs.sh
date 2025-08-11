#!/bin/bash

# JMS Protocol Handler 临时目录查找脚本
# 用法: ./find_temp_dirs.sh

echo "=== macOS 临时目录查找工具 ==="
echo

# 1. 系统临时目录
echo "📁 系统临时目录:"
echo "   TMPDIR: $TMPDIR"
echo "   getconf: $(getconf DARWIN_USER_TEMP_DIR 2>/dev/null || echo '未找到')"
echo

# 2. Swift FileManager 临时目录
echo "📁 Swift FileManager 临时目录:"
SWIFT_TEMP=$(swift -e "import Foundation; print(FileManager.default.temporaryDirectory.path)" 2>/dev/null || echo "Swift未安装")
echo "   路径: $SWIFT_TEMP"
echo

# 3. JMSProtocolHandler 专用目录
echo "📁 JMSProtocolHandler 临时目录:"
JMS_TEMP_DIR="$TMPDIR/JMSProtocolHandler"
echo "   路径: $JMS_TEMP_DIR"

if [ -d "$JMS_TEMP_DIR" ]; then
    echo "   状态: ✅ 存在"
    
    # 统计RDP文件数量
    RDP_COUNT=$(find "$JMS_TEMP_DIR" -name "*.rdp" 2>/dev/null | wc -l | tr -d ' ')
    echo "   RDP文件: $RDP_COUNT 个"
    
    # 显示目录内容
    echo "   内容:"
    ls -la "$JMS_TEMP_DIR" 2>/dev/null | while read line; do
        echo "     $line"
    done
    
    # 显示最近的RDP文件
    LATEST_RDP=$(find "$JMS_TEMP_DIR" -name "*.rdp" -type f -exec ls -t {} + 2>/dev/null | head -1)
    if [ -n "$LATEST_RDP" ]; then
        echo "   最新RDP: $(basename "$LATEST_RDP")"
        echo "   创建时间: $(stat -f "%Sm" "$LATEST_RDP" 2>/dev/null || echo '未知')"
    fi
else
    echo "   状态: ❌ 不存在（应用未运行或已清理）"
fi
echo

# 4. 查找所有可能的RDP临时文件
echo "📁 查找所有RDP临时文件:"
RDP_FILES=$(find "$TMPDIR" -name "jms_connection_*.rdp" 2>/dev/null)
if [ -n "$RDP_FILES" ]; then
    echo "$RDP_FILES" | while read file; do
        echo "   找到: $file"
        echo "   大小: $(stat -f "%z bytes" "$file" 2>/dev/null || echo '未知')"
    done
else
    echo "   未找到任何RDP临时文件"
fi
echo

# 5. 临时目录使用情况
echo "📊 临时目录使用情况:"
if [ -d "$TMPDIR" ]; then
    TEMP_SIZE=$(du -sh "$TMPDIR" 2>/dev/null | cut -f1)
    TEMP_FILES=$(find "$TMPDIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "   总大小: $TEMP_SIZE"
    echo "   文件数: $TEMP_FILES 个"
fi
echo

# 6. 快速访问命令
echo "🚀 快速访问命令:"
echo "   打开临时目录: open \"$TMPDIR\""
echo "   进入临时目录: cd \"$TMPDIR\""
echo "   查看JMS目录: ls -la \"$JMS_TEMP_DIR\""
echo "   清理RDP文件: find \"$TMPDIR\" -name \"jms_connection_*.rdp\" -delete"
echo

echo "=== 查找完成 ==="
