# FlowGate 独立部署指南

本指南帮助你完全独立运营和分发 FlowGate 项目。

---

## 📋 当前状态

✅ **已完成的配置**:
- ✅ 项目名称已从 `new-api` 更改为 `flowgate`
- ✅ Go 模块路径已更新为 `github.com/QuantumNous/flowgate`
- ✅ Docker Compose 已配置为**本地构建模式**
- ✅ 所有配置文件已更新
- ✅ 前端包名已更新

⚠️ **待配置项**:
- ⚠️ Docker 镜像仓库（当前使用本地构建）
- ⚠️ 生产环境密码（使用示例密码）
- ⚠️ 域名和 SSL 证书（如需要）

---

## 🚀 快速开始

### 方式 1: 本地构建部署（推荐新手）

当前配置已支持本地构建，无需镜像仓库：

```bash
# 1. 进入项目目录
cd /Users/leon/work/flowGate/flowgate

# 2. 修改生产环境密码（重要！）
# 编辑 docker-compose.yml，修改以下密码:
# - POSTGRES_PASSWORD
# - REDIS 密码
# - SQL_DSN 中的密码

# 3. 构建并启动
docker compose up -d --build

# 4. 查看日志
docker compose logs -f flowgate

# 5. 访问应用
# 打开浏览器访问: http://localhost:3000
```

### 方式 2: 使用镜像仓库部署（推荐生产环境）

如果你要发布 Docker 镜像供他人使用：

#### 步骤 1: 选择镜像仓库

**推荐使用 GitHub Container Registry (免费)**

```bash
# 使用提供的脚本快速配置
./scripts/update-docker-registry.sh ghcr 你的GitHub用户名

# 例如:
./scripts/update-docker-registry.sh ghcr leon
```

其他选项:
- Docker Hub: `./scripts/update-docker-registry.sh dockerhub 你的用户名`
- 阿里云: `./scripts/update-docker-registry.sh aliyun registry.cn-hangzhou.aliyuncs.com/你的命名空间`

#### 步骤 2: 配置 GitHub Actions

1. 进入你的 GitHub 仓库
2. Settings → Actions → General
3. 启用 "Read and write permissions"
4. 推送代码触发自动构建

#### 步骤 3: 发布镜像

```bash
# 提交更改
git add .
git commit -m "Configure Docker registry"
git push

# 创建版本标签触发发布
git tag v1.0.0
git push origin v1.0.0
```

---

## 🔒 生产环境安全配置

### 1. 修改默认密码

**必须修改** `docker-compose.yml` 中的以下密码：

```yaml
# PostgreSQL 密码
POSTGRES_PASSWORD: 你的强密码

# Redis 密码
command: ["redis-server", "--requirepass", "你的强密码"]

# 数据库连接字符串
SQL_DSN=postgresql://root:你的强密码@postgres:5432/flowgate

# Redis 连接字符串
REDIS_CONN_STRING=redis://:你的强密码@redis:6379
```

### 2. 配置 SESSION_SECRET

在 `docker-compose.yml` 的环境变量中添加：

```yaml
environment:
  - SESSION_SECRET=你的随机字符串（至少32位）
```

生成随机字符串：
```bash
openssl rand -base64 32
```

### 3. 配置 HTTPS（生产环境必需）

使用 Nginx 反向代理：

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 📦 构建和发布流程

### 本地构建

```bash
# 构建 Docker 镜像
docker build -t flowgate:latest .

# 多架构构建（需要 buildx）
docker buildx build --platform linux/amd64,linux/arm64 -t flowgate:latest .
```

### 推送到镜像仓库

```bash
# 登录到镜像仓库
docker login ghcr.io  # GitHub Container Registry
# 或
docker login  # Docker Hub

# 标记镜像
docker tag flowgate:latest ghcr.io/你的用户名/flowgate:latest

# 推送镜像
docker push ghcr.io/你的用户名/flowgate:latest
```

### 自动化发布（GitHub Actions）

项目已配置 GitHub Actions，自动构建和发布：

- **正式版本**: 推送 tag（如 `v1.0.0`）触发
- **Alpha 版本**: 推送 tag（如 `v1.0.0-alpha.1`）触发
- **Nightly 版本**: 每天自动构建

