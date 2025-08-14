#!/bin/bash

echo "▲ Starting Vercel deployment..."

# 检查 Vercel CLI
if ! command -v vercel &> /dev/null; then
    echo "❌ Vercel CLI not found. Installing..."
    npm install -g vercel
fi

echo "📦 Building frontend..."
cd apps/frontend
pnpm install
pnpm run build

echo "🚀 Deploying to Vercel..."
vercel --prod

echo "✅ Vercel deployment complete!"
echo "🔗 Check your deployment at: https://vercel.com/dashboard"
