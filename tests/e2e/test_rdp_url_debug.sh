#!/bin/bash

# RDP URL调试测试
# 用于调试RDP URL处理的完整流程

echo "🔍 JMS Protocol Handler - RDP URL调试测试"
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

# 1. 清理环境
echo "🧹 清理测试环境..."
rm -f "$LOG_FILE"
rm -rf /tmp/JMSProtocolHandler/
rm -f ~/Documents/JMSRDPSettings.json
killall JMSProtocolHandler 2>/dev/null || true
sleep 2

# 2. 确保协议注册
echo "🔗 确保协议注册..."
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "$APP_PATH"

# 3. 读取并解码测试URL
TEST_URL=$(cat "$TEST_URL_FILE")
echo "🎯 测试URL: $TEST_URL"

echo ""
echo "📄 解码URL内容:"
PAYLOAD=$(echo "$TEST_URL" | sed 's/jms:\/\///')
if command -v jq >/dev/null 2>&1; then
    echo "$PAYLOAD" | base64 -d | jq . 2>/dev/null || echo "$PAYLOAD" | base64 -d
else
    echo "$PAYLOAD" | base64 -d
fi

# 4. 启动测试
echo ""
echo "🚀 启动RDP URL测试..."

# 在后台启动日志监控
echo "📊 开始监控日志..."
tail -f "$LOG_FILE" &
LOG_PID=$!

# 等待日志监控启动
sleep 1

# 打开RDP URL
echo "🔗 打开RDP URL..."
open "$TEST_URL"

# 等待处理完成
echo "⏳ 等待15秒观察处理过程..."
sleep 15

# 停止日志监控
kill $LOG_PID 2>/dev/null

# 5. 检查结果
echo ""
echo "📊 === 测试结果检查 ==="

if [ -f "$LOG_FILE" ]; then
    echo "✅ 日志文件存在"
    
    echo ""
    echo "🔍 检查处理流程:"
    
    # URL处理流程检查
    if grep -q "URL处理 - 开始处理" "$LOG_FILE"; then
        echo "✅ URL处理开始"
    else
        echo "❌ URL处理未开始"
    fi
    
    if grep -q "URL解析成功" "$LOG_FILE"; then
        echo "✅ URL解析成功"
    else
        echo "❌ URL解析失败"
    fi
    
    if grep -q "Payload解码成功" "$LOG_FILE"; then
        echo "✅ Payload解码成功"
    else
        echo "❌ Payload解码失败"
    fi
    
    if grep -q "连接信息提取成功" "$LOG_FILE"; then
        echo "✅ 连接信息提取成功"
    else
        echo "❌ 连接信息提取失败"
    fi
    
    # RDP特定检查
    if grep -q "启动RDP连接" "$LOG_FILE"; then
        echo "✅ RDP连接启动"
    else
        echo "❌ RDP连接未启动"
    fi
    
    if grep -q "Microsoft Remote Desktop.*已安装" "$LOG_FILE"; then
        echo "✅ Microsoft Remote Desktop检测"
    else
        echo "❌ Microsoft Remote Desktop检测失败"
    fi
    
    if grep -q "RDP配置生成成功" "$LOG_FILE"; then
        echo "✅ RDP配置生成"
    else
        echo "❌ RDP配置生成失败"
    fi
    
    if grep -q "临时RDP文件创建成功" "$LOG_FILE"; then
        echo "✅ RDP文件创建"
    else
        echo "❌ RDP文件创建失败"
    fi
    
    if grep -q "Microsoft Remote Desktop 启动成功" "$LOG_FILE"; then
        echo "✅ Microsoft Remote Desktop启动"
    else
        echo "❌ Microsoft Remote Desktop启动失败"
    fi
    
else
    echo "❌ 日志文件不存在"
    exit 1
fi

echo ""
echo "📁 检查生成的文件..."

# 检查RDP配置文件
echo "=== RDP配置文件 ==="
RDP_FILES=$(find /tmp/JMSProtocolHandler/ -name "*.rdp" 2>/dev/null)
if [ -n "$RDP_FILES" ]; then
    echo "✅ 找到RDP配置文件:"
    for file in $RDP_FILES; do
        echo "📄 文件: $file"
        echo "大小: $(ls -lh "$file" | awk '{print $5}')"
        echo "修改时间: $(ls -l "$file" | awk '{print $6, $7, $8}')"
        if [ "$1" = "--show-config" ]; then
            echo "内容:"
            cat "$file"
        fi
        echo "---"
    done
else
    echo "❌ 未找到RDP配置文件"
fi

# 检查RDP设置文件
echo ""
echo "=== RDP设置文件 ==="
if [ -f ~/Documents/JMSRDPSettings.json ]; then
    echo "✅ RDP设置文件存在"
    if [ "$1" = "--show-config" ]; then
        echo "📄 内容:"
        cat ~/Documents/JMSRDPSettings.json
    fi
else
    echo "❌ RDP设置文件不存在（使用默认设置）"
fi

# 检查Microsoft Remote Desktop
echo ""
echo "=== Microsoft Remote Desktop检查 ==="
if [ -d "/Applications/Microsoft Remote Desktop.app" ]; then
    echo "✅ Microsoft Remote Desktop 已安装"
else
    echo "❌ Microsoft Remote Desktop 未安装"
    echo "💡 请从Mac App Store安装Microsoft Remote Desktop"
fi

# 显示完整日志（可选）
if [ "$1" = "--verbose" ] || [ "$1" = "-v" ]; then
    echo ""
    echo "📄 完整日志内容:"
    cat "$LOG_FILE"
fi

echo ""
echo "✅ RDP URL调试测试完成！"
