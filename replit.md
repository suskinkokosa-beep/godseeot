# Isleborn Online - MMO Sandbox на Godot 4

## Обзор

Isleborn Online - онлайновая MMO-песочница на движке Godot 4.2 с пиратской тематикой.
Игроки управляют островами, строят корабли и сражаются за ресурсы.

## Текущее состояние

**Версия**: MVP Development
**Дата**: 2024-12-05
**Статус**: Работоспособная среда разработки

### Установленные компоненты
- Godot 4.4.1 (OpenGL ES fallback через VNC)
- Python 3.11 + Flask для backend-сервисов
- Go 1.21 для gateway
- PostgreSQL для хранения данных
- Redis (опционально для блокировок)

## Структура проекта

```
isleborn-online/
├── godot_client_3d/          # Godot 4 клиент
│   ├── project.godot         # Конфигурация проекта
│   ├── assets/               # Игровые ассеты
│   │   ├── models/           # 3D модели
│   │   │   ├── characters/   # Персонажи (male/female)
│   │   │   ├── buildings/    # Постройки
│   │   │   ├── island/       # Элементы острова
│   │   │   └── ships/        # Корабли
│   │   ├── textures/         # Текстуры
│   │   ├── sounds/           # Звуки (placeholder)
│   │   └── icons/            # Иконки UI
│   ├── scripts/              # GDScript код
│   │   ├── systems/          # Игровые системы
│   │   ├── ui/               # Интерфейс
│   │   └── integration/      # Интеграции
│   └── scenes/               # Сцены Godot
├── gateway/                  # Go gateway сервис
├── island_service/           # Flask API для островов
├── instance_manager/         # Управление инстансами (заглушка)
├── godot_server/             # WebSocket сервер
└── db/                       # SQL схемы
```

## Запуск

### Godot Editor (VNC)
Workflow "Godot Editor" запускает редактор через VNC.
Используется OpenGL ES fallback из-за отсутствия Vulkan.

### Backend Services
```bash
cd island_service && python app.py
```

## Ассеты

### Модели персонажей
- `male/default.tscn` - Placeholder мужского персонажа
- `female/default.tscn` - Placeholder женского персонажа
- Анимации в папке `animations/`

### Недостающие ассеты
- Полноценные rigged 3D модели персонажей
- Звуковые эффекты (.ogg файлы)
- Фоновая музыка

### Рекомендуемые CC0 источники
- Модели: VRoid Studio (OpenGameArt.org), Sketchfab CC0
- Звуки: Internet Archive, Freesound.org, BigSoundBank

## База данных

PostgreSQL схема в `db/schema_islands.sql`:
- `islands` - хранение данных островов игроков

## Особенности Replit

- Docker недоступен (instance_manager - заглушка)
- Vulkan недоступен (используется OpenGL ES)
- VNC для GUI приложений
- Bind frontend на 0.0.0.0:5000

## Известные проблемы

### GDScript ошибки (требуют рефакторинга)
Многие скрипты используют устаревший синтаксис Godot 3:
- `translation` → `position` (Godot 4)
- `WebSocketClient` → `WebSocketPeer` (Godot 4)
- `JSON.parse()` → `JSON.parse_string()` (Godot 4)
- Strict typing требует явных типов вместо Variant

### Критичные файлы для исправления:
- `player_controller.gd` - WebSocket API изменен в Godot 4
- `raft_controller.gd` - translation → position
- `character_creation_menu.gd` - отсутствуют ссылки на UI элементы
- `monster_visual_integration.gd` - неверное кол-во аргументов

### Autoload конфликты (исправлено)
- Убраны class_name из database файлов
- Исправлен constants.gd

## Следующие шаги

1. **Критично:** Рефакторинг player_controller.gd для Godot 4 WebSocket API
2. **Критично:** Исправить синтаксис в UI скриптах
3. Заменить placeholder модели на полноценные rigged модели
4. Добавить звуковые эффекты из CC0 источников
5. Настроить сетевое взаимодействие (Nakama/custom WebSocket)
6. Реализовать боевую систему
7. Добавить систему строительства
