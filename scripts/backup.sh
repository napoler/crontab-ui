#!/bin/bash

# 每日备份数据库脚本
# 修改此脚本以适配你的实际备份需求

set -e

REPO_DIR="/home/opencode/workspace/crontab-ui"
LOG_FILE="${REPO_DIR}/logs/backup.log"
BACKUP_DIR="${REPO_DIR}/backups"
DATE=$(date '+%Y%m%d_%H%M%S')

mkdir -p "${BACKUP_DIR}"
mkdir -p "${REPO_DIR}/logs"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

log "开始备份..."

# 示例: 备份数据库（根据实际情况修改）
# mysqldump -u root -p${DB_PASSWORD} mydb > "${BACKUP_DIR}/db_${DATE}.sql"

# 示例: 备份配置文件
# tar -czf "${BACKUP_DIR}/config_${DATE}.tar.gz" /etc/nginx

# 清理7天前的备份
find "${BACKUP_DIR}" -type f -mtime +7 -delete 2>/dev/null || true

log "备份完成"
