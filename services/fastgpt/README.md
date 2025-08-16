# FastGPT 服务配置

这个目录包含 FastGPT 的独立部署配置和说明。

## 独立部署

FastGPT 可以独立部署，通过外部 Copilot Proxy 服务提供 AI 能力。

### 前置要求

- Docker 和 Docker Compose
- 外部运行的 Copilot Proxy 服务（或其他兼容的 OpenAI API）

### 快速部署

1. **配置环境变量**：
```bash
# 复制环境配置
cp .env.example .env
# 编辑 .env 文件，设置数据库密码和外部服务地址
```

2. **启动服务**：
```bash
# 启动 FastGPT 及其依赖的数据库
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f fastgpt
```

3. **访问服务**：
- FastGPT Web 界面：http://localhost:3000
- 默认管理员账户：使用环境变量中设置的密码

### 与 Copilot Proxy 集成

FastGPT 通过以下配置连接到外部 Copilot Proxy：

```env
# 外部 Copilot Proxy 地址
COPILOT_PROXY_URL=http://localhost:8888
CHAT_API_KEY=sk-fastgpt-copilot
```

### 配置说明

#### 必需配置
```env
# 外部服务
COPILOT_PROXY_URL=http://your-copilot-proxy:8888
CHAT_API_KEY=your_api_key

# 数据库
MONGO_USERNAME=your_username
MONGO_PASSWORD=your_secure_password
PG_USERNAME=your_username  
PG_PASSWORD=your_secure_password
PG_DATABASE=fastgpt

# 安全配置
FASTGPT_ROOT_PASSWORD=your_admin_password
TOKEN_KEY=your_token_key
ROOT_KEY=your_root_key
FILE_TOKEN_KEY=your_file_token_key
```

#### 服务依赖

FastGPT 独立部署包含：
- **MongoDB**: 主要数据存储
- **PostgreSQL**: 向量数据库（使用 pgvector）
- **FastGPT**: 主应用服务

### 数据持久化

所有数据通过 Docker volumes 持久化：
- `mongo_data`: MongoDB 数据
- `pg_data`: PostgreSQL 数据  
- `fastgpt_data`: FastGPT 应用数据

### 管理操作

```bash
# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看日志
docker-compose logs -f [service_name]

# 备份数据
docker-compose exec mongo mongodump --out /backup
docker-compose exec pg pg_dump fastgpt > backup.sql

# 更新服务
docker-compose pull
docker-compose up -d
```

### 网络配置

独立部署使用自定义网络 `fastgpt-standalone`：
- MongoDB: 172.32.0.2:27017
- PostgreSQL: 172.32.0.3:5432  
- FastGPT: 172.32.0.4:3000

### 故障排除

1. **服务启动失败**：
```bash
# 检查日志
docker-compose logs

# 检查端口占用
netstat -tulpn | grep :3000
```

2. **数据库连接失败**：
```bash
# 测试 MongoDB
docker-compose exec mongo mongo -u username -p password

# 测试 PostgreSQL  
docker-compose exec pg psql -U username -d fastgpt
```

3. **外部服务连接失败**：
```bash
# 测试 Copilot Proxy 连接
curl http://your-copilot-proxy:8888/health
```

## 与主项目的关系

- **独立运行**: 此配置可以完全独立运行
- **外部依赖**: 需要外部的 Copilot Proxy 或兼容的 OpenAI API 服务
- **数据隔离**: 使用独立的数据库和网络
- **配置分离**: 独立的环境配置文件

查看主项目的 `infrastructure/docker/` 目录了解完整的一体化部署配置。
