# Web App Monitor

Этот проект представляет собой минимальное Flask-приложение и систему мониторинга, обеспечивающую его автоматический запуск, наблюдение за состоянием и перезапуск при сбоях.  

Мониторинг работает как systemd-служба и регулярно проверяет HTTP-доступность веб-приложения. В случае нескольких неудачных проверок подряд сервис автоматически перезапускает приложение.

## Возможности

- Автоматический запуск Flask-приложения.
- Постоянный мониторинг доступности по HTTP.
- Автоматический перезапуск после нескольких неудачных проверок.
- systemd-интеграция.
- Ротация логов.
- Ведение логов приложения и монитора.

## Установка

```
sudo ./install.sh
```

## Обновление

```
git pull && sudo ./install.sh
```

## Настройки (config.sh)

| Параметр | Описание |
|---------|----------|
| APP_PORT | Порт веб-приложения |
| APP_URL | URL веб-приложения |
| CHECK_INTERVAL | Интервал проверок |
| RESTART_AFTER_FAILURES | Кол-во неудачных проверок до перезапуска |
| LOG_DIR | Папка логов |
| MAX_LOG_SIZE | Лимит логов |



## Управление сервисом

```
sudo systemctl start web-app-monitor.service
sudo systemctl stop web-app-monitor.service
sudo systemctl restart web-app-monitor.service
sudo systemctl status web-app-monitor.service
```

## Логи

```
/var/tmp/web-app-monitor/app.log
/var/tmp/web-app-monitor/monitor.log
journalctl -u web-app-monitor.service -f
```