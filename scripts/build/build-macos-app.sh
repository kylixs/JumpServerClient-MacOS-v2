#!/bin/bash

# JMS Protocol Handler macOS App Build Script
# 规范的macOS应用程序编译脚本
# 版本: 1.2.0

set -e

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           JMS Protocol Handler macOS应用程序构建              ║${NC}"
echo -e "${CYAN}║                     版本: 1.2.0                        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}📁 项目根目录: ${PROJECT_ROOT}${NC}"

# 默认参数
CONFIGURATION="release"
ARCHITECTURE=""
APP_NAME="JMSProtocolHandler"
BUNDLE_ID="com.jumpserver.protocol-handler"
VERSION="1.2.0"
BUILD_NUMBER="1"
VERBOSE=false
CLEAN=false
SIGN_APP=false

# 规范的目录结构
BUILD_ROOT="${PROJECT_ROOT}/build"
TEMP_DIR="${BUILD_ROOT}/temp"
SWIFT_BUILD_DIR="${TEMP_DIR}/swift-build"
APP_BUILD_DIR="${TEMP_DIR}/app-build"
FINAL_OUTPUT_DIR="${BUILD_ROOT}/Release"
LOGS_DIR="${BUILD_ROOT}/logs"

# 显示帮助信息
show_help() {
    echo -e "${CYAN}JMS Protocol Handler macOS应用程序构建脚本${NC}"
    echo
    echo -e "${BLUE}用法:${NC}"
    echo "  $0 [选项]"
    echo
    echo -e "${BLUE}选项:${NC}"
    echo "  -c, --configuration [release|debug]  构建配置 (默认: release)"
    echo "  -a, --arch [arm64|x86_64|universal] 目标架构 (默认: 当前架构)"
    echo "  --clean                              构建前清理"
    echo "  --sign                               代码签名"
    echo "  --verbose                            详细输出"
    echo "  -h, --help                           显示帮助信息"
    echo
    echo -e "${BLUE}目录结构:${NC}"
    echo "  build/"
    echo "  ├── temp/                    # 临时构建文件"
    echo "  │   ├── swift-build/         # Swift Package构建缓存"
    echo "  │   └── app-build/           # 应用程序构建临时文件"
    echo "  ├── Release/                 # 最终发布文件"
    echo "  │   └── JMSProtocolHandler.app"
    echo "  └── logs/                    # 构建日志"
    echo
    echo -e "${BLUE}示例:${NC}"
    echo "  $0                           # 默认构建"
    echo "  $0 --clean --sign            # 清理后构建并签名"
    echo "  $0 --arch universal          # 通用二进制构建"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        -a|--arch)
            ARCHITECTURE="$2"
            shift 2
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --sign)
            SIGN_APP=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ 未知参数: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 验证配置
if [[ "$CONFIGURATION" != "release" && "$CONFIGURATION" != "debug" ]]; then
    echo -e "${RED}❌ 无效的构建配置: $CONFIGURATION${NC}"
    echo -e "${YELLOW}支持的配置: release, debug${NC}"
    exit 1
fi

# 设置详细输出
if [ "$VERBOSE" = true ]; then
    set -x
fi

# 设置最终输出目录
if [ "$CONFIGURATION" = "debug" ]; then
    FINAL_OUTPUT_DIR="${BUILD_ROOT}/Debug"
fi

echo -e "${BLUE}📦 构建配置: ${CONFIGURATION}${NC}"
echo -e "${BLUE}🎯 应用程序名称: ${APP_NAME}${NC}"
echo -e "${BLUE}📱 Bundle ID: ${BUNDLE_ID}${NC}"
echo -e "${BLUE}🔢 版本: ${VERSION} (${BUILD_NUMBER})${NC}"
if [ -n "$ARCHITECTURE" ]; then
    echo -e "${BLUE}🏗️ 目标架构: ${ARCHITECTURE}${NC}"
fi

