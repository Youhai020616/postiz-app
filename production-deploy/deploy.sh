#!/bin/bash

# Postiz 生产环境部署脚本
# 使用方法: ./deploy.sh [domain] [email]
# 例如: ./deploy.sh postiz.yourcompany.com admin@yourcompany.com

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查参数
if [ $# -lt 2 ]; then
    log_error "使用方法: $0 <domain> <email>"
    log_error "例如: $0 postiz.yourcompany.com admin@yourcompany.com"
    exit 1
fi

DOMAIN=$1
EMAIL=$2
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info "开始部署 Postiz 到域名: $DOMAIN"
log_info "管理员邮箱: $EMAIL"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    log_error "请使用 sudo 运行此脚本"
    exit 1
fi

# 更新系统
log_info "更新系统包..."
apt update && apt upgrade -y

# 安装必要的软件包
log_info "安装必要的软件包..."
apt install -y curl wget git ufw fail2ban nginx certbot python3-certbot-nginx

# 配置防火墙
log_info "配置防火墙..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# 检查Docker是否已安装
if ! command -v docker &> /dev/null; then
    log_info "安装 Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl start docker
    systemctl enable docker
    rm get-docker.sh
else
    log_success "Docker 已安装"
fi

# 检查Docker Compose是否已安装
if ! command -v docker-compose &> /dev/null; then
    log_info "安装 Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    log_success "Docker Compose 已安装"
fi

# 创建Postiz目录
POSTIZ_DIR="/opt/postiz"
log_info "创建 Postiz 目录: $POSTIZ_DIR"
mkdir -p $POSTIZ_DIR
cd $POSTIZ_DIR

# 复制配置文件
log_info "复制配置文件..."
cp $SCRIPT_DIR/docker-compose.prod.yml $POSTIZ_DIR/docker-compose.yml
cp $SCRIPT_DIR/.env.production $POSTIZ_DIR/.env

# 生成随机JWT密钥
JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-64)
log_info "生成 JWT 密钥..."

# 更新配置文件中的域名和JWT密钥
log_info "更新配置文件..."
sed -i "s/postiz.yourcompany.com/$DOMAIN/g" $POSTIZ_DIR/.env
sed -i "s/your-super-long-random-jwt-secret-change-this-to-something-very-secure/$JWT_SECRET/g" $POSTIZ_DIR/.env

# 配置Nginx
log_info "配置 Nginx..."
cp $SCRIPT_DIR/nginx.conf /etc/nginx/sites-available/$DOMAIN
sed -i "s/postiz.yourcompany.com/$DOMAIN/g" /etc/nginx/sites-available/$DOMAIN

# 创建临时Nginx配置用于获取SSL证书
cat > /etc/nginx/sites-available/$DOMAIN.temp << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }

    server_tokens off;
}
EOF

# 创建证书验证目录
mkdir -p /var/www/certbot/.well-known/acme-challenge
chown -R www-data:www-data /var/www/certbot

# 启用临时Nginx配置
ln -sf /etc/nginx/sites-available/$DOMAIN.temp /etc/nginx/sites-enabled/$DOMAIN
nginx -t && systemctl reload nginx

# 获取SSL证书
log_info "获取 SSL 证书..."
certbot certonly --webroot \
    -w /var/www/certbot \
    -d $DOMAIN \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --non-interactive

# 生成DH参数
if [ ! -f /etc/ssl/certs/dhparam.pem ]; then
    log_info "生成 DH 参数（这可能需要几分钟）..."
    openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
fi

# 启用正式Nginx配置
log_info "启用正式 Nginx 配置..."
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN
rm -f /etc/nginx/sites-enabled/$DOMAIN.temp
rm -f /etc/nginx/sites-enabled/default

# 测试Nginx配置
nginx -t && systemctl reload nginx

# 配置SSL证书自动续期
log_info "配置 SSL 证书自动续期..."
cat > /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh << 'EOF'
#!/bin/bash
nginx -t && systemctl reload nginx
EOF
chmod +x /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh

# 启动Postiz服务
log_info "启动 Postiz 服务..."
cd $POSTIZ_DIR
docker-compose pull
docker-compose up -d

# 等待服务启动
log_info "等待服务启动..."
sleep 30

# 检查服务状态
log_info "检查服务状态..."
docker-compose ps

# 配置Fail2Ban
log_info "配置 Fail2Ban..."
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/$DOMAIN.error.log
maxretry = 3

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /var/log/nginx/$DOMAIN.error.log
maxretry = 10
EOF

systemctl restart fail2ban

# 创建备份脚本
log_info "创建备份脚本..."
mkdir -p /opt/backups/postiz
cat > /opt/backups/backup-postiz.sh << EOF
#!/bin/bash
BACKUP_DIR="/opt/backups/postiz"
DATE=\$(date +%Y%m%d_%H%M%S)

# 备份数据库
docker exec postiz-postgres pg_dump -U postiz-user postiz-production > \$BACKUP_DIR/postiz_db_\$DATE.sql

# 备份上传文件
docker run --rm -v postiz_postiz-uploads:/uploads -v \$BACKUP_DIR:/backup alpine tar czf /backup/postiz_uploads_\$DATE.tar.gz -C /uploads .

# 删除7天前的备份
find \$BACKUP_DIR -name "*.sql" -mtime +7 -delete
find \$BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: \$DATE"
EOF

chmod +x /opt/backups/backup-postiz.sh

# 添加定时备份任务
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/backups/backup-postiz.sh >> /var/log/postiz-backup.log 2>&1") | crontab -

log_success "部署完成！"
log_info "访问地址: https://$DOMAIN"
log_info "配置文件位置: $POSTIZ_DIR/.env"
log_info "日志查看: docker-compose -f $POSTIZ_DIR/docker-compose.yml logs -f"
log_info "备份脚本: /opt/backups/backup-postiz.sh"

log_warning "请注意："
log_warning "1. 首次访问时需要创建管理员账户"
log_warning "2. 如需配置社交媒体API，请编辑 $POSTIZ_DIR/.env 文件"
log_warning "3. 重启服务命令: docker-compose -f $POSTIZ_DIR/docker-compose.yml restart"
