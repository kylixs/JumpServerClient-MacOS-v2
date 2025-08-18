#!/bin/bash

# 严格协议检测测试脚本
set -e

echo "🔍 JMS协议检测严格性测试"
echo "========================"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "📁 项目根目录: $PROJECT_ROOT"

# 创建临时测试项目
TEMP_DIR=$(mktemp -d)
TEST_PROJECT="$TEMP_DIR/StrictDetectionTest"

echo "📁 临时目录: $TEST_PROJECT"

# 创建项目结构
mkdir -p "$TEST_PROJECT/Sources/JMSProtocolManager"
mkdir -p "$TEST_PROJECT/Tests/JMSProtocolManagerTests"

# 复制源文件
echo "📋 复制源文件..."
cp Sources/JMSProtocolManager/*.swift "$TEST_PROJECT/Sources/JMSProtocolManager/"

# 复制测试文件
echo "📋 复制测试文件..."
cp tests/unit/ProtocolDetectionStrictTest.swift "$TEST_PROJECT/Tests/JMSProtocolManagerTests/"

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

# 运行严格测试
echo ""
echo "🧪 运行严格协议检测测试..."
echo "注意: 此测试会详细验证协议检测逻辑的严谨性"
echo ""

if swift test --filter ProtocolDetectionStrictTest 2>&1; then
    echo ""
    echo "✅ 严格协议检测测试完成"
    RESULT=0
else
    echo ""
    echo "❌ 严格测试失败"
    RESULT=1
fi

# 清理
cd "$PROJECT_ROOT"
rm -rf "$TEMP_DIR"

echo ""
echo "📋 严格测试总结"
echo "==============="
echo "测试类型: 协议检测逻辑严谨性验证"
echo "测试重点: 路径验证、状态识别、唯一性检查"
echo "测试结果: $([ $RESULT -eq 0 ] && echo "✅ 通过" || echo "❌ 失败")"

echo ""
echo "🎯 验证要点:"
echo "1. 处理器路径应该指向实际存在的.app文件"
echo "2. 当前应用识别应该准确"
echo "3. 不应该有重复的处理器条目"
echo "4. 状态分类应该正确"
echo "5. 多次检测结果应该一致"

exit $RESULT
