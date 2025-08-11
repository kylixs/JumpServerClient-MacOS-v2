#!/bin/bash

# Swift Files Compilation Script with Custom Paths
# 使用自定义路径编译Swift文件

echo "=== Swift文件编译脚本 ==="

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

# 加载构建配置
if [ -f ".build-config" ]; then
    source .build-config
else
    echo "❌ 构建配置文件不存在"
    exit 1
fi

# 确保输出目录存在
mkdir -p "$BUILD_OBJECTS_DIR" "$BUILD_TEMP_DIR"

echo "📁 对象文件输出: $BUILD_OBJECTS_DIR"
echo "📁 临时文件目录: $BUILD_TEMP_DIR"

# 查找Swift文件
SWIFT_FILES=$(find . -name "*.swift" -not -path "./JMSProtocolHandler/.build/*" -not -path "./JMSProtocolHandler/build/*" -not -path "./build/*")

if [ -z "$SWIFT_FILES" ]; then
    echo "⚠️  未找到Swift文件"
    exit 0
fi

echo "🔍 找到Swift文件:"
echo "$SWIFT_FILES"
echo

# 编译每个Swift文件
for swift_file in $SWIFT_FILES; do
    filename=$(basename "$swift_file" .swift)
    output_file="$BUILD_OBJECTS_DIR/${filename}.o"
    
    echo "🔨 编译: $swift_file -> $output_file"
    
    swiftc \
        -c "$swift_file" \
        -o "$output_file" \
        -module-cache-path "$BUILD_TEMP_DIR/module-cache" \
        -emit-dependencies-path "$BUILD_TEMP_DIR/${filename}.d" \
        -emit-module-path "$BUILD_TEMP_DIR/${filename}.swiftmodule" \
        -O \
        -whole-module-optimization
    
    if [ $? -eq 0 ]; then
        echo "   ✅ 编译成功: $output_file"
    else
        echo "   ❌ 编译失败: $swift_file"
    fi
done

echo
echo "🎉 Swift文件编译完成！"
echo "📦 对象文件位置: $BUILD_OBJECTS_DIR"
