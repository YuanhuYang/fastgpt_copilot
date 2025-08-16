# FastGPT Docker Compose 部署指南

本项目提供了使用 Docker Compose 快速部署 FastGPT 的完整解决方案，并集成了 GitHub Copilot 的大模型 API。

## 🚀 快速开始

### 1. 前置要求

- Docker >= 20.10
- Docker Compose >= 2.0
- 至少 4GB 可用内存
- GitHub Copilot API 密钥

### 2. 获取 GitHub Copilot API 密钥

1. 访问 [GitHub Settings - Developer settings](https://github.com/settings/tokens) 或 [GitHub Copilot API 管理页面](https://github.com/settings/copilot)
2. 订阅 GitHub Copilot 服务
3. 在设置中生成 API 密钥

### 3. 配置环境变量

编辑 `.env` 文件，修改以下关键配置：

```bash
# 修改为您的 GitHub Copilot API 密钥
CHAT_API_KEY=your_github_copilot_api_key_here

# 修改 JWT 密钥 (建议使用强密码)
TOKEN_KEY=your_jwt_secret_key_here_change_this
ROOT_KEY=your_root_key_here_change_this
FILE_TOKEN_SECRET=your_file_token_secret_change_this
```

### 4. 启动服务

```bash
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f fastgpt
```

### 5. 访问应用

- FastGPT Web 界面: http://localhost:3000
- MongoDB: localhost:27017
- Redis: localhost:6379
- PostgreSQL: localhost:5432

## 📋 服务架构

```
┌─────────────────┐
│   FastGPT Web   │ :3000
└─────────────────┘
         │
┌─────────────────┐
│   FastGPT API   │
└─────────────────┘
         │
    ┌────┴────┐
    │         │
┌───▼───┐ ┌──▼──┐ ┌─────────┐
│MongoDB│ │Redis│ │PostgreSQL│
│ :27017│ │:6379│ │  :5432   │
└───────┘ └─────┘ └─────────┘
```

## ⚙️ 配置说明

### 数据库配置

- **MongoDB**: 主数据库，存储用户、应用、数据集等信息
- **Redis**: 缓存服务，提高应用性能
- **PostgreSQL**: 向量数据库（可选），用于高级向量搜索

### GitHub Copilot API 配置

在 `docker-compose.yml` 中的关键环境变量：

```yaml
environment:
  OPENAI_BASE_URL: https://api.githubcopilot.com
  CHAT_API_KEY: your_github_copilot_api_key_here
  DEFAULT_MODEL: gpt-4
```

### 支持的模型

默认配置支持以下模型：

- **GPT-4**: 最强大的模型，适合复杂任务
- **GPT-3.5-Turbo**: 快速响应，适合日常对话

## 🔧 高级配置

### 自定义模型配置

编辑环境变量中的 `OPENAI_MODELS` 来添加或修改模型：

```json
[
  {
    "model": "gpt-4",
    "name": "GPT-4",
    "maxToken": 8000,
    "price": 0.03,
    "maxResponse": 4000,
    "censor": false
  }
]
```

### 文件存储配置

默认使用本地存储，数据持久化到 Docker 卷：

- `mongodb_data`: MongoDB 数据
- `redis_data`: Redis 数据
- `postgres_data`: PostgreSQL 数据
- `fastgpt_data`: FastGPT 应用数据

## 🛠️ 常用命令

```bash
# 重启服务
docker-compose restart

# 更新 FastGPT 镜像
docker-compose pull fastgpt
docker-compose up -d fastgpt

# 备份数据库
docker exec fastgpt-mongodb mongodump --uri="mongodb://root:fastgpt123@localhost:27017/fastgpt?authSource=admin" --out=/tmp/backup

# 查看容器资源使用
docker stats

# 进入容器调试
docker exec -it fastgpt-app bash
```

## 🐛 故障排除

### 1. 服务启动失败

```bash
# 查看详细日志
docker-compose logs fastgpt

# 检查端口占用
netstat -tlnp | grep -E '3000|27017|6379|5432'
```

### 2. 连接 GitHub Copilot API 失败

- 检查 API 密钥是否正确
- 确认网络可以访问 api.githubcopilot.com
- 检查 GitHub Copilot 订阅状态

### 3. 数据库连接问题

- 等待数据库完全启动（约 30 秒）
- 检查数据库容器状态
- 验证连接字符串和密码

### 4. 内存不足

- 确保系统有至少 4GB 可用内存
- 使用 `docker system prune` 清理无用容器

## 📚 更多资源

- [FastGPT 官方文档](https://doc.fastgpt.in/)
- [GitHub Copilot API 文档](https://docs.github.com/en/copilot)
- [Docker Compose 文档](https://docs.docker.com/compose/)

## 🔒 安全建议

1. **修改默认密码**: 更改所有默认密码和密钥
2. **网络安全**: 生产环境中使用防火墙限制端口访问
3. **HTTPS**: 配置反向代理启用 HTTPS
4. **备份**: 定期备份数据库数据
5. **更新**: 定期更新镜像版本

## 📝 许可证

本项目遵循 MIT 许可证。
