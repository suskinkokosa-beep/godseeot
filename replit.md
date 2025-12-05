# Isleborn Online

## Overview
Isleborn Online - онлайновая песочница-выживалка в огромном процедурном океане. Каждый игрок получает собственный маленький остров (5x5 м), который может расти и развиваться.

## Project Architecture

### Components
- **Main API Server** (порт 5000) - единый Flask сервер для веб-интерфейса и API
  - Авторизация/регистрация пользователей
  - Nakama-совместимый endpoint для Godot клиента
  - Управление островами (интегрировано)
  - Новости, гайды, рейтинг
  - Админ-панель
- **Gateway Server** (порт 8080) - Go прокси для WebSocket с rate limiting
- **Godot WebSocket Server** (порт 8090) - игровой сервер для real-time взаимодействия
- **Godot Client** - игровой клиент (запускается через VNC)
- **PostgreSQL** - база данных

### Directory Structure
```
isleborn-online/
├── main.py                 # Единый API сервер (порт 5000)
├── web_frontend/           # Веб-интерфейс (HTML/CSS/JS)
│   ├── index.html          # Страница входа
│   ├── dashboard.html      # Личный кабинет с вкладками
│   └── payment.html        # Магазин
├── godot_client_3d/        # Godot 4.x клиент
│   ├── project.godot
│   ├── scripts/            # GDScript логика
│   │   └── network/
│   │       └── auth_client.gd  # Авторизация через API
│   └── scenes/             # Игровые сцены
├── godot_server/           # Игровой сервер
│   ├── server.gd           # Основной сервер на GDScript
│   └── placeholder_ws.py   # Python WebSocket сервер
├── gateway/                # Go Gateway (WebSocket прокси)
│   ├── main.go
│   └── go.mod
├── island_service/         # (устарело - интегрировано в main.py)
├── db/                     # SQL схемы
└── replit.md               # Этот файл
```

## API Endpoints

### Авторизация
- `POST /api/auth/register` - Регистрация
- `POST /api/auth/login` - Вход
- `POST /api/auth/verify` - Проверка токена
- `POST /api/auth/logout` - Выход

### Nakama-совместимые (для Godot)
- `POST /v2/account/authenticate/email` - Авторизация
- `POST /v2/rpc/validate_session` - Валидация сессии (для Gateway)

### Данные
- `GET /api/news` - Новости
- `GET /api/guides` - Игровые гайды
- `GET /api/leaderboard` - Рейтинг игроков
- `GET /api/online` - Количество онлайн

### Острова
- `GET /api/islands/<user_id>` - Острова пользователя
- `POST /api/islands` - Создать остров
- `PUT /api/islands/<island_id>` - Обновить остров

### Админ
- `POST /api/admin/news` - Создать новость
- `DELETE /api/admin/news/<id>` - Удалить новость

## Running the Project

### Workflows
1. **Web Server** - Запускает main.py на порту 5000

### Environment Variables
- `DATABASE_URL` - URL подключения к PostgreSQL
- `JWT_SECRET` - Секрет для JWT токенов (генерируется автоматически)

### Gateway (опционально)
```bash
cd gateway && ./gateway
```
Переменные окружения:
- `NAKAMA_RPC_URL=http://localhost:5000/v2/rpc/validate_session`
- `NAKAMA_HTTP_KEY=defaulthttpkey`
- `WORLD_WS=ws://localhost:8090/ws`

## Database Schema

### Таблицы
- `users` - Пользователи (id, email, username, password_hash, pearls, level, is_admin)
- `sessions` - Сессии авторизации
- `news` - Новости
- `leaderboard` - Рейтинг игроков
- `online_users` - Онлайн пользователи
- `islands` - Острова игроков

## Recent Changes
- 2025-12-05: Добавлен endpoint /v2/rpc/validate_session для Gateway
- 2025-12-05: Обновлены URL в Godot клиенте (исправлена ошибка HTTP 0)
- 2025-12-05: Интегрирован Island Service в main.py
- 2025-12-05: Добавлены гайды, рейтинг, админ-панель
- 2025-12-05: Создан единый API сервер main.py

## Technologies
- Python 3.11 (Flask)
- Go 1.21 (Gateway)
- Godot 4.4
- PostgreSQL (Neon)
- WebSockets
- JWT для авторизации

## Known Issues
- Gateway требует запуска Godot WebSocket сервера на порту 8090
- VNC требуется для запуска Godot клиента
