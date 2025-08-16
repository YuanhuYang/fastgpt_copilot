#!/bin/bash

# FastGPT Copilot 测试脚本
# 集成测试各个服务的功能

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
COPILOT_PROXY_URL="http://localhost:8888"
FASTGPT_URL="http://localhost:3000"

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

# 测试健康检查
test_health() {
    log_info "测试健康检查..."
    
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$COPILOT_PROXY_URL/health")
    
    if [[ "$response" == "200" ]]; then
        log_success "健康检查通过"
        return 0
    else
        log_error "健康检查失败 (HTTP $response)"
        return 1
    fi
}

# 测试模型列表
test_models() {
    log_info "测试模型列表..."
    
    local response=$(curl -s "$COPILOT_PROXY_URL/v1/models")
    
    if echo "$response" | jq -e '.data | length > 0' > /dev/null 2>&1; then
        log_success "模型列表获取成功"
        echo "$response" | jq '.data[].id'
        return 0
    else
        log_error "模型列表获取失败"
        echo "Response: $response"
        return 1
    fi
}

# 测试聊天完成
test_chat_completion() {
    log_info "测试聊天完成..."
    
    local payload='{
        "model": "gpt-4",
        "messages": [
            {"role": "user", "content": "Hello, this is a test message."}
        ],
        "max_tokens": 100
    }'
    
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$COPILOT_PROXY_URL/v1/chat/completions")
    
    if echo "$response" | jq -e '.choices[0].message.content' > /dev/null 2>&1; then
        log_success "聊天完成测试通过"
        echo "Response: $(echo "$response" | jq -r '.choices[0].message.content')"
        return 0
    else
        log_error "聊天完成测试失败"
        echo "Response: $response"
        return 1
    fi
}

# 测试CORS
test_cors() {
    log_info "测试CORS..."
    
    local response=$(curl -s -I \
        -H "Origin: http://localhost:3000" \
        -H "Access-Control-Request-Method: POST" \
        "$COPILOT_PROXY_URL/v1/chat/completions")
    
    if echo "$response" | grep -i "access-control-allow-origin" > /dev/null; then
        log_success "CORS配置正确"
        return 0
    else
        log_warning "CORS配置可能有问题"
        return 1
    fi
}

# 性能测试
test_performance() {
    log_info "执行性能测试..."
    
    local start_time=$(date +%s%3N)
    test_health
    local end_time=$(date +%s%3N)
    
    local duration=$((end_time - start_time))
    
    if [[ $duration -lt 1000 ]]; then
        log_success "响应时间良好: ${duration}ms"
    elif [[ $duration -lt 3000 ]]; then
        log_warning "响应时间一般: ${duration}ms"
    else
        log_error "响应时间过长: ${duration}ms"
    fi
}

# 测试错误处理
test_error_handling() {
    log_info "测试错误处理..."
    
    # 测试无效endpoint
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$COPILOT_PROXY_URL/invalid")
    
    if [[ "$response" == "404" ]]; then
        log_success "404错误处理正确"
    else
        log_warning "404错误处理可能有问题 (HTTP $response)"
    fi
    
    # 测试无效JSON
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "invalid json" \
        "$COPILOT_PROXY_URL/v1/chat/completions")
    
    if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
        log_success "JSON错误处理正确"
    else
        log_warning "JSON错误处理可能有问题"
    fi
}

# 运行所有测试
run_all_tests() {
    log_info "开始运行所有测试..."
    echo ""
    
    local tests_passed=0
    local tests_total=6
    
    # 运行各项测试
    test_health && ((tests_passed++))
    echo ""
    
    test_models && ((tests_passed++))
    echo ""
    
    test_chat_completion && ((tests_passed++))
    echo ""
    
    test_cors && ((tests_passed++))
    echo ""
    
    test_performance && ((tests_passed++))
    echo ""
    
    test_error_handling && ((tests_passed++))
    echo ""
    
    # 总结
    log_info "测试完成: $tests_passed/$tests_total 通过"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        log_success "所有测试通过！"
        exit 0
    else
        log_warning "部分测试失败"
        exit 1
    fi
}

# 显示帮助
show_help() {
    cat << EOF
FastGPT Copilot 测试脚本

用法: $0 [选项] [测试]

选项:
    -h, --help              显示帮助信息
    -u, --url URL           指定Copilot Proxy URL [默认: $COPILOT_PROXY_URL]

测试:
    health                  健康检查测试
    models                  模型列表测试
    chat                    聊天完成测试
    cors                    CORS测试
    performance             性能测试
    errors                  错误处理测试
    all                     运行所有测试 [默认]

示例:
    $0                      # 运行所有测试
    $0 health               # 只运行健康检查
    $0 -u http://localhost:8889 all  # 使用自定义URL运行所有测试
EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -u|--url)
            COPILOT_PROXY_URL="$2"
            shift 2
            ;;
        health)
            test_health
            exit $?
            ;;
        models)
            test_models
            exit $?
            ;;
        chat)
            test_chat_completion
            exit $?
            ;;
        cors)
            test_cors
            exit $?
            ;;
        performance)
            test_performance
            exit $?
            ;;
        errors)
            test_error_handling
            exit $?
            ;;
        all)
            run_all_tests
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 默认运行所有测试
run_all_tests
