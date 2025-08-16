#!/bin/bash

# 项目配置验证脚本
# 验证项目是否满足安全和独立部署要求

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 验证敏感信息不在版本控制中
check_sensitive_info() {
    log_info "检查敏感信息是否被正确保护..."
    
    local issues=0
    
    # 检查是否有实际的配置文件被跟踪
    if git ls-files | grep -E "(\.env$|development\.env$|production\.env$)" > /dev/null; then
        log_error "发现敏感配置文件被Git跟踪！"
        git ls-files | grep -E "(\.env$|development\.env$|production\.env$)"
        ((issues++))
    else
        log_success "敏感配置文件未被Git跟踪"
    fi
    
    # 检查示例文件是否存在
    if [[ ! -f "config/development.env.example" ]]; then
        log_error "缺少开发环境配置示例文件"
        ((issues++))
    else
        log_success "开发环境配置示例文件存在"
    fi
    
    if [[ ! -f "config/production.env.example" ]]; then
        log_error "缺少生产环境配置示例文件"
        ((issues++))
    else
        log_success "生产环境配置示例文件存在"
    fi
    
    # 检查示例文件中是否包含真实密钥
    if grep -r "ghp_" config/*.example > /dev/null 2>&1; then
        log_warning "示例文件中可能包含真实的GitHub Token"
    fi
    
    if grep -r "sk-[a-zA-Z0-9]" config/*.example > /dev/null 2>&1; then
        log_warning "示例文件中可能包含真实的API密钥"
    fi
    
    return $issues
}

# 验证独立部署配置
check_independent_deployment() {
    log_info "检查独立部署配置..."
    
    local issues=0
    
    # 检查 Copilot Proxy 独立部署
    if [[ ! -f "services/copilot-proxy/docker-compose.yml" ]]; then
        log_error "Copilot Proxy 缺少独立部署配置"
        ((issues++))
    else
        log_success "Copilot Proxy 独立部署配置存在"
    fi
    
    if [[ ! -f "services/copilot-proxy/.env.example" ]]; then
        log_error "Copilot Proxy 缺少环境配置示例"
        ((issues++))
    else
        log_success "Copilot Proxy 环境配置示例存在"
    fi
    
    # 检查 FastGPT 独立部署
    if [[ ! -f "services/fastgpt/docker-compose.yml" ]]; then
        log_error "FastGPT 缺少独立部署配置"
        ((issues++))
    else
        log_success "FastGPT 独立部署配置存在"
    fi
    
    if [[ ! -f "services/fastgpt/.env.example" ]]; then
        log_error "FastGPT 缺少环境配置示例"
        ((issues++))
    else
        log_success "FastGPT 环境配置示例存在"
    fi
    
    return $issues
}

# 验证Docker配置
check_docker_configs() {
    log_info "检查Docker配置..."
    
    local issues=0
    
    # 检查主要的compose文件
    local compose_files=(
        "infrastructure/docker/docker-compose.yml"
        "infrastructure/docker/docker-compose.dev.yml"
        "infrastructure/docker/docker-compose.prod.yml"
    )
    
    for file in "${compose_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "缺少Docker配置文件: $file"
            ((issues++))
        else
            # 验证YAML语法
            if docker-compose -f "$file" config > /dev/null 2>&1; then
                log_success "Docker配置文件有效: $file"
            else
                log_error "Docker配置文件语法错误: $file"
                ((issues++))
            fi
        fi
    done
    
    return $issues
}

# 验证脚本和文档
check_scripts_docs() {
    log_info "检查脚本和文档..."
    
    local issues=0
    
    # 必需的脚本
    local scripts=(
        "scripts/deploy.sh"
        "scripts/test.sh"
        "scripts/cleanup.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "$script" ]]; then
            log_error "缺少脚本: $script"
            ((issues++))
        elif [[ ! -x "$script" ]]; then
            log_warning "脚本没有执行权限: $script"
        else
            log_success "脚本存在且可执行: $script"
        fi
    done
    
    # 必需的文档
    local docs=(
        "README.md"
        "docs/deployment.md"
        "docs/configuration.md"
        "docs/troubleshooting.md"
    )
    
    for doc in "${docs[@]}"; do
        if [[ ! -f "$doc" ]]; then
            log_error "缺少文档: $doc"
            ((issues++))
        else
            log_success "文档存在: $doc"
        fi
    done
    
    return $issues
}

# 主验证函数
main() {
    log_info "开始项目配置验证..."
    echo ""
    
    local total_issues=0
    
    # 运行各项检查
    check_sensitive_info
    total_issues=$((total_issues + $?))
    echo ""
    
    check_independent_deployment
    total_issues=$((total_issues + $?))
    echo ""
    
    check_docker_configs
    total_issues=$((total_issues + $?))
    echo ""
    
    check_scripts_docs
    total_issues=$((total_issues + $?))
    echo ""
    
    # 总结
    if [[ $total_issues -eq 0 ]]; then
        log_success "🎉 所有验证通过！项目配置正确。"
        echo ""
        log_info "项目满足以下要求："
        echo "  ✅ 敏感信息已被保护，不会提交到版本控制"
        echo "  ✅ Copilot Proxy 和 FastGPT 可以独立部署"
        echo "  ✅ 提供了完整的部署脚本和文档"
        echo "  ✅ Docker 配置文件语法正确"
        echo ""
        log_info "可以安全地提交到代码仓库！"
    else
        log_error "发现 $total_issues 个问题，请修复后再提交。"
        exit 1
    fi
}

# 检查是否在项目根目录
if [[ ! -f "README.md" ]] || [[ ! -d "services" ]]; then
    log_error "请在项目根目录运行此脚本"
    exit 1
fi

main
