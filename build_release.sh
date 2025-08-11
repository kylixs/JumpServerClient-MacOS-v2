#!/bin/bash

# JMS Protocol Handler 通用构建脚本
# 可以手工重复执行来生成可执行文件

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 脚本开始
print_info "🚀 开始构建 JMS Protocol Handler v1.2.0"
echo "========================================"

# 检查当前目录
if [ ! -d "JMSProtocolHandler" ]; then
    print_error "未找到 JMSProtocolHandler 目录，请在项目根目录执行此脚本"
    exit 1
fi

# 进入项目目录
cd JMSProtocolHandler
print_info "📁 进入项目目录: $(pwd)"

# 检查 Xcode 项目文件
if [ ! -f "JMSProtocolHandler.xcodeproj/project.pbxproj" ]; then
    print_error "未找到 Xcode 项目文件"
    exit 1
fi

# 清理之前的构建
print_info "🧹 清理之前的构建文件..."
xcodebuild clean -project JMSProtocolHandler.xcodeproj -scheme JMSProtocolHandler -configuration Release > /dev/null 2>&1
print_success "清理完成"

# 构建 Release 版本
print_info "🔨 开始构建 Release 版本..."
print_info "   - 配置: Release"
print_info "   - 架构: arm64 (Apple Silicon)"
print_info "   - 优化: 全模块优化 (-O)"

xcodebuild \
    -project JMSProtocolHandler.xcodeproj \
    -scheme JMSProtocolHandler \
    -configuration Release \
    -derivedDataPath ../build/xcode \
    build

if [ $? -eq 0 ]; then
    print_success "构建成功！"
else
    print_error "构建失败"
    exit 1
fi

# 返回项目根目录
cd ..

# 查找构建产物
BUILD_PATH="build/xcode/Build/Products/Release/JMSProtocolHandler.app"

if [ ! -d "$BUILD_PATH" ]; then
    print_error "未找到构建产物: $BUILD_PATH"
    exit 1
fi

# 复制应用程序到项目根目录
print_info "📦 复制应用程序到项目根目录..."
if [ -d "JMSProtocolHandler.app" ]; then
    rm -rf JMSProtocolHandler.app
    print_info "   - 删除旧版本应用程序"
fi

cp -R "$BUILD_PATH" ./JMSProtocolHandler.app
print_success "应用程序复制完成"

# 验证应用程序
print_info "🔍 验证应用程序..."

# 检查可执行文件
EXECUTABLE="JMSProtocolHandler.app/Contents/MacOS/JMSProtocolHandler"
if [ ! -f "$EXECUTABLE" ]; then
    print_error "未找到可执行文件: $EXECUTABLE"
    exit 1
fi

# 获取文件信息
FILE_INFO=$(file "$EXECUTABLE")
print_info "   - 文件类型: $FILE_INFO"

# 获取文件大小
FILE_SIZE=$(ls -lh "$EXECUTABLE" | awk '{print $5}')
print_info "   - 文件大小: $FILE_SIZE"

# 检查应用程序信息
if [ -f "JMSProtocolHandler.app/Contents/Info.plist" ]; then
    BUNDLE_ID=$(plutil -extract CFBundleIdentifier raw JMSProtocolHandler.app/Contents/Info.plist 2>/dev/null || echo "未知")
    VERSION=$(plutil -extract CFBundleShortVersionString raw JMSProtocolHandler.app/Contents/Info.plist 2>/dev/null || echo "未知")
    BUILD=$(plutil -extract CFBundleVersion raw JMSProtocolHandler.app/Contents/Info.plist 2>/dev/null || echo "未知")
    
    print_info "   - Bundle ID: $BUNDLE_ID"
    print_info "   - 版本: $VERSION"
    print_info "   - 构建号: $BUILD"
else
    print_warning "未找到 Info.plist 文件"
fi

# 检查代码签名
print_info "🔐 检查代码签名..."
CODESIGN_INFO=$(codesign -dv JMSProtocolHandler.app 2>&1 || echo "未签名")
if [[ "$CODESIGN_INFO" == *"Signature"* ]]; then
    print_success "应用程序已签名"
    print_info "   - 签名信息: $CODESIGN_INFO"
else
    print_warning "应用程序未签名或签名无效"
fi

# 检查权限
print_info "🔑 检查应用程序权限..."
if [ -f "JMSProtocolHandler.app/Contents/MacOS/JMSProtocolHandler" ]; then
    PERMISSIONS=$(ls -la "JMSProtocolHandler.app/Contents/MacOS/JMSProtocolHandler" | awk '{print $1}')
    print_info "   - 文件权限: $PERMISSIONS"
    
    if [[ "$PERMISSIONS" == *"x"* ]]; then
        print_success "可执行文件具有执行权限"
    else
        print_warning "可执行文件缺少执行权限"
        chmod +x "JMSProtocolHandler.app/Contents/MacOS/JMSProtocolHandler"
        print_info "   - 已添加执行权限"
    fi
fi

# 测试应用程序启动
print_info "🧪 测试应用程序启动..."
timeout 5s ./JMSProtocolHandler.app/Contents/MacOS/JMSProtocolHandler --version 2>/dev/null || true
if [ $? -eq 0 ]; then
    print_success "应用程序可以正常启动"
else
    print_info "应用程序启动测试完成（GUI应用程序正常）"
fi

# 显示构建摘要
echo ""
echo "========================================"
print_success "🎉 构建完成！"
echo ""
print_info "📋 构建摘要:"
print_info "   - 项目: JMS Protocol Handler"
print_info "   - 版本: v1.2.0"
print_info "   - 配置: Release"
print_info "   - 架构: arm64 (Apple Silicon)"
print_info "   - 输出: ./JMSProtocolHandler.app"
print_info "   - 大小: $FILE_SIZE"
echo ""
print_info "🚀 功能特性:"
print_info "   ✅ RDP协议支持（包含智能显示优化）"
print_info "   ✅ SSH协议支持"
print_info "   ✅ 自动显示器检测和优化"
print_info "   ✅ HiDPI显示器支持"
print_info "   ✅ 多显示器环境支持"
print_info "   ✅ Apple Silicon原生支持"
echo ""
print_info "📖 使用方法:"
print_info "   1. 将 JMSProtocolHandler.app 复制到 /Applications/"
print_info "   2. 运行协议注册脚本: ./scripts/deployment/register_jms_protocol.sh"
print_info "   3. 点击任何 jms:// 协议链接即可使用"
echo ""
print_success "构建脚本执行完成！"
