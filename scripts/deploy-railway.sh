#!/bin/bash

echo "🚂 Starting Railway deployment..."

# 检查 Railway CLI
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found. Installing..."
    npm install -g @railway/cli
fi

# 检查登录状态
if ! railway whoami &> /dev/null; then
    echo "❌ Not logged in to Railway. Please run: railway login"
    exit 1
fi

echo "📦 Building project..."
pnpm install
pnpm run prisma-generate
pnpm run build:backend
pnpm run build:workers  
pnpm run build:cron

echo "🚀 Deploying to Railway..."
railway up

echo "✅ Railway deployment complete!"
echo "🔗 Check your deployment at: https://railway.app/dashboard"
