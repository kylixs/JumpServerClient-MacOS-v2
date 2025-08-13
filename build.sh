#!/bin/bash

# JMS Protocol Handler Quick Build Script
# 快速构建脚本 - 项目根目录入口
# 版本: 1.2.0

# 设置颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}🚀 JMS Protocol Handler 快速构建${NC}"
echo

# 检查构建脚本是否存在
MACOS_APP_SCRIPT="./scripts/build/build-macos-app.sh"

if [ ! -f "$MACOS_APP_SCRIPT" ]; then
    echo -e "${RED}❌ macOS应用程序构建脚本不存在: $MACOS_APP_SCRIPT${NC}"
    exit 1
fi

# 确保脚本有执行权限
chmod +x "$MACOS_APP_SCRIPT"

echo -e "${BLUE}📋 可用的构建选项:${NC}"
echo "  1. 规范macOS应用程序构建 (推荐)"
echo "  2. 规范通用二进制构建"
echo "  3. Debug模式构建"
echo "  4. 清理后构建"
echo "  5. 代码签名构建"
echo "  6. 详细输出构建"
echo "  7. 显示帮助信息"
echo

# 如果有参数，直接传递给构建脚本
if [ $# -gt 0 ]; then
    case $1 in
        macos-app)
            echo -e "${GREEN}📱 执行规范macOS应用程序构建${NC}"
            exec "$MACOS_APP_SCRIPT" "${@:2}"
            ;;
        universal-app)
            echo -e "${GREEN}🌍 执行规范通用二进制构建${NC}"
            exec "$MACOS_APP_SCRIPT" --arch universal "${@:2}"
            ;;
        debug)
            echo -e "${GREEN}🐛 执行Debug构建${NC}"
            exec "$MACOS_APP_SCRIPT" --configuration debug "${@:2}"
            ;;
        clean)
            echo -e "${GREEN}🧹 执行清理后构建${NC}"
            exec "$MACOS_APP_SCRIPT" --clean "${@:2}"
            ;;
        sign)
            echo -e "${GREEN}🔐 执行代码签名构建${NC}"
            exec "$MACOS_APP_SCRIPT" --sign "${@:2}"
            ;;
        verbose)
            echo -e "${GREEN}📝 执行详细输出构建${NC}"
            exec "$MACOS_APP_SCRIPT" --verbose "${@:2}"
            ;;
        help|--help|-h)
            exec "$MACOS_APP_SCRIPT" --help
            ;;
        *)
            echo -e "${GREEN}🔄 执行: $MACOS_APP_SCRIPT $@${NC}"
            exec "$MACOS_APP_SCRIPT" "$@"
            ;;
    esac
fi

# 交互式选择
read -p "请选择构建选项 (1-7, 默认1): " choice

case $choice in
    1|"")
        echo -e "${GREEN}📱 执行规范macOS应用程序构建${NC}"
        exec "$MACOS_APP_SCRIPT" --clean
        ;;
    2)
        echo -e "${GREEN}🌍 执行规范通用二进制构建${NC}"
        exec "$MACOS_APP_SCRIPT" --clean --arch universal
        ;;
    3)
        echo -e "${GREEN}🐛 执行Debug模式构建${NC}"
        exec "$MACOS_APP_SCRIPT" --clean --configuration debug
        ;;
    4)
        echo -e "${GREEN}🧹 执行清理后构建${NC}"
        exec "$MACOS_APP_SCRIPT" --clean
        ;;
    5)
        echo -e "${GREEN}🔐 执行代码签名构建${NC}"
        exec "$MACOS_APP_SCRIPT" --clean --sign
        ;;
    6)
        echo -e "${GREEN}📝 执行详细输出构建${NC}"
        exec "$MACOS_APP_SCRIPT" --clean --verbose
        ;;
    7)
        echo -e "${GREEN}📖 显示帮助信息${NC}"
        exec "$MACOS_APP_SCRIPT" --help
        ;;
    *)
        echo -e "${RED}❌ 无效选择: $choice${NC}"
        echo -e "${YELLOW}请选择 1-7 之间的数字${NC}"
        exit 1
        ;;
esac
