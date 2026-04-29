# FlowGate 云服务器部署指南

本指南帮助你将 FlowGate 部署到云服务器（VPS/云主机）。

---

## 📋 服务器要求

### 最低配置
- **CPU**: 2 核
- **内存**: 2GB RAM
- **存储**: 20GB 硬盘空间
- **系统**: Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- **网络**: 公网 IP，开放 3000 端口（或自定义端口）

### 推荐配置
- **CPU**: 4 核
- **内存**: 4GB RAM
- **存储**: 50GB SSD
- **带宽**: 5Mbps+

---

## 🚀 快速部署（推荐）

### 步骤 1: 上传文件到服务器

在**本地**执行（将文件上传到服务器）：

```bash
# 方式 1: 使用 scp
scp docker-compose.prod.yml deploy.sh root@YOUR_SERVER_IP:/root/flowgate/

# 方式 2: 使用 rsync
rsync -avz docker-compose.prod.yml deploy.sh root@YOUR_SERVER_IP:/root/flowgate/
```

或者在**服务器上**直接下载：

```bash
# 登录服务器
ssh root@YOUR_SERVER_IP

# 创建目录
mkdir -p /root/flowgate
cd /root/flowgate

# 下载文件（如果你的文件在 GitHub 上）
wget https://raw.githubusercontent.com/dinnelthai/flowgate/main/docker-compose.prod.yml
wget https://raw.githubusercontent.com/dinnelthai/flowgate/main/deploy.sh
chmod +x deploy.sh
```

### 步骤 2: 运行一键部署脚本

```bash
cd /root/flowgate
bash deploy.sh
```

脚本会自动：
1. ✅ 检查系统环境
2. ✅ 检查 Docker 安装
3. ✅ 生成安全密码
4. ✅ 配置环境变量
5. ✅ 拉取 Docker 镜像
6. ✅ 启动所有服务
7. ✅ 显示访问信息

---

## 🔧 手动部署

如果自动脚本失败，可以手动部署：

### 1. 安装 Docker（如果未安装）

**Ubuntu/Debian:**
```bash
# 更新包索引
sudo apt-get update

# 安装依赖
sudo apt-get install -y ca-certificates curl gnupg

# 添加 Docker 官方 GPG 密钥
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 添加 Docker 仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker
```

**CentOS/RHEL:**
```bash
# 安装依赖
sudo yum install -y yum-utils

# 添加 Docker 仓库
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 安装 Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker
```

### 2. 修改配置文件

编辑 `docker-compose.prod.yml`，修改所有 `CHANGE_THIS_PASSWORD` 和 `CHANGE_THIS_TO_RANDOM_STRING`：

```bash
# 生成随机密码
openssl rand -base64 32

# 编辑配置文件
nano docker-compose.prod.yml
```

需要修改的位置：
- PostgreSQL 密码（2处）
- Redis 密码（2处）
- SESSION_SECRET（1处）

### 3. 拉取镜像并启动

```bash
# 拉取镜像
docker compose -f docker-compose.prod.yml pull

# 启动服务
docker compose -f docker-compose.prod.yml up -d

# 查看日志
docker compose -f docker-compose.prod.yml logs -f
```

---

## 🔒 安全配置

### 1. 配置防火墙

**UFW (Ubuntu):**
```bash
# 允许 SSH
sudo ufw allow 22/tcp

# 允许 FlowGate
sudo ufw allow 3000/tcp

# 启用防火墙
sudo ufw enable
```

**Firewalld (CentOS):**
```bash
# 允许端口
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

### 2. 配置 HTTPS（推荐）

使用 Nginx 作为反向代理：

```bash
# 安装 Nginx
sudo apt-get install -y nginx certbot python3-certbot-nginx

# 创建 Nginx 配置
sudo nano /etc/nginx/sites-available/flowgate
```

配置内容：
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket 支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

启用配置并获取 SSL 证书：
```bash
# 启用站点
sudo ln -s /etc/nginx/sites-available/flowgate /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx

# 获取 SSL 证书
sudo certbot --nginx -d your-domain.com
```

---

## 📊 服务管理

### 常用命令

```bash
# 查看服务状态
docker compose -f docker-compose.prod.yml ps

# 查看日志
docker compose -f docker-compose.prod.yml logs -f flowgate

# 停止服务
docker compose -f docker-compose.prod.yml stop

# 启动服务
docker compose -f docker-compose.prod.yml start

# 重启服务
docker compose -f docker-compose.prod.yml restart

# 停止并删除容器
docker compose -f docker-compose.prod.yml down

# 更新镜像
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

### 数据备份

```bash
# 备份数据库
docker compose -f docker-compose.prod.yml exec postgres \
  pg_dump -U flowgate flowgate > backup_$(date +%Y%m%d).sql

# 备份数据目录
tar -czf data_backup_$(date +%Y%m%d).tar.gz ./data

# 备份配置
cp docker-compose.prod.yml docker-compose.prod.yml.bak
cp .env.prod .env.prod.bak
```

---

## 🐛 故障排查

### 服务无法启动

```bash
# 查看详细日志
docker compose -f docker-compose.prod.yml logs

# 检查端口占用
sudo netstat -tlnp | grep 3000

# 检查 Docker 状态
sudo systemctl status docker
```

### 数据库连接失败

```bash
# 进入数据库容器
docker compose -f docker-compose.prod.yml exec postgres bash

# 测试连接
psql -U flowgate -d flowgate

# 检查密码是否正确
grep POSTGRES_PASSWORD docker-compose.prod.yml
```

### 内存不足

编辑 `docker-compose.prod.yml`，调整资源限制：

```yaml
deploy:
  resources:
    limits:
      memory: 512M  # 根据实际情况调整
```

---

## 🔄 更新 FlowGate

```bash
# 1. 拉取最新镜像
docker compose -f docker-compose.prod.yml pull

# 2. 重启服务
docker compose -f docker-compose.prod.yml up -d

# 3. 查看日志确认
docker compose -f docker-compose.prod.yml logs -f flowgate
```

---

## 📞 获取帮助

- **GitHub Issues**: https://github.com/dinnelthai/flowgate/issues
- **官方文档**: https://docs.newapi.pro
- **部署指南**: `DEPLOYMENT_GUIDE.md`

---

## ✅ 部署检查清单

- [ ] 服务器满足最低配置要求
- [ ] Docker 和 Docker Compose 已安装
- [ ] 已修改所有默认密码
- [ ] 防火墙已配置（开放 3000 端口）
- [ ] 服务已成功启动
- [ ] 可以通过浏览器访问
- [ ] 已修改默认管理员密码
- [ ] 已配置 HTTPS（生产环境推荐）
- [ ] 已设置数据备份计划

---

**部署完成后，访问 `http://YOUR_SERVER_IP:3000` 开始使用！**

默认管理员账号：
- 用户名: `root`
- 密码: `123456`

**⚠️ 首次登录后请立即修改密码！**
