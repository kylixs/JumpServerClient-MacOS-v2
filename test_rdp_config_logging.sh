#!/bin/bash

echo "🧪 测试RDP配置参数日志记录功能"
echo "=================================="
echo ""

# 创建测试用的JMS URL
TEST_URL="jms://rdp/192.168.1.100:3389?username=testuser&password=testpass"

echo "📋 测试URL: $TEST_URL"
echo ""

# 检查应用程序是否存在
APP_PATH="/Users/gongdewei/work/projects/jumpserver-client/.build/debug/JMSProtocolHandler"

if [ ! -f "$APP_PATH" ]; then
    echo "❌ 应用程序不存在: $APP_PATH"
    echo "请先构建项目: swift build"
    exit 1
fi

echo "✅ 找到应用程序: $APP_PATH"
echo ""

# 运行应用程序并捕获输出
echo "🚀 启动应用程序处理RDP连接..."
echo "注意: 这将尝试启动Microsoft Remote Desktop"
echo ""

# 使用timeout防止程序挂起
timeout 30s "$APP_PATH" "$TEST_URL" 2>&1 | tee rdp_config_test_output.log

echo ""
echo "📄 日志输出已保存到: rdp_config_test_output.log"
echo ""

# 检查日志中是否包含预期的配置信息
echo "🔍 检查日志内容..."

if grep -q "显示器检测结果" rdp_config_test_output.log; then
    echo "✅ 找到显示器检测结果"
else
    echo "❌ 未找到显示器检测结果"
fi

if grep -q "RDP配置参数详情" rdp_config_test_output.log; then
    echo "✅ 找到RDP配置参数详情"
else
    echo "❌ 未找到RDP配置参数详情"
fi

if grep -q "desktopwidth" rdp_config_test_output.log; then
    echo "✅ 找到桌面分辨率配置"
else
    echo "❌ 未找到桌面分辨率配置"
fi

if grep -q "session bpp" rdp_config_test_output.log; then
    echo "✅ 找到颜色深度配置"
else
    echo "❌ 未找到颜色深度配置"
fi

echo ""
echo "📊 日志文件统计:"
echo "总行数: $(wc -l < rdp_config_test_output.log)"
echo "配置参数行数: $(grep -c ":" rdp_config_test_output.log)"
echo ""

echo "✅ 测试完成！"
echo "查看完整日志: cat rdp_config_test_output.log"
