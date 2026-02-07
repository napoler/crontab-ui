# Docker 容器管理宿主机 Cron 完整指南

本指南介绍如何配置 cronitor 仪表盘，使其可以通过 Docker 容器直接编辑和管理宿主机的 cron 任务。

## 快速开始

### 1. 修改 docker-compose.yml

确保挂载所有必要的 cron 目录：

```yaml
services:
  crontab-guru:
    image: napoler/crontab-guru-dashboard:latest
    build:
      context: .
      args:
        DASHBOARD_USERNAME: ${CRONITOR_USERNAME}
        DASHBOARD_PASSWORD: ${CRONITOR_PASSWORD}
    container_name: crontab-guru-dashboard
    ports:
      - "9000:9000"
    volumes:
      # 关键挂载：允许容器写入宿主机 cron 目录
      - /etc/cron.d:/etc/cron.d
      - /var/spool/cron:/var/spool/cron
      - /etc/crontab:/etc/crontab
      # Docker socket 挂载（用于在 cron 作业中执行 docker 命令）
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
```

### 2. 重建容器（重要！）

修改 `docker-compose.yml` 后必须重建容器才能应用新挂载：

```bash
# 停止并删除旧容器
docker compose down

# 重建并启动容器
docker compose up -d --build

# 等待容器启动
sleep 3
```

### 3. 验证挂载是否生效

```bash
# 方法 1: 检查容器挂载点
docker inspect crontab-guru-dashboard | grep -A 20 "Mounts"

# 方法 2: 进入容器查看挂载目录
docker exec -it crontab-guru-dashboard ls -la /etc/cron.d
docker exec -it crontab-guru-dashboard ls -la /var/spool/cron
docker exec -it crontab-guru-dashboard ls -la /etc/crontab

# 方法 3: 在容器内写入测试文件
docker exec -it crontab-guru-dashboard sh -c "echo 'test' > /etc/cron.d/test-file"

# 在宿主机验证（能看到 test-file 说明挂载成功）
cat /etc/cron.d/test-file
```

### 4. 访问仪表盘

```bash
# 浏览器访问
http://localhost:9000

# 或通过 SSH 隧道（更安全）
ssh -L 9000:localhost:9000 user@your-server
# 然后访问 http://localhost:9000
```

## 架构说明

```
┌─────────────────────────────────────────────────────┐
│  宿主机 (Host Machine)                              │
│  ├─ /etc/cron.d         (系统 cron 配置)           │
│  ├─ /var/spool/cron     (用户 crontab)            │
│  ├─ /etc/crontab        (主 crontab)              │
│  └─ cron 服务           (执行实际任务)             │
└─────────────────────────────────────────────────────┘
                      ▲ 挂载（读写）
                      │
┌─────────────────────────────────────────────────────┐
│  Docker 容器                                         │
│  ├─ /etc/cron.d       → 宿主机 /etc/cron.d        │
│  ├─ /var/spool/cron   → 宿主机 /var/spool/cron    │
│  ├─ /etc/crontab      → 宿主机 /etc/crontab       │
│  ├─ cronitor dash     (Web 仪表盘)                │
│  └─ cronitor CLI      (命令行工具)                │
└─────────────────────────────────────────────────────┘
```

## 工作原理

