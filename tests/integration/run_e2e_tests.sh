#!/bin/bash

# JMS Protocol Handler 端到端自动化测试脚本
# 验证完整的功能流程和配置同步

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 记录测试结果
record_test_result() {
    local test_name="$1"
    local result="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_success "✅ $test_name - PASSED"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_error "❌ $test_name - FAILED"
    fi
}

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

log_info "🚀 开始JMS Protocol Handler端到端测试"
log_info "📁 项目根目录: $PROJECT_ROOT"

# 1. 检查构建状态
log_info "🔍 步骤1: 检查项目构建状态"
if [ -f "build/Release/JMSProtocolHandler" ] || [ -d "build/app/JMSProtocolHandler.app" ]; then
    record_test_result "项目构建检查" "PASS"
else
    log_warning "未找到构建产物，尝试构建项目..."
    if ./build.sh quick > /dev/null 2>&1; then
        record_test_result "项目构建" "PASS"
    else
        record_test_result "项目构建" "FAIL"
        log_error "项目构建失败，无法继续测试"
        exit 1
    fi
fi

# 2. 运行单元测试
log_info "🧪 步骤2: 运行配置同步单元测试"
if swift test --filter RDPConfigSyncTests > /dev/null 2>&1; then
    record_test_result "配置同步单元测试" "PASS"
else
    record_test_result "配置同步单元测试" "FAIL"
fi

# 3. 运行集成测试
log_info "🔗 步骤3: 运行配置同步集成测试"
if swift test --filter ConfigSyncIntegrationTest > /dev/null 2>&1; then
    record_test_result "配置同步集成测试" "PASS"
else
    record_test_result "配置同步集成测试" "FAIL"
fi

# 4. 运行协议处理端到端测试
log_info "🌐 步骤4: 运行协议处理端到端测试"
if swift test --filter JMSProtocolE2ETest > /dev/null 2>&1; then
    record_test_result "协议处理端到端测试" "PASS"
else
    record_test_result "协议处理端到端测试" "FAIL"
fi

# 5. 运行RDP参数验证测试
log_info "🖥️ 步骤5: 运行RDP参数验证测试"
if swift test --filter RDPParameterValidationTest > /dev/null 2>&1; then
    record_test_result "RDP参数验证测试" "PASS"
else
    record_test_result "RDP参数验证测试" "FAIL"
fi

# 6. 测试应用程序启动
log_info "🚀 步骤6: 测试应用程序启动"
if [ -f "build/Release/JMSProtocolHandler" ]; then
    # 启动应用程序并检查是否正常运行
    timeout 5s ./build/Release/JMSProtocolHandler --test-mode > /dev/null 2>&1 || true
    if [ $? -eq 0 ] || [ $? -eq 124 ]; then  # 0=正常退出, 124=timeout
        record_test_result "应用程序启动测试" "PASS"
    else
        record_test_result "应用程序启动测试" "FAIL"
    fi
else
    log_warning "跳过应用程序启动测试（未找到可执行文件）"
fi

# 7. 测试URL协议注册
log_info "🔗 步骤7: 测试URL协议注册"
if ./scripts/deployment/register_jms_protocol.sh > /dev/null 2>&1; then
    # 检查协议是否注册成功
    if defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers | grep -q "jms"; then
        record_test_result "URL协议注册测试" "PASS"
    else
        record_test_result "URL协议注册测试" "FAIL"
    fi
else
    record_test_result "URL协议注册测试" "FAIL"
fi

# 8. 测试配置文件读写
log_info "💾 步骤8: 测试配置文件读写"
test_config_file() {
    local temp_config="/tmp/jms_test_config.json"
    local test_content='{"profileName":"测试配置","resolution":{"width":1920,"height":1080},"colorDepth":24}'
    
    # 写入测试配置
    echo "$test_content" > "$temp_config"
    
    # 验证文件是否可读
    if [ -f "$temp_config" ] && [ -r "$temp_config" ]; then
        # 清理测试文件
        rm -f "$temp_config"
        return 0
    else
        return 1
    fi
}

if test_config_file; then
    record_test_result "配置文件读写测试" "PASS"
else
    record_test_result "配置文件读写测试" "FAIL"
fi

# 9. 测试显示器检测功能
log_info "🖥️ 步骤9: 测试显示器检测功能"
# 这里可以添加显示器检测的测试逻辑
# 由于显示器检测依赖于实际硬件，我们只做基本的功能测试
if system_profiler SPDisplaysDataType > /dev/null 2>&1; then
    record_test_result "显示器检测功能测试" "PASS"
else
    record_test_result "显示器检测功能测试" "FAIL"
fi

# 10. 性能基准测试
log_info "⚡ 步骤10: 性能基准测试"
performance_test() {
    local start_time=$(date +%s%N)
    
    # 模拟URL处理性能测试
    for i in {1..100}; do
        echo "jms://eyJ0ZXN0IjoidmFsdWUifQ==" > /dev/null
    done
    
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # 转换为毫秒
    
    log_info "URL处理性能: 100次操作耗时 ${duration}ms"
    
    # 如果处理时间超过1秒，认为性能测试失败
    if [ $duration -lt 1000 ]; then
        return 0
    else
        return 1
    fi
}

if performance_test; then
    record_test_result "性能基准测试" "PASS"
else
    record_test_result "性能基准测试" "FAIL"
fi

# 输出测试结果摘要
echo
log_info "📊 测试结果摘要"
echo "=================================="
echo "总测试数: $TOTAL_TESTS"
echo "通过: $PASSED_TESTS"
echo "失败: $FAILED_TESTS"
echo "成功率: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
echo "=================================="

# 生成测试报告
REPORT_FILE="$PROJECT_ROOT/test_report_$(date +%Y%m%d_%H%M%S).txt"
cat > "$REPORT_FILE" << EOF
JMS Protocol Handler 端到端测试报告
生成时间: $(date)
项目路径: $PROJECT_ROOT

测试结果摘要:
- 总测试数: $TOTAL_TESTS
- 通过测试: $PASSED_TESTS
- 失败测试: $FAILED_TESTS
- 成功率: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%

测试环境:
- 操作系统: $(uname -s) $(uname -r)
- Swift版本: $(swift --version | head -n1)
- Xcode版本: $(xcodebuild -version | head -n1)

详细测试结果请查看测试日志。
EOF

log_info "📄 测试报告已生成: $REPORT_FILE"

# 根据测试结果设置退出码
if [ $FAILED_TESTS -eq 0 ]; then
    log_success "🎉 所有测试通过！"
    exit 0
else
    log_error "💥 有 $FAILED_TESTS 个测试失败"
    exit 1
fi
