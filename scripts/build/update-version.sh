#!/bin/bash

# JMS Protocol Handler - 版本号更新脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
INFO_PLIST="JMSProtocolHandler/JMSProtocolHandler/Info.plist"
VERSION_FILE="VERSION"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 获取当前版本
get_current_version() {
    /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || echo "1.0"
}

# 获取当前构建号
get_current_build() {
    /usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFO_PLIST" 2>/dev/null || echo "1"
}

# 更新版本号
update_version() {
    local new_version="$1"
    local new_build="$2"
    
    if [ -z "$new_version" ]; then
        log_info "未指定版本号，保持当前版本"
        return
    fi
    
    # 更新 Info.plist
    /usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $new_version" "$INFO_PLIST"
    
    if [ -n "$new_build" ]; then
        /usr/libexec/PlistBuddy -c "Set CFBundleVersion $new_build" "$INFO_PLIST"
    fi
    
    # 更新版本文件
    echo "$new_version" > "$VERSION_FILE"
    
    log_success "版本已更新: $new_version (构建号: ${new_build:-$(get_current_build)})"
}

# 自动递增构建号
increment_build() {
    local current_build=$(get_current_build)
    local new_build=$((current_build + 1))
    
    /usr/libexec/PlistBuddy -c "Set CFBundleVersion $new_build" "$INFO_PLIST"
    
    log_success "构建号已递增: $current_build -> $new_build"
}

# 显示当前版本信息
show_version() {
    local version=$(get_current_version)
    local build=$(get_current_build)
    
    echo "当前版本信息:"
    echo "  版本号: $version"
    echo "  构建号: $build"
    echo "  Info.plist: $INFO_PLIST"
}

# 主函数
main() {
    case "${1:-show}" in
        "show")
            show_version
            ;;
        "increment")
            increment_build
            ;;
        "set")
            if [ -z "$2" ]; then
                echo "用法: $0 set <版本号> [构建号]"
                echo "示例: $0 set 1.1.0 10"
                exit 1
            fi
            update_version "$2" "$3"
            ;;
        *)
            echo "用法: $0 [show|increment|set]"
            echo "  show      - 显示当前版本信息 (默认)"
            echo "  increment - 递增构建号"
            echo "  set       - 设置版本号和构建号"
            exit 1
            ;;
    esac
}

# 检查 Info.plist 是否存在
if [ ! -f "$INFO_PLIST" ]; then
    echo "错误: Info.plist 文件不存在: $INFO_PLIST"
    exit 1
fi

main "$@"
