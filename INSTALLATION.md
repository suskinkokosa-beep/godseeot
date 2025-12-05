# Isleborn Online - Руководство по установке и запуску

## Содержание

1. [Системные требования](#системные-требования)
2. [Установка на Ubuntu 20.04+](#установка-на-ubuntu-2004)
3. [Установка на Windows](#установка-на-windows)
4. [Ручная установка](#ручная-установка)
5. [Настройка серверов](#настройка-серверов)
6. [Запуск проекта](#запуск-проекта)
7. [Устранение проблем](#устранение-проблем)

---

## Системные требования

### Минимальные требования

**Клиент:**
- OS: Ubuntu 20.04+ / Windows 10+
- CPU: 2 ядра, 2.0 GHz
- RAM: 4 GB
- GPU: DirectX 11 / OpenGL 3.3
- Диск: 2 GB свободного места

**Сервер:**
- OS: Ubuntu 20.04+ / Windows Server 2019+
- CPU: 4 ядра, 2.5 GHz
- RAM: 8 GB
- Диск: 5 GB свободного места
- Сеть: Стабильное подключение к интернету

### Рекомендуемые требования

**Клиент:**
- CPU: 4+ ядра, 3.0 GHz
- RAM: 8 GB
- GPU: DirectX 12 / Vulkan поддержка
- Диск: 5 GB (SSD предпочтительно)

**Сервер:**
- CPU: 8+ ядер, 3.0 GHz
- RAM: 16 GB
- Диск: 10 GB (SSD обязательно)

---

## Установка на Ubuntu 20.04+

### Быстрая установка (автоматическая)

```bash
cd /path/to/isleborn
chmod +x scripts/install_ubuntu.sh
./scripts/install_ubuntu.sh
```

### Пошаговая установка

#### 1. Обновление системы

```bash
sudo apt update
sudo apt upgrade -y
```

#### 2. Установка зависимостей

```bash
# Основные инструменты
sudo apt install -y \
    git \
    curl \
    wget \
    build-essential \
    python3 \
    python3-pip \
    python3-venv

# Godot 4.x (загружаем официальный билд)
cd /tmp
wget https://github.com/godotengine/godot/releases/download/4.2-stable/Godot_v4.2-stable_linux.x86_64.zip
unzip Godot_v4.2-stable_linux.x86_64.zip
sudo mv Godot_v4.2-stable_linux.x86_64 /usr/local/bin/godot
sudo chmod +x /usr/local/bin/godot

# Проверка установки
godot --version
```

#### 3. Установка Docker и Docker Compose

```bash
# Удаляем старые версии
sudo apt remove -y docker docker-engine docker.io containerd runc

# Устанавливаем зависимости
sudo apt install -y \
    ca-certificates \
    gnupg \
    lsb-release

# Добавляем официальный GPG ключ Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Настраиваем репозиторий
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Устанавливаем Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Добавляем пользователя в группу docker
sudo usermod -aG docker $USER

# Проверка установки
docker --version
docker compose version
```

**Важно:** После добавления в группу docker требуется перелогиниться!

#### 4. Установка PostgreSQL

```bash
# Устанавливаем PostgreSQL 15
sudo apt install -y postgresql postgresql-contrib

# Запускаем сервис
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Создаём базу данных
sudo -u postgres psql -c "CREATE DATABASE isleborn_online;"
sudo -u postgres psql -c "CREATE USER isleborn_user WITH PASSWORD 'isleborn_pass';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE isleborn_online TO isleborn_user;"
```

#### 5. Установка Redis

```bash
sudo apt install -y redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Проверка
redis-cli ping
```

#### 6. Установка Python зависимостей для Island Service

```bash
cd island_service
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate
```

#### 7. Настройка переменных окружения

```bash
cd /path/to/isleborn
cp .env.example .env
nano .env  # Отредактируйте файл с вашими настройками
```

#### 8. Инициализация базы данных

```bash
# Применяем схему базы данных
cd db
sudo -u postgres psql -d isleborn_online -f schema_islands.sql
```

#### 9. Сборка и запуск Docker контейнеров

```bash
cd /path/to/isleborn
docker compose build
docker compose up -d

# Проверка статуса
docker compose ps
```

---

## Установка на Windows

### Быстрая установка (автоматическая)

Откройте PowerShell от имени администратора:

```powershell
cd C:\path\to\isleborn
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\install_windows.ps1
```

### Пошаговая установка

#### 1. Установка Git

Скачайте и установите Git с [git-scm.com](https://git-scm.com/download/win)

#### 2. Установка Docker Desktop

1. Скачайте Docker Desktop с [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
2. Запустите установщик и следуйте инструкциям
3. Перезагрузите компьютер
4. Запустите Docker Desktop

#### 3. Установка Godot 4.x

1. Скачайте Godot 4.2 с [godotengine.org/download/windows](https://godotengine.org/download/windows)
2. Распакуйте архив в папку `C:\Godot\`
3. Добавьте путь в PATH:
   - Откройте "Система" → "Дополнительные параметры системы" → "Переменные среды"
   - Добавьте `C:\Godot\` в переменную PATH

#### 4. Установка PostgreSQL

1. Скачайте PostgreSQL 15 с [postgresql.org/download/windows](https://www.postgresql.org/download/windows/)
2. Установите PostgreSQL, запомните пароль для пользователя postgres
3. Откройте pgAdmin или командную строку:
   ```sql
   CREATE DATABASE isleborn_online;
   CREATE USER isleborn_user WITH PASSWORD 'isleborn_pass';
   GRANT ALL PRIVILEGES ON DATABASE isleborn_online TO isleborn_user;
   ```

#### 5. Установка Redis

Способ 1: Через Docker (рекомендуется)
```powershell
docker run -d -p 6379:6379 --name redis redis:latest
```

Способ 2: Нативный Windows
1. Скачайте Redis для Windows с [github.com/microsoftarchive/redis/releases](https://github.com/microsoftarchive/redis/releases)
2. Распакуйте и запустите `redis-server.exe`

#### 6. Установка Python

1. Скачайте Python 3.10+ с [python.org/downloads](https://www.python.org/downloads/)
2. При установке отметьте "Add Python to PATH"
3. Проверьте установку:
   ```powershell
   python --version
   pip --version
   ```

#### 7. Установка Python зависимостей

```powershell
cd island_service
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install --upgrade pip
pip install -r requirements.txt
deactivate
```

#### 8. Настройка переменных окружения

```powershell
cd C:\path\to\isleborn
Copy-Item .env.example .env
notepad .env  # Отредактируйте файл
```

#### 9. Инициализация базы данных

```powershell
cd db
psql -U postgres -d isleborn_online -f schema_islands.sql
```

#### 10. Сборка и запуск Docker контейнеров

```powershell
cd C:\path\to\isleborn
docker compose build
docker compose up -d

# Проверка статуса
docker compose ps
```

---

## Ручная установка

### Клонирование репозитория

```bash
# Ubuntu
git clone https://github.com/yourusername/isleborn-online.git
cd isleborn-online

# Windows
git clone https://github.com/yourusername/isleborn-online.git
cd isleborn-online
```

### Структура проекта

```
isleborn-online/
├── godot_client_3d/      # Клиент Godot
├── godot_server/         # Сервер Godot (headless)
├── gateway/              # Gateway сервер (Go)
├── island_service/       # Island Service (Flask)
├── db/                   # Схемы базы данных
├── docker-compose.yml    # Docker конфигурация
└── scripts/              # Скрипты установки
```

---

## Настройка серверов

### Настройка Gateway сервера

Редактируйте `gateway/config.yaml`:

```yaml
server:
  host: "0.0.0.0"
  port: 8080
  
nakama:
  host: "nakama:7349"
  
world_servers:
  - name: "World-1"
    ws_url: "ws://world-server-1:8081/ws"
```

### Настройка Island Service

Редактируйте `island_service/.env`:

```env
FLASK_APP=app.py
FLASK_ENV=development
DATABASE_URL=postgresql://isleborn_user:isleborn_pass@localhost:5432/isleborn_online
REDIS_URL=redis://localhost:6379/0
```

### Настройка Nakama

Nakama настраивается через `docker-compose.yml`. Для кастомизации создайте `nakama/data/config.yml`.

---

## Запуск проекта

### Полный запуск (все сервисы)

#### Ubuntu

```bash
./scripts/run_all.sh
```

#### Windows

```powershell
.\scripts\run_all.ps1
```

### Запуск отдельных компонентов

#### 1. База данных и инфраструктура

```bash
# Ubuntu
docker compose up -d postgres redis nakama

# Windows
docker compose up -d postgres redis nakama
```

#### 2. Gateway сервер

```bash
# Ubuntu
cd gateway
go run main.go

# Windows
cd gateway
go run main.go
```

#### 3. Island Service

```bash
# Ubuntu
cd island_service
source venv/bin/activate
python app.py

# Windows
cd island_service
.\venv\Scripts\Activate.ps1
python app.py
```

#### 4. Godot Server

```bash
# Ubuntu/Windows
cd godot_server
godot --headless --path . src/main/server_main.tscn
```

#### 5. Godot Client

```bash
# Ubuntu/Windows
cd godot_client_3d
godot --path .
```

### Проверка работы

1. **Gateway:** `http://localhost:8080/health` → должен вернуть `{"status":"ok"}`
2. **Island Service:** `http://localhost:5000/health` → должен вернуть `{"status":"ok"}`
3. **Nakama:** `http://localhost:7350` → веб-консоль Nakama
4. **PostgreSQL:** `psql -U isleborn_user -d isleborn_online` → подключение к БД
5. **Redis:** `redis-cli ping` → должен вернуть `PONG`

---

## Устранение проблем

### Проблема: Docker не запускается

**Ubuntu:**
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

**Windows:**
- Убедитесь, что Docker Desktop запущен
- Проверьте виртуализацию в BIOS

### Проблема: Порт уже занят

Найдите процесс, занимающий порт:

**Ubuntu:**
```bash
sudo lsof -i :8080
sudo kill -9 <PID>
```

**Windows:**
```powershell
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

### Проблема: База данных не подключается

Проверьте:
1. PostgreSQL запущен: `sudo systemctl status postgresql`
2. Пользователь существует: `sudo -u postgres psql -c "\du"`
3. База данных создана: `sudo -u postgres psql -c "\l"`

### Проблема: Godot не найден

**Ubuntu:**
```bash
which godot
# Если не найден, добавьте в PATH или установите заново
```

**Windows:**
```powershell
where.exe godot
# Проверьте PATH в переменных среды
```

### Проблема: Ошибки при сборке Docker

```bash
# Очистка кэша Docker
docker system prune -a

# Пересборка без кэша
docker compose build --no-cache
```

### Проблема: Permission denied в Linux

```bash
# Дайте права на выполнение скриптам
chmod +x scripts/*.sh

# Проверьте права на файлы
ls -la scripts/
```

---

## Дополнительная информация

### Логи сервисов

```bash
# Все логи
docker compose logs

# Конкретный сервис
docker compose logs gateway
docker compose logs island_service

# Следить за логами в реальном времени
docker compose logs -f
```

### Остановка всех сервисов

```bash
docker compose down
```

### Перезапуск сервиса

```bash
docker compose restart gateway
```

### Обновление проекта

```bash
git pull origin main
docker compose down
docker compose build
docker compose up -d
```

---

## Поддержка

Если у вас возникли проблемы:

1. Проверьте логи: `docker compose logs`
2. Проверьте документацию в `docs/`
3. Создайте issue на GitHub
4. Напишите в Discord/Telegram сообщество

---

**Приятной игры! 🎮🌊**

