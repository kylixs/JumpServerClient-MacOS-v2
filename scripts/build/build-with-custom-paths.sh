#!/bin/bash

# JMS Protocol Handler Custom Build Script
# 使用自定义路径构建项目

echo "=== 使用自定义路径构建项目 ==="

# 加载构建配置
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

if [ -f ".build-config" ]; then
    source .build-config
    echo "✅ 已加载构建配置"
else
    echo "❌ 构建配置文件不存在"
    exit 1
fi

# 确保目录存在
mkdir -p "$BUILD_OBJECTS_DIR" "$BUILD_TEMP_DIR" "$BUILD_ARTIFACTS_DIR"

# 构建选项
CONFIGURATION=${1:-Release}
SCHEME=${2:-JMSProtocolHandler}

echo "📦 构建配置: $CONFIGURATION"
echo "🎯 构建方案: $SCHEME"
echo "📁 输出目录: $BUILD_ROOT"

# 使用自定义路径构建
if [ -d "JMSProtocolHandler/JMSProtocolHandler.xcodeproj" ]; then
    echo "🏗️ 使用Xcode构建..."
    
    cd JMSProtocolHandler
    
    xcodebuild \
        -project JMSProtocolHandler.xcodeproj \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -xcconfig "../build-paths.xcconfig" \
        OBJROOT="$BUILD_TEMP_DIR/xcode" \
        SYMROOT="$BUILD_ROOT/xcode" \
        CONFIGURATION_BUILD_DIR="$BUILD_ROOT/xcode/$CONFIGURATION" \
        DERIVED_DATA_DIR="$BUILD_ROOT/derived-data" \
        build
    
    BUILD_RESULT=$?
    cd ..
    
    if [ $BUILD_RESULT -eq 0 ]; then
        echo "✅ Xcode构建成功"
        
        # 复制最终产物到artifacts目录
        if [ -f "$BUILD_ROOT/xcode/$CONFIGURATION/JMSProtocolHandler.app/Contents/MacOS/JMSProtocolHandler" ]; then
            cp -R "$BUILD_ROOT/xcode/$CONFIGURATION/JMSProtocolHandler.app" "$BUILD_ARTIFACTS_DIR/"
            echo "✅ 应用程序已复制到artifacts目录"
        fi
    else
        echo "❌ Xcode构建失败"
        exit 1
    fi
else
    echo "❌ 未找到Xcode项目文件"
    exit 1
fi

echo "🎉 构建完成！"
echo "📦 输出位置: $BUILD_ARTIFACTS_DIR/JMSProtocolHandler.app"
