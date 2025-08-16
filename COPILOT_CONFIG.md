# FastGPT GitHub Copilot API 配置指南

本文档详细说明如何配置 FastGPT 使用 GitHub Copilot 的大模型 API。

## GitHub Copilot API 配置

### 1. 获取 API 密钥

1. **订阅 GitHub Copilot**
   - 访问 [GitHub Copilot](https://github.com/features/copilot)
   - 选择合适的订阅计划（个人版或企业版）

2. **生成 API 密钥**
   - 登录 GitHub，进入设置页面
   - 导航到 "Developer settings" > "Personal access tokens"
   - 生成新的 token，确保包含 Copilot 相关权限

### 2. 配置 API 连接

在 `.env` 文件中设置以下环境变量：

```bash
# GitHub Copilot API 基础 URL
OPENAI_BASE_URL=https://api.githubcopilot.com

# 您的 GitHub Copilot API 密钥
CHAT_API_KEY=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 默认使用的模型
DEFAULT_MODEL=gpt-4
```

### 3. 模型配置

GitHub Copilot 支持的模型：

```json
{
  "gpt-4": {
    "name": "GPT-4",
    "maxToken": 8000,
    "maxResponse": 4000,
    "description": "最强大的模型，适合复杂推理和创作"
  },
  "gpt-3.5-turbo": {
    "name": "GPT-3.5-Turbo", 
    "maxToken": 4000,
    "maxResponse": 2000,
    "description": "快速响应，适合日常对话"
  }
}
```

## API 使用限制和注意事项

### 使用限制

1. **请求频率限制**
   - 个人版：每分钟最多 100 次请求
   - 企业版：更高的请求限制

2. **Token 限制**
   - GPT-4：最大 8000 tokens
   - GPT-3.5-Turbo：最大 4000 tokens

3. **并发限制**
   - 同时最多 10 个并发请求

### 最佳实践

1. **合理使用模型**
   - 简单任务使用 GPT-3.5-Turbo
   - 复杂任务使用 GPT-4

2. **优化提示词**
   - 清晰、具体的指令
   - 适当的上下文信息
   - 避免冗余信息

3. **错误处理**
   - 实现重试机制
   - 处理速率限制
   - 监控 API 使用情况

## 故障排除

### 常见问题

1. **401 Unauthorized**
   - 检查 API 密钥是否正确
   - 确认 GitHub Copilot 订阅状态

2. **429 Too Many Requests**
   - 降低请求频率
   - 实现指数退避重试

3. **连接超时**
   - 检查网络连接
   - 确认防火墙设置

### 调试方法

1. **查看日志**
   ```bash
   docker-compose logs -f fastgpt | grep -i "api\|copilot\|openai"
   ```

2. **测试 API 连接**
   ```bash
   curl -H "Authorization: Bearer $CHAT_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{"model":"gpt-3.5-turbo","messages":[{"role":"user","content":"Hello"}]}' \
        https://api.githubcopilot.com/v1/chat/completions
   ```

3. **监控资源使用**
   ```bash
   docker stats fastgpt-app
   ```

## 高级配置

### 自定义请求参数

可以在环境变量中设置额外的请求参数：

```bash
# 温度参数（0-2，控制创造性）
DEFAULT_TEMPERATURE=0.7

# 最大响应长度
DEFAULT_MAX_TOKENS=2000

# Top-p 采样参数
DEFAULT_TOP_P=0.9
```

### 负载均衡

对于高并发场景，可以配置多个 API 密钥：

```bash
CHAT_API_KEYS=key1,key2,key3
```

### 缓存策略

启用响应缓存以提高性能：

```bash
ENABLE_CACHE=true
CACHE_TTL=3600  # 缓存时间（秒）
```

## 监控和分析

### API 使用统计

FastGPT 提供内置的 API 使用统计功能：

1. 访问管理面板
2. 查看 "API 使用情况" 页面
3. 分析请求量、错误率等指标

### 成本控制

1. **设置使用限额**
   ```bash
   MONTHLY_TOKEN_LIMIT=1000000
   DAILY_REQUEST_LIMIT=10000
   ```

2. **用户级别限制**
   - 为不同用户设置不同的配额
   - 实现基于角色的访问控制

3. **实时监控**
   - 设置告警阈值
   - 自动暂停超额使用

## 安全建议

1. **API 密钥安全**
   - 使用环境变量存储密钥
   - 定期轮换 API 密钥
   - 限制密钥权限范围

2. **网络安全**
   - 使用 HTTPS 连接
   - 配置防火墙规则
   - 启用访问日志

3. **数据保护**
   - 敏感数据脱敏
   - 实现数据加密
   - 遵循数据保护法规

## 更新和维护

### 定期更新

1. **更新 FastGPT**
   ```bash
   docker-compose pull fastgpt
   docker-compose up -d fastgpt
   ```

2. **更新配置**
   - 关注 GitHub Copilot API 更新
   - 调整模型参数
   - 优化性能设置

### 备份策略

1. **配置备份**
   ```bash
   cp .env .env.backup
   cp docker-compose.yml docker-compose.yml.backup
   ```

2. **数据备份**
   ```bash
   # 备份 MongoDB
   docker exec fastgpt-mongodb mongodump --out /tmp/backup
   
   # 备份应用数据
   docker cp fastgpt-app:/app/data ./backup/
   ```
