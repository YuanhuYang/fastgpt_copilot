# 故障排除指南

本文档提供常见问题的解决方案和调试技巧。

## 快速诊断

### 服务健康检查

```bash
# 检查所有服务状态
./scripts/deploy.sh status

# 运行健康检查
./scripts/test.sh health

# 查看容器状态
docker ps -a
```

### 网络连接测试

```bash
# 测试 Copilot Proxy
curl -f http://localhost:8888/health

# 测试 FastGPT
curl -f http://localhost:3000

# 测试数据库连接
docker exec mongo ping -c 1 localhost
docker exec pg pg_isready
```

## 常见问题

### 1. GitHub Token 相关问题

#### 问题：400 Bad Request - Personal Access Tokens not supported

**症状：**
```
HTTP 400: Personal Access Tokens not supported for this API
```

**解决方案：**
1. 这是 GitHub Copilot API 的限制，PAT 不支持
2. 代理服务已实现智能回退机制
3. 检查代理服务是否正常运行：

```bash
curl http://localhost:8888/v1/models
```

#### 问题：Token 权限不足

**症状：**
```
HTTP 403: Insufficient permissions
```

**解决方案：**
1. 检查 Token 权限设置
2. 确保包含必要权限：`repo`, `read:user`
3. 重新生成 Token：

```bash
# 验证当前 Token
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

### 2. 容器启动问题

#### 问题：端口冲突

**症状：**
```
ERROR: Port 8888 is already in use
```

**解决方案：**
1. 检查端口占用：

```bash
sudo netstat -tulpn | grep :8888
sudo lsof -i :8888
```

2. 修改配置文件中的端口：

```env
# config/development.env
PORT=8889
```

3. 重新部署：

```bash
./scripts/deploy.sh restart
```

#### 问题：内存不足

**症状：**
```
ERROR: Container killed due to OOM
```

**解决方案：**
1. 检查系统内存：

```bash
free -h
docker stats
```

2. 增加交换空间：

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

3. 优化容器资源限制：

```yaml
# docker-compose.yml
services:
  fastgpt:
    deploy:
      resources:
        limits:
          memory: 2G
```

### 3. 数据库连接问题

#### 问题：MongoDB 连接失败

**症状：**
```
MongoServerError: Authentication failed
```

**解决方案：**
1. 检查用户名密码：

```bash
# 测试连接
docker exec -it mongo mongo -u username -p password --authenticationDatabase admin
```

2. 重置数据库用户：

```bash
# 进入 MongoDB 容器
docker exec -it mongo mongo admin

# 创建用户
db.createUser({
  user: "fastgpt",
  pwd: "password",
  roles: ["readWrite"]
})
```

#### 问题：PostgreSQL 连接超时

**症状：**
```
Error: connection timeout
```

**解决方案：**
1. 检查网络连接：

```bash
# 测试连接
docker exec -it pg pg_isready -h localhost -p 5432
```

2. 检查防火墙设置：

```bash
sudo ufw status
sudo ufw allow 5432
```

### 4. API 请求问题

#### 问题：CORS 错误

**症状：**
```
Access to fetch at 'http://localhost:8888' blocked by CORS policy
```

**解决方案：**
1. 检查 CORS 配置：

```env
# config/development.env
CORS_ORIGIN=http://localhost:3000
```

2. 重启代理服务：

```bash
docker-compose restart copilot-proxy
```

#### 问题：请求超时

**症状：**
```
Error: Request timeout after 30000ms
```

**解决方案：**
1. 增加超时时间：

```javascript
// 在代理服务中调整
const timeout = 60000; // 60秒
```

2. 检查网络延迟：

```bash
ping github.com
traceroute github.com
```

### 5. 性能问题

#### 问题：响应速度慢

**诊断步骤：**
1. 检查资源使用：

```bash
docker stats
htop
iotop
```

2. 分析日志：

```bash
docker logs copilot-proxy | grep -i slow
docker logs fastgpt | grep -i timeout
```

**优化方案：**
1. 增加容器资源：

```yaml
services:
  copilot-proxy:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
