#!/bin/bash

# Postiz 本地测试启动脚本
# 适用于在当前远程环境中快速测试 Postiz

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 检查Docker是否运行
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker 未运行或无权限访问"
        log_info "请确保 Docker 服务正在运行"
        exit 1
    fi
    log_success "Docker 检查通过"
}

# 检查端口是否被占用
check_ports() {
    local ports=("5000" "5432" "6379" "8081")
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            log_warning "端口 $port 已被占用，可能会导致冲突"
        fi
    done
}

# 启动服务
start_services() {
    log_info "启动 Postiz 本地测试环境..."
    
    # 拉取最新镜像
    log_info "拉取 Docker 镜像..."
    docker-compose -f docker-compose.local.yml pull
    
    # 启动服务
    log_info "启动服务容器..."
    docker-compose -f docker-compose.local.yml up -d
    
    # 等待服务启动
    log_info "等待服务启动（约30秒）..."
    sleep 30
    
    # 检查服务状态
    log_info "检查服务状态..."
    docker-compose -f docker-compose.local.yml ps
}

# 显示访问信息
show_access_info() {
    echo ""
    log_success "🎉 Postiz 本地测试环境启动成功！"
    echo ""
    echo "📱 访问地址："
    echo "   主应用: http://localhost:5000"
    echo "   Redis管理: http://localhost:8081"
    echo ""
    echo "🔧 数据库连接信息："
    echo "   PostgreSQL: localhost:5432"
    echo "   用户名: postiz-user"
    echo "   密码: postiz-password"
    echo "   数据库: postiz-local"
    echo ""
    echo "📊 Redis连接信息："
    echo "   地址: localhost:6379"
    echo ""
    echo "🛠️ 管理命令："
    echo "   查看日志: docker-compose -f docker-compose.local.yml logs -f"
    echo "   停止服务: docker-compose -f docker-compose.local.yml down"
    echo "   重启服务: docker-compose -f docker-compose.local.yml restart"
    echo ""
    log_warning "注意：这是本地测试环境，不适用于生产部署！"
}

# 主函数
main() {
    echo "🚀 Postiz 本地测试环境启动器"
    echo "================================"
    
    # 检查环境
    check_docker
    check_ports
    
    # 启动服务
    start_services
    
    # 显示访问信息
    show_access_info
}

# 执行主函数
main "$@"