1. **仪表盘编辑**：在 Web 界面 (http://localhost:9000) 创建/编辑 cron 任务
2. **保存到容器**：任务保存在容器内的配置文件
3. **写入宿主机**：通过挂载的目录，直接写入宿主机的 `/etc/cron.d` 或 `/var/spool/cron`
4. **执行任务**：宿主机的 cron 守护进程读取并执行任务

## Cron 目录说明

| 目录 | 用途 | 适用场景 |
|------|------|---------|
| `/etc/cron.d/` | 系统 cron 任务配置文件 | 系统级定时任务，推荐使用 |
| `/var/spool/cron/` | 用户 crontab 文件 | 用户级定时任务 |
| `/etc/crontab` | 主 crontab 配置 | 全局 cron 配置 |

**推荐使用**：`/etc/cron.d/` 目录，每个任务一个单独文件，便于管理。

## 使用示例

### 在仪表盘中创建任务

访问 http://localhost:9000，创建示例任务：

```cron
# 每天凌晨 2 点拉取代码
0 2 * * * cd /home/opencode/workspace/crontab-ui && git pull origin main >> /tmp/git-pull.log 2>&1

# 每 6 小时执行备份脚本
0 */6 * * * /home/opencode/workspace/crontab-ui/scripts/backup.sh >> /tmp/backup.log 2>&1

# 工作日早上 8:30 使用 OpenCode AI 获取最新代码
30 8 * * 1-5 cd /home/opencode/workspace/crontab-ui && /usr/local/bin/opencode run -m opencode/glm-4.7-free "切换到 main 分支并获取最新代码" >> /tmp/opencode.log 2>&1
```

### 验证任务已同步到宿主机

```bash
# 查看宿主机的 /etc/cron.d
ls -la /etc/cron.d/

# 查看某个任务文件
cat /etc/cron.d/task-name

# 查看当前用户的 crontab
crontab -l

# 查看 cron 服务日志
tail -f /var/log/syslog | grep CRON
```

### 与 Docker 容器交互

由于挂载了 Docker socket，可以在 cron 作业中执行 `docker exec`：

```cron
# 示例：备份另一个容器中的应用数据
0 2 * * * docker exec my-app-container /app/backup.sh >> /tmp/backup.log 2>&1

# 示例：重启容器
0 3 * * 0 docker restart my-app-container >> /tmp/restart.log 2>&1

# 示例：执行容器内脚本
*/30 * * * * docker exec crontab-guru-dashboard /scripts/health-check.sh
```

## 配置 Cronitor CLI（可选）

如果需要通过命令行配置 cronitor：

```bash
# 进入容器
docker exec -it crontab-guru-dashboard sh

# 查看帮助
cronitor help
cronitor configure --help

# 查看当前配置
cronitor configure --show
```

## 常见问题排查

### 问题 1：任务未执行

**症状**：在仪表盘创建了任务，但宿主机没有执行

**排查步骤**：

```bash
# 1. 检查挂载是否生效
docker inspect crontab-guru-dashboard | grep -A 20 Mounts

# 2. 手动在容器内创建测试文件
docker exec -it crontab-guru-dashboard sh -c "echo 'TEST * * * * * date' > /etc/cron.d/test"

# 3. 在宿主机查看文件是否存在
cat /etc/cron.d/test

# 4. 检查 cron 服务状态
systemctl status cron

# 5. 查看日志
tail -f /var/log/syslog | grep CRON
```

**可能原因**：
- 挂载未生效（忘记重建容器）
- cron 服务未运行
- 文件权限问题
- cron 语法错误

### 问题 2：修改 docker-compose.yml 后无变化

**原因**：修改配置后必须重建容器

**解决方法**：

```bash
docker compose down
docker compose up -d --build
```

### 问题 3：权限问题

**症状**：容器内无法写入宿主机目录

**排查**：

```bash
# 检查宿主机目录权限
ls -la /etc/cron.d /var/spool/cron /etc/crontab

# 如果不存在目录，需要先创建
sudo mkdir -p /etc/cron.d
sudo mkdir -p /var/spool/cron
sudo touch /etc/crontab

# 设置权限
sudo chmod 755 /etc/cron.d
sudo chmod 700 /var/spool/cron
sudo chmod 644 /etc/crontab
```

### 问题 4：任务文件不生效

**原因**：cron 任务的文件必须符合命名规范

**解决方法**：

```bash
# /etc/cron.d/ 中的文件必须：
# 1. 不包含点号（.）和波浪号（~）
# 2. 是有效的 cron 语法
# 3. 有所有者执行权限

# 正确的文件名
/etc/cron.d/git-pull
/etc/cron.d/daily-backup

# 错误的文件名（不会被执行）
/etc/cron.d/git-pull.sh
/etc/cron.d/.backup
/etc/cron.d/backup~

# 检查语法
crontab -l /etc/cron.d/git-pull
```

## 安全建议

1. **不要暴露到公共互联网**：仪表盘包含敏感的定时任务信息
2. **使用 IP 白名单**：限制访问来源
3. **使用 SSH 隧道**：推荐的安全访问方式
4. **定期审计**：检查 cron 任务是否有异常
5. **限制超时时间**：防止任务无限运行消耗资源

```bash
# 配置 IP 白名单
docker exec -it crontab-guru-dashboard cronitor configure --allow-ips 192.168.1.0/24,10.0.0.1
```

## 高级技巧：任务超时控制

在仪表盘管理的 cron 任务中使用超时控制，防止长时间运行的任务阻塞系统资源。

### 基本语法

```bash
timeout [选项] 持续时间 命令
```

**时间单位**：
- `s` - 秒
- `m` - 分钟
- `h` - 小时
- `d` - 天

### 在仪表盘中使用超时示例

```cron
# Git 拉取（最多 10 分钟）
0 2 * * * timeout 10m sh -c 'cd /home/myproject && git pull origin main' >> /tmp/git.log 2>&1

# 备份脚本（最多 1 小时）
0 3 * * * timeout 1h /home/backup/scripts/daily-backup.sh >> /tmp/backup.log 2>&1

# Docker 容器任务（最多 30 分钟）
0 4 * * * timeout 30m docker exec my-app-container /app/process.sh >> /tmp/process.log 2>&1

# OpenCode AI 任务（最多 30 分钟）
0 9 * * * timeout 30m sh -c 'cd /home/opencode/workspace/crontab-ui && /usr/local/bin/opencode run -m opencode/glm-4.7-free "获取最新代码"' >> /tmp/opencode.log 2>&1
```

### 正确使用方式对比

```cron
# ✅ 正确：使用 sh -c 包裹所有命令
0 9 * * * timeout 30m sh -c 'cd /home/opencode/workspace/crontab-ui && /usr/local/bin/opencode run -m opencode/glm-4.7-free "获取最新代码"' >> /tmp/opencode.log 2>&1

# ✅ 正确：使用子 shell
0 9 * * * timeout 30m (cd /home/opencode/workspace/crontab-ui && /usr/local/bin/opencode run -m opencode/glm-4.7-free "获取最新代码") >> /tmp/opencode.log 2>&1

# ❌ 错误：timeout 只对 cd 生效
0 9 * * * timeout 30m cd /home/opencode/workspace/crontab-ui && /usr/local/bin/opencode run -m opencode/glm-4.7-free "获取最新代码"
```

### 高级选项示例

```cron
# 超时后发送 TERM 信号，10 秒后发送 KILL 信号
0 2 * * * timeout -k 10s 1h /path/to/script.sh >> /tmp/task.log 2>&1

# 使用特定信号
0 3 * * * timeout -s SIGQUIT 15m /path/to/script.sh >> /tmp/task.log 2>&1
```

### 监控超时任务

```bash
# 查看超时的 cron 任务（退出码 124）
grep "exit status 124" /var/log/syslog | grep CRON

# 创建超时日志记录
timeout 300 /path/to/script.sh 2>> /var/log/timeout.log

# 监控超时日志
tail -f /var/log/timeout.log
```

## 参考资源

- [Cronitor CLI 文档](https://crontab.guru/dashboard.html)
- [Crontab 表达式编辑器](https://crontab.guru)
- [Crontor CLI GitHub](https://github.com/cronitorio/cronitor-cli)
- [Cron 教程](https://crontab.guru/tutorial.html)
