# 部署指南

本文档详细说明如何在不同环境中部署 FastGPT Copilot 集成服务。

## 部署架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Nginx       │    │    FastGPT      │    │  Copilot Proxy  │
│  反向代理/负载均衡  │◄──►│   主应用服务     │◄──►│   GitHub代理     │
│   Port: 80/443  │    │   Port: 3000    │    │   Port: 8888    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐    ┌─────────────────┐
         │              │    MongoDB      │    │   PostgreSQL    │
         └──────────────►│   数据存储      │    │   向量数据库     │
                        │  Port: 27017    │    │   Port: 5432    │
                        └─────────────────┘    └─────────────────┘
```

## 环境要求

### 最低要求
- **CPU**: 2 核心
- **内存**: 4GB RAM
- **存储**: 20GB 可用空间
- **Docker**: 20.10+
- **Docker Compose**: 2.0+

### 推荐配置
- **CPU**: 4 核心以上
- **内存**: 8GB RAM 以上
- **存储**: 50GB+ SSD
- **网络**: 100Mbps+ 带宽

## 部署步骤

### 1. 环境准备

#### 安装 Docker
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### 克隆项目
```bash
git clone https://github.com/YuanhuYang/fastgpt_copilot.git
cd fastgpt_copilot
```

### 2. 配置环境变量

#### 开发环境
```bash
cp config/development.env.example config/development.env
# 编辑配置文件
nano config/development.env
```

**必须修改的配置项：**
```env
# GitHub Token (必需)
GITHUB_TOKEN=ghp_your_github_personal_access_token

# 数据库密码 (建议修改)
MONGO_PASSWORD=your_secure_mongo_password
PG_PASSWORD=your_secure_pg_password

# FastGPT 管理员密码
FASTGPT_ROOT_PASSWORD=your_admin_password
```

#### 生产环境
```bash
cp config/production.env.example config/production.env
# 编辑配置文件
nano config/production.env
```

**生产环境额外配置：**
```env
# SSL 证书路径
SSL_CERT_PATH=/etc/nginx/ssl/cert.pem
SSL_KEY_PATH=/etc/nginx/ssl/key.pem

# 域名配置
CORS_ORIGIN=https://your-domain.com

# 备份配置
BACKUP_S3_BUCKET=your-backup-bucket
```

### 3. 获取 GitHub Personal Access Token

1. 访问 [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)
2. 点击 "Generate new token (classic)"
3. 选择权限：
   - `repo` (如果需要访问私有仓库)
   - `read:user`
   - `read:org` (如果在组织中使用)
4. 复制生成的 token 到配置文件

### 4. 部署服务

#### 开发环境部署
```bash
# 使用部署脚本
./scripts/deploy.sh -e development deploy

# 或手动部署
docker-compose -f infrastructure/docker/docker-compose.dev.yml --env-file config/development.env up -d
```

#### 生产环境部署
```bash
# 使用部署脚本
./scripts/deploy.sh -e production deploy

# 或手动部署
docker-compose -f infrastructure/docker/docker-compose.prod.yml --env-file config/production.env up -d
```

### 5. 验证部署

#### 检查服务状态
```bash
./scripts/deploy.sh status
```

#### 运行健康检查
```bash
./scripts/test.sh health
```

#### 验证 API 接口
```bash
# 检查 Copilot Proxy
curl http://localhost:8888/health

# 检查模型列表
curl http://localhost:8888/v1/models

# 测试聊天接口
curl -X POST http://localhost:8888/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

## 服务管理

### 启动服务
```bash
./scripts/deploy.sh start
```

### 停止服务
```bash
./scripts/deploy.sh stop
```

### 重启服务
```bash
./scripts/deploy.sh restart
```

### 查看日志
```bash
# 查看所有服务日志
./scripts/deploy.sh logs

# 查看特定服务日志
docker-compose logs -f copilot-proxy
docker-compose logs -f fastgpt
```

### 更新服务
```bash
# 拉取最新镜像
docker-compose pull

# 重新构建并启动
./scripts/deploy.sh -e production deploy
```

## SSL 配置

### 生产环境 SSL 设置

1. **获取 SSL 证书**
```bash
# 使用 Let's Encrypt
sudo apt install certbot
sudo certbot certonly --standalone -d your-domain.com
```

2. **配置 Nginx SSL**
```bash
# 复制证书到项目目录
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem infrastructure/nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem infrastructure/nginx/ssl/key.pem
```

3. **更新环境配置**
```env
# 在 config/production.env 中设置
SSL_CERT_PATH=/etc/nginx/ssl/cert.pem
SSL_KEY_PATH=/etc/nginx/ssl/key.pem
CORS_ORIGIN=https://your-domain.com
```

## 数据备份

### 自动备份
```bash
# 设置定时备份 (每天凌晨 2 点)
crontab -e
# 添加以下行
0 2 * * * /path/to/fastgpt_copilot/scripts/deploy.sh backup
```

### 手动备份
```bash
./scripts/deploy.sh backup
```

### 恢复备份
```bash
# 恢复 MongoDB
docker exec -i fastgpt-mongo-prod mongorestore --authenticationDatabase admin -u username -p password /backups/mongo

# 恢复 PostgreSQL
docker exec -i fastgpt-pg-prod psql -U username -d postgres < backup.sql
```

## 监控设置

### 系统监控
```bash
# 安装监控工具
sudo apt install htop iotop nethogs

# 监控容器资源使用
docker stats
```

### 日志轮转
```bash
# 配置 Docker 日志轮转
sudo nano /etc/docker/daemon.json
```

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
```

## 故障排除

### 常见问题

1. **端口冲突**
```bash
# 检查端口占用
sudo netstat -tulpn | grep :8888
# 修改配置文件中的端口
```

2. **容器启动失败**
```bash
# 查看容器日志
docker logs copilot-proxy
# 检查配置文件
docker-compose config
```

3. **数据库连接失败**
```bash
# 检查数据库容器状态
docker ps | grep mongo
# 测试数据库连接
docker exec -it fastgpt-mongo mongo -u username -p
```

### 性能优化

1. **增加容器资源限制**
```yaml
# 在 docker-compose 中添加
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 4G
```

2. **优化数据库配置**
```bash
# MongoDB 优化
command: mongod --wiredTigerCacheSizeGB 2 --auth

# PostgreSQL 优化
command: postgres -c shared_buffers=256MB -c max_connections=200
```

## 安全建议

1. **使用强密码**
2. **定期更新镜像**
3. **配置防火墙**
4. **启用 SSL/TLS**
5. **定期备份数据**
6. **监控系统日志**
