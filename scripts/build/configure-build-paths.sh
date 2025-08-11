#!/bin/bash

# JMS Protocol Handler Build Path Configuration Script
# 配置构建路径，确保编译产物输出到正确的目录

echo "=== JMS Protocol Handler 构建路径配置 ==="
echo

# 设置颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "📁 项目根目录: $PROJECT_ROOT"

# 加载构建配置
if [ -f ".build-config" ]; then
    source .build-config
    echo -e "${GREEN}✅ 已加载构建配置文件${NC}"
else
    echo -e "${YELLOW}⚠️  构建配置文件不存在，使用默认配置${NC}"
    BUILD_ROOT="${PROJECT_ROOT}/build"
    BUILD_OBJECTS_DIR="${BUILD_ROOT}/objects"
    BUILD_TEMP_DIR="${BUILD_ROOT}/temp"
    BUILD_ARTIFACTS_DIR="${BUILD_ROOT}/artifacts"
fi

echo

# 创建必要的目录
echo -e "${BLUE}🏗️ 创建构建目录结构...${NC}"

directories=(
    "$BUILD_ROOT"
    "$BUILD_OBJECTS_DIR"
    "$BUILD_TEMP_DIR"
    "$BUILD_ARTIFACTS_DIR"
    "${BUILD_ROOT}/swift-build"
    "${BUILD_ROOT}/xcode"
    "${BUILD_ROOT}/derived-data"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "   ✅ 创建目录: $dir"
    else
        echo "   ℹ️  目录已存在: $dir"
    fi
done

echo

# 配置Swift Package Manager构建路径
echo -e "${BLUE}🔧 配置Swift Package Manager...${NC}"

if [ -d "JMSProtocolHandler" ]; then
    cd JMSProtocolHandler
    
    # 创建Swift Package配置
    cat > .swiftpm/xcode/package.xcworkspace/xcshareddata/swiftpm/Package.resolved << 'EOF'
{
  "pins" : [ ],
  "version" : 2
}
EOF

    # 设置构建路径环境变量
    export SWIFT_BUILD_PATH="${BUILD_ROOT}/swift-build"
    
    echo "   ✅ Swift构建路径: $SWIFT_BUILD_PATH"
    
    cd ..
else
    echo -e "${YELLOW}⚠️  JMSProtocolHandler目录不存在${NC}"
fi

echo

# 创建Xcode构建配置
echo -e "${BLUE}🔧 配置Xcode构建路径...${NC}"

# 创建xcconfig文件
cat > build-paths.xcconfig << 'EOF'
// JMS Protocol Handler Build Paths Configuration
// Xcode构建路径配置文件

// 构建根目录
BUILD_ROOT = $(PROJECT_DIR)/../build

// 构建产物输出目录
CONFIGURATION_BUILD_DIR = $(BUILD_ROOT)/xcode/$(CONFIGURATION)
BUILT_PRODUCTS_DIR = $(CONFIGURATION_BUILD_DIR)

// 中间文件目录
OBJROOT = $(BUILD_ROOT)/temp/xcode
SYMROOT = $(BUILD_ROOT)/xcode

// DerivedData路径
DERIVED_DATA_DIR = $(BUILD_ROOT)/derived-data

// 编译器输出
COMPILER_INDEX_STORE_PATH = $(BUILD_ROOT)/temp/index-store

// 模块缓存
SWIFT_MODULE_CACHE_PATH = $(BUILD_ROOT)/temp/module-cache

// 预编译头文件
PRECOMPS_INCLUDE_HEADERS_FROM_BUILT_PRODUCTS_DIR = YES
SHARED_PRECOMPS_DIR = $(BUILD_ROOT)/temp/precomps

// 调试信息
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
DWARF_DSYM_FOLDER_PATH = $(BUILD_ROOT)/artifacts/dsym

// 归档路径
ARCHIVE_PATH = $(BUILD_ROOT)/artifacts/archive
EOF

echo "   ✅ 创建Xcode配置文件: build-paths.xcconfig"

echo

# 更新.gitignore
echo -e "${BLUE}📝 更新.gitignore配置...${NC}"

# 添加新的构建路径到.gitignore
cat >> .gitignore << 'EOF'

# Build configuration
build-paths.xcconfig
.build-config

# Custom build directories
build/xcode/
build/swift-build/
build/derived-data/
build/temp/
build/artifacts/

EOF

echo "   ✅ 已更新.gitignore文件"

echo

# 创建构建脚本
echo -e "${BLUE}🔧 创建自定义构建脚本...${NC}"

cat > scripts/build/build-with-custom-paths.sh << 'EOF'
#!/bin/bash

# JMS Protocol Handler Custom Build Script
# 使用自定义路径构建项目

echo "=== 使用自定义路径构建项目 ==="

# 加载构建配置
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

if [ -f ".build-config" ]; then
    source .build-config
    echo "✅ 已加载构建配置"
else
    echo "❌ 构建配置文件不存在"
    exit 1
fi

# 确保目录存在
mkdir -p "$BUILD_OBJECTS_DIR" "$BUILD_TEMP_DIR" "$BUILD_ARTIFACTS_DIR"

# 构建选项
CONFIGURATION=${1:-Release}
SCHEME=${2:-JMSProtocolHandler}

echo "📦 构建配置: $CONFIGURATION"
echo "🎯 构建方案: $SCHEME"
echo "📁 输出目录: $BUILD_ROOT"

# 使用自定义路径构建
if [ -d "JMSProtocolHandler/JMSProtocolHandler.xcodeproj" ]; then
    echo "🏗️ 使用Xcode构建..."
    
    cd JMSProtocolHandler
    
    xcodebuild \
        -project JMSProtocolHandler.xcodeproj \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -xcconfig "../build-paths.xcconfig" \
        OBJROOT="$BUILD_TEMP_DIR/xcode" \
        SYMROOT="$BUILD_ROOT/xcode" \
        CONFIGURATION_BUILD_DIR="$BUILD_ROOT/xcode/$CONFIGURATION" \
        DERIVED_DATA_DIR="$BUILD_ROOT/derived-data" \
        build
    
    BUILD_RESULT=$?
    cd ..
    
    if [ $BUILD_RESULT -eq 0 ]; then
        echo "✅ Xcode构建成功"
        
        # 复制最终产物到artifacts目录
        if [ -f "$BUILD_ROOT/xcode/$CONFIGURATION/JMSProtocolHandler.app/Contents/MacOS/JMSProtocolHandler" ]; then
            cp -R "$BUILD_ROOT/xcode/$CONFIGURATION/JMSProtocolHandler.app" "$BUILD_ARTIFACTS_DIR/"
            echo "✅ 应用程序已复制到artifacts目录"
        fi
    else
        echo "❌ Xcode构建失败"
        exit 1
    fi
else
    echo "❌ 未找到Xcode项目文件"
    exit 1
fi

echo "🎉 构建完成！"
echo "📦 输出位置: $BUILD_ARTIFACTS_DIR/JMSProtocolHandler.app"
EOF

chmod +x scripts/build/build-with-custom-paths.sh
echo "   ✅ 创建自定义构建脚本: scripts/build/build-with-custom-paths.sh"

echo

# 创建Swift编译脚本
echo -e "${BLUE}🔧 创建Swift编译脚本...${NC}"

cat > scripts/build/compile-swift-files.sh << 'EOF'
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
EOF

chmod +x scripts/build/compile-swift-files.sh
echo "   ✅ 创建Swift编译脚本: scripts/build/compile-swift-files.sh"

echo

# 显示配置总结
echo -e "${GREEN}📊 构建路径配置总结:${NC}"
echo "   📁 构建根目录: $BUILD_ROOT"
echo "   📁 对象文件目录: $BUILD_OBJECTS_DIR"
echo "   📁 临时文件目录: $BUILD_TEMP_DIR"
echo "   📁 构建产物目录: $BUILD_ARTIFACTS_DIR"
echo "   📁 Xcode构建目录: ${BUILD_ROOT}/xcode"
echo "   📁 Swift构建目录: ${BUILD_ROOT}/swift-build"

echo
echo -e "${GREEN}🎯 使用方法:${NC}"
echo "   # 使用自定义路径构建Xcode项目"
echo "   ./scripts/build/build-with-custom-paths.sh"
echo
echo "   # 编译单独的Swift文件"
echo "   ./scripts/build/compile-swift-files.sh"
echo
echo "   # 清理构建文件"
echo "   ./scripts/build/clean.sh"

echo
echo "=== 构建路径配置完成 ==="
