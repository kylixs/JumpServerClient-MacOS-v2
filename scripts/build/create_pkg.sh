#!/bin/bash
# PKG创建脚本

APP_NAME="JMSProtocolHandler"
PKG_NAME="JMS-Protocol-Handler-1.0.0"

# 创建包结构
mkdir -p pkg_root/Applications
cp -R "${APP_NAME}.app" pkg_root/Applications/

# 创建PKG
pkgbuild --root pkg_root --identifier com.jumpserver.protocol-handler --version 1.0.0 "${PKG_NAME}.pkg"

# 清理
rm -rf pkg_root

echo "PKG创建完成: ${PKG_NAME}.pkg"