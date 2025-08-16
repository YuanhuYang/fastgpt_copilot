// MongoDB 初始化脚本
db = db.getSiblingDB('fastgpt');

// 创建 fastgpt 用户
db.createUser({
  user: 'fastgpt',
  pwd: 'fastgpt123',
  roles: [
    {
      role: 'readWrite',
      db: 'fastgpt'
    }
  ]
});

// 创建基础集合
db.createCollection('users');
db.createCollection('apps');
db.createCollection('datasets');
db.createCollection('models');
db.createCollection('chats');

print('MongoDB initialization completed for FastGPT');