# 创建目录结构
create_directories() {
    echo -e "${PURPLE}📁 创建规范目录结构...${NC}"
    
    local directories=(
        "$BUILD_ROOT"
        "$TEMP_DIR"
        "$SWIFT_BUILD_DIR"
        "$APP_BUILD_DIR"
        "$FINAL_OUTPUT_DIR"
        "$LOGS_DIR"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        echo -e "   ${GREEN}✅ ${dir}${NC}"
    done
}

# 清理构建文件
clean_build() {
    if [ "$CLEAN" = true ]; then
        echo -e "${YELLOW}🧹 清理构建文件...${NC}"
        
        # 清理临时目录
        if [ -d "$TEMP_DIR" ]; then
            rm -rf "$TEMP_DIR"
            echo -e "${GREEN}✅ 已清理临时目录${NC}"
        fi
        
        # 清理Swift Package构建缓存
        if [ -d ".build" ]; then
            rm -rf .build
            echo -e "${GREEN}✅ 已清理Swift Package缓存${NC}"
        fi
        
        # 清理最终输出目录
        if [ -d "$FINAL_OUTPUT_DIR" ]; then
            rm -rf "$FINAL_OUTPUT_DIR"
            echo -e "${GREEN}✅ 已清理输出目录${NC}"
        fi
    fi
}

# 构建Swift Package
build_swift_package() {
    echo -e "${PURPLE}🔨 构建Swift Package...${NC}"
    
    local log_file="${LOGS_DIR}/swift-build.log"
    
    # 构建命令
    local build_cmd="swift build --configuration $CONFIGURATION --build-path $SWIFT_BUILD_DIR"
    
    # 添加架构参数
    case "$ARCHITECTURE" in
        arm64)
            build_cmd="$build_cmd --arch arm64"
            BINARY_PATH="$SWIFT_BUILD_DIR/arm64-apple-macosx/$CONFIGURATION/$APP_NAME"
            ;;
        x86_64)
            build_cmd="$build_cmd --arch x86_64"
            BINARY_PATH="$SWIFT_BUILD_DIR/x86_64-apple-macosx/$CONFIGURATION/$APP_NAME"
            ;;
        universal)
            echo -e "${BLUE}🔄 构建通用二进制文件...${NC}"
            
            # 构建arm64
            echo -e "${BLUE}   🔨 构建ARM64架构...${NC}"
            swift build --configuration $CONFIGURATION --build-path $SWIFT_BUILD_DIR --arch arm64 2>&1 | tee "${log_file}.arm64"
            local arm64_binary="$SWIFT_BUILD_DIR/arm64-apple-macosx/$CONFIGURATION/$APP_NAME"
            
            # 构建x86_64
            echo -e "${BLUE}   🔨 构建x86_64架构...${NC}"
            swift build --configuration $CONFIGURATION --build-path $SWIFT_BUILD_DIR --arch x86_64 2>&1 | tee "${log_file}.x86_64"
            local x86_64_binary="$SWIFT_BUILD_DIR/x86_64-apple-macosx/$CONFIGURATION/$APP_NAME"
            
            # 创建通用二进制文件
            local universal_dir="$SWIFT_BUILD_DIR/universal-apple-macosx/$CONFIGURATION"
            mkdir -p "$universal_dir"
            lipo -create "$arm64_binary" "$x86_64_binary" -output "$universal_dir/$APP_NAME"
            
            BINARY_PATH="$universal_dir/$APP_NAME"
            echo -e "${GREEN}✅ 通用二进制文件创建成功${NC}"
            return 0
            ;;
        "")
            # 使用默认架构
            local arch=$(uname -m)
            if [ "$arch" = "arm64" ]; then
                BINARY_PATH="$SWIFT_BUILD_DIR/arm64-apple-macosx/$CONFIGURATION/$APP_NAME"
            else
                BINARY_PATH="$SWIFT_BUILD_DIR/x86_64-apple-macosx/$CONFIGURATION/$APP_NAME"
            fi
            ;;
        *)
            echo -e "${RED}❌ 不支持的架构: $ARCHITECTURE${NC}"
            exit 1
            ;;
    esac
    
    # 执行构建
    echo -e "${BLUE}🔨 执行: $build_cmd${NC}"
    eval "$build_cmd" 2>&1 | tee "$log_file"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✅ Swift Package构建成功${NC}"
    else
        echo -e "${RED}❌ Swift Package构建失败，查看日志: $log_file${NC}"
        exit 1
    fi
}

