#!/bin/bash

# JMS Protocol Handler - 镜像构建脚本
# 用于构建DMG安装包和Docker开发环境镜像

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="JMSProtocolHandler"
VERSION="1.0.0"
BUILD_DIR="build"
SCRIPTS_DIR="scripts/build"
DOCKER_DIR="docker"

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

# 检查依赖
check_dependencies() {
    log_info "检查构建依赖..."
    
    # 检查 Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode 未安装或未配置"
        exit 1
    fi
    
    # 检查 Docker (可选)
    if command -v docker &> /dev/null; then
        log_info "Docker 已安装"
        DOCKER_AVAILABLE=true
    else
        log_warning "Docker 未安装，跳过 Docker 镜像构建"
        DOCKER_AVAILABLE=false
    fi
    
    # 检查 hdiutil (macOS DMG 工具)
    if ! command -v hdiutil &> /dev/null; then
        log_error "hdiutil 未找到，无法创建 DMG"
        exit 1
    fi
    
    log_success "依赖检查完成"
}

# 构建应用程序
build_app() {
    log_info "构建 ${PROJECT_NAME} 应用程序..."
    
    cd "${PROJECT_NAME}"
    
    # 使用自定义构建路径
    xcodebuild \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${PROJECT_NAME}" \
        -configuration Release \
        -derivedDataPath "../${BUILD_DIR}/xcode/DerivedData" \
        OBJROOT="../${BUILD_DIR}/objects" \
        SYMROOT="../${BUILD_DIR}/artifacts" \
        build
    
    cd ..
    
    # 复制应用程序到项目根目录
    if [ -d "${BUILD_DIR}/artifacts/Release/${PROJECT_NAME}.app" ]; then
        cp -R "${BUILD_DIR}/artifacts/Release/${PROJECT_NAME}.app" .
        log_success "应用程序构建完成: ${PROJECT_NAME}.app"
    else
        log_error "应用程序构建失败"
        exit 1
    fi
}

# 创建 DMG 镜像
create_dmg() {
    log_info "创建 DMG 安装镜像..."
    
    local dmg_name="JMS-Protocol-Handler-v${VERSION}.dmg"
    local temp_dmg="temp-${dmg_name}"
    local volume_name="JMS Protocol Handler Installer"
    local temp_dir="temp_dmg"
    
    # 清理旧文件
    rm -f "${dmg_name}" "${temp_dmg}"
    rm -rf "${temp_dir}"
    
    # 创建临时目录
    mkdir -p "${temp_dir}"
    
    # 复制应用程序
    cp -R "${PROJECT_NAME}.app" "${temp_dir}/"
    
    # 创建 Applications 链接
    ln -s /Applications "${temp_dir}/Applications"
    
    # 创建临时 DMG
    hdiutil create \
        -srcfolder "${temp_dir}" \
        -volname "${volume_name}" \
        -fs HFS+ \
        -fsargs "-c c=64,a=16,e=16" \
        -format UDRW \
        -size 100m \
        "${temp_dmg}"
    
    # 挂载临时 DMG
    local device=$(hdiutil attach -readwrite -noverify -noautoopen "${temp_dmg}" | egrep '^/dev/' | sed 1q | awk '{print $1}')
    local mount_point="/Volumes/${volume_name}"
    
    # 等待挂载完成
    sleep 2
    
    # 卸载临时 DMG
    hdiutil detach "${device}"
    
    # 创建最终的压缩 DMG
    hdiutil convert "${temp_dmg}" \
        -format UDZO \
        -imagekey zlib-level=9 \
        -o "${dmg_name}"
    
    # 清理临时文件
    rm -f "${temp_dmg}"
    rm -rf "${temp_dir}"
    
    if [ -f "${dmg_name}" ]; then
        local dmg_size=$(du -h "${dmg_name}" | cut -f1)
        log_success "DMG 镜像创建完成: ${dmg_name} (${dmg_size})"
    else
        log_error "DMG 镜像创建失败"
        exit 1
    fi
}

# 构建 Docker 镜像
build_docker_image() {
    if [ "$DOCKER_AVAILABLE" = false ]; then
        log_warning "跳过 Docker 镜像构建"
        return
    fi
    
    log_info "构建 Docker 开发环境镜像..."
    
    # 构建开发环境镜像
    docker build \
        -f "${DOCKER_DIR}/Dockerfile" \
        -t "jms-protocol-handler:${VERSION}" \
        -t "jms-protocol-handler:latest" \
        .
    
    log_success "Docker 镜像构建完成: jms-protocol-handler:${VERSION}"
}

# 验证镜像
verify_images() {
    log_info "验证构建的镜像..."
    
    # 验证 DMG
    local dmg_name="JMS-Protocol-Handler-v${VERSION}.dmg"
    if [ -f "${dmg_name}" ]; then
        log_success "✅ DMG 镜像: ${dmg_name}"
        hdiutil verify "${dmg_name}" && log_success "DMG 完整性验证通过"
    else
        log_error "❌ DMG 镜像未找到"
    fi
    
    # 验证应用程序
    if [ -d "${PROJECT_NAME}.app" ]; then
        log_success "✅ 应用程序: ${PROJECT_NAME}.app"
        codesign -dv "${PROJECT_NAME}.app" 2>/dev/null && log_success "应用程序签名验证通过" || log_warning "应用程序未签名"
    else
        log_error "❌ 应用程序未找到"
    fi
    
    # 验证 Docker 镜像
    if [ "$DOCKER_AVAILABLE" = true ]; then
        if docker images | grep -q "jms-protocol-handler"; then
            log_success "✅ Docker 镜像: jms-protocol-handler:${VERSION}"
        else
            log_error "❌ Docker 镜像未找到"
        fi
    fi
}

# 清理函数
cleanup() {
    log_info "清理临时文件..."
    rm -rf temp_dmg temp-*.dmg
    log_success "清理完成"
}

# 主函数
main() {
    log_info "开始构建 JMS Protocol Handler 镜像..."
    log_info "版本: ${VERSION}"
    
    # 设置错误处理
    trap cleanup EXIT
    
    # 执行构建步骤
    check_dependencies
    build_app
    create_dmg
    build_docker_image
    verify_images
    
    log_success "所有镜像构建完成！"
    
    # 显示构建结果
    echo ""
    log_info "构建结果:"
    ls -la *.dmg *.app 2>/dev/null || true
    
    if [ "$DOCKER_AVAILABLE" = true ]; then
        echo ""
        log_info "Docker 镜像:"
        docker images | grep jms-protocol-handler || true
    fi
}

# 处理命令行参数
case "${1:-all}" in
    "app")
        check_dependencies
        build_app
        ;;
    "dmg")
        create_dmg
        ;;
    "docker")
        build_docker_image
        ;;
    "verify")
        verify_images
        ;;
    "clean")
        cleanup
        ;;
    "all"|"")
        main
        ;;
    *)
        echo "用法: $0 [app|dmg|docker|verify|clean|all]"
        echo "  app    - 仅构建应用程序"
        echo "  dmg    - 仅创建 DMG 镜像"
        echo "  docker - 仅构建 Docker 镜像"
        echo "  verify - 验证已构建的镜像"
        echo "  clean  - 清理临时文件"
        echo "  all    - 执行完整构建流程 (默认)"
        exit 1
        ;;
esac
