# Isleborn Online - Звуковые эффекты

## Структура папок

```
sounds/
├── ui/              # UI звуки (клики, уведомления)
├── combat/          # Боевые звуки (удары, выстрелы)
├── environment/     # Звуки окружения (волны, ветер)
├── music/           # Фоновая музыка
└── effects/         # Специальные эффекты
```

## Рекомендуемые CC0 источники звуков

### Океан и волны:
- https://archive.org/details/ocean-sea-sounds
- https://freesound.org/people/Noted451/sounds/531015/
- https://opengameart.org/content/beach-ocean-waves

### UI звуки:
- https://opengameart.org/content/cc0-sounds-library
- https://freesound.org (фильтр CC0)

### Боевые звуки:
- https://opengameart.org/content/cc0-sounds-library
- https://freesound.org/search/?q=sword+swing&f=license%3A%22CC0%22

## Формат файлов
- Рекомендуется: .ogg (лучшее сжатие для Godot)
- Альтернатива: .wav (без сжатия)

## Как добавить звуки

1. Скачайте звуки из источников выше
2. Конвертируйте в .ogg если необходимо
3. Поместите в соответствующую папку
4. Звуки автоматически загрузятся через AssetManager
