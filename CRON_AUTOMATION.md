# 使用 Cron 自动执行代码维护任务

本文档介绍如何使用 cron 定时执行代码相关的维护任务，包括自动拉取最新代码、合并分支等。

## 前提条件

```bash
# 确保已安装 opencode
which opencode

# 查看 opencode 版本
opencode --version

# 查看可用模型（如有 AI 功能需求）
opencode models
```

## 方案一：使用 Git 命令（推荐，免费且稳定）

### 1. 直接写入 crontab

```bash
# 编辑当前用户的 crontab
crontab -e
```

添加以下内容：

```bash
# 每天凌晨 2 点自动拉取代码
0 2 * * * cd /home/opencode/workspace/crontab-ui && git pull origin main >> /tmp/git-pull.log 2>&1

# 每天上午 9 点拉取并合并
0 9 * * * cd /home/opencode/workspace/crontab-ui && git fetch origin && git merge origin/main --no-edit >> /tmp/git-merge.log 2>&1
```

### 2. 创建脚本文件

创建 `/home/opencode/workspace/crontab-ui/scripts/pull-and-merge.sh`：

```bash
#!/bin/bash
set -e

REPO_DIR="/home/opencode/workspace/crontab-ui"
LOG_FILE="${REPO_DIR}/logs/auto-merge.log"

mkdir -p "${REPO_DIR}/logs"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

cd "${REPO_DIR}"

log "开始拉取代码"
git fetch origin
git merge origin/main --no-edit

log "完成"
```

赋予权限并添加到 crontab：

```bash
chmod +x /home/opencode/workspace/crontab-ui/scripts/pull-and-merge.sh

crontab -e
# 添加:
# 0 2 * * * /home/opencode/workspace/crontab-ui/scripts/pull-and-merge.sh
```

### 常用 Cron 时间表达式

| 表达式 | 说明 |
|--------|------|
| `0 2 * * *` | 每天凌晨 2 点 |
| `0 9 * * *` | 每天上午 9 点 |
| `0 */6 * * *` | 每 6 小时 |
| `30 8 * * 1-5` | 工作日早上 8:30 |
| `0 0 * * 0` | 每周日午夜 |
| `0 0 1 * *` | 每月 1 号午夜 |

### Crontab 管理命令

```bash
# 查看 crontab
crontab -l

# 编辑 crontab
crontab -e

# 删除 crontab
crontab -r
```

## 方案二：使用 OpenCode AI

### 前置条件

```bash
# 1. 查看 opencode 路径
which opencode

# 2. 启动 opencode web 服务（必须先启动）
opencode web &

# 3. 查看可用模型
opencode models
```

**重要**：`opencode run` 命令依赖 opencode web 服务在后台运行，否则会卡住。

### 正确的使用方式

```bash
# 查看命令帮助
opencode run --help

# 基本格式（无 model 参数时使用默认模型）
opencode run "拉取最新代码"

# 指定模型 - 使用 -m 简写（推荐）
opencode run -m opencode/glm-4.7-free "获取最新代码"

# 或使用完整参数
opencode run --model opencode/glm-4.7-free "获取最新代码"
```

**参数说明**：
- `-m` 或 `--model`: 指定模型，格式为 `provider/model`（空格分隔）
- 消息直接作为位置参数放在最后
- **没有** `--prompt` 选项

### 添加到 crontab

```bash
# 编辑 crontab
crontab -e

# 添加定时任务（确保使用完整路径）
cd /home/opencode/workspace/crontab-ui && /usr/local/bin/opencode run -m opencode/glm-4.7-free "获取最新代码" >> /tmp/opencode.log 2>&1
```

**示例时间设置**：

```bash
# 每天凌晨 2 点执行
0 2 * * * cd /home/opencode/workspace/crontab-ui && /usr/local/bin/opencode run -m opencode/glm-4.7-free "切换到 main 分支并获取最新代码" >> /tmp/opencode.log 2>&1

# 每天上午 9 点执行
0 9 * * * cd /home/opencode/workspace/crontab-ui && /usr/local/bin/opencode run -m opencode/glm-4.7-free "切换到 main 分支并获取最新代码" >> /tmp/opencode.log 2>&1

# 每 6 小时执行一次
0 */6 * * * cd /home/opencode/workspace/crontab-ui && /usr/local/bin/opencode run -m opencode/glm-4.7-free "切换到 main 分支并获取最新代码" >> /tmp/opencode.log 2>&1

# 切换到 dev 分支并获取代码
30 8 * * * cd /home/opencode/workspace/crontab-ui && /usr/local/bin/opencode run -m opencode/glm-4.7-free "切换到 dev 分支并获取最新代码" >> /tmp/opencode.log 2>&1
```

