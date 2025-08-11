#!/bin/bash
# DMG创建脚本

APP_NAME="JMSProtocolHandler"
DMG_NAME="JMS-Protocol-Handler-1.0.0"

# 创建临时目录
mkdir -p dmg_temp

# 复制应用程序
cp -R "${APP_NAME}.app" dmg_temp/

# 复制文档
cp "安装说明.txt" dmg_temp/
cp "许可协议.txt" dmg_temp/

# 创建DMG
hdiutil create -volname "${DMG_NAME}" -srcfolder dmg_temp -ov -format UDZO "${DMG_NAME}.dmg"

# 清理
rm -rf dmg_temp

echo "DMG创建完成: ${DMG_NAME}.dmg"