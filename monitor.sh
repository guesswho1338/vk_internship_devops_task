#!/bin/bash
set -uo pipefail

# подгружаем конфиг
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# простая ротация логов
truncate_if_large() {
    local log_file="$1"
    if [[ -f "$log_file" ]]; then
        local size=$(stat -c%s "$log_file" 2>/dev/null || stat -f%z "$log_file" 2>/dev/null || echo 0)
        if (( size > MAX_LOG_SIZE )); then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOG TRUNCATED - exceeded 100 MB" > "$log_file"
        fi
    fi
}

# пишем в лог монитора
log() {
    truncate_if_large "$MONITOR_LOG"
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$MONITOR_LOG" || true
}

# запуск приложения
start_app() {
    truncate_if_large "$APP_LOG"

    if [[ -f "$PID_FILE" ]]; then
        old_pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            return 0
        fi
    fi

    log "Starting application..."
    nohup $APP_CMD >> "$APP_LOG" 2>&1 &
    local new_pid=$!
    echo "$new_pid" > "$PID_FILE"

    # таймаут, чтобы приложение успелось запуститься
    sleep 3
    log "Application started (PID: $new_pid)"
}

# рестарт
restart_app() {
    log "Application not responding - restarting after $RESTART_AFTER_FAILURES consecutive failures" || true

    if [[ -f "$PID_FILE" ]]; then
        old_pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [[ -n "$old_pid" ]]; then
            kill "$old_pid" 2>/dev/null || true
            wait "$old_pid" 2>/dev/null || true
        fi
    fi

    start_app
}

# основной цикл
main() {
    start_app
    
    log "Monitor started (interval ${CHECK_INTERVAL}s, restart after $RESTART_AFTER_FAILURES consecutive failures)" || true

    local consecutive_failures=0
    
    while true; do
        # получаем HTTP-код и обрабатываем его
        curl_output=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 --max-time 3 -I "$APP_URL")
        if [[ $? -ne 0 ]]; then
            http_code="000"
        else
            http_code="$curl_output"
        fi

        if [[ "$http_code" == "200" ]]; then
            consecutive_failures=0
            log "Health check OK (HTTP 200)" || true
        else
            ((consecutive_failures++))
            log "Health check FAILED (HTTP $http_code) - failure $consecutive_failures/$RESTART_AFTER_FAILURES" || true
            
            if (( consecutive_failures >= RESTART_AFTER_FAILURES )); then

                restart_app
                consecutive_failures=0
            fi
        fi

        sleep "$CHECK_INTERVAL"
    done
}

main