**要点说明**：
- `cd /home/opencode/workspace/crontab-ui` - 先切换到项目目录
- 任务描述中明确说明"切换到 X 分支并获取最新代码"
- 使用 `&&` 连接多个命令，确保逐个执行
```

### 注意事项

1. **服务依赖**：必须先启动 `opencode web &`，否则命令会卡住
2. **路径问题**：在 crontab 中使用绝对路径（`/usr/local/bin/opencode`）
3. **模型可用性**：使用前需运行 `opencode models` 确认可用模型
4. **免费模型**：`opencode/glm-4.7-free` 是免费模型，其他大模型可能需要付费
5. **错误处理**：如遇到 "No payment method" 错误，需访问 https://opencode.ai 添加支付方式，或使用免费模型

## 常见错误与解决方案

### Error: ProviderModelNotFoundError

```bash
# 错误信息示例
ProviderModelNotFoundError: ProviderModelNotFoundError
  providerID: "z-ai",
  modelID: "glm4.7",
  suggestions: [],
```

**解决方法**：
```bash
# 先查看可用模型
opencode models

# 使用正确的模型名称（格式：provider/model）
opencode run -m 正确的模型名 "任务描述"
```

### Error: No payment method

**解决方法**：访问 https://opencode.ai/workspace/.../billing 添加支付方式

或使用免费模型：
```bash
opencode run -m opencode/glm-4.7-free "任务描述"
```

### 命令卡住无响应

**症状**：执行 `opencode run` 后命令无输出，长时间卡住

**原因**：opencode web 服务未启动

**解决方法**：
```bash
# 方案 1：启动 web 服务后再执行
opencode web &
sleep 3  # 等待服务启动
opencode run -m opencode/glm-4.7-free "获取最新代码"

# 方案 2：使用启动脚本（推荐用于 crontab）
# 创建 /usr/local/bin/opencode-with-web.sh：
#!/bin/bash
pgrep -f "opencode web" > /dev/null || opencode web &
sleep 2
/usr/local/bin/opencode run "$@"
```

### 参数格式错误

**错误示例**：
```bash
# 错误：使用了不存在的 --prompt 选项
opencode run --prompt="获取最新代码" --model=opencode/glm-4.7-free

# 错误：--model 使用等号连接
opencode run --model=opencode/glm-4.7-free "获取最新代码"
```

**正确方式**：
```bash
# 正确：-m 或 --model 后用空格分隔
opencode run -m opencode/glm-4.7-free "获取最新代码"
opencode run --model opencode/glm-4.7-free "获取最新代码"
```

### Cron 任务未执行

```bash
# 检查 cron 服务状态
systemctl status cron

# 查看 cron 日志
tail -f /var/log/syslog | grep CRON

# 验证脚本权限
ls -l /path/to/script.sh
# 需要 x 权限
chmod +x /path/to/script.sh

# 手动测试脚本
bash /path/to/script.sh

# 验证 web 服务是否在运行
ps aux | grep "opencode web"
```

## 完整示例：每日自动合并与备份

创建 `/home/opencode/workspace/crontab-ui/scripts/daily-maintenance.sh`：

```bash
#!/bin/bash
set -e

REPO_DIR="/home/opencode/workspace/crontab-ui"
LOG_DIR="${REPO_DIR}/logs"
BACKUP_DIR="${REPO_DIR}/backups"

mkdir -p "${LOG_DIR}"
mkdir -p "${BACKUP_DIR}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_DIR}/maintenance.log"
}

cd "${REPO_DIR}"

log "开始维护任务"

# 1. 拉取最新代码
log "拉取代码"
git fetch origin
git merge origin/main --no-edit

# 2. 创建备份
log "创建备份"
DATE=$(date '+%Y%m%d')
tar -czf "${BACKUP_DIR}/backup_${DATE}.tar.gz" --exclude='.git' --exclude='node_modules' .

# 3. 清理 7 天前的备份
find "${BACKUP_DIR}" -name "backup_*.tar.gz" -mtime +7 -delete

