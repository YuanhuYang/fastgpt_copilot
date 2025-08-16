#!/bin/bash

# 清理旧文件脚本
# 删除重构过程中产生的重复文件

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

# 要删除的旧文件列表
OLD_FILES=(
    "config.json"
    "CONTAINER_DEPLOYMENT_GUIDE.md"
    "COPILOT_CONFIG.md"
    "COPILOT_INTEGRATION_GUIDE.md"
    "deploy_copilot_container.sh"
    "deploy_copilot_proxy.sh"
    "deploy.sh"
    "docker-compose.copilot.yml"
    "docker-compose.prod.yml"
    "docker-compose.yml"
    "get_token.js"
    "run.sh"
    "setup_copilot_proxy.sh"
    "setup.sh"
    "test_copilot_chat_api.sh"
    "test_copilot_container.sh"
    "test_github_copilot_api.sh"
    "test.sh"
)

# 要删除的旧目录列表
OLD_DIRS=(
    "copilot-proxy"
    "nginx"
    "infrastructure/docker"
)

log_info "开始清理旧文件..."

# 删除旧文件
for file in "${OLD_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        log_info "删除文件: $file"
        rm "$file"
    fi
done

# 删除旧目录
for dir in "${OLD_DIRS[@]}"; do
    if [[ -d "$dir" && "$dir" != "infrastructure/docker" ]]; then
        log_info "删除目录: $dir"
        rm -rf "$dir"
    fi
done

# 保留某些重要的旧文件作为备份
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 备份特定文件
if [[ -f "config/config.json" ]]; then
    cp "config/config.json" "$BACKUP_DIR/"
    log_info "备份 config/config.json 到 $BACKUP_DIR"
fi

log_success "旧文件清理完成"
log_info "重要文件已备份到: $BACKUP_DIR"

# 显示当前目录结构
log_info "当前项目结构:"
tree -L 3 -I 'node_modules|.git|backup_*' || ls -la
