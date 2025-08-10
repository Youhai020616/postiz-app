#!/bin/bash

# Postiz 管理脚本
# 用于管理 Postiz 服务的常用操作

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
POSTIZ_DIR="/opt/postiz"
BACKUP_DIR="/opt/backups/postiz"

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

# 检查是否在正确的目录
check_directory() {
    if [ ! -f "$POSTIZ_DIR/docker-compose.yml" ]; then
        log_error "Postiz 未安装或配置文件不存在: $POSTIZ_DIR/docker-compose.yml"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    echo "Postiz 管理脚本"
    echo ""
    echo "使用方法: $0 <command>"
    echo ""
    echo "可用命令:"
    echo "  start       启动 Postiz 服务"
    echo "  stop        停止 Postiz 服务"
    echo "  restart     重启 Postiz 服务"
    echo "  status      查看服务状态"
    echo "  logs        查看服务日志"
    echo "  update      更新 Postiz 到最新版本"
    echo "  backup      手动备份数据"
    echo "  restore     从备份恢复数据"
    echo "  shell       进入应用容器shell"
    echo "  db-shell    进入数据库shell"
    echo "  cleanup     清理未使用的Docker资源"
    echo "  monitor     实时监控系统资源"
    echo "  ssl-renew   手动续期SSL证书"
    echo "  help        显示此帮助信息"
}

# 启动服务
start_service() {
    log_info "启动 Postiz 服务..."
    cd $POSTIZ_DIR
    docker-compose up -d
    log_success "服务已启动"
}

# 停止服务
stop_service() {
    log_info "停止 Postiz 服务..."
    cd $POSTIZ_DIR
    docker-compose down
    log_success "服务已停止"
}

# 重启服务
restart_service() {
    log_info "重启 Postiz 服务..."
    cd $POSTIZ_DIR
    docker-compose restart
    log_success "服务已重启"
}

# 查看状态
show_status() {
    log_info "Postiz 服务状态:"
    cd $POSTIZ_DIR
    docker-compose ps
    echo ""
    log_info "系统资源使用:"
    echo "内存使用:"
    free -h
    echo ""
    echo "磁盘使用:"
    df -h
    echo ""
    echo "Docker 资源使用:"
    docker system df
}

# 查看日志
show_logs() {
    log_info "显示 Postiz 服务日志 (按 Ctrl+C 退出):"
    cd $POSTIZ_DIR
    docker-compose logs -f --tail=100
}

# 更新服务
update_service() {
    log_info "更新 Postiz 到最新版本..."
    cd $POSTIZ_DIR
    
    # 备份当前数据
    log_info "更新前自动备份..."
    backup_data
    
    # 拉取最新镜像
    log_info "拉取最新镜像..."
    docker-compose pull
    
    # 重启服务
    log_info "重启服务..."
    docker-compose up -d
    
    # 清理旧镜像
    log_info "清理旧镜像..."
    docker image prune -f
    
    log_success "更新完成"
}

# 备份数据
backup_data() {
    log_info "开始备份数据..."
    mkdir -p $BACKUP_DIR
    
    DATE=$(date +%Y%m%d_%H%M%S)
    
    # 备份数据库
    log_info "备份数据库..."
    docker exec postiz-postgres pg_dump -U postiz-user postiz-production > $BACKUP_DIR/postiz_db_$DATE.sql
    
    # 备份上传文件
    log_info "备份上传文件..."
    docker run --rm -v postiz_postiz-uploads:/uploads -v $BACKUP_DIR:/backup alpine tar czf /backup/postiz_uploads_$DATE.tar.gz -C /uploads .
    
    # 备份配置文件
    log_info "备份配置文件..."
    cp $POSTIZ_DIR/.env $BACKUP_DIR/env_$DATE.backup
    cp $POSTIZ_DIR/docker-compose.yml $BACKUP_DIR/docker-compose_$DATE.yml
    
    log_success "备份完成: $BACKUP_DIR"
    log_info "数据库备份: postiz_db_$DATE.sql"
    log_info "文件备份: postiz_uploads_$DATE.tar.gz"
    log_info "配置备份: env_$DATE.backup"
}

# 恢复数据
restore_data() {
    log_warning "数据恢复操作将覆盖现有数据！"
    echo "可用的备份文件:"
    ls -la $BACKUP_DIR/*.sql 2>/dev/null || echo "没有找到数据库备份文件"
    echo ""
    read -p "请输入要恢复的数据库备份文件名 (不含路径): " backup_file
    
    if [ ! -f "$BACKUP_DIR/$backup_file" ]; then
        log_error "备份文件不存在: $BACKUP_DIR/$backup_file"
        exit 1
    fi
    
    read -p "确认要恢复数据吗? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "操作已取消"
        exit 0
    fi
    
    log_info "恢复数据库..."
    cd $POSTIZ_DIR
    docker-compose stop postiz
    docker exec postiz-postgres psql -U postiz-user -d postiz-production -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
    docker exec -i postiz-postgres psql -U postiz-user -d postiz-production < $BACKUP_DIR/$backup_file
    docker-compose start postiz
    
    log_success "数据恢复完成"
}

# 进入应用容器
enter_shell() {
    log_info "进入 Postiz 应用容器..."
    docker exec -it postiz-app /bin/bash
}

# 进入数据库shell
enter_db_shell() {
    log_info "进入数据库 shell..."
    docker exec -it postiz-postgres psql -U postiz-user -d postiz-production
}

# 清理Docker资源
cleanup_docker() {
    log_info "清理未使用的 Docker 资源..."
    docker system prune -f
    docker volume prune -f
    log_success "清理完成"
}

# 监控系统资源
monitor_system() {
    log_info "实时监控系统资源 (按 Ctrl+C 退出):"
    while true; do
        clear
        echo "=== Postiz 系统监控 ==="
        echo "时间: $(date)"
        echo ""
        echo "=== Docker 容器状态 ==="
        cd $POSTIZ_DIR && docker-compose ps
        echo ""
        echo "=== 系统资源 ==="
        echo "CPU 使用率:"
        top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
        echo ""
        echo "内存使用:"
        free -h
        echo ""
        echo "磁盘使用:"
        df -h | grep -E "/$|/opt"
        echo ""
        echo "=== 网络连接 ==="
        ss -tulpn | grep :443
        echo ""
        sleep 5
    done
}

# 续期SSL证书
renew_ssl() {
    log_info "续期 SSL 证书..."
    certbot renew --dry-run
    if [ $? -eq 0 ]; then
        certbot renew
        systemctl reload nginx
        log_success "SSL 证书续期完成"
    else
        log_error "SSL 证书续期失败"
    fi
}

# 主函数
main() {
    case "$1" in
        start)
            check_directory
            start_service
            ;;
        stop)
            check_directory
            stop_service
            ;;
        restart)
            check_directory
            restart_service
            ;;
        status)
            check_directory
            show_status
            ;;
        logs)
            check_directory
            show_logs
            ;;
        update)
            check_directory
            update_service
            ;;
        backup)
            check_directory
            backup_data
            ;;
        restore)
            check_directory
            restore_data
            ;;
        shell)
            check_directory
            enter_shell
            ;;
        db-shell)
            check_directory
            enter_db_shell
            ;;
        cleanup)
            cleanup_docker
            ;;
        monitor)
            check_directory
            monitor_system
            ;;
        ssl-renew)
            renew_ssl
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 检查参数
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# 执行主函数
main "$@"
