#!/bin/bash

# 每日自动合并代码脚本
# 用途: 自动拉取远程代码并合并到本地分支

set -e  # 遇到错误时退出

# 配置
REPO_DIR="/home/opencode/workspace/crontab-ui"
LOG_FILE="${REPO_DIR}/logs/auto-merge.log"
BRANCH="main"

# 创建日志目录
mkdir -p "${REPO_DIR}/logs"

# 记录日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

log "=== 开始自动合并代码 ==="
log "工作目录: ${REPO_DIR}"
log "目标分支: ${BRANCH}"

# 进入项目目录
cd "${REPO_DIR}" || exit 1

# 保存当前状态（如果有未提交的更改）
if [ -n "$(git status --porcelain)" ]; then
    log "⚠️  检测到未提交的更改，跳过本次合并"
    log "未提交的文件:"
    git status --short | tee -a "${LOG_FILE}"
    exit 1
fi

# 拉取最新代码
log "正在拉取远程更新..."
git fetch origin || {
    log "❌ 拉取失败"
    exit 1
}

# 检查是否有更新
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/${BRANCH})

if [ "${LOCAL_COMMIT}" = "${REMOTE_COMMIT}" ]; then
    log "✅ 代码已是最新，无需合并"
    exit 0
fi

log "发现远程更新，执行合并..."

# 合并代码
git merge origin/${BRANCH} --no-edit || {
    log "❌ 合并失败，可能存在冲突"
    # 回滚
    git merge --abort 2>/dev/null || true
    exit 1
}

log "✅ 代码合并成功"
log "合并后的提交: $(git log -1 --oneline)"

# 如果有 git push 权限和需求，可以推送
# log "正在推送到远程..."
# git push origin ${BRANCH}

log "=== 自动合并完成 ==="
exit 0
