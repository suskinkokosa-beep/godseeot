Полная инструкция по развёртыванию и тестированию (русский)
=========================================================

Требования:
- Docker 20+, Docker Compose v2+
- Go 1.20+ (для сборки gateway)
- Godot 4.x (если собираешь headless локально) или настрой GitHub Actions
- websocat (для WebSocket тестов), curl, python3

1) Подготовка
-------------
Распакуй архив в удобную папку:
```
unzip isleborn_server_improved.zip -d isleborn_server
cd isleborn_server
```

2) Сборка Gateway (локально, опционально)
-----------------------------------------
```bash
cd gateway
go mod download
go build -o gateway main.go
# Либо собрать Docker image:
docker build -t isleborn/gateway:local .
cd ..
```

3) Сборка/экспорт Godot headless (опционально)
----------------------------------------------
Есть два варианта:
A) Локально: открой `godot_server` в Godot 4.x и экспортируй headless бинарь `isleborn_server.x86_64` в `godot_server/export/` (см. GitHub Actions ниже).
B) CI: настроить `.github/workflows/export_godot.yml` и собрать бинарь в Actions; скачай артефакт и помести в `godot_server/export/`.

Пример команды (локальная машина с Godot CLI):
```bash
godot --export "Linux/X11" godot_export_presets.cfg godot_server/export/isleborn_server.x86_64
```

4) Запуск стека
----------------
Если собрали Gateway образ локально или хотите использовать билд в Docker Compose — запустить:
```bash
docker compose up --build -d
```
Подождите ~10-20 сек пока Nakama и DB поднимутся.

5) Автоматическая проверка (скрипт)
-----------------------------------
Скрипт `scripts/check_stack.sh` выполнит:
- проверит `/health` Gateway
- создаст тестовый аккаунт в Nakama и получит session JWT
- попытается подключиться к Gateway по WS и отправить простой `ping`

Запуск:
```bash
chmod +x scripts/check_stack.sh
./scripts/check_stack.sh
```

6) Ручное тестирование WebSocket (websocat)
-------------------------------------------
Получив токен (в ответе от Nakama authenticate/email), подключись через Gateway:
```bash
websocat -H "Authorization: Bearer <TOKEN>" ws://localhost:8080/ws
# После подключения Gateway пошлёт auth_init в World и World вернёт spawn.
# Отправь движение (пример):
{"t":"move","dx":1,"dz":0}
# Получишь snapshot от World каждую секунду (или близко к тому).
```

7) Проверка логов
------------------
- Gateway: `docker compose logs -f gateway`
- Nakama: `docker compose logs -f nakama`
- World: `docker compose logs -f world`

8) Примечания по безопасности
-----------------------------
- В продакшне обязательно использовать JWKS URL или любой метод строгой валидации подписи JWT.
- Для масштабирования Gateway используйте Redis-backed rate limiter.
- Настройте TLS и секреtы через менеджер секретов.


Добавлено: Redis-backed rate limiter (lua script)
-----------------------------------------------
Реализация предлагает два варианта:
A) Простой: Gateway использует INCR с 1-секундными окнами (по умолчанию).
B) Более точный: использовать Lua token-bucket в Redis.

Чтобы включить Lua-скрипт в Redis и использовать его из Gateway (пример):
1) Подключись к redis-cli (или используй библиотеку redis в Go):
   redis-cli -h localhost -p 6379 SCRIPT LOAD "$(cat redis/token_bucket.lua)"
   Это вернёт SHA1 хеш скрипта.
2) В Gateway в коде можно вызывать EVALSHA <sha> 1 rl:<ip> <max_tokens> <rate>
   (вместо текущей реализации NewRedisLimiter.Allow).

Примеры: в docker-compose переменные уже установлены:
  USE_REDIS_RATE=true
  REDIS_URL=redis://redis:6379/0
  RATE_LIMIT_RPS=5
  RATE_LIMIT_BURST=10

