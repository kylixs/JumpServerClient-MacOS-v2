#!/bin/bash

# JMS Protocol Registration Script
# 用于注册 jms:// 协议到 JMSProtocolHandler 应用程序

echo "=== JMS Protocol Registration Script ==="
echo

# 检查应用程序是否存在
APP_PATH="/Applications/JMSProtocolHandler.app"
LOCAL_APP_PATH="./JMSProtocolHandler.app"

if [ -d "$APP_PATH" ]; then
    TARGET_APP="$APP_PATH"
    echo "✅ 找到已安装的应用程序: $APP_PATH"
elif [ -d "$LOCAL_APP_PATH" ]; then
    TARGET_APP="$LOCAL_APP_PATH"
    echo "✅ 找到本地应用程序: $LOCAL_APP_PATH"
else
    echo "❌ 错误: 未找到 JMSProtocolHandler.app"
    echo "请确保应用程序已安装到 /Applications/ 目录"
    exit 1
fi

echo

# 显示应用程序信息
echo "📱 应用程序信息:"
BUNDLE_ID=$(defaults read "$TARGET_APP/Contents/Info.plist" CFBundleIdentifier 2>/dev/null)
VERSION=$(defaults read "$TARGET_APP/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)
echo "   Bundle ID: $BUNDLE_ID"
echo "   Version: $VERSION"
echo

# 注册协议处理程序
echo "🔧 注册 jms:// 协议处理程序..."
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R -trusted "$TARGET_APP"

if [ $? -eq 0 ]; then
    echo "✅ 协议注册成功"
else
    echo "❌ 协议注册失败"
    exit 1
fi

echo

# 验证注册结果
echo "🔍 验证协议注册状态..."
sleep 2

# 检查 jms 协议是否已注册
JMS_HANDLER=$(defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers | grep -A 3 -B 1 "jms" | grep "LSHandlerRoleAll" | head -1 | sed 's/.*= "\(.*\)";/\1/')

if [ -n "$JMS_HANDLER" ]; then
    echo "✅ jms:// 协议已注册"
    echo "   当前处理程序: $JMS_HANDLER"
    
    if [ "$JMS_HANDLER" = "$BUNDLE_ID" ]; then
        echo "✅ 协议已正确注册到我们的应用程序"
    else
        echo "⚠️  协议注册到了其他应用程序"
        echo "   尝试重新设置默认处理程序..."
        
        # 尝试设置为默认处理程序
        defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerURLScheme=jms;LSHandlerRoleAll='$BUNDLE_ID';}'
        
        # 重建Launch Services数据库
        /System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -kill -r -domain local -domain system -domain user
        
        echo "✅ 已尝试重新设置，请重启系统以确保生效"
    fi
else
    echo "❌ jms:// 协议未找到，可能注册失败"
fi

echo

# 提供测试方法
echo "🧪 测试方法:"
echo "1. 创建测试URL:"
echo '   echo "jms://eyJjb25maWciOiJ0ZXN0In0=" | pbcopy'
echo "2. 在浏览器地址栏粘贴并访问该URL"
echo "3. 系统应该提示使用 JMSProtocolHandler 打开"

echo

# 显示故障排除信息
echo "🔧 故障排除:"
echo "如果协议未正确注册，请尝试:"
echo "1. 重启应用程序"
echo "2. 重启系统"
echo "3. 在系统偏好设置中手动设置默认应用程序"
echo "4. 运行: sudo /System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -kill -r -domain local -domain system -domain user"

echo
echo "=== 协议注册完成 ==="
