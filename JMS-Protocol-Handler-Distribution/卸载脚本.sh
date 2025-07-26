#!/bin/bash
# JMS Protocol Handler 卸载脚本

echo "开始卸载 JMS Protocol Handler..."

# 停止应用程序
killall JMSProtocolHandler 2>/dev/null

# 删除应用程序
rm -rf "/Applications/JMSProtocolHandler.app"

# 清理用户数据
rm -rf "~/Library/Application Support/JMSProtocolHandler"
rm -rf "~/Library/Caches/com.jumpserver.protocol-handler"
rm -rf "~/Library/Logs/JMSProtocolHandler"

# 清理临时文件
rm -rf "/tmp/JMSProtocolHandler"

# 重置协议处理程序 (需要用户手动操作)
echo "请手动重置协议处理程序:"
echo "1. 打开系统偏好设置"
echo "2. 选择'通用' -> '默认网页浏览器'"
echo "3. 重置 jms:// 协议的默认应用程序"

echo "卸载完成！"