```

2. 优化数据库：

```bash
# MongoDB 索引优化
docker exec mongo mongo fastgpt --eval "db.collection.createIndex({field: 1})"

# PostgreSQL 查询优化
docker exec pg psql -U username -d fastgpt -c "ANALYZE;"
```

### 6. 日志分析

#### 收集日志

```bash
# 收集所有日志
mkdir -p logs
docker-compose logs > logs/all-services.log

# 分别收集各服务日志
docker logs copilot-proxy > logs/copilot-proxy.log
docker logs fastgpt > logs/fastgpt.log
docker logs mongo > logs/mongo.log
docker logs pg > logs/postgres.log
```

#### 日志分析命令

```bash
# 查找错误
grep -i error logs/*.log

# 查找特定时间段
grep "2024-08-16 15:" logs/copilot-proxy.log

# 统计错误频率
grep -i error logs/copilot-proxy.log | wc -l

# 查看最近的日志
tail -f logs/copilot-proxy.log
```

### 7. 网络问题

#### 问题：容器间通信失败

**症状：**
```
Error: connect ECONNREFUSED 172.30.0.5:8888
```

**解决方案：**
1. 检查网络配置：

```bash
# 查看网络
docker network ls
docker network inspect fastgpt-copilot

# 检查容器 IP
docker inspect copilot-proxy | grep IPAddress
```

2. 测试容器间连通性：

```bash
# 从 FastGPT 容器测试
docker exec fastgpt ping copilot-proxy
docker exec fastgpt telnet copilot-proxy 8888
```

#### 问题：DNS 解析失败

**解决方案：**
1. 检查 Docker DNS：

```bash
# 测试域名解析
docker exec copilot-proxy nslookup github.com
```

2. 配置自定义 DNS：

```yaml
services:
  copilot-proxy:
    dns:
      - 8.8.8.8
      - 8.8.4.4
```

## 调试技巧

### 1. 详细日志模式

```env
# 开启调试日志
LOG_LEVEL=debug
NODE_ENV=development
```

### 2. 手动测试 API

```bash
# 测试模型列表
curl -X GET http://localhost:8888/v1/models \
  -H "Content-Type: application/json"

# 测试聊天接口
curl -X POST http://localhost:8888/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "测试消息"}],
    "max_tokens": 100
  }'
```

### 3. 容器内调试

```bash
# 进入容器
docker exec -it copilot-proxy /bin/sh

# 查看进程
ps aux

# 查看文件
ls -la /app
cat /app/src/server.js

# 测试网络
wget -O- http://localhost:8888/health
```

### 4. 性能分析

```bash
# 监控资源使用
watch docker stats

# 分析内存使用
docker exec copilot-proxy cat /proc/meminfo

# 监控网络流量
sudo iftop -i docker0
```

## 恢复步骤

### 完全重置

```bash
# 1. 停止所有服务
docker-compose down -v

# 2. 清理数据
sudo rm -rf infrastructure/docker/dev-data/*

# 3. 重新部署
./scripts/deploy.sh deploy

# 4. 验证服务
./scripts/test.sh
```

### 备份恢复

```bash
# 恢复数据库
./scripts/deploy.sh backup restore backup_20240816_120000

# 重启服务
./scripts/deploy.sh restart
```

## 获取帮助

### 收集信息

在报告问题时，请提供以下信息：

```bash
# 系统信息
uname -a
docker --version
docker-compose --version

# 服务状态
./scripts/deploy.sh status

# 错误日志
docker logs copilot-proxy --tail=100

# 配置信息（去除敏感信息）
cat config/development.env | grep -v TOKEN | grep -v PASSWORD
```

### 联系支持

1. 查看 [GitHub Issues](https://github.com/YuanhuYang/fastgpt_copilot/issues)
2. 创建新的 Issue，包含上述信息
3. 加入社区讨论

### 应急联系

如遇紧急问题：
1. 查看日志确定问题类型
2. 使用备份快速恢复服务
3. 联系技术支持团队
