#!/bin/bash

# JMS Protocol Test Script
# 用于测试 jms:// 协议是否正确注册和工作

echo "=== JMS Protocol Test Script ==="
echo

# 创建测试用的JMS URL
TEST_CONFIG='{"config":"full address:s:test.server.com:3389\nusername:s:testuser\nsession bpp:i:32\naudiomode:i:0"}'
TEST_PAYLOAD=$(echo -n "$TEST_CONFIG" | base64)
TEST_URL="jms://$TEST_PAYLOAD"

echo "🧪 测试URL已生成:"
echo "   $TEST_URL"
echo

# 检查协议处理程序
echo "🔍 检查当前协议处理程序:"
JMS_HANDLER=$(defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers | grep -A 3 -B 1 "jms" | grep "LSHandlerRoleAll" | head -1 | sed 's/.*= "\(.*\)";/\1/')

if [ -n "$JMS_HANDLER" ]; then
    echo "   当前处理程序: $JMS_HANDLER"
else
    echo "   ❌ 未找到jms协议处理程序"
fi

echo

# 提供多种测试方法
echo "📋 测试方法:"
echo

echo "方法1: 命令行测试"
echo "   open '$TEST_URL'"
echo

echo "方法2: 浏览器测试"
echo "   1. 复制以下URL到剪贴板:"
echo "      $TEST_URL"
echo "   2. 在浏览器地址栏粘贴并访问"
echo

echo "方法3: 自动测试 (将在5秒后执行)"
echo "   按 Ctrl+C 取消自动测试"

# 倒计时
for i in {5..1}; do
    echo -n "   $i..."
    sleep 1
done
echo

echo "🚀 执行自动测试..."
open "$TEST_URL"

if [ $? -eq 0 ]; then
    echo "✅ 测试URL已发送到系统"
    echo "   如果协议注册正确，JMSProtocolHandler应用程序应该会启动"
else
    echo "❌ 测试URL发送失败"
fi

echo

echo "🔍 检查应用程序是否启动:"
sleep 2
RUNNING_APPS=$(ps aux | grep JMSProtocolHandler | grep -v grep | wc -l)

if [ $RUNNING_APPS -gt 0 ]; then
    echo "✅ JMSProtocolHandler 应用程序正在运行"
    echo "   进程数: $RUNNING_APPS"
else
    echo "❌ JMSProtocolHandler 应用程序未运行"
    echo "   可能的原因:"
    echo "   1. 协议未正确注册"
    echo "   2. 应用程序未安装到正确位置"
    echo "   3. 需要重启系统"
fi

echo

echo "📝 预期行为:"
echo "1. 系统应该提示选择应用程序打开jms://链接"
echo "2. 选择JMSProtocolHandler后，应用程序应该启动"
echo "3. 应用程序应该解析URL并显示连接信息"
echo "4. 如果安装了Microsoft Remote Desktop，应该尝试启动连接"

echo
echo "=== 测试完成 ==="
