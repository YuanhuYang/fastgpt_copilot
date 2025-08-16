# FastGPT Copilot 项目重构方案

## 新目录结构

```
fastgpt_copilot/
├── README.md                           # 项目主文档
├── .gitignore                          # Git忽略文件
├── LICENSE                             # 许可证
│
├── docs/                               # 文档目录
│   ├── deployment.md                   # 部署指南
│   ├── configuration.md                # 配置指南
│   └── troubleshooting.md              # 故障排除
│
├── services/                           # 服务目录
│   ├── copilot-proxy/                  # Copilot代理服务
│   │   ├── src/
│   │   │   ├── server.js               # 主服务文件
│   │   │   ├── config/
│   │   │   ├── middleware/
│   │   │   └── routes/
│   │   ├── package.json
│   │   ├── Dockerfile
│   │   └── README.md
│   │
│   └── fastgpt/                        # FastGPT服务
│       ├── docker-compose.yml
│       ├── .env.example
│       └── README.md
│
├── infrastructure/                     # 基础设施
│   ├── docker/
│   │   ├── docker-compose.yml          # 主compose文件
│   │   ├── docker-compose.dev.yml      # 开发环境
│   │   └── docker-compose.prod.yml     # 生产环境
│   │
│   ├── nginx/
│   │   ├── nginx.conf
│   │   └── ssl/
│   │
│   └── monitoring/
│       ├── prometheus/
│       └── grafana/
│
├── scripts/                            # 部署和管理脚本
│   ├── deploy.sh                       # 主部署脚本
│   ├── test.sh                         # 测试脚本
│   └── cleanup.sh                      # 清理脚本
│
├── config/                             # 配置文件
│   ├── development.env
│   ├── production.env
│   └── test.env
│
└── tests/                              # 测试目录
    ├── integration/
    ├── unit/
    └── e2e/
```

## 重构原则

1. **服务解耦**: copilot-proxy和fastgpt完全独立
2. **清晰分层**: 基础设施、服务、配置分离
3. **环境分离**: 开发、测试、生产环境配置独立
4. **文档完善**: 每个模块都有独立的README
5. **标准化**: 遵循微服务最佳实践
