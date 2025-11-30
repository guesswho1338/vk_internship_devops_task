#!/bin/bash
set -uo pipefail

# путь к папке с проектом
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# путь к виртуальному окружению
VENV_DIR="${REPO_DIR}/.venv"

# папка для логов и пидов
LOG_DIR="/var/tmp/web-app-monitor"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# параметры приложения
APP_PORT=5000
APP_URL="http://127.0.0.1:${APP_PORT}"
APP_CMD="${VENV_DIR}/bin/python ${REPO_DIR}/app.py"
APP_LOG="${LOG_DIR}/app.log"
MONITOR_LOG="${LOG_DIR}/monitor.log"
PID_FILE="${LOG_DIR}/app.pid"

# настройки монитора
CHECK_INTERVAL=5
RESTART_AFTER_FAILURES=3
SERVICE_NAME="web-app-monitor"

# максимальный размер лога
MAX_LOG_SIZE=$((100 * 1024 * 1024))
