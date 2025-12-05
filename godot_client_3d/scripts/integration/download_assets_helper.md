# Помощник по загрузке ассетов

Этот файл содержит прямые ссылки и инструкции для быстрой загрузки ассетов.

## 🚀 Быстрый старт

### 1. Персонажи (Mixamo)

1. Перейдите на https://www.mixamo.com/
2. Зарегистрируйтесь (бесплатно)
3. Выберите персонажа:
   - Мужской: "Remy", "YBot", "Warrior"
   - Женский: "Alicia", "Sofia", "Archer"
4. Скачайте в формате FBX
5. Конвертируйте в GLB через:
   - Blender (File > Export > glTF 2.0)
   - Онлайн: https://products.aspose.app/3d/conversion/fbx-to-gltf
6. Поместите в `assets/models/characters/male/` или `female/`

### 2. Анимации (Mixamo)

1. На Mixamo выберите "Animations"
2. Скачайте:
   - Idle
   - Walking
   - Running
   - Jumping
   - Swimming
   - Attack (различные)
   - Death
3. Конвертируйте в GLB
4. Импортируйте в Godot как Animation ресурсы

### 3. Монстры (Kenney)

1. Перейдите на https://kenney.nl/assets
2. Скачайте "Monster Pack"
3. Распакуйте в `assets/models/monsters/`

### 4. Постройки (Kenney)

1. На Kenney скачайте:
   - "Building Pack"
   - "Nature Pack"
2. Распакуйте в `assets/models/buildings/`

### 5. Текстуры (Poly Haven)

1. Перейдите на https://polyhaven.com/textures
2. Скачайте:
   - Wood (дерево)
   - Stone (камень)
   - Metal (металл)
   - Fabric (ткань)
   - Sand (песок)
   - Water (вода)
3. Распакуйте в `assets/textures/`

### 6. Звуки (Freesound)

1. Перейдите на https://freesound.org/
2. Зарегистрируйтесь
3. Скачайте:
   - UI: "click", "hover", "notification"
   - Combat: "sword", "hit", "block"
   - Environment: "ocean", "wind", "rain"
4. Конвертируйте в OGG через Audacity или онлайн
5. Поместите в `assets/sounds/`

## 📦 Готовые пакеты

### Kenney Asset Packs (CC0)

- Character Pack: https://kenney.nl/assets/character-pack
- Monster Pack: https://kenney.nl/assets/monster-pack
- Building Pack: https://kenney.nl/assets/building-pack
- Nature Pack: https://kenney.nl/assets/nature-pack
- UI Pack: https://kenney.nl/assets/ui-pack

### OpenGameArt Collections

- Low Poly Characters: https://opengameart.org/art-search-advanced?keys=low+poly+character
- Monsters: https://opengameart.org/art-search-advanced?keys=monster
- Buildings: https://opengameart.org/art-search-advanced?keys=building

## 🔄 Конвертация форматов

### FBX to GLB (Blender)

1. Откройте Blender
2. File > Import > FBX
3. Выберите модель
4. File > Export > glTF 2.0
5. Выберите формат: glTF Binary (.glb)

### WAV to OGG (Audacity)

1. Откройте Audacity
2. File > Open (выберите WAV)
3. File > Export > Export as OGG
4. Выберите качество: Quality 5 (хороший баланс)

## ✅ Проверка после загрузки

После загрузки всех ассетов проверьте:

1. Все файлы в правильных папках
2. Форматы правильные (GLB для моделей, OGG для звуков)
3. Текстуры оптимизированы (не больше 2048x2048)
4. Godot видит файлы (проверьте FileSystem)

## 🎯 Приоритеты загрузки

**Высокий приоритет:**
1. Персонажи (мужской и женский)
2. Базовые анимации (idle, walk, run)
3. Основные монстры (3-5 видов)
4. Базовые постройки (campfire, workshop)
5. UI звуки

**Средний приоритет:**
1. Боссы
2. Дополнительные анимации
3. Больше монстров
4. Больше построек
5. Звуки боя и окружения

**Низкий приоритет:**
1. Дополнительные предметы
2. Декоративные элементы
3. Музыка
4. Специальные эффекты

