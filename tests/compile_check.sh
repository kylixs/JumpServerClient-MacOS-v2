#!/bin/bash

# 简化的编译检查脚本
set -e

echo "🔨 JMS协议管理功能编译检查"
echo "=========================="

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# 创建临时测试项目
TEMP_DIR=$(mktemp -d)
TEST_PROJECT="$TEMP_DIR/CompileCheck"

echo "📁 临时目录: $TEST_PROJECT"

# 创建项目结构
mkdir -p "$TEST_PROJECT/Sources/JMSProtocolManager"

# 复制源文件
echo "📋 复制源文件..."
cp Sources/JMSProtocolManager/*.swift "$TEST_PROJECT/Sources/JMSProtocolManager/"

# 创建Package.swift
cat > "$TEST_PROJECT/Package.swift" << 'EOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JMSProtocolManager",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "JMSProtocolManager",
            targets: ["JMSProtocolManager"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "JMSProtocolManager",
            dependencies: []
        ),
    ]
)
EOF

# 进入测试项目目录
cd "$TEST_PROJECT"

# 编译检查
echo ""
echo "🔨 编译检查..."
if swift build 2>&1; then
    echo ""
    echo "✅ 编译成功，无错误"
    RESULT=0
else
    echo ""
    echo "❌ 编译失败"
    RESULT=1
fi

# 清理
cd "$PROJECT_ROOT"
rm -rf "$TEMP_DIR"

exit $RESULT
