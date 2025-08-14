# Postiz Railway + Vercel 部署指南

## 🚀 部署架构

- **Railway**: 后端服务 (NestJS) + Redis + Workers + Cron
- **Vercel**: 前端服务 (Next.js)
- **Supabase**: PostgreSQL 数据库 (已配置)

## 📋 部署前准备

### 1. 账户准备
- [Railway](https://railway.app) 账户
- [Vercel](https://vercel.com) 账户
- GitHub 仓库 (用于自动部署)

### 2. 环境变量准备
```bash
# 数据库 (已配置)
DATABASE_URL="postgresql://postgres.xprjrgfftchdxvjlflye:2653063588Xyh%21%40%23@aws-0-us-east-2.pooler.supabase.com:6543/postgres"

# JWT 密钥
JWT_SECRET="postiz-jwt-secret-key-for-development-2025-very-long-and-secure-string"

# 存储
STORAGE_PROVIDER="local"

# 其他必需变量
IS_GENERAL="true"
NX_ADD_PLUGINS=false
API_LIMIT=30
```

## 🚂 Railway 部署 (后端 + Redis)

### 1. 创建 Railway 项目
```bash
# 安装 Railway CLI
npm install -g @railway/cli

# 登录
railway login

# 在项目根目录初始化
railway init
```

### 2. 添加 Redis 服务
在 Railway Dashboard:
1. 点击 "New Service"
2. 选择 "Database" → "Redis"
3. 部署完成后获取 `REDIS_URL`

### 3. 配置后端服务
创建 Railway 配置文件:
```toml
# railway.toml
[build]
builder = "nixpacks"
buildCommand = "pnpm install && pnpm run build:backend && pnpm run build:workers && pnpm run build:cron"

[deploy]
startCommand = "pnpm run start:prod:backend"
restartPolicyType = "on_failure"
restartPolicyMaxRetries = 10

[[services]]
name = "backend"
source = "."

[[services]]
name = "workers"
source = "."
startCommand = "pnpm run start:prod:workers"

[[services]]
name = "cron"
source = "."
startCommand = "pnpm run start:prod:cron"
```

### 4. 设置环境变量
在 Railway Dashboard 的 Variables 部分添加:
```
DATABASE_URL=postgresql://postgres.xprjrgfftchdxvjlflye:2653063588Xyh%21%40%23@aws-0-us-east-2.pooler.supabase.com:6543/postgres
REDIS_URL=redis://railway-redis-url:6379
JWT_SECRET=postiz-jwt-secret-key-for-development-2025-very-long-and-secure-string
STORAGE_PROVIDER=local
IS_GENERAL=true
NX_ADD_PLUGINS=false
API_LIMIT=30
BACKEND_INTERNAL_URL=https://your-railway-backend.railway.app
```

### 5. 部署
```bash
railway up
```

## ▲ Vercel 部署 (前端)

### 1. 准备前端项目
创建 Vercel 配置文件:
```json
{
  "name": "postiz-frontend",
  "version": 2,
  "builds": [
    {
      "src": "apps/frontend/package.json",
      "use": "@vercel/next"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "apps/frontend/$1"
    }
  ],
  "env": {
    "NEXT_PUBLIC_BACKEND_URL": "https://your-railway-backend.railway.app"
  },
  "buildCommand": "cd apps/frontend && pnpm run build",
  "outputDirectory": "apps/frontend/.next",
  "installCommand": "pnpm install"
}
```

### 2. 配置环境变量
在 Vercel Dashboard 设置:
```
NEXT_PUBLIC_BACKEND_URL=https://your-railway-backend.railway.app
FRONTEND_URL=https://your-vercel-app.vercel.app
```

### 3. 部署设置
```bash
# 安装 Vercel CLI
npm install -g vercel

# 在项目根目录
vercel

# 或者通过 GitHub 自动部署
```

## 🔧 配置文件更新

### 1. 更新 Railway 配置
```toml
# railway.toml (更新版本)
[phases.setup]
nixPkgs = ['nodejs', 'python3']
aptPkgs = ['build-essential', 'libudev-dev']

[build]
builder = "nixpacks"
buildCommand = "pnpm install && pnpm run prisma-generate && pnpm run build"

[deploy]
startCommand = "pnpm run start:prod:backend"
```

### 2. 创建部署脚本
```bash
# scripts/deploy-railway.sh
#!/bin/bash
echo "🚂 Deploying to Railway..."
railway up --service backend
railway up --service workers  
railway up --service cron
echo "✅ Railway deployment complete!"
```

```bash
# scripts/deploy-vercel.sh  
#!/bin/bash
echo "▲ Deploying to Vercel..."
cd apps/frontend
vercel --prod
echo "✅ Vercel deployment complete!"
```

## 🌐 域名配置

### 1. Railway 自定义域名
1. 在 Railway Dashboard → Settings → Domains
2. 添加自定义域名
3. 配置 DNS CNAME 记录

### 2. Vercel 自定义域名
1. 在 Vercel Dashboard → Domains
2. 添加域名并验证
3. 更新环境变量中的 URL

## 📊 监控和日志

### Railway 监控
```bash
# 查看日志
railway logs

# 查看服务状态
railway status
```

### Vercel 监控
- 在 Vercel Dashboard 查看部署状态
- 查看 Function 日志和性能指标

## 🔄 CI/CD 自动部署

### GitHub Actions 配置
```yaml
# .github/workflows/deploy.yml
name: Deploy to Railway and Vercel

on:
  push:
    branches: [main]

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - run: npm install -g @railway/cli
      - run: railway login --token ${{ secrets.RAILWAY_TOKEN }}
      - run: railway up

  deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - run: npm install -g vercel
      - run: vercel --token ${{ secrets.VERCEL_TOKEN }} --prod
```

## 🚀 快速部署命令

```bash
# 1. 部署后端到 Railway
railway up

# 2. 部署前端到 Vercel  
cd apps/frontend && vercel --prod

# 3. 验证部署
curl https://your-railway-backend.railway.app/health
curl https://your-vercel-app.vercel.app
```

## 📝 注意事项

1. **环境变量同步**: 确保 Railway 和 Vercel 的环境变量保持一致
2. **CORS 配置**: 后端需要允许前端域名的跨域请求
3. **数据库连接**: 确保 Railway 服务可以访问 Supabase
4. **Redis 连接**: Workers 和 Cron 服务需要 Redis 连接
5. **文件上传**: 考虑使用 Cloudflare R2 或其他云存储服务

## 🔧 故障排除

### 常见问题
1. **构建失败**: 检查 Node.js 版本和依赖
2. **数据库连接**: 验证 DATABASE_URL 格式
3. **Redis 连接**: 确保 REDIS_URL 正确
4. **CORS 错误**: 检查后端 CORS 配置
5. **环境变量**: 确保所有必需变量已设置
