#!/bin/bash

# JMS Protocol Handler Build Clean Script
# 用于清理项目构建文件和临时文件

echo "=== JMS Protocol Handler 构建清理脚本 ==="
echo

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "📁 项目根目录: $PROJECT_ROOT"
echo

# 函数：显示文件大小
show_size() {
    local path="$1"
    local description="$2"
    
    if [ -d "$path" ] || [ -f "$path" ]; then
        local size=$(du -sh "$path" 2>/dev/null | cut -f1)
        echo "   $description: $size"
    else
        echo "   $description: 不存在"
    fi
}

# 函数：安全删除目录内容
safe_clean() {
    local path="$1"
    local description="$2"
    
    if [ -d "$path" ]; then
        local file_count=$(find "$path" -type f | wc -l | tr -d ' ')
        if [ "$file_count" -gt 0 ]; then
            echo -e "${YELLOW}🧹 清理 $description...${NC}"
            rm -rf "$path"/*
            echo -e "${GREEN}✅ 已清理 $file_count 个文件${NC}"
        else
            echo -e "${BLUE}ℹ️  $description 已经是空的${NC}"
        fi
    else
        echo -e "${BLUE}ℹ️  $description 目录不存在${NC}"
    fi
}

# 显示清理前的状态
echo "🔍 清理前状态:"
show_size "build/" "构建目录总大小"
show_size "build/objects/" "编译对象文件"
show_size "build/temp/" "临时文件"
show_size "build/artifacts/" "构建产物"
show_size "JMSProtocolHandler/build/" "Xcode构建目录"
show_size "JMSProtocolHandler/.build/" "Swift Package构建目录"
echo

# 询问用户确认
echo "🤔 请选择清理选项:"
echo "1) 清理项目构建文件 (build/objects/, build/temp/, build/artifacts/)"
echo "2) 清理Xcode构建缓存 (JMSProtocolHandler/build/)"
echo "3) 清理Swift Package缓存 (JMSProtocolHandler/.build/)"
echo "4) 清理所有构建文件 (选项1+2+3)"
echo "5) 清理DerivedData (Xcode系统缓存)"
echo "6) 显示构建文件详情"
echo "0) 退出"
echo

read -p "请输入选项 (0-6): " choice

case $choice in
    1)
        echo -e "${BLUE}🧹 清理项目构建文件...${NC}"
        safe_clean "build/objects" "编译对象文件"
        safe_clean "build/temp" "临时文件"
        safe_clean "build/artifacts" "构建产物"
        ;;
    2)
        echo -e "${BLUE}🧹 清理Xcode构建缓存...${NC}"
        if [ -d "JMSProtocolHandler" ]; then
            cd JMSProtocolHandler
            xcodebuild clean 2>/dev/null && echo -e "${GREEN}✅ Xcode clean 完成${NC}" || echo -e "${YELLOW}⚠️  Xcode clean 失败或无需清理${NC}"
            cd ..
        fi
        safe_clean "JMSProtocolHandler/build" "Xcode构建目录"
        ;;
    3)
        echo -e "${BLUE}🧹 清理Swift Package缓存...${NC}"
        if [ -d "JMSProtocolHandler" ]; then
            cd JMSProtocolHandler
            swift package clean 2>/dev/null && echo -e "${GREEN}✅ Swift package clean 完成${NC}" || echo -e "${YELLOW}⚠️  Swift package clean 失败或无需清理${NC}"
            cd ..
        fi
        safe_clean "JMSProtocolHandler/.build" "Swift Package构建目录"
        ;;
    4)
        echo -e "${BLUE}🧹 清理所有构建文件...${NC}"
        
        # 清理项目构建文件
        safe_clean "build/objects" "编译对象文件"
        safe_clean "build/temp" "临时文件"
        safe_clean "build/artifacts" "构建产物"
        
        # 清理Xcode缓存
        if [ -d "JMSProtocolHandler" ]; then
            cd JMSProtocolHandler
            xcodebuild clean 2>/dev/null && echo -e "${GREEN}✅ Xcode clean 完成${NC}"
            swift package clean 2>/dev/null && echo -e "${GREEN}✅ Swift package clean 完成${NC}"
            cd ..
        fi
        
        safe_clean "JMSProtocolHandler/build" "Xcode构建目录"
        safe_clean "JMSProtocolHandler/.build" "Swift Package构建目录"
        ;;
    5)
        echo -e "${BLUE}🧹 清理DerivedData...${NC}"
        DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"
        JMS_DERIVED_DATA=$(find "$DERIVED_DATA_PATH" -name "*JMSProtocolHandler*" -type d 2>/dev/null)
        
        if [ -n "$JMS_DERIVED_DATA" ]; then
            echo "找到DerivedData目录:"
            echo "$JMS_DERIVED_DATA"
            read -p "确认删除? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                rm -rf $JMS_DERIVED_DATA
                echo -e "${GREEN}✅ DerivedData已清理${NC}"
            else
                echo -e "${YELLOW}⚠️  已取消DerivedData清理${NC}"
            fi
        else
            echo -e "${BLUE}ℹ️  未找到JMSProtocolHandler的DerivedData${NC}"
        fi
        ;;
    6)
        echo -e "${BLUE}📊 构建文件详情:${NC}"
        echo
        echo "📁 项目构建文件:"
        if [ -d "build/objects" ]; then
            echo "   编译对象文件 (.o):"
            ls -lh build/objects/ 2>/dev/null | grep -v "^total" | while read line; do
                echo "     $line"
            done
        fi
        
        echo
        echo "📁 Xcode构建文件:"
        if [ -d "JMSProtocolHandler/build" ]; then
            find JMSProtocolHandler/build -name "*.o" -exec ls -lh {} \; 2>/dev/null | head -10
        fi
        
        echo
        echo "📁 Swift Package构建文件:"
        if [ -d "JMSProtocolHandler/.build" ]; then
            find JMSProtocolHandler/.build -name "*.o" -exec ls -lh {} \; 2>/dev/null | head -10
        fi
        ;;
    0)
        echo -e "${BLUE}👋 退出清理脚本${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ 无效选项${NC}"
        exit 1
        ;;
esac

echo

# 显示清理后的状态
echo "📊 清理后状态:"
show_size "build/" "构建目录总大小"
show_size "build/objects/" "编译对象文件"
show_size "build/temp/" "临时文件"
show_size "build/artifacts/" "构建产物"
show_size "JMSProtocolHandler/build/" "Xcode构建目录"
show_size "JMSProtocolHandler/.build/" "Swift Package构建目录"

echo
echo -e "${GREEN}✅ 清理完成${NC}"

# 提供重新构建建议
echo
echo "💡 重新构建建议:"
echo "   cd JMSProtocolHandler"
echo "   xcodebuild -project JMSProtocolHandler.xcodeproj -scheme JMSProtocolHandler -configuration Release build"

echo
echo "=== 构建清理完成 ==="
