# FastGPT Copilot Integration

一个将 GitHub Copilot 模型集成到 FastGPT 的完整解决方案，通过代理服务提供 OpenAI 兼容的 API 接口。

## 🚀 特性

- **GitHub Copilot 集成**: 将 GitHub Copilot Chat 模型无缝集成到 FastGPT
- **OpenAI 兼容**: 提供标准的 OpenAI API 格式，便于集成
- **容器化部署**: 完整的 Docker 容器化解决方案
- **环境分离**: 支持开发、测试和生产环境
- **健康监控**: 内置健康检查和监控功能
- **安全配置**: 生产级别的安全配置和最佳实践

## 📁 项目结构

```
fastgpt_copilot/
├── README.md                           # 项目主文档
├── docs/                               # 文档目录
│   ├── deployment.md                   # 部署指南
│   ├── configuration.md                # 配置指南
│   └── troubleshooting.md              # 故障排除
├── services/                           # 服务目录
│   ├── copilot-proxy/                  # Copilot代理服务
│   │   ├── src/server.js               # 主服务文件
│   │   ├── package.json                # 依赖配置
│   │   ├── Dockerfile                  # 容器配置
│   │   └── README.md                   # 服务文档
│   └── fastgpt/                        # FastGPT服务配置
├── infrastructure/                     # 基础设施
│   ├── docker/                         # Docker配置
│   │   ├── docker-compose.yml          # 主compose文件
│   │   ├── docker-compose.dev.yml      # 开发环境
│   │   └── docker-compose.prod.yml     # 生产环境
│   └── nginx/                          # Nginx配置
│       └── nginx.conf                  # 反向代理配置
├── scripts/                            # 部署和管理脚本
│   ├── deploy.sh                       # 主部署脚本
│   └── test.sh                         # 测试脚本
├── config/                             # 配置文件
│   ├── development.env                 # 开发环境配置
│   └── production.env                  # 生产环境配置
└── tests/                              # 测试目录
```

## 🚀 快速开始

### 1. 前置要求

- Docker 和 Docker Compose
- GitHub Personal Access Token (PAT)
- 至少 4GB 可用内存

### 2. 环境配置

复制并修改环境配置文件：

```bash
# 开发环境
cp config/development.env.example config/development.env
# 编辑 config/development.env，设置你的 GITHUB_TOKEN

# 生产环境
cp config/production.env.example config/production.env
# 编辑 config/production.env，设置所有必要的配置
```

### 3. 部署

```bash
# 开发环境部署
./scripts/deploy.sh deploy

# 生产环境部署
./scripts/deploy.sh -e production deploy
```

### 4. 验证部署

```bash
# 运行测试
./scripts/test.sh

# 查看服务状态
./scripts/deploy.sh status
```

## 🔧 配置说明

### GitHub Token 配置

1. 访问 [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)
2. 创建新的 PAT，需要以下权限：
   - `repo` (如果访问私有仓库)
   - `read:user`
3. 将 token 设置到环境配置文件中

### FastGPT 配置

在 FastGPT 中添加新的模型配置：

```json
{
  "model": "gpt-4",
  "name": "GitHub Copilot GPT-4",
  "baseUrl": "http://copilot-proxy:8888",
  "apiKey": "sk-fastgpt-copilot"
}
```

## 📖 API 文档

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

## 🐳 容器化部署

项目支持三种部署模式：

### 开发环境

```bash
./scripts/deploy.sh -e development deploy
```

- 适用于本地开发和调试
- 包含调试日志和热重载
- 使用较少的资源配置

### 生产环境

```bash
./scripts/deploy.sh -e production deploy
```

- 优化的性能配置
- 完整的安全设置
- 日志轮转和备份功能

## 🔍 监控和日志

### 查看日志

```bash
# 查看所有服务日志
./scripts/deploy.sh logs

# 查看特定服务日志
docker-compose logs copilot-proxy
```

### 健康检查

```bash
# 运行健康检查
./scripts/test.sh health

# 查看服务状态
./scripts/deploy.sh status
```

## 🛠️ 开发指南

### 本地开发

1. 启动开发环境：
```bash
./scripts/deploy.sh -e development deploy
```

2. 修改代码后重新构建：
```bash
docker-compose -f infrastructure/docker/docker-compose.dev.yml up --build -d copilot-proxy
```

### 测试

```bash
# 运行所有测试
./scripts/test.sh

# 运行特定测试
./scripts/test.sh chat
./scripts/test.sh performance
```

## 🔧 故障排除

### 常见问题

1. **端口冲突**: 修改 `config/*.env` 中的端口配置
2. **Token 无效**: 检查 GitHub PAT 是否正确设置
3. **容器启动失败**: 检查 Docker 资源限制

### 日志分析

```bash
# 查看详细错误日志
docker-compose logs --tail=100 copilot-proxy

# 查看容器状态
docker ps -a
```

## 📝 许可证

MIT License

## 🤝 贡献

欢迎提交 Issues 和 Pull Requests！

## 📞 支持

如有问题，请：

1. 查看[故障排除文档](docs/troubleshooting.md)
2. 搜索现有的 [Issues](https://github.com/YuanhuYang/fastgpt_copilot/issues)
3. 创建新的 Issue