# 创建应用程序包
create_app_bundle() {
    echo -e "${PURPLE}📦 创建应用程序包...${NC}"
    
    # 验证二进制文件存在
    if [ ! -f "$BINARY_PATH" ]; then
        echo -e "${RED}❌ 未找到生成的二进制文件: $BINARY_PATH${NC}"
        exit 1
    fi
    
    # 应用程序包路径
    local app_path="$APP_BUILD_DIR/$APP_NAME.app"
    local contents_dir="$app_path/Contents"
    local macos_dir="$contents_dir/MacOS"
    local resources_dir="$contents_dir/Resources"
    
    # 创建应用程序目录结构
    echo -e "${BLUE}📁 创建应用程序目录结构${NC}"
    mkdir -p "$macos_dir"
    mkdir -p "$resources_dir"
    
    echo -e "   ${CYAN}$app_path${NC}"
    echo -e "   ${CYAN}├── Contents/${NC}"
    echo -e "   ${CYAN}│   ├── MacOS/${NC}"
    echo -e "   ${CYAN}│   ├── Resources/${NC}"
    echo -e "   ${CYAN}│   └── Info.plist${NC}"
    
    # 复制可执行文件
    echo -e "${BLUE}📋 复制可执行文件...${NC}"
    cp "$BINARY_PATH" "$macos_dir/$APP_NAME"
    chmod +x "$macos_dir/$APP_NAME"
    
    # 创建Info.plist
    echo -e "${BLUE}📄 创建Info.plist...${NC}"
    create_info_plist "$contents_dir/Info.plist"
    
    # 复制资源文件
    echo -e "${BLUE}📦 复制资源文件...${NC}"
    copy_resources "$resources_dir"
    
    # 代码签名
    if [ "$SIGN_APP" = true ]; then
        sign_application "$app_path"
    fi
    
    # 移动到最终输出目录
    echo -e "${BLUE}📦 移动到最终输出目录...${NC}"
    if [ -d "$FINAL_OUTPUT_DIR/$APP_NAME.app" ]; then
        rm -rf "$FINAL_OUTPUT_DIR/$APP_NAME.app"
    fi
    mv "$app_path" "$FINAL_OUTPUT_DIR/"
    
    echo -e "${GREEN}✅ 应用程序包创建完成${NC}"
}

# 创建Info.plist
create_info_plist() {
    local plist_path="$1"
    
    cat > "$plist_path" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string></string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSMainNibFile</key>
    <string>MainMenu</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>JMS Protocol Handler</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>jms</string>
            </array>
            <key>LSHandlerRank</key>
            <string>Owner</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
        </dict>
    </array>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
EOF
    
    echo -e "   ${GREEN}✅ Info.plist创建完成${NC}"
}

# 复制资源文件
copy_resources() {
    local resources_dir="$1"
    local resources_source="Sources/JMSProtocolHandler/Resources"
    
    if [ -d "$resources_source" ]; then
        # 复制XIB文件
        if [ -f "$resources_source/Base.lproj/MainMenu.xib" ]; then
            mkdir -p "$resources_dir/Base.lproj"
            cp "$resources_source/Base.lproj/MainMenu.xib" "$resources_dir/Base.lproj/"
            echo -e "   ${GREEN}✅ MainMenu.xib${NC}"
        fi
        
        # 复制Assets.xcassets
        if [ -d "$resources_source/Assets.xcassets" ]; then
            cp -R "$resources_source/Assets.xcassets" "$resources_dir/"
            echo -e "   ${GREEN}✅ Assets.xcassets${NC}"
        fi
        
        # 复制Entitlements文件到Contents目录
        if [ -f "$resources_source/JMSProtocolHandler.entitlements" ]; then
            cp "$resources_source/JMSProtocolHandler.entitlements" "$(dirname "$resources_dir")/"
            echo -e "   ${GREEN}✅ Entitlements文件${NC}"
        fi
    else
        echo -e "   ${YELLOW}⚠️  资源目录不存在: $resources_source${NC}"
    fi
}

