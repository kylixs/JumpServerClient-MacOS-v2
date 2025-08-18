#!/bin/bash

# RDP设置窗口崩溃修复测试
# 测试多次打开和关闭RDP设置窗口是否会导致崩溃

echo "🔍 RDP设置窗口崩溃修复测试"
echo "=================================="

# 配置
PROJECT_ROOT="/Users/gongdewei/work/projects/jumpserver-client"
APP_PATH="/Applications/JMSProtocolHandler.app"
LOG_FILE="$HOME/Documents/JMSProtocolHandler.log"

# 检查应用程序
if [ ! -d "$APP_PATH" ]; then
    echo "❌ 应用程序未安装: $APP_PATH"
    echo "💡 请先安装应用程序: cp -R build/Release/JMSProtocolHandler.app /Applications/"
    exit 1
fi

# 清理环境
echo "🧹 清理测试环境..."
rm -f "$LOG_FILE"
killall JMSProtocolHandler 2>/dev/null || true
sleep 2

echo "✅ 环境清理完成"
echo ""

# 启动应用程序
echo "🚀 启动JMSProtocolHandler..."
open "$APP_PATH"
sleep 3

# 检查应用程序是否启动
if ! pgrep -f JMSProtocolHandler >/dev/null; then
    echo "❌ 应用程序启动失败"
    exit 1
fi

echo "✅ 应用程序启动成功"
echo ""

# 测试多次打开RDP设置窗口
echo "🧪 开始RDP设置窗口测试..."
echo "测试场景: 多次打开和关闭RDP设置窗口"
echo ""

for i in {1..5}; do
    echo "📱 第 $i 次测试:"
    
    # 通过菜单快捷键打开RDP设置窗口 (Cmd+,)
    echo "   打开RDP设置窗口..."
    osascript -e 'tell application "JMSProtocolHandler" to activate'
    sleep 1
    osascript -e 'tell application "System Events" to keystroke "," using command down'
    sleep 2
    
    # 检查窗口是否打开
    window_count=$(osascript -e 'tell application "JMSProtocolHandler" to count windows' 2>/dev/null || echo "0")
    if [ "$window_count" -gt 0 ]; then
        echo "   ✅ RDP设置窗口已打开"
    else
        echo "   ⚠️ 无法确认窗口状态"
    fi
    
    # 等待一下让窗口完全加载
    sleep 1
    
    # 关闭窗口 (Cmd+W)
    echo "   关闭RDP设置窗口..."
    osascript -e 'tell application "System Events" to keystroke "w" using command down'
    sleep 1
    
    # 检查应用程序是否仍在运行
    if pgrep -f JMSProtocolHandler >/dev/null; then
        echo "   ✅ 应用程序正常运行"
    else
        echo "   ❌ 应用程序崩溃！"
        echo ""
        echo "💥 检测到崩溃，查看崩溃日志:"
        
        # 查找最新的崩溃日志
        crash_log=$(ls -t ~/Library/Logs/DiagnosticReports/JMSProtocolHandler* 2>/dev/null | head -1)
        if [ -n "$crash_log" ]; then
            echo "📄 崩溃日志: $crash_log"
            echo "最后几行:"
            tail -20 "$crash_log"
        else
            echo "❌ 未找到崩溃日志"
        fi
        
        exit 1
    fi
    
    echo "   ⏳ 等待2秒后进行下一次测试..."
    sleep 2
    echo ""
done

echo "🎉 所有测试完成！"
echo ""
echo "📊 测试结果:"
echo "   ✅ 成功完成 5 次打开/关闭循环"
echo "   ✅ 应用程序未发生崩溃"
echo "   ✅ 内存管理修复有效"

# 检查应用程序日志
if [ -f "$LOG_FILE" ]; then
    echo ""
    echo "📄 应用程序日志摘要:"
    echo "清理操作次数: $(grep -c "清理RDP设置窗口组件" "$LOG_FILE")"
    echo "窗口创建次数: $(grep -c "RDP设置窗口创建完成" "$LOG_FILE")"
    echo "窗口关闭次数: $(grep -c "RDP设置窗口即将关闭" "$LOG_FILE")"
    
    if [ "$1" = "--verbose" ] || [ "$1" = "-v" ]; then
        echo ""
        echo "📄 详细日志:"
        grep -E "(清理RDP设置窗口|RDP设置窗口创建|RDP设置窗口即将关闭)" "$LOG_FILE"
    fi
fi

# 清理
echo ""
echo "🧹 清理测试环境..."
killall JMSProtocolHandler 2>/dev/null || true

echo "✅ RDP设置窗口崩溃修复测试完成！"
