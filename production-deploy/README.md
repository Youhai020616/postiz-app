# Postiz 生产环境部署指南

这是一个完整的 Postiz 生产环境部署解决方案，包含自动化部署脚本、Nginx 反向代理配置、SSL 证书管理和系统监控。

## 📋 系统要求

- **操作系统**: Ubuntu 20.04+ / CentOS 8+ / Debian 11+
- **CPU**: 2+ vCPUs (推荐 4 vCPUs)
- **内存**: 2GB+ RAM (推荐 4GB)
- **存储**: 20GB+ SSD (推荐 50GB)
- **网络**: 公网 IP 或内网固定 IP
- **域名**: 已解析到服务器 IP 的域名

## 🚀 快速部署

### 1. 准备工作

确保您的域名已正确解析到服务器 IP：

```bash
# 检查域名解析
nslookup postiz.yourcompany.com
```

### 2. 一键部署

```bash
# 给部署脚本执行权限
chmod +x deploy.sh

# 运行部署脚本
sudo ./deploy.sh postiz.yourcompany.com admin@yourcompany.com
```

**参数说明**：
- `postiz.yourcompany.com`: 您的域名
- `admin@yourcompany.com`: 管理员邮箱（用于 SSL 证书）

### 3. 部署完成

部署完成后，您可以通过以下地址访问：
- **Web 界面**: https://postiz.yourcompany.com
- **健康检查**: https://postiz.yourcompany.com/health

## 📁 文件结构

```
production-deploy/
├── deploy.sh                 # 一键部署脚本
├── manage.sh                 # 服务管理脚本
├── docker-compose.prod.yml   # Docker Compose 配置
├── .env.production           # 环境变量配置
├── nginx.conf                # Nginx 配置模板
└── README.md                 # 本文档
```

## 🔧 配置说明

### 环境变量配置

主要配置文件：`/opt/postiz/.env`

**核心配置**：
```bash
# 域名配置
MAIN_URL=https://postiz.yourcompany.com
FRONTEND_URL=https://postiz.yourcompany.com
NEXT_PUBLIC_BACKEND_URL=https://postiz.yourcompany.com/api

# 安全配置
JWT_SECRET=your-generated-jwt-secret
DISABLE_REGISTRATION=true  # 企业环境建议禁用注册
```

**社交媒体 API 配置**：
```bash
# Twitter/X
X_API_KEY=your-x-api-key
X_API_SECRET=your-x-api-secret

# LinkedIn
LINKEDIN_CLIENT_ID=your-linkedin-client-id
LINKEDIN_CLIENT_SECRET=your-linkedin-client-secret

# 其他平台...
```

### 邮件配置（可选）

```bash
EMAIL_PROVIDER=nodemailer
EMAIL_HOST=smtp.yourcompany.com
EMAIL_PORT=587
EMAIL_SECURE=true
EMAIL_USER=postiz@yourcompany.com
EMAIL_PASS=your-email-password
```

## 🛠️ 服务管理

使用管理脚本进行日常操作：

```bash
# 给管理脚本执行权限
chmod +x manage.sh

# 查看所有可用命令
./manage.sh help
```

### 常用命令

```bash
# 查看服务状态
./manage.sh status

# 查看日志
./manage.sh logs

# 重启服务
./manage.sh restart

# 更新到最新版本
./manage.sh update

# 备份数据
./manage.sh backup

# 监控系统资源
./manage.sh monitor
```

## 🔒 安全配置

### 防火墙设置

```bash
# 查看防火墙状态
sudo ufw status

# 只允许必要端口
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### SSL 证书管理

```bash
# 手动续期证书
./manage.sh ssl-renew

# 查看证书状态
sudo certbot certificates
```

### Fail2Ban 保护

自动配置了 Fail2Ban 来防止暴力攻击：

```bash
# 查看 Fail2Ban 状态
sudo fail2ban-client status

# 查看被封禁的 IP
sudo fail2ban-client status nginx-http-auth
```

## 📊 监控和日志

### 系统监控

```bash
# 实时监控
./manage.sh monitor

# 查看 Docker 资源使用
docker system df

# 查看容器状态
docker-compose ps
```

### 日志管理

```bash
# 查看应用日志
./manage.sh logs

# 查看 Nginx 日志
sudo tail -f /var/log/nginx/postiz.yourcompany.com.access.log
sudo tail -f /var/log/nginx/postiz.yourcompany.com.error.log

# 查看系统日志
sudo journalctl -u docker -f
```

## 💾 备份和恢复

### 自动备份

系统已配置每日凌晨 2 点自动备份：

```bash
# 查看备份任务
crontab -l

# 手动运行备份
/opt/backups/backup-postiz.sh
```

### 手动备份

```bash
# 创建备份
./manage.sh backup

# 查看备份文件
ls -la /opt/backups/postiz/
```

### 数据恢复

```bash
# 从备份恢复
./manage.sh restore
```

## 🔧 故障排除

### 常见问题

1. **服务无法启动**
   ```bash
   # 检查日志
   ./manage.sh logs
   
   # 检查端口占用
   sudo netstat -tulpn | grep :5000
   ```

2. **SSL 证书问题**
   ```bash
   # 检查证书状态
   sudo certbot certificates
   
   # 重新获取证书
   sudo certbot delete --cert-name postiz.yourcompany.com
   sudo certbot certonly --webroot -w /var/www/certbot -d postiz.yourcompany.com
   ```

3. **数据库连接问题**
   ```bash
   # 进入数据库容器
   ./manage.sh db-shell
   
   # 检查数据库状态
   docker exec postiz-postgres pg_isready -U postiz-user
   ```

4. **内存不足**
   ```bash
   # 检查内存使用
   free -h
   
   # 清理 Docker 资源
   ./manage.sh cleanup
   ```

### 性能优化

1. **增加内存限制**
   ```bash
   # 编辑 docker-compose.yml
   nano /opt/postiz/docker-compose.yml
   
   # 在服务中添加内存限制
   mem_limit: 1g
   ```

2. **数据库优化**
   ```bash
   # 进入数据库容器
   ./manage.sh db-shell
   
   # 查看数据库大小
   SELECT pg_size_pretty(pg_database_size('postiz-production'));
   ```

## 📞 支持

如果遇到问题，请：

1. 查看日志：`./manage.sh logs`
2. 检查服务状态：`./manage.sh status`
3. 查看官方文档：https://docs.postiz.com
4. 提交 Issue：https://github.com/gitroomhq/postiz-app/issues

## 📝 更新日志

- **v1.0.0**: 初始版本，包含完整的部署和管理功能
- 支持一键部署
- 自动 SSL 证书配置
- 完整的备份和恢复功能
- 系统监控和日志管理
