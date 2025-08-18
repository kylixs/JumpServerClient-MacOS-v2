#!/bin/bash

# JMS Protocol Handler DMG 程序包构建脚本
# 使用现有build.sh构建app，然后创建包含脚本和文档的DMG包

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# 配置
PROJECT_NAME="JMSProtocolHandler"
VERSION="1.2.0"
DMG_NAME="JMS-Protocol-Handler-v${VERSION}"

# 路径
PROJECT_ROOT="$(pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
APP_PATH="${BUILD_DIR}/Release/${PROJECT_NAME}.app"
DMG_TEMP_DIR="${BUILD_DIR}/dmg_temp"

echo -e "${BLUE}🚀 JMS Protocol Handler DMG 程序包构建器${NC}"
echo "版本: ${VERSION}"
echo ""

# 1. 使用现有build.sh构建应用程序
echo -e "${YELLOW}🏗️ 构建应用程序...${NC}"
if [ ! -f "./build.sh" ]; then
    echo -e "${RED}❌ 构建脚本不存在: ./build.sh${NC}"
    exit 1
fi

./build.sh --clean

if [ ! -d "${APP_PATH}" ]; then
    echo -e "${RED}❌ 应用程序构建失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 应用程序构建完成${NC}"

# 2. 创建DMG目录结构
echo -e "${YELLOW}📁 创建DMG目录结构...${NC}"
rm -rf "${DMG_TEMP_DIR}"
mkdir -p "${DMG_TEMP_DIR}/Scripts"

# 复制应用程序
cp -R "${APP_PATH}" "${DMG_TEMP_DIR}/"

# 复制JMS协议相关脚本
echo "复制JMS协议脚本..."
cp "${PROJECT_ROOT}/scripts/deployment/register_jms_protocol.sh" "${DMG_TEMP_DIR}/Scripts/" 2>/dev/null || echo "⚠️ register_jms_protocol.sh 未找到"
cp "${PROJECT_ROOT}/scripts/deployment/check_jms_protocol.py" "${DMG_TEMP_DIR}/Scripts/" 2>/dev/null || echo "⚠️ check_jms_protocol.py 未找到"
cp "${PROJECT_ROOT}/scripts/deployment/cleanup_jms_handlers.py" "${DMG_TEMP_DIR}/Scripts/" 2>/dev/null || echo "⚠️ cleanup_jms_handlers.py 未找到"
cp "${PROJECT_ROOT}/scripts/deployment/卸载脚本.sh" "${DMG_TEMP_DIR}/Scripts/" 2>/dev/null || echo "⚠️ 卸载脚本.sh 未找到"

# 设置脚本执行权限
chmod +x "${DMG_TEMP_DIR}/Scripts"/*.sh 2>/dev/null || true
chmod +x "${DMG_TEMP_DIR}/Scripts"/*.py 2>/dev/null || true

# 创建Applications快捷方式
ln -sf /Applications "${DMG_TEMP_DIR}/Applications"

# 3. 创建使用说明文档
echo -e "${YELLOW}📝 复制使用说明文档...${NC}"

# 复制README文档
if [ -f "build-docs/DMG_README.md" ]; then
    cp "build-docs/DMG_README.md" "${DMG_TEMP_DIR}/README.md"
    echo "✓ 复制 README.md"
else
    echo "⚠️ build-docs/DMG_README.md 未找到，创建基本README"
    cat > "${DMG_TEMP_DIR}/README.md" << 'EOF'
# JMS Protocol Handler v1.2.0

## 🚀 快速安装
1. 拖拽 JMSProtocolHandler.app 到 Applications 文件夹
2. 运行 Scripts/register_jms_protocol.sh
3. 完成！

## 📋 系统要求
- macOS 10.15+
- Microsoft Remote Desktop (RDP)
- Terminal/iTerm2 (SSH)
EOF
fi

# 4. 创建DMG文件
echo -e "${YELLOW}💿 创建DMG文件...${NC}"
DMG_PATH="${PROJECT_ROOT}/${DMG_NAME}.dmg"
rm -f "${DMG_PATH}"

hdiutil create \
    -srcfolder "${DMG_TEMP_DIR}" \
    -volname "${PROJECT_NAME} v${VERSION}" \
    -fs HFS+ \
    -format UDZO \
    -imagekey zlib-level=9 \
    "${DMG_PATH}"

# 5. 清理临时文件
rm -rf "${DMG_TEMP_DIR}"

# 6. 显示结果
echo ""
echo -e "${GREEN}🎉 DMG程序包创建完成！${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${BLUE}📦 DMG文件:${NC} ${DMG_NAME}.dmg"
echo -e "${BLUE}📊 大小:${NC} $(du -h "${DMG_PATH}" | cut -f1)"
echo ""
echo -e "${BLUE}📋 包含内容:${NC}"
echo "  • JMSProtocolHandler.app - 主应用程序"
echo "  • Scripts/ - JMS协议管理脚本"
echo "  • README.md - 使用说明文档"
echo "  • Applications - 安装快捷方式"
echo ""
echo -e "${YELLOW}💡 使用方法:${NC}"
echo "  1. 双击 ${DMG_NAME}.dmg 挂载"
echo "  2. 拖拽 app 到 Applications 文件夹"
echo "  3. 运行 Scripts 中的注册脚本"
echo ""
echo -e "${GREEN}✅ 程序包已准备就绪！${NC}"
