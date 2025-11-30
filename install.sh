#!/bin/bash
set -uo pipefail

# подгружаем конфиг
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# если запустили не от рута, то перезапускаем с sudo
if [[ $EUID -ne 0 ]]; then
    echo "Script requires root privileges for systemd operations. Restarting with sudo..."
    exec sudo "$0" "$@"
fi

# создаём/обновляем venv
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment in $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
fi

# устанавливаем зависимости
echo "Installing requirements in virtual environment..."
"$VENV_DIR/bin/pip" install --quiet --upgrade pip -r requirements.txt

# права на исполнение
chmod +x "$REPO_DIR"/monitor.sh "$REPO_DIR"/install.sh

# создаём (или перезаписываем) systemd unit
echo "Installing web app monitor as systemd service..."
cat <<EOF | tee /etc/systemd/system/${SERVICE_NAME}.service
[Unit]
Description=Web App Monitoring
After=network-online.target

[Service]
Type=simple
WorkingDirectory=$REPO_DIR
ExecStart=$REPO_DIR/monitor.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# применяем изменения
systemctl daemon-reload
systemctl enable $SERVICE_NAME.service
systemctl restart $SERVICE_NAME.service || true # в случае первого запуска, просто запустится

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Monitoring installed successfully!"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Application URL: $APP_URL"
echo "Application logs: tail -f $APP_LOG"
echo "Monitor logs: tail -f $MONITOR_LOG"
echo "Systemd logs: journalctl -u $SERVICE_NAME.service -f"
echo "Update: git pull && sudo ./install.sh"
echo "Stop service: sudo systemctl stop $SERVICE_NAME.service"
