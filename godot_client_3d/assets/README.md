# Assets Directory - Isleborn Online

Эта директория содержит все игровые ассеты: модели, текстуры, шейдеры и звуки.

## Структура

```
assets/
├── models/              # 3D модели
│   ├── characters/      # Персонажи
│   │   ├── male/        # Мужские модели
│   │   ├── female/      # Женские модели
│   │   └── animations/   # Анимации персонажей
│   ├── monsters/        # Монстры
│   ├── bosses/          # Боссы
│   ├── buildings/       # Постройки
│   ├── island/          # Элементы острова
│   ├── items/           # Предметы
│   └── ships/           # Корабли
├── textures/            # Текстуры и материалы
│   ├── characters/      # Текстуры персонажей
│   ├── monsters/        # Текстуры монстров
│   ├── buildings/       # Текстуры построек
│   ├── island/          # Текстуры острова
│   ├── items/           # Текстуры предметов
│   └── environment/     # Текстуры окружения
├── shaders/             # Шейдеры
└── sounds/              # Звуки
    ├── ui/              # Звуки интерфейса
    ├── combat/          # Звуки боя
    ├── environment/     # Звуки окружения
    ├── music/           # Музыка
    └── effects/         # Звуковые эффекты
```

## Рекомендуемые ресурсы

### 3D Модели

#### Персонажи
- **Mixamo** (Adobe): https://www.mixamo.com/ - Бесплатные персонажи с анимациями (требуется аккаунт Adobe)
- **Kenney Assets**: https://kenney.nl/assets - Низкополигональные модели персонажей
- **OpenGameArt**: https://opengameart.org/ - Бесплатные игровые ассеты
- **Sketchfab**: https://sketchfab.com/ - Модели с лицензией CC0

#### Монстры и боссы
- **Free3D**: https://free3d.com/ - Бесплатные модели монстров
- **OpenGameArt**: https://opengameart.org/art-search-advanced?keys=monster - Монстры
- **Kenney Assets**: https://kenney.nl/assets - Низкополигональные монстры

#### Постройки
- **Kenney Assets**: https://kenney.nl/assets - Низкополигональные постройки
- **OpenGameArt**: https://opengameart.org/art-search-advanced?keys=building - Постройки
- **Free3D**: https://free3d.com/ - Бесплатные модели построек

#### Остров и окружение
- **Kenney Assets**: https://kenney.nl/assets - Низкополигональные элементы окружения
- **OpenGameArt**: https://opengameart.org/art-search-advanced?keys=island - Острова

### Текстуры

- **Poly Haven**: https://polyhaven.com/textures - Бесплатные PBR текстуры (CC0)
- **Texture Haven**: https://texturehaven.com/ - Высококачественные PBR текстуры
- **CC0 Textures**: https://cc0textures.com/ - Бесплатные текстуры CC0
- **OpenGameArt**: https://opengameart.org/art-search-advanced?keys=texture - Текстуры

### Шейдеры

- **Godot Shaders**: https://godotshaders.com/ - Шейдеры для Godot
- **OpenGameArt**: https://opengameart.org/art-search-advanced?keys=shader - Шейдеры

### Звуки

- **Freesound**: https://freesound.org/ - Бесплатные звуковые эффекты
- **OpenGameArt**: https://opengameart.org/art-search-advanced?keys=sound - Звуки
- **Zapsplat**: https://www.zapsplat.com/ - Бесплатные звуки (требуется регистрация)
- **Kenney Assets**: https://kenney.nl/assets - Звуковые эффекты

## Форматы файлов

### Модели
- **Рекомендуется**: `.glb` (GLTF Binary) - лучшая поддержка в Godot 4
- **Альтернатива**: `.fbx`, `.obj` (требуют конвертации)

### Текстуры
- **Рекомендуется**: `.png` или `.jpg` для диффузных текстур
- **PBR**: `.png` для Albedo, Normal, Roughness, Metallic, AO

### Звуки
- **Рекомендуется**: `.ogg` (Ogg Vorbis) - лучшая компрессия
- **Альтернатива**: `.wav` (несжатый)

## Инструкции по импорту

1. Скачайте ассеты с рекомендованных ресурсов
2. Поместите файлы в соответствующие папки
3. Godot автоматически импортирует ассеты при открытии проекта
4. Используйте AssetManager для управления ассетами в коде

## Лицензии

Убедитесь, что все используемые ассеты имеют подходящую лицензию:
- **CC0** - Публичное достояние, можно использовать свободно
- **CC-BY** - Требуется указание авторства
- **CC-BY-SA** - Требуется указание авторства и производные работы под той же лицензией

## Оптимизация

- Используйте низкополигональные модели для игровых объектов
- Сжимайте текстуры до разумных размеров (1024x1024 или 2048x2048)
- Используйте формат OGG для звуков
- Группируйте ассеты по категориям для лучшей организации

