# GitHub Copilot Proxy Service

A proxy service that provides OpenAI-compatible API endpoints for GitHub Copilot Chat functionality.

## Overview

This service acts as a bridge between FastGPT and GitHub Copilot, providing:
- OpenAI-compatible API endpoints
- Model listing and management
- Chat completion functionality
- Health monitoring

## Features

- **Health Check**: `/health` endpoint for monitoring
- **Model Management**: `/v1/models` endpoint
- **Chat Completions**: `/v1/chat/completions` endpoint
- **CORS Support**: Configurable cross-origin requests
- **Error Handling**: Comprehensive error management

## 独立部署

### 环境配置

```bash
# 复制环境配置
cp .env.example .env
# 编辑 .env 文件，设置 GITHUB_TOKEN
```

### Docker 部署

```bash
# 构建并启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 本地开发

```bash
npm install
npm start
```

## API 端点

### 健康检查

```http
GET /health
```

### 列出模型

```http
GET /v1/models
```

### 聊天完成

```http
POST /v1/chat/completions
Content-Type: application/json

{
  "model": "gpt-4",
  "messages": [
    {"role": "user", "content": "Hello!"}
  ]
}
```

## 配置选项

```env
# GitHub Token
GITHUB_TOKEN=your_github_token_here

# 服务配置
PORT=8888
CORS_ORIGIN=*
LOG_LEVEL=info
NODE_ENV=production

# 可选配置
MAX_REQUESTS_PER_MINUTE=60
TIMEOUT_MS=30000
```

## 与 FastGPT 集成

FastGPT 可以通过以下配置连接到此代理服务：

```env
# 在 FastGPT 中配置
OPENAI_BASE_URL=http://copilot-proxy:8888
CHAT_API_KEY=sk-fastgpt-copilot
```

## 测试

```bash
# 健康检查
curl http://localhost:8888/health

# 测试聊天接口
curl -X POST http://localhost:8888/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```
