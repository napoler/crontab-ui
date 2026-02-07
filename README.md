# Crontab Guru Dashboard

免费、自托管、开源的 Cron 作业管理仪表盘。基于 [Cronitor CLI](https://crontab.guru/dashboard.html)。

## 功能特性

- ✅ 创建和管理 cron 作业
- ✅ 一键立即运行任务
- ✅ 内置控制台测试和调整作业
- ✅ Crontab.Guru 表达式编辑器
- ✅ 查看并终止正在运行的作业实例
- ✅ MCP 支持连接编码助理
- ✅ 需要时可启用 Cron 监控

## 快速开始

### Docker Compose 部署（推荐）

```bash
# 1. 复制环境变量模板
cp .env.example .env

# 2. 编辑 .env 文件，设置用户名和密码
vim .env
# 修改以下内容：
# CRONITOR_USERNAME=<your_username>
# CRONITOR_PASSWORD=<your_password>

# 3. 构建镜像（会自动从 .env 文件读取凭证）
docker compose build

# 4. 启动服务
docker compose up -d

# 5. 访问仪表盘
# 浏览器访问 http://<server-ip>:9000
```

**如果不使用 .env 文件，可以直接在命令行指定**：

```bash
# 构建镜像（命令行指定凭证）
docker compose build --build-arg DASHBOARD_USERNAME=<your_username> --build-arg DASHBOARD_PASSWORD=<your_password>

# 启动服务
docker compose up -d
```

**示例**：
```bash
docker compose build --build-arg DASHBOARD_USERNAME=admin --build-arg DASHBOARD_PASSWORD=mypassword
docker compose up -d
```

**安全警告**：不要将仪表盘直接暴露在公共互联网！

推荐访问方式：

1. **SSH 隧道**（最安全）:
   ```bash
   ssh -L 9000:localhost:9000 user@your-server
   ```
   然后访问 http://localhost:9000

2. **IP 白名单**:
   ```bash
   cronitor configure --allow-ips 192.168.1.0/24,10.0.0.1
   ```

### Docker 命令行部署

```bash
# 1. 构建镜像（指定用户名和密码）
docker build \
  --build-arg DASHBOARD_USERNAME=<YOUR_USERNAME> \
  --build-arg DASHBOARD_PASSWORD=<YOUR_PASSWORD> \
  -t napoler/crontab-guru-dashboard:latest \
  .

# 2. 运行容器
docker run -d \
  --name crontab-guru \
  --restart unless-stopped \
  -p 9000:9000 \
  -v /etc/cron.d:/etc/cron.d \
  -v /var/spool/cron:/var/spool/cron \
  -v /var/run/docker.sock:/var/run/docker.sock \
  napoler/crontab-guru-dashboard:latest
```

### 直接安装（无需 Docker）

```bash
curl https://crontab.guru/install | sh
```

安装后，系统会提示设置用户名和密码。

### Systemd 服务（生产环境）

创建 `/etc/systemd/system/crontab-guru-dashboard.service`:

```ini
[Unit]
Description=Crontab Guru Dashboard
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
ExecStart=cronitor dash --port 9000
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

启动服务：

```bash
sudo systemctl enable crontab-guru-dashboard
sudo systemctl start crontab-guru-dashboard
sudo systemctl status crontab-guru-dashboard
```

## Docker 高级配置

### 管理主机系统的 cron

当前配置已挂载主机 cron 目录：
- `/etc/cron.d` - 系统 cron 配置
- `/var/spool/cron` - 用户 crontab 文件

**注意**：管理主机 cron 需要适当权限，存在安全风险。

### 与 Docker 容器交互

当前配置已挂载 Docker socket，可在 cron 作业中使用 `docker exec`:

示例 cron 作业：
```
0 2 * * * docker exec my-app-container /app/backup.sh
```

### IP 白名单

限制只允许特定 IP 访问：

```bash
# 配置白名单
cronitor configure --allow-ips 192.168.1.0/24,10.0.0.1
```

## 更新维护

### 更新 Cronitor CLI

```bash
# 更新到最新版本
cronitor update

# 重启服务（Docker）
docker compose up -d --build

# 重启服务（Systemd）
sudo systemctl restart crontab-guru-dashboard
```

## 帮助资源

- 官方文档: https://crontab.guru/dashboard.html
- Crontab 表达式编辑器: https://crontab.guru
- GitHub: https://github.com/cronitorio/cronitor-cli
