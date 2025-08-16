#!/bin/bash

# FastGPT 一键部署脚本
# 使用 Docker Compose 部署 FastGPT 并集成 GitHub Copilot API

set -e

echo "🚀 开始部署 FastGPT..."

# 检查 Docker 和 Docker Compose
check_dependencies() {
    echo "📋 检查依赖..."
    
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    echo "✅ 依赖检查通过"
}

# 检查端口占用
check_ports() {
    echo "📋 检查端口占用..."
    
    ports=(3000 27017 6379 5432)
    for port in "${ports[@]}"; do
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            echo "❌ 端口 $port 已被占用，请释放该端口或修改配置"
            exit 1
        fi
    done
    
    echo "✅ 端口检查通过"
}

# 配置环境变量
setup_environment() {
    echo "⚙️ 配置环境变量..."
    
    if [ ! -f ".env" ]; then
        echo "❌ .env 文件不存在，请先创建配置文件"
        exit 1
    fi
    
    # 检查必要的环境变量
    if grep -q "your_github_copilot_api_key_here" .env; then
        echo "⚠️  警告: 请在 .env 文件中设置您的 GitHub Copilot API 密钥"
        echo "编辑 .env 文件，将 CHAT_API_KEY 设置为您的实际 API 密钥"
        read -p "是否继续部署？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo "✅ 环境变量配置完成"
}

# 启动服务
start_services() {
    echo "🐳 启动 Docker 服务..."
    
    # 拉取最新镜像
    echo "📥 拉取镜像..."
    docker-compose pull
    
    # 启动服务
    echo "🚀 启动服务..."
    docker-compose up -d
    
    # 等待服务启动
    echo "⏳ 等待服务启动..."
    sleep 30
    
    # 检查服务状态
    echo "📊 检查服务状态..."
    docker-compose ps
}

# 健康检查
health_check() {
    echo "🏥 进行健康检查..."
    
    # 检查 FastGPT 服务
    if curl -f http://localhost:3000/api/health 2>/dev/null; then
        echo "✅ FastGPT 服务运行正常"
    else
        echo "⚠️  FastGPT 服务可能还在启动中，请稍后检查"
    fi
    
    # 检查数据库连接
    if docker exec fastgpt-mongodb mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
        echo "✅ MongoDB 连接正常"
    else
        echo "⚠️  MongoDB 连接异常"
    fi
    
    if docker exec fastgpt-redis redis-cli ping &>/dev/null; then
        echo "✅ Redis 连接正常"
    else
        echo "⚠️  Redis 连接异常"
    fi
}

# 显示部署信息
show_info() {
    echo ""
    echo "🎉 FastGPT 部署完成！"
    echo ""
    echo "📍 访问信息:"
    echo "   FastGPT Web 界面: http://localhost:3000"
    echo "   MongoDB: localhost:27017"
    echo "   Redis: localhost:6379"
    echo "   PostgreSQL: localhost:5432"
    echo ""
    echo "📋 管理命令:"
    echo "   查看日志: docker-compose logs -f fastgpt"
    echo "   重启服务: docker-compose restart"
    echo "   停止服务: docker-compose down"
    echo "   更新服务: docker-compose pull && docker-compose up -d"
    echo ""
    echo "📚 更多信息请查看 README.md"
}

# 主函数
main() {
    echo "FastGPT Docker Compose 部署工具"
    echo "================================="
    
    check_dependencies
    check_ports
    setup_environment
    start_services
    health_check
    show_info
}

# 运行主函数
main "$@"