---

## 🔧 环境变量配置

### 核心配置

| 变量名 | 说明 | 默认值 | 必需 |
|--------|------|--------|------|
| `PORT` | 服务端口 | `3000` | ❌ |
| `SQL_DSN` | 数据库连接 | - | ✅ |
| `REDIS_CONN_STRING` | Redis 连接 | - | ✅ |
| `SESSION_SECRET` | 会话密钥 | 随机生成 | ✅ 生产环境 |
| `TZ` | 时区 | `Asia/Shanghai` | ❌ |

### 安全配置

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `ENABLE_PPROF` | 性能分析（生产禁用） | `false` |
| `DEBUG` | 调试模式（生产禁用） | `false` |
| `TLS_INSECURE_SKIP_VERIFY` | 跳过 TLS 验证 | `false` |

### 功能配置

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `BATCH_UPDATE_ENABLED` | 批量更新 | `true` |
| `MEMORY_CACHE_ENABLED` | 内存缓存 | `true` |
| `RELAY_TIMEOUT` | 请求超时（秒） | `0`（无限制） |
| `STREAMING_TIMEOUT` | 流式超时（秒） | `120` |

完整配置请参考: `.env.example`

---

## 📊 监控和维护

### 查看日志

```bash
# 查看所有服务日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f flowgate

# 查看最近 100 行日志
docker compose logs --tail=100 flowgate
```

### 备份数据

```bash
# 备份 PostgreSQL 数据库
docker compose exec postgres pg_dump -U root flowgate > backup_$(date +%Y%m%d).sql

# 备份数据目录
tar -czf data_backup_$(date +%Y%m%d).tar.gz ./data
```

### 更新应用

```bash
# 拉取最新代码
git pull

# 重新构建并启动
docker compose up -d --build

# 或者拉取最新镜像（如果使用远程镜像）
docker compose pull
docker compose up -d
```

---

## 🐛 故障排查

### 服务无法启动

```bash
# 检查服务状态
docker compose ps

# 查看详细日志
docker compose logs flowgate

# 检查端口占用
lsof -i :3000
```

### 数据库连接失败

```bash
# 检查数据库是否运行
docker compose ps postgres

# 测试数据库连接
docker compose exec postgres psql -U root -d flowgate

# 检查密码是否正确
# 确保 SQL_DSN 中的密码与 POSTGRES_PASSWORD 一致
```

### 内存不足

```bash
# 限制容器内存使用
# 在 docker-compose.yml 中添加:
services:
  flowgate:
    deploy:
      resources:
        limits:
          memory: 2G
```

---

## 📚 相关文档

- **Docker 镜像配置**: `DOCKER_REGISTRY.md`
- **环境变量示例**: `.env.example`
- **项目约定**: `AGENTS.md`
- **更新脚本**: `scripts/update-docker-registry.sh`

---

## 🆘 获取帮助

### 常见问题

1. **如何修改端口？**
   - 编辑 `docker-compose.yml`，修改 `ports: - "3000:3000"` 为 `"你的端口:3000"`

2. **如何使用 MySQL 而不是 PostgreSQL？**
   - 参考 `docker-compose.yml` 中的注释，取消注释 MySQL 相关配置

3. **如何配置多节点部署？**
   - 设置 `SESSION_SECRET` 环境变量（所有节点使用相同值）
   - 配置 `NODE_NAME` 区分不同节点

### 社区支持

- GitHub Issues: https://github.com/QuantumNous/flowgate/issues
- 官方文档: https://docs.newapi.pro

---

## ✅ 部署检查清单

部署前请确认：

- [ ] 已修改所有默认密码
- [ ] 已配置 SESSION_SECRET
- [ ] 已配置 HTTPS（生产环境）
- [ ] 已配置数据备份策略
- [ ] 已禁用调试功能（ENABLE_PPROF, DEBUG）
- [ ] 已配置防火墙规则
- [ ] 已测试应用功能
- [ ] 已配置监控和日志

---

**最后更新**: 2026-04-29
**版本**: 1.0.0
