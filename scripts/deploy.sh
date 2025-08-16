#!/bin/bash

# FastGPT Copilot 部署脚本
# 支持开发环境和生产环境部署

set -e

# 默认配置
ENVIRONMENT="development"
PROJECT_NAME="fastgpt-copilot"
COMPOSE_DIR="./infrastructure/docker"
CONFIG_DIR="./config"

# 颜色输出
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

# 显示帮助信息
show_help() {
    cat << EOF
FastGPT Copilot 部署脚本

用法: $0 [选项] <命令>

选项:
    -e, --env ENVIRONMENT    部署环境 (development|production) [默认: development]
    -h, --help              显示帮助信息

命令:
    deploy                  部署服务
    start                   启动服务
    stop                    停止服务
    restart                 重启服务
    logs                    查看日志
    status                  查看状态
    clean                   清理资源
    backup                  备份数据

示例:
    $0 deploy                       # 部署开发环境
    $0 -e production deploy         # 部署生产环境
    $0 logs                         # 查看开发环境日志
    $0 -e production logs           # 查看生产环境日志
    $0 status                       # 查看服务状态
EOF
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装或不在 PATH 中"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装或不在 PATH 中"
        exit 1
    fi
    
    log_success "依赖检查完成"
}

# 检查环境变量
check_env_vars() {
    log_info "检查环境变量..."
    
    local env_file="${CONFIG_DIR}/${ENVIRONMENT}.env"
    if [[ ! -f "$env_file" ]]; then
        log_error "环境配置文件不存在: $env_file"
        exit 1
    fi
    
    source "$env_file"
    
    if [[ -z "$GITHUB_TOKEN" ]]; then
        log_error "GITHUB_TOKEN 环境变量未设置"
        exit 1
    fi
    
    log_success "环境变量检查完成"
}

# 获取compose文件
get_compose_file() {
    if [[ "$ENVIRONMENT" == "production" ]]; then
        echo "$COMPOSE_DIR/docker-compose.prod.yml"
    elif [[ "$ENVIRONMENT" == "development" ]]; then
        echo "$COMPOSE_DIR/docker-compose.dev.yml"
    else
        echo "$COMPOSE_DIR/docker-compose.yml"
    fi
}

# 部署服务
deploy() {
    log_info "开始部署 $ENVIRONMENT 环境..."
    
    check_dependencies
    check_env_vars
    
    local compose_file=$(get_compose_file)
    local env_file="${CONFIG_DIR}/${ENVIRONMENT}.env"
    
    log_info "使用配置文件: $compose_file"
    log_info "使用环境文件: $env_file"
    
    # 构建并启动服务
    docker-compose -f "$compose_file" --env-file "$env_file" up --build -d
    
    log_success "$ENVIRONMENT 环境部署完成"
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 10
    
    # 检查服务状态
    status
}

# 启动服务
start() {
    log_info "启动 $ENVIRONMENT 环境服务..."
    
    local compose_file=$(get_compose_file)
    local env_file="${CONFIG_DIR}/${ENVIRONMENT}.env"
    
    docker-compose -f "$compose_file" --env-file "$env_file" start
    
    log_success "$ENVIRONMENT 环境服务启动完成"
}

# 停止服务
stop() {
    log_info "停止 $ENVIRONMENT 环境服务..."
    
    local compose_file=$(get_compose_file)
    local env_file="${CONFIG_DIR}/${ENVIRONMENT}.env"
    
    docker-compose -f "$compose_file" --env-file "$env_file" stop
    
    log_success "$ENVIRONMENT 环境服务停止完成"
}

# 重启服务
restart() {
    log_info "重启 $ENVIRONMENT 环境服务..."
    stop
    start
    log_success "$ENVIRONMENT 环境服务重启完成"
}

# 查看日志
logs() {
    local compose_file=$(get_compose_file)
    local env_file="${CONFIG_DIR}/${ENVIRONMENT}.env"
    
    docker-compose -f "$compose_file" --env-file "$env_file" logs -f
}

# 查看状态
status() {
    log_info "查看 $ENVIRONMENT 环境服务状态..."
    
    local compose_file=$(get_compose_file)
    local env_file="${CONFIG_DIR}/${ENVIRONMENT}.env"
    
    docker-compose -f "$compose_file" --env-file "$env_file" ps
    
    # 检查健康状态
    echo ""
    log_info "健康检查..."
    
    # 检查copilot-proxy健康状态
    if curl -s http://localhost:8888/health > /dev/null 2>&1; then
        log_success "Copilot Proxy 服务健康"
    else
        log_warning "Copilot Proxy 服务可能存在问题"
    fi
}

# 清理资源
clean() {
    log_warning "这将删除所有容器、镜像和数据卷！"
    read -p "确认继续? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local compose_file=$(get_compose_file)
        local env_file="${CONFIG_DIR}/${ENVIRONMENT}.env"
        
        docker-compose -f "$compose_file" --env-file "$env_file" down -v --rmi all
        log_success "清理完成"
    else
        log_info "操作已取消"
    fi
}

# 备份数据
backup() {
    log_info "备份 $ENVIRONMENT 环境数据..."
    
    local backup_dir="./backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 备份MongoDB
    docker exec fastgpt-mongo-${ENVIRONMENT} mongodump --authenticationDatabase admin -u myusername -p mypassword --out /backups/mongo
    docker cp "fastgpt-mongo-${ENVIRONMENT}:/backups/mongo" "$backup_dir/"
    
    # 备份PostgreSQL
    docker exec fastgpt-pg-${ENVIRONMENT} pg_dump -U username postgres > "$backup_dir/postgres.sql"
    
    log_success "备份完成: $backup_dir"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        deploy|start|stop|restart|logs|status|clean|backup)
            COMMAND="$1"
            shift
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 验证环境参数
if [[ "$ENVIRONMENT" != "development" && "$ENVIRONMENT" != "production" ]]; then
    log_error "无效的环境: $ENVIRONMENT"
    log_info "支持的环境: development, production"
    exit 1
fi

# 执行命令
case $COMMAND in
    deploy)
        deploy
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    logs)
        logs
        ;;
    status)
        status
        ;;
    clean)
        clean
        ;;
    backup)
        backup
        ;;
    *)
        log_error "请指定命令"
        show_help
        exit 1
        ;;
esac
