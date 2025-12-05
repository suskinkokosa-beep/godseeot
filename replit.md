# Isleborn Online

## Overview
Isleborn Online - онлайновая песочница-выживалка в огромном процедурном океане. Каждый игрок получает собственный маленький остров (5×5 м), который может расти и развиваться.

## Project Architecture

### Components
- **Web Frontend** (порт 5000) - веб-интерфейс для регистрации и управления аккаунтом
- **Island Service** (порт 5001) - Flask API для управления островами
- **Godot WebSocket Server** (порт 8090) - игровой сервер для real-time взаимодействия
- **Godot Client** - игровой клиент (запускается через VNC)
- **PostgreSQL** - база данных для хранения островов

### Directory Structure
```
isleborn-online/
├── web_frontend/           # Веб-интерфейс (HTML/CSS/JS)
│   ├── index.html          # Страница регистрации
│   ├── dashboard.html      # Личный кабинет
│   └── payment.html        # Магазин
├── island_service/         # Flask API для островов
│   └── app.py
├── godot_client_3d/        # Godot 4.x клиент
│   ├── project.godot
│   ├── scripts/            # GDScript логика
│   └── scenes/             # Игровые сцены
├── godot_server/           # Игровой сервер
│   ├── placeholder_ws.py   # WebSocket сервер (заглушка)
│   ├── server.gd           # Основной сервер на GDScript
│   └── islands/            # JSON файлы островов
├── gateway/                # Go сервер для маршрутизации (опционально)
├── db/                     # SQL схемы
└── run_services.py         # Скрипт запуска всех сервисов
```

## Running the Project

### Workflows
1. **Web Frontend & Services** - запускает веб-интерфейс и backend сервисы
2. **Godot Client VNC** - запускает Godot клиент через VNC

### Environment Variables
- `DATABASE_URL` - URL подключения к PostgreSQL
- `PORT` - порт для сервисов (по умолчанию: 5000 для frontend, 5001 для island_service)

## Recent Changes
- 2024-12-05: Настроена интеграция с Replit
- 2024-12-05: Добавлен CORS к Island Service
- 2024-12-05: Исправлен autoload constants.gd
- 2024-12-05: Обновлен web_frontend с русской локализацией

## Technologies
- Godot 4.4
- Python (Flask)
- Go (Gateway)
- PostgreSQL
- WebSockets

## Known Issues
- Некоторые GDScript файлы требуют обновления для совместимости с Godot 4.x
- 3D модели (.DAE, .GLB) требуют повторного импорта в Godot Editor