Grafana dashboard:
- Загружен базовый дашборд в monitoring/grafana/dashboards/gateway-dashboard.json
- В Grafana (http://localhost:3000, admin/admin) он будет доступен в папке dashboards.


Доработка: 3D Godot клиент и headless World Server
------------------------------------------------
Добавлен базовый 3D клиент-прототип в папке `godot_client_3d/` и обновлён headless сервер в `godot_server/server.gd`.

Как тестировать локально:
1) Если у тебя есть экспортированный Godot headless binary -> положи его в `godot_server/export/isleborn_server.x86_64`.
2) Запусти стек: `docker compose up --build -d`
3) Открой Godot 4.x, импортируй `godot_client_3d` как проект, открой сцену с `player.gd` и запусти.
4) Установи token в `player.gd` (export var token) или оставь пустым и Gateway будет пытаться пропустить (в dev режимах может потребоваться подстановка токена).
5) Нажимай WASD — клиент будет отправлять движения на сервер, сервер будет рассылать snapshot другим игрокам.


=== Миграция островов в PostgreSQL ===
Добавлены артефакты для миграции JSON-файлов островов в таблицу PostgreSQL `islands`.

1) Применить схему к БД (пример для docker-compose):
   docker exec -i <postgres_container> psql -U postgres -d isleborn -f /path/to/db/schema_islands.sql
   (в нашем compose файл postgres монтируется внутрь контейнера: используйте абсолютный путь или скопируйте файл)

2) Или локально:
   psql postgresql://postgres:postgres@localhost:5432/isleborn -f db/schema_islands.sql

3) Запустить миграцию (требуется psycopg2):
   pip install psycopg2-binary
   export DATABASE_URL=postgresql://postgres:postgres@localhost:5432/isleborn
   python db/migrate_islands.py --source godot_server/islands

4) Примечание:
   - Скрипт делает UPSERT (INSERT ... ON CONFLICT DO UPDATE).
   - В продакшне рекомендую запускать миграцию в maintenance-окне и тестировать откат.


=== IslandGenerator ===
Добавлен инструмент генерации стартовых островов: tools/generate_island.py
Примеры:
  python tools/generate_island.py --owner alice --seed 12345 --radius 3.0 --out godot_server/islands
Скрипт создаст godot_server/islands/island_alice.json

Рекомендации:
- seed обеспечивает воспроизводимость острова.
- можно генерировать партию островов для бета-тестеров.



=== Island Service ===
Добавлен микросервис island_service (Flask). Endpoints:
- GET /island/<owner> — получить island JSON
- POST /island — создать/upsert island
- PUT /island/<owner> — обновить island

Запуск:
  docker compose build island_service
  docker compose up -d island_service

Пример:
  curl http://localhost:5000/island/alice
  curl -X POST -H 'Content-Type: application/json' -d '{"owner":"dave","island":{...}}' http://localhost:5000/island


=== Instance Manager ===
Добавлен сервис instance_manager, управляющий lifecycle Godot headless instances.

Endpoints:
- POST /start/<owner> { "owner_dir": "/abs/path/to/owner/data" } — запускает контейнер для острова
- POST /stop/<owner> — останавливает
- GET /status/<owner>

Важно:
- Сервис использует docker CLI под капотом. Для работы в Docker Compose монтируется /var/run/docker.sock.
- В production лучше использовать Kubernetes или полноценный Docker SDK.

Пример:
  curl -X POST http://localhost:5100/start/alice -H 'Content-Type: application/json' -d '{"owner_dir":"/abs/path/to/islands/alice"}'


=== Resource & Building Update ===
Сервер теперь поддерживает:
- gather: сбор ресурсов с уменьшением amount
- build: установка зданий с сохранением в island JSON
Примеры сообщений клиента:
{"t":"gather","x":1.0,"z":0.5}
{"t":"build","type":"campfire","x":0.3,"z":0.1}


=== world_update_10: API persistence ===
Godot server теперь использует island_service API (HTTP) для загрузки/сохранения островов.
Убедитесь, что island_service запущен и доступен по адресу http://island_service:5000 в Docker Compose.


=== world_update_11: Redis Lock ===
Добавлен Redis lock для PUT /island/<owner>.
Если остров занят -> 409 BUSY.


=== world_update_12: Client visuals ===
Godot client now contains World.tscn, resource/building scenes and dynamic spawning.
Open godot_client_3d in Godot 4.x, run World.tscn. On connect the client will display resources and buildings from island_state.
