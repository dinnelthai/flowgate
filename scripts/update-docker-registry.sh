#!/bin/bash

# FlowGate Docker 镜像仓库更新脚本
# 用于批量替换项目中的 Docker 镜像引用

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
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

# 显示使用说明
show_usage() {
    cat << EOF
使用方法:
  $0 <registry-type> <username/namespace>

参数说明:
  registry-type    镜像仓库类型，可选值:
                   - dockerhub    : Docker Hub
                   - ghcr         : GitHub Container Registry
                   - aliyun       : 阿里云容器镜像服务
                   - custom       : 自定义镜像仓库

  username         用户名或命名空间

示例:
  # 使用 Docker Hub
  $0 dockerhub yourname

  # 使用 GitHub Container Registry
  $0 ghcr yourname

  # 使用阿里云（需要提供完整地址）
  $0 aliyun registry.cn-hangzhou.aliyuncs.com/yournamespace

  # 使用自定义仓库
  $0 custom your-registry.com/namespace

EOF
}

# 检查参数
if [ $# -lt 2 ]; then
    print_error "参数不足"
    show_usage
    exit 1
fi

REGISTRY_TYPE=$1
USERNAME=$2

# 确定新的镜像前缀
case $REGISTRY_TYPE in
    dockerhub)
        NEW_IMAGE="${USERNAME}/flowgate"
        print_info "使用 Docker Hub: ${NEW_IMAGE}"
        ;;
    ghcr)
        NEW_IMAGE="ghcr.io/${USERNAME}/flowgate"
        print_info "使用 GitHub Container Registry: ${NEW_IMAGE}"
        ;;
    aliyun)
        NEW_IMAGE="${USERNAME}/flowgate"
        print_info "使用阿里云容器镜像服务: ${NEW_IMAGE}"
        ;;
    custom)
        NEW_IMAGE="${USERNAME}/flowgate"
        print_info "使用自定义镜像仓库: ${NEW_IMAGE}"
        ;;
    *)
        print_error "不支持的镜像仓库类型: $REGISTRY_TYPE"
        show_usage
        exit 1
        ;;
esac

# 确认操作
print_warning "即将替换以下文件中的镜像引用:"
echo "  - docker-compose.yml"
echo "  - docker-compose.dev.yml"
echo "  - .github/workflows/*.yml"
echo "  - README*.md"
echo ""
print_warning "原镜像: calciumion/flowgate"
print_warning "新镜像: ${NEW_IMAGE}"
echo ""
read -p "确认继续? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "操作已取消"
    exit 0
fi

# 获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

print_info "开始替换镜像引用..."

# 备份重要文件
BACKUP_DIR=".backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
print_info "创建备份目录: $BACKUP_DIR"

cp docker-compose.yml "$BACKUP_DIR/" 2>/dev/null || true
cp docker-compose.dev.yml "$BACKUP_DIR/" 2>/dev/null || true
cp -r .github/workflows "$BACKUP_DIR/" 2>/dev/null || true

# 替换 docker-compose.yml
print_info "更新 docker-compose.yml..."
if [ -f "docker-compose.yml" ]; then
    sed -i.bak "s|calciumion/flowgate|${NEW_IMAGE}|g" docker-compose.yml
    # 如果使用本地构建，改为远程镜像
    if grep -q "build:" docker-compose.yml; then
        print_warning "检测到本地构建配置，建议手动检查 docker-compose.yml"
    fi
    rm -f docker-compose.yml.bak
fi

# 替换 docker-compose.dev.yml
print_info "更新 docker-compose.dev.yml..."
if [ -f "docker-compose.dev.yml" ]; then
    sed -i.bak "s|calciumion/flowgate|${NEW_IMAGE}|g" docker-compose.dev.yml
    rm -f docker-compose.dev.yml.bak
fi

# 替换 GitHub Actions 工作流
print_info "更新 GitHub Actions 工作流..."
find .github/workflows -name "*.yml" -type f | while read -r file; do
    print_info "  处理: $file"
    sed -i.bak "s|calciumion/flowgate|${NEW_IMAGE}|g" "$file"
    sed -i.bak "s|CalciumIon/flowgate|${NEW_IMAGE}|g" "$file"
    rm -f "${file}.bak"
done

# 替换 README 文件
print_info "更新 README 文件..."
find . -maxdepth 1 -name "README*.md" -type f | while read -r file; do
    print_info "  处理: $file"
    sed -i.bak "s|calciumion/flowgate|${NEW_IMAGE}|g" "$file"
    sed -i.bak "s|CalciumIon/flowgate|${NEW_IMAGE}|g" "$file"
    # 更新 Docker Hub 链接
    if [ "$REGISTRY_TYPE" = "dockerhub" ]; then
        sed -i.bak "s|hub.docker.com/r/CalciumIon/flowgate|hub.docker.com/r/${USERNAME}/flowgate|g" "$file"
    fi
    rm -f "${file}.bak"
done

print_success "镜像引用替换完成！"
echo ""
print_info "备份文件保存在: $BACKUP_DIR"
print_info "新镜像地址: ${NEW_IMAGE}"
echo ""
print_warning "下一步操作:"
echo "  1. 检查 docker-compose.yml 确保配置正确"
echo "  2. 如果使用 GitHub Actions，配置相应的 Secrets"
echo "  3. 推送代码到 GitHub 触发自动构建"
echo ""
print_info "详细说明请参考: DOCKER_REGISTRY.md"
