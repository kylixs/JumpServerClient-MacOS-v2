#!/bin/bash

# 第一次启动端到端测试
# 测试第一次点击jms链接时的URL处理机制

echo "🔍 JMS Protocol Handler - 第一次启动测试"
echo "=============================================="

# 配置
PROJECT_ROOT="/Users/gongdewei/work/projects/jumpserver-client"
APP_PATH="/Applications/JMSProtocolHandler.app"
LOG_FILE="$HOME/Documents/JMSProtocolHandler.log"
TEST_URL_FILE="$PROJECT_ROOT/scripts/test/test_rdp_url.txt"

# 检查依赖
if [ ! -f "$TEST_URL_FILE" ]; then
    echo "❌ 测试URL文件不存在: $TEST_URL_FILE"
    exit 1
fi

# 1. 安装最新的应用程序
echo "📦 安装最新的应用程序..."
if [ -d "$PROJECT_ROOT/build/Release/JMSProtocolHandler.app" ]; then
    cp -R "$PROJECT_ROOT/build/Release/JMSProtocolHandler.app" /Applications/
    echo "✅ 应用程序已安装"
else
    echo "❌ 构建的应用程序不存在，请先运行 ./build.sh"
    exit 1
fi

# 2. 重新注册协议
echo "🔗 重新注册jms协议..."
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "$APP_PATH"
echo "✅ 协议注册完成"

# 3. 清理环境
echo "🧹 清理测试环境..."
rm -f "$LOG_FILE"
killall JMSProtocolHandler 2>/dev/null || true
sleep 3
echo "✅ 环境清理完成"

# 4. 读取测试URL
TEST_URL=$(cat "$TEST_URL_FILE")
echo "🎯 测试URL: $TEST_URL"

# 5. 执行第一次启动测试
echo ""
echo "🚀 === 第一次启动测试 ==="

# 在后台启动日志监控
echo "📊 启动日志监控..."
tail -f "$LOG_FILE" &
LOG_PID=$!

# 等待日志监控启动
sleep 1

# 模拟第一次点击jms链接
echo "🔗 模拟第一次点击jms链接..."
open "$TEST_URL"

# 等待处理完成
echo "⏳ 等待15秒观察处理过程..."
sleep 15

# 停止日志监控
kill $LOG_PID 2>/dev/null

# 6. 分析测试结果
echo ""
echo "📊 === 测试结果分析 ==="

if [ -f "$LOG_FILE" ]; then
    echo "✅ 日志文件存在"
    
    # 检查关键日志点
    echo ""
    echo "🔍 检查关键功能点:"
    
    # 检查应用程序生命周期
    if grep -q "applicationWillFinishLaunching 开始执行" "$LOG_FILE"; then
        echo "✅ applicationWillFinishLaunching 被调用"
    else
        echo "❌ applicationWillFinishLaunching 未被调用"
    fi
    
    if grep -q "applicationDidFinishLaunching 开始执行" "$LOG_FILE"; then
        echo "✅ applicationDidFinishLaunching 被调用"
    else
        echo "❌ applicationDidFinishLaunching 未被调用"
    fi
    
    # 检查URL处理
    if grep -q "handleURLEvent() 被调用" "$LOG_FILE"; then
        echo "✅ handleURLEvent 被调用"
    else
        echo "❌ handleURLEvent 未被调用 - 这是问题所在！"
        echo ""
        echo "📄 完整日志内容:"
        cat "$LOG_FILE"
        exit 1
    fi
    
    # 检查URL缓存机制
    if grep -q "保存URL稍后处理" "$LOG_FILE"; then
        echo "✅ URL缓存机制工作正常"
    else
        echo "⚠️ URL没有被缓存（可能直接处理了）"
    fi
    
    if grep -q "处理待处理的URL" "$LOG_FILE"; then
        echo "✅ 缓存的URL被正确处理"
    else
        echo "⚠️ 没有处理缓存的URL（可能直接处理了）"
    fi
    
    # 检查RDP处理流程
    if grep -q "JMS URL处理完成" "$LOG_FILE"; then
        echo "✅ URL处理流程完成"
    else
        echo "❌ URL处理流程未完成"
        exit 1
    fi
    
    if grep -q "RDP连接启动成功" "$LOG_FILE"; then
        echo "✅ RDP连接启动成功"
    else
        echo "❌ RDP连接启动失败"
        exit 1
    fi
    
    echo ""
    echo "🎉 第一次启动测试通过！"
    
    # 可选：显示完整日志
    if [ "$1" = "--verbose" ] || [ "$1" = "-v" ]; then
        echo ""
        echo "📄 完整日志内容:"
        cat "$LOG_FILE"
    fi
    
else
    echo "❌ 日志文件不存在，应用程序可能没有启动"
    exit 1
fi

echo ""
echo "✅ 第一次启动测试完成！"
