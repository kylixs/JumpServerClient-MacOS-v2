#!/bin/bash

# JMS Protocol Handler - Info.plist 验证脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
INFO_PLIST="JMSProtocolHandler/JMSProtocolHandler/Info.plist"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 验证函数
validate_plist() {
    local key="$1"
    local expected="$2"
    local description="$3"
    
    local value=$(/usr/libexec/PlistBuddy -c "Print $key" "$INFO_PLIST" 2>/dev/null || echo "")
    
    if [ -z "$value" ]; then
        log_error "缺少必需的键: $key ($description)"
        return 1
    elif [ -n "$expected" ] && [ "$value" != "$expected" ]; then
        log_warning "$description: $value (期望: $expected)"
        return 1
    else
        log_success "$description: $value"
        return 0
    fi
}

# 验证数组
validate_array() {
    local key="$1"
    local description="$2"
    
    local count=$(/usr/libexec/PlistBuddy -c "Print $key" "$INFO_PLIST" 2>/dev/null | grep -c "Array {" || echo "0")
    
    if [ "$count" -eq 0 ]; then
        log_error "缺少或无效的数组: $key ($description)"
        return 1
    else
        log_success "$description: 已配置"
        return 0
    fi
}

# 主验证函数
main() {
    log_info "验证 Info.plist 配置..."
    log_info "文件路径: $INFO_PLIST"
    
    # 检查文件是否存在
    if [ ! -f "$INFO_PLIST" ]; then
        log_error "Info.plist 文件不存在: $INFO_PLIST"
        exit 1
    fi
    
    # 验证 plist 格式
    if ! plutil -lint "$INFO_PLIST" >/dev/null 2>&1; then
        log_error "Info.plist 格式无效"
        exit 1
    fi
    
    log_success "Info.plist 格式有效"
    
    # 验证基本配置
    local errors=0
    
    echo ""
    log_info "验证基本应用信息..."
    
    validate_plist "CFBundleIdentifier" "" "Bundle Identifier" || ((errors++))
    validate_plist "CFBundleName" "" "应用名称" || ((errors++))
    validate_plist "CFBundleShortVersionString" "" "版本号" || ((errors++))
    validate_plist "CFBundleVersion" "" "构建号" || ((errors++))
    validate_plist "CFBundlePackageType" "APPL" "包类型" || ((errors++))
    
    echo ""
    log_info "验证协议处理配置..."
    
    # 验证 URL Types 配置
    if validate_array "CFBundleURLTypes" "URL 类型配置"; then
        # 检查 jms 协议配置
        local jms_scheme=$(/usr/libexec/PlistBuddy -c "Print CFBundleURLTypes:0:CFBundleURLSchemes:0" "$INFO_PLIST" 2>/dev/null || echo "")
        if [ "$jms_scheme" = "jms" ]; then
            log_success "JMS 协议配置: jms://"
        else
            log_error "JMS 协议配置错误: $jms_scheme (期望: jms)"
            ((errors++))
        fi
        
        local handler_rank=$(/usr/libexec/PlistBuddy -c "Print CFBundleURLTypes:0:LSHandlerRank" "$INFO_PLIST" 2>/dev/null || echo "")
        if [ "$handler_rank" = "Owner" ]; then
            log_success "处理器优先级: Owner"
        else
            log_warning "处理器优先级: $handler_rank (建议: Owner)"
        fi
    else
        ((errors++))
    fi
    
    echo ""
    log_info "验证系统集成配置..."
    
    validate_plist "LSMinimumSystemVersion" "" "最低系统版本" || ((errors++))
    validate_plist "LSApplicationCategoryType" "" "应用分类" || ((errors++))
    
    # 可选配置检查
    echo ""
    log_info "检查可选配置..."
    
    local auto_term=$(/usr/libexec/PlistBuddy -c "Print NSSupportsAutomaticTermination" "$INFO_PLIST" 2>/dev/null || echo "")
    if [ "$auto_term" = "true" ]; then
        log_success "支持自动终止: 已启用"
    else
        log_info "支持自动终止: 未配置"
    fi
    
    local sudden_term=$(/usr/libexec/PlistBuddy -c "Print NSSupportsSuddenTermination" "$INFO_PLIST" 2>/dev/null || echo "")
    if [ "$sudden_term" = "true" ]; then
        log_success "支持突然终止: 已启用"
    else
        log_info "支持突然终止: 未配置"
    fi
    
    # 显示完整的协议配置
    echo ""
    log_info "完整的协议配置:"
    /usr/libexec/PlistBuddy -c "Print CFBundleURLTypes" "$INFO_PLIST" 2>/dev/null || log_error "无法读取协议配置"
    
    # 总结
    echo ""
    if [ $errors -eq 0 ]; then
        log_success "✅ Info.plist 验证通过！所有必需配置都正确。"
        
        # 显示关键信息摘要
        echo ""
        log_info "关键配置摘要:"
        echo "  应用名称: $(/usr/libexec/PlistBuddy -c "Print CFBundleName" "$INFO_PLIST" 2>/dev/null)"
        echo "  Bundle ID: $(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$INFO_PLIST" 2>/dev/null)"
        echo "  版本: $(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null)"
        echo "  构建号: $(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFO_PLIST" 2>/dev/null)"
        echo "  支持协议: jms://"
        echo "  最低系统: $(/usr/libexec/PlistBuddy -c "Print LSMinimumSystemVersion" "$INFO_PLIST" 2>/dev/null)"
        
        exit 0
    else
        log_error "❌ Info.plist 验证失败！发现 $errors 个问题。"
        exit 1
    fi
}

main "$@"
