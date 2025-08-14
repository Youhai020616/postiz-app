# 环境变量配置指南

## 🔧 Railway 环境变量

在 Railway Dashboard → Variables 中设置以下变量：

### 必需变量
```bash
# 数据库连接 (已配置 Supabase)
DATABASE_URL=postgresql://postgres.xprjrgfftchdxvjlflye:2653063588Xyh%21%40%23@aws-0-us-east-2.pooler.supabase.com:6543/postgres

# Redis 连接 (Railway Redis 服务)
REDIS_URL=redis://default:password@redis-service.railway.internal:6379

# JWT 密钥
JWT_SECRET=postiz-jwt-secret-key-for-development-2025-very-long-and-secure-string

# 应用配置
IS_GENERAL=true
NX_ADD_PLUGINS=false
API_LIMIT=30
STORAGE_PROVIDER=local

# URL 配置 (部署后更新)
BACKEND_INTERNAL_URL=https://your-railway-backend.railway.app
FRONTEND_URL=https://your-vercel-app.vercel.app
```

### 可选变量
```bash
# 邮件服务 (Resend)
RESEND_API_KEY=your-resend-api-key
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
EMAIL_FROM_NAME=Postiz

# 支付服务 (Stripe)
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_SECRET_KEY=sk_live_...
STRIPE_SIGNING_KEY=whsec_...

# AI 功能 (OpenAI)
OPENAI_API_KEY=sk-...

# 社交媒体 API
X_API_KEY=your-x-api-key
X_API_SECRET=your-x-api-secret
LINKEDIN_CLIENT_ID=your-linkedin-client-id
LINKEDIN_CLIENT_SECRET=your-linkedin-client-secret
FACEBOOK_APP_ID=your-facebook-app-id
FACEBOOK_APP_SECRET=your-facebook-app-secret
```

## ▲ Vercel 环境变量

在 Vercel Dashboard → Settings → Environment Variables 中设置：

### 必需变量
```bash
# 后端 API 地址
NEXT_PUBLIC_BACKEND_URL=https://your-railway-backend.railway.app

# 前端地址
FRONTEND_URL=https://your-vercel-app.vercel.app
```

### 可选变量
```bash
# 分析和监控
NEXT_PUBLIC_POSTHOG_KEY=your-posthog-key
NEXT_PUBLIC_SENTRY_DSN=your-sentry-dsn

# 其他前端配置
NEXT_PUBLIC_DISCORD_SUPPORT=your-discord-invite
NEXT_PUBLIC_POLOTNO=your-polotno-key
```

## 🔄 环境变量同步

### 开发环境 (.env)
```bash
# 复制并编辑环境变量
cp .env.example .env

# 本地开发配置
DATABASE_URL=postgresql://postgres.xprjrgfftchdxvjlflye:2653063588Xyh%21%40%23@aws-0-us-east-2.pooler.supabase.com:6543/postgres
REDIS_URL=redis://localhost:6379
JWT_SECRET=postiz-jwt-secret-key-for-development-2025-very-long-and-secure-string
FRONTEND_URL=http://localhost:4200
NEXT_PUBLIC_BACKEND_URL=http://localhost:3000
BACKEND_INTERNAL_URL=http://localhost:3000
```

### 生产环境检查清单
- [ ] DATABASE_URL 已设置
- [ ] REDIS_URL 已设置  
- [ ] JWT_SECRET 已设置
- [ ] FRONTEND_URL 已设置
- [ ] NEXT_PUBLIC_BACKEND_URL 已设置
- [ ] BACKEND_INTERNAL_URL 已设置
- [ ] 社交媒体 API 密钥已配置 (可选)
- [ ] 邮件服务已配置 (可选)
- [ ] 支付服务已配置 (可选)

## 🔐 安全注意事项

1. **JWT_SECRET**: 使用强随机字符串，至少 32 字符
2. **API 密钥**: 不要在前端代码中暴露后端 API 密钥
3. **数据库**: 确保数据库连接使用 SSL
4. **Redis**: 在生产环境中启用 Redis 认证
5. **CORS**: 正确配置跨域请求白名单

## 🚀 快速配置脚本

```bash
# 设置 Railway 环境变量
railway variables set DATABASE_URL="postgresql://postgres.xprjrgfftchdxvjlflye:2653063588Xyh%21%40%23@aws-0-us-east-2.pooler.supabase.com:6543/postgres"
railway variables set JWT_SECRET="postiz-jwt-secret-key-for-development-2025-very-long-and-secure-string"
railway variables set IS_GENERAL="true"
railway variables set STORAGE_PROVIDER="local"

# 设置 Vercel 环境变量
vercel env add NEXT_PUBLIC_BACKEND_URL
vercel env add FRONTEND_URL
```
