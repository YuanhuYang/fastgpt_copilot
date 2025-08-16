#!/bin/bash

# FastGPT 快速配置脚本
# 此脚本将帮助您快速配置 FastGPT 项目

echo "🚀 FastGPT 快速配置脚本"
echo "=========================="

# 检查是否存在 .env 文件
if [ ! -f ".env" ]; then
    echo "❌ .env 文件不存在，请先创建 .env 文件"
    exit 1
fi

echo "✅ 发现 .env 文件"

# 生成随机密钥函数
generate_random_key() {
    openssl rand -hex 32
}

echo ""
echo "🔧 配置检查和修复..."

# 检查必要的环境变量
echo "📋 检查环境变量配置..."

# 读取当前 .env 文件
source .env

# 检查 GitHub Copilot API 密钥
if [[ "$CHAT_API_KEY" == "your_github_copilot_api_key_here" ]]; then
    echo "⚠️  请设置您的 GitHub Copilot API 密钥"
    echo "   编辑 .env 文件，将 CHAT_API_KEY 设置为您的实际 API 密钥"
fi

# 检查并生成安全密钥
if [[ "$TOKEN_KEY" == "your_jwt_secret_key_here_change_this" ]]; then
    echo "🔑 生成新的 JWT 密钥..."
    NEW_TOKEN_KEY=$(generate_random_key)
    sed -i "s/TOKEN_KEY=your_jwt_secret_key_here_change_this/TOKEN_KEY=$NEW_TOKEN_KEY/" .env
    echo "✅ JWT 密钥已更新"
fi

if [[ "$ROOT_KEY" == "your_root_key_here_change_this" ]]; then
    echo "🔑 生成新的根密钥..."
    NEW_ROOT_KEY=$(generate_random_key)
    sed -i "s/ROOT_KEY=your_root_key_here_change_this/ROOT_KEY=$NEW_ROOT_KEY/" .env
    echo "✅ 根密钥已更新"
fi

if [[ "$FILE_TOKEN_SECRET" == "your_file_token_secret_change_this" ]]; then
    echo "🔑 生成新的文件令牌密钥..."
    NEW_FILE_TOKEN=$(generate_random_key)
    sed -i "s/FILE_TOKEN_SECRET=your_file_token_secret_change_this/FILE_TOKEN_SECRET=$NEW_FILE_TOKEN/" .env
    echo "✅ 文件令牌密钥已更新"
fi

echo ""
echo "🐳 Docker 服务检查..."

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

# 检查 Docker Compose 是否安装
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

echo "✅ Docker 和 Docker Compose 已安装"

# 检查端口占用
echo ""
echo "🔍 检查端口占用..."

check_port() {
    local port=$1
    local service=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null; then
        echo "⚠️  端口 $port ($service) 已被占用"
        echo "   请确保端口可用或修改 docker-compose.yml 中的端口配置"
        return 1
    else
        echo "✅ 端口 $port ($service) 可用"
        return 0
    fi
}

check_port 3200 "FastGPT Web"
check_port 27017 "MongoDB"
check_port 6379 "Redis"
check_port 5432 "PostgreSQL"

echo ""
echo "📁 创建必要的目录..."

# 创建数据目录
mkdir -p data/logs
mkdir -p data/uploads
mkdir -p data/temp

echo "✅ 目录创建完成"

echo ""
echo "🎉 配置完成！"
echo ""
echo "接下来的步骤："
echo "1. 编辑 .env 文件，设置您的 GitHub Copilot API 密钥"
echo "2. 运行 'docker-compose up -d' 启动服务"
echo "3. 访问 http://localhost:3200 使用 FastGPT"
echo ""
echo "有用的命令："
echo "  启动服务: docker-compose up -d"
echo "  查看日志: docker-compose logs -f"
echo "  停止服务: docker-compose down"
echo "  重启服务: docker-compose restart"
echo ""
echo "如需帮助，请查看 README.md 文件或访问项目文档。"
