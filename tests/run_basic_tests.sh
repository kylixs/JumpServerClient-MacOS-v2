#!/bin/bash

# 基础功能测试运行脚本
set -e

echo "🧪 JMS协议管理基础功能测试"
echo "========================="

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# 创建临时测试项目
TEMP_DIR=$(mktemp -d)
TEST_PROJECT="$TEMP_DIR/BasicTests"

echo "📁 临时目录: $TEST_PROJECT"

# 创建项目结构
mkdir -p "$TEST_PROJECT/Sources/JMSProtocolManager"
mkdir -p "$TEST_PROJECT/Tests/JMSProtocolManagerTests"

# 复制源文件
echo "📋 复制源文件..."
cp Sources/JMSProtocolManager/*.swift "$TEST_PROJECT/Sources/JMSProtocolManager/"

# 复制测试文件
echo "📋 复制测试文件..."
cp tests/unit/BasicProtocolTests.swift "$TEST_PROJECT/Tests/JMSProtocolManagerTests/"

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
        .testTarget(
            name: "JMSProtocolManagerTests",
            dependencies: ["JMSProtocolManager"]
        ),
    ]
)
EOF

# 进入测试项目目录
cd "$TEST_PROJECT"

# 编译
echo ""
echo "🔨 编译..."
if swift build; then
    echo "✅ 编译成功"
else
    echo "❌ 编译失败"
    exit 1
fi

# 运行测试
echo ""
echo "🧪 运行基础测试..."
if swift test; then
    echo ""
    echo "✅ 所有基础测试通过"
    RESULT=0
else
    echo ""
    echo "❌ 部分测试失败"
    RESULT=1
fi

# 清理
cd "$PROJECT_ROOT"
rm -rf "$TEMP_DIR"

echo ""
echo "📋 测试完成"
echo "结果: $([ $RESULT -eq 0 ] && echo "✅ 通过" || echo "❌ 失败")"

exit $RESULT
