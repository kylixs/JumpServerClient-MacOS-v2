#!/bin/bash

echo "🧪 修复后的RDP测试"

# 创建正确的RDP配置
TEST_CONFIG='{
    "protocol": "rdp",
    "config": "full address:s:test.server.com:3389\\nusername:s:testuser\\nsession bpp:i:32\\naudiomode:i:0"
}'

ENCODED=$(echo -n "$TEST_CONFIG" | base64)
TEST_URL="jms://$ENCODED"

echo "📝 测试URL: $TEST_URL"
echo ""
echo "🧪 打开测试URL..."

open "$TEST_URL"

echo "⏳ 等待5秒查看结果..."
sleep 5

echo "📋 检查日志:"
tail -30 ~/Documents/JMSProtocolHandler.log
