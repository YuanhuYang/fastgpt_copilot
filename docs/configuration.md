# 配置指南

本文档详细说明 FastGPT Copilot 集成的各项配置选项。

## 配置文件结构

```
config/
├── development.env     # 开发环境配置
├── production.env      # 生产环境配置
├── config.json         # FastGPT 主配置
├── models.json         # 模型配置
├── system.json         # 系统配置
└── vector.json         # 向量数据库配置
```

## 环境变量配置

### GitHub Copilot 配置

```env
# GitHub Personal Access Token
GITHUB_TOKEN=ghp_your_token_here
```

**获取 GitHub Token：**
1. 访问 [GitHub Settings](https://github.com/settings/tokens)
2. 生成新的 Personal Access Token
3. 选择权限：`repo`, `read:user`, `read:org`

### Copilot Proxy 配置

```env
# 服务端口
PORT=8888

# CORS 配置
CORS_ORIGIN=*

# 日志级别
LOG_LEVEL=info

# 运行环境
NODE_ENV=development
```

**日志级别选项：**
- `debug`: 详细调试信息
- `info`: 一般信息
- `warn`: 警告信息
- `error`: 仅错误信息

### 数据库配置

```env
# MongoDB 配置
MONGO_USERNAME=fastgpt_user
MONGO_PASSWORD=secure_password
MONGO_DATABASE=fastgpt

# PostgreSQL 配置
PG_USERNAME=fastgpt_user
PG_PASSWORD=secure_password
PG_DATABASE=fastgpt
PG_HOST=localhost
PG_PORT=5432
```

### FastGPT 配置

```env
# 管理员密码
FASTGPT_ROOT_PASSWORD=admin_password

# API 密钥
CHAT_API_KEY=sk-fastgpt-copilot
TOKEN_KEY=your_token_key
ROOT_KEY=your_root_key
FILE_TOKEN_KEY=your_file_token_key

# 数据库连接
MONGODB_URI=mongodb://user:password@localhost:27017/fastgpt
PG_URL=postgresql://user:password@localhost:5432/fastgpt
```

## FastGPT 模型配置

### models.json 配置

```json
{
  "models": [
    {
      "id": "gpt-4-copilot",
      "name": "GitHub Copilot GPT-4",
      "model": "gpt-4",
      "baseUrl": "http://copilot-proxy:8888",
      "apiKey": "sk-fastgpt-copilot",
      "maxTokens": 4096,
      "temperature": 0.7,
      "provider": "copilot-proxy",
      "enabled": true
    },
    {
      "id": "gpt-3.5-copilot",
      "name": "GitHub Copilot GPT-3.5",
      "model": "gpt-3.5-turbo",
      "baseUrl": "http://copilot-proxy:8888",
      "apiKey": "sk-fastgpt-copilot",
      "maxTokens": 4096,
      "temperature": 0.7,
      "provider": "copilot-proxy",
      "enabled": true
    }
  ]
}
```

### 模型参数说明

- `id`: 模型唯一标识符
- `name`: 模型显示名称
- `model`: 实际模型名称
- `baseUrl`: API 基础 URL
- `apiKey`: API 密钥
- `maxTokens`: 最大 token 数量
- `temperature`: 创造性参数 (0-1)
- `provider`: 提供商标识
- `enabled`: 是否启用

## 系统配置

### system.json 配置

```json
{
  "database": {
    "mongodb": {
      "maxConnections": 50,
      "timeout": 30000,
      "retryWrites": true
    },
    "postgresql": {
      "max": 20,
      "idleTimeoutMillis": 30000,
      "connectionTimeoutMillis": 2000
    }
  },
  "cache": {
    "type": "memory",
    "ttl": 3600,
    "maxSize": 1000
  },
  "logging": {
    "level": "info",
    "format": "json",
    "destination": "stdout"
  },
  "security": {
    "rateLimiting": {
      "windowMs": 900000,
      "max": 100
    },
    "cors": {
      "origin": "*",
      "credentials": true
    }
  }
}
```

## 向量数据库配置

### vector.json 配置

```json
{
  "vectorDb": {
    "type": "pgvector",
    "connection": {
      "host": "localhost",
      "port": 5432,
      "database": "fastgpt",
      "username": "fastgpt_user",
      "password": "secure_password"
    },
    "embedding": {
      "model": "text-embedding-ada-002",
      "dimensions": 1536,
      "maxBatchSize": 100
    },
    "index": {
      "type": "ivfflat",
      "lists": 1000,
      "probes": 10
    }
  }
}
```

## Docker Compose 配置

### 网络配置

```yaml
networks:
  fastgpt-copilot:
    driver: bridge
    ipam:
      config:
        - subnet: 172.30.0.0/16
```

### 服务配置

```yaml
services:
  copilot-proxy:
    environment:
      - PORT=8888
      - GITHUB_TOKEN=${GITHUB_TOKEN}
      - CORS_ORIGIN=${CORS_ORIGIN}
      - LOG_LEVEL=${LOG_LEVEL}
    networks:
      fastgpt-copilot:
        ipv4_address: 172.30.0.5
    ports:
      - "8888:8888"
```

## 高级配置

### 负载均衡配置

```nginx
upstream copilot_backend {
    server copilot-proxy-1:8888;
    server copilot-proxy-2:8888;
    server copilot-proxy-3:8888;
}

server {
    location /v1/ {
        proxy_pass http://copilot_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### SSL 配置

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
}
```

### 监控配置

```yaml
# Prometheus 监控
monitoring:
  prometheus:
    enabled: true
    port: 9090
    path: /metrics
  
  grafana:
    enabled: true
    port: 3001
    dashboards:
      - fastgpt-dashboard
      - copilot-proxy-dashboard
```

## 性能优化配置

### 数据库连接池

```json
{
  "mongodb": {
    "maxPoolSize": 50,
    "minPoolSize": 5,
    "maxIdleTimeMS": 30000,
    "waitQueueTimeoutMS": 5000
  },
  "postgresql": {
    "max": 20,
    "min": 2,
    "idleTimeoutMillis": 30000,
    "connectionTimeoutMillis": 2000
  }
}
```

### 缓存配置

```json
{
  "cache": {
    "models": {
      "ttl": 86400,
      "maxSize": 100
    },
    "conversations": {
      "ttl": 3600,
      "maxSize": 1000
    },
    "embeddings": {
      "ttl": 604800,
      "maxSize": 10000
    }
  }
}
```

## 安全配置

### API 限流

```json
{
  "rateLimiting": {
    "global": {
      "windowMs": 900000,
      "max": 1000
    },
    "perUser": {
      "windowMs": 60000,
      "max": 60
    },
    "perModel": {
      "windowMs": 60000,
      "max": 30
    }
  }
}
```

### 访问控制

```json
{
  "security": {
    "authentication": {
      "required": true,
      "methods": ["bearer", "api-key"]
    },
    "authorization": {
      "enabled": true,
      "roles": ["admin", "user", "guest"]
    },
    "cors": {
      "origin": ["https://your-domain.com"],
      "credentials": true,
      "methods": ["GET", "POST", "PUT", "DELETE"]
    }
  }
}
```

## 配置验证

### 验证脚本

```bash
#!/bin/bash
# 验证配置文件
echo "验证配置文件..."

# 检查环境变量
if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "错误: GITHUB_TOKEN 未设置"
    exit 1
fi

# 验证 JSON 格式
for file in config/*.json; do
    if ! jq empty "$file" 2>/dev/null; then
        echo "错误: $file 不是有效的 JSON"
        exit 1
    fi
done

echo "配置验证通过"
```

### 配置测试

```bash
# 测试数据库连接
docker-compose exec mongo mongo --eval "db.adminCommand('ping')"
docker-compose exec pg psql -U username -d postgres -c "SELECT 1;"

# 测试 API 接口
curl -f http://localhost:8888/health
curl -f http://localhost:8888/v1/models
```

## 故障排除

### 常见配置错误

1. **GitHub Token 无效**
```bash
# 验证 Token
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

2. **数据库连接失败**
```bash
# 检查连接字符串
echo $MONGODB_URI
echo $PG_URL
```

3. **端口冲突**
```bash
# 检查端口占用
netstat -tulpn | grep :8888
```

### 配置调试

```bash
# 查看环境变量
docker-compose config

# 检查服务配置
docker-compose ps
docker logs copilot-proxy
```