# 代码签名
sign_application() {
    local app_path="$1"
    
    echo -e "${PURPLE}🔐 代码签名...${NC}"
    
    # 查找可用的开发者证书
    local cert_name=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/')
    
    if [ -n "$cert_name" ]; then
        echo -e "${BLUE}🔑 使用证书: $cert_name${NC}"
        
        # 签名应用程序
        local entitlements_path="$app_path/Contents/JMSProtocolHandler.entitlements"
        if [ -f "$entitlements_path" ]; then
            codesign --force --sign "$cert_name" --entitlements "$entitlements_path" "$app_path"
        else
            codesign --force --sign "$cert_name" "$app_path"
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ 代码签名成功${NC}"
            
            # 验证签名
            codesign --verify --verbose "$app_path"
            echo -e "${GREEN}✅ 签名验证通过${NC}"
        else
            echo -e "${RED}❌ 代码签名失败${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  未找到开发者证书，跳过签名${NC}"
    fi
}

# 显示构建摘要
show_build_summary() {
    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                        构建摘要                              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    local final_app_path="$FINAL_OUTPUT_DIR/$APP_NAME.app"
    
    if [ -d "$final_app_path" ]; then
        # 应用程序信息
        echo -e "${BLUE}📊 应用程序信息:${NC}"
        echo -e "   ${GREEN}✅ 路径: ${final_app_path}${NC}"
        
        # 应用程序大小
        local app_size=$(du -sh "$final_app_path" | cut -f1)
        echo -e "   ${GREEN}✅ 大小: ${app_size}${NC}"
        
        # 二进制文件信息
        local binary_path="$final_app_path/Contents/MacOS/$APP_NAME"
        if [ -f "$binary_path" ]; then
            local binary_info=$(file "$binary_path")
            echo -e "   ${GREEN}✅ 二进制: ${binary_info}${NC}"
            
            # 架构信息
            if command -v lipo >/dev/null 2>&1; then
                local archs=$(lipo -info "$binary_path" 2>/dev/null | grep "Architectures" | cut -d: -f2 | xargs)
                if [ -n "$archs" ]; then
                    echo -e "   ${GREEN}✅ 架构: ${archs}${NC}"
                fi
            fi
        fi
        
        echo -e "${BLUE}📁 目录结构:${NC}"
        echo -e "   ${CYAN}build/${NC}"
        echo -e "   ${CYAN}├── temp/                    # 临时文件 (可删除)${NC}"
        echo -e "   ${CYAN}├── ${CONFIGURATION}/                 # 最终输出${NC}"
        echo -e "   ${CYAN}│   └── ${APP_NAME}.app${NC}"
        echo -e "   ${CYAN}└── logs/                    # 构建日志${NC}"
        
        echo -e "${BLUE}🚀 使用方法:${NC}"
        echo -e "   ${GREEN}双击运行: open \"${final_app_path}\"${NC}"
        echo -e "   ${GREEN}安装到Applications: cp -R \"${final_app_path}\" /Applications/${NC}"
        
        echo -e "${BLUE}🔗 协议测试:${NC}"
        echo -e "   ${CYAN}RDP: open 'jms://rdp://user:pass@host:3389'${NC}"
        echo -e "   ${CYAN}SSH: open 'jms://ssh://user:pass@host:22'${NC}"
        
        echo -e "${BLUE}📊 构建统计:${NC}"
        echo -e "   ${CYAN}构建时间: $(date)${NC}"
        echo -e "   ${CYAN}配置: ${CONFIGURATION}${NC}"
        echo -e "   ${CYAN}版本: ${VERSION} (${BUILD_NUMBER})${NC}"
        echo -e "   ${CYAN}Bundle ID: ${BUNDLE_ID}${NC}"
        
        # 清理建议
        echo -e "${BLUE}💡 清理建议:${NC}"
        echo -e "   ${YELLOW}临时文件: rm -rf ${TEMP_DIR}${NC}"
        echo -e "   ${YELLOW}构建缓存: rm -rf .build${NC}"
        
    else
        echo -e "${RED}❌ 应用程序构建失败${NC}"
        exit 1
    fi
}

# 主函数
main() {
    # 清理构建文件
    clean_build
    
    # 创建目录结构
    create_directories
    
    # 构建Swift Package
    build_swift_package
    
    # 创建应用程序包
    create_app_bundle
    
    # 显示构建摘要
    show_build_summary
    
    echo
    echo -e "${GREEN}🎉 macOS应用程序构建完成！${NC}"
}

# 执行主函数
main "$@"
