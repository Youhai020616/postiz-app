# 🚀 Postiz 快速开始指南

## 📋 部署概览

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Vercel        │    │    Railway      │    │   Supabase      │
│   (Frontend)    │◄──►│   (Backend)     │◄──►│  (Database)     │
│   Next.js       │    │   NestJS        │    │  PostgreSQL     │
│                 │    │   + Redis       │    │                 │
│                 │    │   + Workers     │    │                 │
│                 │    │   + Cron        │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## ⚡ 一键部署

### 1. 准备工作 (5分钟)
```bash
# 1. 克隆项目
git clone https://github.com/your-username/postiz-app.git
cd postiz-app

# 2. 安装依赖
pnpm install

# 3. 生成 Prisma 客户端
pnpm run prisma-generate
```

### 2. Railway 部署 (10分钟)
```bash
# 1. 安装 Railway CLI
npm install -g @railway/cli

# 2. 登录 Railway
railway login

# 3. 创建项目
railway init

# 4. 添加 Redis 服务
# 在 Railway Dashboard 添加 Redis 数据库

# 5. 部署后端
pnpm run deploy:railway
```

### 3. Vercel 部署 (5分钟)
```bash
# 1. 安装 Vercel CLI
npm install -g vercel

# 2. 部署前端
pnpm run deploy:vercel
```

### 4. 配置环境变量 (5分钟)
参考 [环境变量配置指南](./ENVIRONMENT_VARIABLES.md)

## 🔧 详细步骤

### Railway 配置

1. **创建 Railway 项目**
   - 访问 [Railway](https://railway.app)
   - 点击 "New Project"
   - 选择 "Deploy from GitHub repo"

2. **添加 Redis 服务**
   - 在项目中点击 "New Service"
   - 选择 "Database" → "Redis"
   - 复制 Redis 连接 URL

3. **配置环境变量**
   ```bash
   DATABASE_URL=postgresql://postgres.xprjrgfftchdxvjlflye:2653063588Xyh%21%40%23@aws-0-us-east-2.pooler.supabase.com:6543/postgres
   REDIS_URL=redis://default:password@redis.railway.internal:6379
   JWT_SECRET=postiz-jwt-secret-key-for-development-2025-very-long-and-secure-string
   IS_GENERAL=true
   STORAGE_PROVIDER=local
   ```

4. **部署服务**
   - Backend: `pnpm run start:prod:backend`
   - Workers: `pnpm run start:prod:workers`
   - Cron: `pnpm run start:prod:cron`

### Vercel 配置

1. **连接 GitHub**
   - 访问 [Vercel](https://vercel.com)
   - 导入 GitHub 仓库

2. **配置构建设置**
   ```
   Framework Preset: Next.js
   Root Directory: apps/frontend
   Build Command: pnpm run build
   Output Directory: .next
   Install Command: pnpm install
   ```

3. **设置环境变量**
   ```bash
   NEXT_PUBLIC_BACKEND_URL=https://your-railway-backend.railway.app
   FRONTEND_URL=https://your-vercel-app.vercel.app
   ```

## 🎯 验证部署

### 1. 检查后端服务
```bash
# 健康检查
curl https://your-railway-backend.railway.app/health

# API 测试
curl https://your-railway-backend.railway.app/api/auth/me
```

### 2. 检查前端服务
```bash
# 访问前端
curl https://your-vercel-app.vercel.app

# 检查 API 连接
# 在浏览器中访问前端，检查网络请求
```

### 3. 检查数据库连接
```bash
# 在 Railway 控制台运行
railway run pnpm dlx prisma db push
```

## 🔄 自动部署设置

### GitHub Actions
创建 `.github/workflows/deploy.yml`:
```yaml
name: Deploy to Railway and Vercel

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
          cache: 'pnpm'
      
      - name: Install dependencies
        run: pnpm install
      
      - name: Deploy to Railway
        run: |
          npm install -g @railway/cli
          railway login --token ${{ secrets.RAILWAY_TOKEN }}
          railway up
      
      - name: Deploy to Vercel
        run: |
          npm install -g vercel
          vercel --token ${{ secrets.VERCEL_TOKEN }} --prod
```

## 📊 监控和维护

### 日志查看
```bash
# Railway 日志
railway logs

# Vercel 日志
vercel logs your-vercel-app.vercel.app
```

### 性能监控
- Railway: 内置监控面板
- Vercel: Analytics 和 Speed Insights
- Supabase: 数据库监控

## 🚨 故障排除

### 常见问题

1. **构建失败**
   ```bash
   # 检查 Node.js 版本
   node --version  # 应该是 20.17.0
   
   # 清理缓存
   pnpm store prune
   rm -rf node_modules
   pnpm install
   ```

2. **数据库连接失败**
   ```bash
   # 测试数据库连接
   pnpm dlx prisma db push --schema ./libraries/nestjs-libraries/src/database/prisma/schema.prisma
   ```

3. **Redis 连接失败**
   ```bash
   # 检查 Redis URL 格式
   echo $REDIS_URL
   ```

4. **CORS 错误**
   - 检查后端 CORS 配置
   - 确保前端 URL 在白名单中

### 获取帮助
- 📖 [完整部署指南](./RAILWAY_VERCEL_DEPLOYMENT.md)
- 🔧 [环境变量配置](./ENVIRONMENT_VARIABLES.md)
- 💬 [Discord 支持](https://discord.postiz.com)
- 📚 [官方文档](https://docs.postiz.com)

## ✅ 部署检查清单

- [ ] GitHub 仓库已创建
- [ ] Railway 项目已创建
- [ ] Redis 服务已添加
- [ ] Vercel 项目已创建
- [ ] 环境变量已配置
- [ ] 后端服务正常运行
- [ ] 前端服务正常运行
- [ ] 数据库连接正常
- [ ] Redis 连接正常
- [ ] API 请求正常
- [ ] 自动部署已配置 (可选)

🎉 **恭喜！您的 Postiz 应用已成功部署！**
