#!/bin/bash

# FlowGate 云服务器一键部署脚本
# 使用方法: bash deploy.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  FlowGate 云服务器部署脚本${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -eq 0 ]; then 
        print_warning "检测到 root 用户，建议使用普通用户 + sudo"
    fi
}

# 检查系统
check_system() {
    print_info "检查系统环境..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        print_success "系统: $OS $VER"
    else
        print_error "无法检测系统版本"
        exit 1
    fi
}

# 检查 Docker
check_docker() {
    print_info "检查 Docker 安装..."
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
        print_success "Docker 已安装: $DOCKER_VERSION"
        
        # 检查 Docker 是否运行
        if ! docker ps &> /dev/null; then
            print_error "Docker 未运行，请启动 Docker 服务"
            print_info "运行: sudo systemctl start docker"
            exit 1
        fi
    else
        print_error "Docker 未安装"
        print_info "请先安装 Docker: https://docs.docker.com/engine/install/"
        exit 1
    fi
    
    # 检查 Docker Compose
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version | awk '{print $4}')
        print_success "Docker Compose 已安装: $COMPOSE_VERSION"
    else
        print_error "Docker Compose 未安装"
        exit 1
    fi
}

# 生成随机密码
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

# 配置环境变量
configure_env() {
    print_info "配置环境变量..."
    
    # 生成随机密码
    DB_PASSWORD=$(generate_password)
    REDIS_PASSWORD=$(generate_password)
    SESSION_SECRET=$(generate_password)
    
    print_success "已生成安全密码"
    
    # 创建配置文件
    cat > .env.prod << EOF
# FlowGate 生产环境配置
# 自动生成于: $(date)

# 数据库密码
POSTGRES_PASSWORD=${DB_PASSWORD}

# Redis 密码
REDIS_PASSWORD=${REDIS_PASSWORD}

# 会话密钥
SESSION_SECRET=${SESSION_SECRET}

# 时区
TZ=Asia/Shanghai
EOF

    print_success "配置文件已创建: .env.prod"
    print_warning "请妥善保管密码！"
}

# 更新 docker-compose 配置
update_compose_config() {
    print_info "更新 Docker Compose 配置..."
    
    if [ ! -f docker-compose.prod.yml ]; then
        print_error "找不到 docker-compose.prod.yml"
        exit 1
    fi
    
    # 读取密码
    source .env.prod
    
    # 替换密码
    sed -i.bak \
        -e "s/CHANGE_THIS_PASSWORD/${POSTGRES_PASSWORD}/g" \
        -e "s/CHANGE_THIS_TO_RANDOM_STRING/${SESSION_SECRET}/g" \
        docker-compose.prod.yml
    
    # 单独替换 Redis 密码（因为有两处）
    sed -i.bak2 "s/redis:\/\/:CHANGE_THIS_PASSWORD@/redis:\/\/:${REDIS_PASSWORD}@/g" docker-compose.prod.yml
    sed -i.bak3 "s/--requirepass\", \"CHANGE_THIS_PASSWORD/--requirepass\", \"${REDIS_PASSWORD}/g" docker-compose.prod.yml
    
    # 删除备份文件
    rm -f docker-compose.prod.yml.bak docker-compose.prod.yml.bak2 docker-compose.prod.yml.bak3
    
    print_success "配置已更新"
}

# 拉取镜像
pull_images() {
    print_info "拉取 Docker 镜像..."
    
    docker compose -f docker-compose.prod.yml pull
    
    print_success "镜像拉取完成"
}

# 启动服务
start_services() {
    print_info "启动 FlowGate 服务..."
    
    docker compose -f docker-compose.prod.yml up -d
    
    print_success "服务已启动"
}

# 检查服务状态
check_services() {
    print_info "检查服务状态..."
    
    sleep 5
    
    docker compose -f docker-compose.prod.yml ps
    
    print_success "服务状态检查完成"
}

# 显示访问信息
show_access_info() {
    echo ""
    print_success "========================================="
    print_success "  FlowGate 部署完成！"
    print_success "========================================="
    echo ""
    
    # 获取服务器 IP
    SERVER_IP=$(curl -s ifconfig.me || echo "YOUR_SERVER_IP")
    
    echo -e "${GREEN}访问地址:${NC}"
    echo -e "  http://${SERVER_IP}:3000"
    echo ""
    
    echo -e "${GREEN}默认管理员账号:${NC}"
    echo -e "  用户名: root"
    echo -e "  密码: 123456"
    echo -e "  ${RED}⚠️  首次登录后请立即修改密码！${NC}"
    echo ""
    
    echo -e "${GREEN}配置文件位置:${NC}"
    echo -e "  .env.prod - 环境变量和密码"
    echo ""
    
    echo -e "${GREEN}常用命令:${NC}"
    echo -e "  查看日志: ${BLUE}docker compose -f docker-compose.prod.yml logs -f flowgate${NC}"
    echo -e "  停止服务: ${BLUE}docker compose -f docker-compose.prod.yml stop${NC}"
    echo -e "  启动服务: ${BLUE}docker compose -f docker-compose.prod.yml start${NC}"
    echo -e "  重启服务: ${BLUE}docker compose -f docker-compose.prod.yml restart${NC}"
    echo -e "  查看状态: ${BLUE}docker compose -f docker-compose.prod.yml ps${NC}"
    echo ""
    
    echo -e "${YELLOW}下一步操作:${NC}"
    echo -e "  1. 访问 http://${SERVER_IP}:3000"
    echo -e "  2. 使用默认账号登录"
    echo -e "  3. 修改管理员密码"
    echo -e "  4. 配置 AI 服务提供商"
    echo -e "  5. 配置 HTTPS（推荐使用 Nginx 反向代理）"
    echo ""
}

# 主函数
main() {
    print_header
    check_root
    check_system
    check_docker
    configure_env
    update_compose_config
    pull_images
    start_services
    check_services
    show_access_info
}

# 运行主函数
main
