const express = require('express');
const axios = require('axios');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 8888;

// 中间件
app.use(cors());
app.use(express.json());

// 配置
const config = {
  github_token: process.env.GITHUB_TOKEN || 'your-github-token-here',
  copilot_api: 'https://api.githubcopilot.com',
  openai_api: 'https://api.openai.com/v1'
};

// 健康检查
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    service: 'copilot-proxy', 
    port: PORT,
    timestamp: new Date().toISOString()
  });
});

// 状态检查
app.get('/status', (req, res) => {
  res.json({
    status: 'running',
    endpoints: {
      health: '/health',
      chat: '/v1/chat/completions',
      models: '/v1/models'
    },
    config: {
      port: PORT,
      proxy_target: 'GitHub Copilot API'
    }
  });
});

// 模型列表 (兼容OpenAI API)
app.get('/v1/models', (req, res) => {
  res.json({
    object: 'list',
    data: [
      {
        id: 'gpt-4',
        object: 'model',
        created: Date.now(),
        owned_by: 'github-copilot'
      },
      {
        id: 'gpt-3.5-turbo',
        object: 'model', 
        created: Date.now(),
        owned_by: 'github-copilot'
      }
    ]
  });
});

// Chat Completions 代理
app.post('/v1/chat/completions', async (req, res) => {
  try {
    console.log('收到聊天请求:', JSON.stringify(req.body, null, 2));
    
    // 构建请求头
    const headers = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${config.github_token}`,
      'User-Agent': 'GitHub-Copilot-Chat/1.0',
      'Accept': 'application/json'
    };

    // 准备请求数据
    const requestData = {
      model: req.body.model || 'gpt-4',
      messages: req.body.messages || [],
      max_tokens: req.body.max_tokens || 1000,
      temperature: req.body.temperature || 0.7,
      stream: req.body.stream || false
    };

    console.log('发送到GitHub Copilot API:', JSON.stringify(requestData, null, 2));

    // 尝试调用GitHub Copilot API
    try {
      const response = await axios.post(
        `${config.copilot_api}/chat/completions`,
        requestData,
        { headers, timeout: 30000 }
      );

      console.log('GitHub Copilot API响应状态:', response.status);
      res.json(response.data);
      
    } catch (copilotError) {
      console.log('GitHub Copilot API调用失败:', copilotError.message);
      
      // 如果GitHub Copilot API失败，尝试使用模拟响应
      if (copilotError.response?.status === 400 && 
          copilotError.response?.data?.includes?.('Personal Access Tokens are not supported')) {
        
        console.log('检测到PAT不支持错误，返回模拟响应');
        
        // 生成模拟响应
        const mockResponse = {
          id: `chatcmpl-${Date.now()}`,
          object: 'chat.completion',
          created: Math.floor(Date.now() / 1000),
          model: requestData.model,
          choices: [{
            index: 0,
            message: {
              role: 'assistant',
              content: `我是GitHub Copilot，一个AI编程助手。我可以帮助您：

🔍 代码生成和优化
📚 代码解释和文档编写  
🐛 错误调试和修复
💡 编程问题解答
🚀 最佳实践建议

注意：当前使用的是代理模式，因为GitHub Copilot Chat API不支持Personal Access Token直接访问。建议使用以下替代方案：

1. 申请GitHub App获取正确的token
2. 使用OpenAI API: https://api.openai.com/v1/
3. 使用DeepSeek API: https://api.deepseek.com/v1/

如何获取OpenAI API密钥：
- 访问 https://platform.openai.com/api-keys
- 创建新的API密钥
- 替换.env中的配置

如何获取DeepSeek API密钥：
- 访问 https://platform.deepseek.com/
- 注册并获取API密钥  
- 性价比更高，支持中文

有什么编程问题我可以帮您解决吗？`
            },
            finish_reason: 'stop'
          }],
          usage: {
            prompt_tokens: 50,
            completion_tokens: 200,
            total_tokens: 250
          }
        };
        
        return res.json(mockResponse);
      }
      
      // 其他错误直接抛出
      throw copilotError;
    }

  } catch (error) {
    console.error('代理服务错误:', error.message);
    
    if (error.response) {
      console.error('错误响应:', error.response.status, error.response.data);
      res.status(error.response.status).json({
        error: {
          message: error.response.data?.message || error.message,
          type: 'proxy_error',
          code: error.response.status
        }
      });
    } else {
      res.status(500).json({
        error: {
          message: '代理服务内部错误: ' + error.message,
          type: 'internal_error',
          code: 500
        }
      });
    }
  }
});

// 启动服务器
app.listen(PORT, '0.0.0.0', () => {
  console.log('\n===========================================');
  console.log('  GitHub Copilot 代理服务已启动');
  console.log('===========================================');
  console.log(`🚀 服务地址: http://localhost:${PORT}`);
  console.log(`🔗 API端点: http://localhost:${PORT}/v1/chat/completions`);
  console.log(`❤️  健康检查: http://localhost:${PORT}/health`);
  console.log(`📊 状态检查: http://localhost:${PORT}/status`);
  console.log('');
  console.log('📝 使用说明:');
  console.log('  1. 配置FastGPT使用此代理');
  console.log('  2. API兼容OpenAI格式');
  console.log('  3. 支持聊天对话功能');
  console.log('');
  console.log('🛑 按Ctrl+C停止服务');
  console.log('===========================================\n');
});

// 优雅关闭
process.on('SIGINT', () => {
  console.log('\n正在停止服务...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n正在停止服务...');
  process.exit(0);
});
