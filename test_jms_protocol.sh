#!/bin/bash

# JMS协议测试脚本

echo "🧪 JMS协议测试脚本"
echo "=================="

# 创建测试RDP配置 - 修复：添加完整的用户名
TEST_CONFIG='{
    "protocol": "rdp",
    "config": "full address:s:test.server.com:3389\\nusername:s:testuser\\nsession bpp:i:32\\naudiomode:i:0"
}'

# Base64编码
ENCODED=$(echo -n "$TEST_CONFIG" | base64)
TEST_URL="jms://$ENCODED"

echo "📝 测试URL: $TEST_URL"
echo ""

# 检查应用程序是否存在
APP_PATH="/Applications/JMSProtocolHandler.app"
if [ ! -d "$APP_PATH" ]; then
    echo "❌ 应用程序不存在: $APP_PATH"
    exit 1
fi

echo "✅ 应用程序存在: $APP_PATH"

# 检查协议注册
echo "🔍 检查协议注册状态..."
HANDLER=$(defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers | grep -A 3 -B 1 "jms" | grep "LSHandlerRoleAll" | tail -1 | sed 's/.*= "\(.*\)";/\1/')
echo "当前jms协议处理程序: $HANDLER"

# 启动应用程序（如果没有运行）
if ! pgrep -f "JMSProtocolHandler" > /dev/null; then
    echo "🚀 启动应用程序..."
    open "$APP_PATH"
    sleep 2
fi

# 检查日志文件位置
LOG_FILE="$HOME/Documents/JMSProtocolHandler.log"
echo "📄 日志文件位置: $LOG_FILE"

if [ -f "$LOG_FILE" ]; then
    echo "📋 当前日志内容:"
    tail -10 "$LOG_FILE"
else
    echo "⚠️  日志文件不存在"
fi

echo ""
echo "🧪 测试jms协议..."
echo "即将打开URL: $TEST_URL"
echo ""

# 打开测试URL
open "$TEST_URL"

echo "✅ 已发送jms协议请求"
echo "⏳ 等待3秒查看结果..."
sleep 3

# 检查日志更新
if [ -f "$LOG_FILE" ]; then
    echo ""
    echo "📋 最新日志内容:"
    tail -20 "$LOG_FILE"
else
    echo "❌ 仍然没有日志文件"
fi

echo ""
echo "🔍 检查应用程序进程..."
if pgrep -f "JMSProtocolHandler" > /dev/null; then
    echo "✅ 应用程序正在运行"
    echo "进程信息:"
    ps aux | grep JMSProtocolHandler | grep -v grep
else
    echo "❌ 应用程序未运行"
fi

echo ""
echo "📊 测试完成"
echo "如果没有看到协议处理日志，请检查:"
echo "1. 协议是否正确注册"
echo "2. 应用程序是否正确处理URL事件"
echo "3. 日志记录是否正常工作"