log "维护完成"
```

添加到 crontab：

```bash
crontab -e
# 添加:
# 0 2 * * * /home/opencode/workspace/crontab-ui/scripts/daily-maintenance.sh
```

## 调试技巧

### 测试 cron 任务

```bash
# 模拟 cron 环境
* * * * * /path/to/script >> /tmp/debug.log 2>&1
# 每分钟执行一次，查看日志输出后立即禁用
```

### 查看执行环境

```bash
# 在脚本中添加调试信息
echo "PATH: $PATH"
echo "SHELL: $SHELL"
echo "USER: $USER"
echo "HOME: $HOME"
```

### 使用绝对路径

```bash
# 在 crontab 中始终使用绝对路径
/usr/bin/git pull origin main
/usr/local/bin/opencode run "任务"
```

## 进阶技巧

### 任务超时控制

Cron 本身不支持超时，但可以通过 `timeout` 命令实现。

#### 基本语法

```bash
timeout [选项] 持续时间 命令
```

**时间单位**：
- `s` - 秒
- `m` - 分钟
- `h` - 小时
- `d` - 天

#### 正确使用方式

**✅ 使用 sh -c 包裹所有命令**：
```bash
# 对整个命令块设置超时
0 9 * * * timeout 30m sh -c 'cd /home/opencode/workspace/crontab-ui && /usr/local/bin/opencode run -m opencode/glm-4.7-free "获取最新代码"' >> /tmp/opencode.log 2>&1
```

**✅ 使用子 shell**：
```bash
0 9 * * * timeout 30m (cd /home/opencode/workspace/crontab-ui && /usr/local/bin/opencode run -m opencode/glm-4.7-free "获取最新代码") >> /tmp/opencode.log 2>&1
```

**✅ 使用包装脚本**：

创建 `scripts/fetch-with-timeout.sh`:
```bash
#!/bin/bash
cd /home/opencode/workspace/crontab-ui
/usr/local/bin/opencode run -m opencode/glm-4.7-free "获取最新代码"
```

crontab:
```bash
0 9 * * * timeout 30m /home/opencode/workspace/crontab-ui/scripts/fetch-with-timeout.sh >> /tmp/opencode.log 2>&1
```

**❌ 错误：timeout 只对第一个命令生效**：
```bash
# ⚠️ 错误：timeout 只对 cd 命令生效
0 9 * * * timeout 30m cd /home/opencode/workspace/crontab-ui && /usr/local/bin/opencode run -m opencode/glm-4.7-free "获取最新代码"
```

#### 实用示例

```bash
# Git 自动合并（最多 10 分钟）
0 2 * * * timeout 10m sh -c 'cd /home/opencode/workspace/crontab-ui && git pull origin main --no-edit' >> /tmp/git.log 2>&1

# OpenCode AI 任务（最多 30 分钟）
0 9 * * * timeout 30m sh -c 'cd /home/opencode/workspace/crontab-ui && /usr/local/bin/opencode run -m opencode/glm-4.7-free "获取最新代码"' >> /tmp/opencode.log 2>&1

# 备份任务（最多 1 小时）
0 3 * * * timeout 1h /home/opencode/workspace/crontab-ui/scripts/backup.sh >> /tmp/backup.log 2>&1
```

#### 高级选项

```bash
# 超时后等待 10 秒，再发送 KILL 信号强制终止
0 2 * * * timeout -k 10s 1h /path/to/script.sh

# 发送特定信号
0 2 * * * timeout -s SIGQUIT 10m /path/to/script.sh

# 保留退出状态
timeout --preserve-status 5m /path/to/script.sh
```

#### 检测超时

**退出码 124** 表示超时：

```bash
#!/bin/bash
# 在脚本中检测超时

timeout 300 /path/to/slow-command
EXIT_CODE=$?

if [ $EXIT_CODE -eq 124 ]; then
    echo "[$(date)] 命令超时" >> /var/log/timeout.log
    exit 1
fi
```

#### 监控超时日志

```bash
# 查找超时的 cron 任务
grep "exit status 124" /var/log/syslog | grep CRON

# 监控自定义超时日志
tail -f /var/log/timeout.log
```

### 使用 Git Hooks

在 `.git/hooks/post-merge` 中添加自动化任务：

```bash
#!/bin/bash
npm install
npm run build
```

### 使用 Git Workflows

创建 `.github/workflows/auto-merge.yml`（如使用 GitHub Actions，替代 cron）

```yaml
name: Auto Merge
on:
  schedule:
    - cron: '0 2 * * *'

jobs:
  merge:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: |
          git fetch origin
          git merge origin/main
```

## 参考资源

- [Cron 表达式编辑器](https://crontab.guru)
- [OpenCode 文档](https://opencode.ai)
- [Git 自动化工作流](https://git-scm.com/book/zh/v2/自定义-Git-Git-钩子)
