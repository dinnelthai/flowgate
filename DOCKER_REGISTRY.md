# Docker 镜像仓库配置指南

## 当前状态

项目已配置为**本地构建模式**，不依赖外部镜像仓库。

## 如何切换到远程镜像仓库

当你准备好发布 Docker 镜像时，按照以下步骤操作：

---

## 选项 1：使用 GitHub Container Registry (推荐)

### 1. 准备工作

GitHub Container Registry (ghcr.io) 是免费的，与 GitHub 无缝集成。

**镜像格式**：`ghcr.io/你的GitHub用户名/flowgate`

### 2. 替换镜像引用

假设你的 GitHub 用户名是 `yourname`，执行以下命令：

```bash
# 进入项目目录
cd /Users/leon/work/flowGate/flowgate

# 替换所有文件中的镜像引用
find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" \) \
  ! -path "./.git/*" ! -path "./node_modules/*" \
  -exec sed -i '' 's|calciumion/flowgate|ghcr.io/yourname/flowgate|g' {} +

find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" \) \
  ! -path "./.git/*" ! -path "./node_modules/*" \
  -exec sed -i '' 's|CalciumIon/flowgate|yourname/flowgate|g' {} +
```

### 3. 更新 docker-compose.yml

将 `docker-compose.yml` 中的本地构建改为远程镜像：

```yaml
services:
  flowgate:
    image: ghcr.io/yourname/flowgate:latest
    # build:  # 注释掉本地构建
    #   context: .
    #   dockerfile: Dockerfile
```

### 4. 配置 GitHub Actions

在 GitHub 仓库设置中：
1. Settings → Actions → General
2. 启用 "Read and write permissions"
3. GitHub Actions 会自动推送镜像到 ghcr.io

---

## 选项 2：使用 Docker Hub

### 1. 注册账号

访问 https://hub.docker.com/ 注册账号

### 2. 替换镜像引用

假设你的 Docker Hub 用户名是 `yourname`：

```bash
cd /Users/leon/work/flowGate/flowgate

# 替换镜像引用
find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" \) \
  ! -path "./.git/*" ! -path "./node_modules/*" \
  -exec sed -i '' 's|calciumion/flowgate|yourname/flowgate|g' {} +

find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" \) \
  ! -path "./.git/*" ! -path "./node_modules/*" \
  -exec sed -i '' 's|CalciumIon/flowgate|yourname/flowgate|g' {} +
```

### 3. 配置 GitHub Actions Secrets

在 GitHub 仓库中添加 Docker Hub 凭证：
1. Settings → Secrets and variables → Actions
2. 添加以下 secrets：
   - `DOCKERHUB_USERNAME`: 你的 Docker Hub 用户名
   - `DOCKERHUB_TOKEN`: Docker Hub Access Token

### 4. 更新 GitHub Actions 工作流

编辑 `.github/workflows/docker-build.yml`，添加 Docker Hub 登录步骤：

```yaml
- name: Login to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
```

---

## 选项 3：使用阿里云容器镜像服务

### 1. 创建命名空间

1. 登录阿里云控制台
2. 容器镜像服务 → 命名空间 → 创建命名空间
3. 创建镜像仓库 `flowgate`

### 2. 镜像格式

```
registry.cn-hangzhou.aliyuncs.com/你的命名空间/flowgate
```

### 3. 替换镜像引用

```bash
cd /Users/leon/work/flowGate/flowgate

# 替换为阿里云镜像地址
find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" \) \
  ! -path "./.git/*" ! -path "./node_modules/*" \
  -exec sed -i '' 's|calciumion/flowgate|registry.cn-hangzhou.aliyuncs.com/你的命名空间/flowgate|g' {} +
```

---

## 当前配置文件列表

需要更新镜像引用的文件：

### Docker Compose 文件
- `docker-compose.yml` - 生产环境配置
- `docker-compose.dev.yml` - 开发环境配置

### GitHub Actions 工作流
- `.github/workflows/docker-build.yml` - 正式版本构建
- `.github/workflows/docker-image-alpha.yml` - Alpha 版本构建
- `.github/workflows/docker-image-nightly.yml` - 每日构建

### 文档文件
- `README.md` - 英文文档
- `README.zh_CN.md` - 简体中文文档
- `README.zh_TW.md` - 繁体中文文档
- `README.en.md` - 英文文档（备份）
- `README.fr.md` - 法文文档
- `README.ja.md` - 日文文档

---

## 本地构建和使用

当前配置已支持本地构建，无需远程镜像仓库：

```bash
# 构建并启动
docker compose up -d --build

# 查看日志
docker compose logs -f flowgate

# 停止服务
docker compose down
```

---

## 手动构建和推送镜像

如果你想手动构建和推送镜像：

```bash
# 构建镜像
docker build -t yourname/flowgate:latest .

# 登录到镜像仓库
docker login  # Docker Hub
# 或
docker login ghcr.io  # GitHub Container Registry

# 推送镜像
docker push yourname/flowgate:latest
```

---

## 注意事项

1. **GitHub Actions 权限**：确保 GitHub Actions 有权限推送镜像
2. **镜像标签**：建议使用语义化版本标签（如 v1.0.0）
3. **多架构支持**：当前配置支持 amd64 和 arm64 架构
4. **缓存优化**：GitHub Actions 已配置缓存加速构建

---

## 快速参考

| 仓库类型 | 镜像格式 | 费用 | 推荐度 |
|---------|---------|------|--------|
| GitHub Container Registry | `ghcr.io/username/flowgate` | 免费 | ⭐⭐⭐⭐⭐ |
| Docker Hub | `username/flowgate` | 免费（1个公开仓库） | ⭐⭐⭐⭐ |
| 阿里云 ACR | `registry.cn-xxx.aliyuncs.com/ns/flowgate` | 免费额度 | ⭐⭐⭐ |
| 腾讯云 TCR | `ccr.ccs.tencentyun.com/ns/flowgate` | 免费额度 | ⭐⭐⭐ |

---

**最后更新**: 2026-04-29
