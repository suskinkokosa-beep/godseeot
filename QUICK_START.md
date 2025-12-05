# Isleborn Online - Быстрый старт

## 🚀 Быстрая установка и запуск

### Ubuntu 20.04+

```bash
# 1. Клонируйте репозиторий
git clone https://github.com/yourusername/isleborn-online.git
cd isleborn-online

# 2. Запустите скрипт установки
chmod +x scripts/install_ubuntu.sh
./scripts/install_ubuntu.sh

# 3. Перелогиньтесь (для применения прав Docker)
# Или выполните: newgrp docker

# 4. Запустите все сервисы
./scripts/run_all.sh

# 5. Запустите клиент
cd godot_client_3d
godot
```

### Windows 10+

1. Откройте PowerShell от имени администратора
2. Выполните:

```powershell
# 1. Клонируйте репозиторий
git clone https://github.com/yourusername/isleborn-online.git
cd isleborn-online

# 2. Разрешите выполнение скриптов
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Запустите скрипт установки
.\scripts\install_windows.ps1

# 4. Запустите все сервисы
.\scripts\run_all.ps1

# 5. Запустите клиент
cd godot_client_3d
godot
```

## 📋 Что установится

- **Godot 4.2** - Игровой движок
- **Docker & Docker Compose** - Контейнеризация
- **PostgreSQL 15** - База данных
- **Redis** - Кэширование
- **Python 3** - Island Service
- **Go 1.21+** - Gateway сервер
- **Nakama** - Авторизация (через Docker)

## 🎮 Запуск игры

После запуска всех сервисов:

1. Откройте Godot Client
2. В главном меню нажмите "Play"
3. Войдите с вашими учётными данными (если есть)
4. Или зарегистрируйтесь через веб-интерфейс: `http://localhost:7350`

## 🔧 Проверка работы сервисов

```bash
# Проверка Gateway
curl http://localhost:8080/health

# Проверка Island Service
curl http://localhost:5000/health

# Проверка PostgreSQL
docker compose exec postgres pg_isready

# Проверка Redis
docker compose exec redis redis-cli ping

# Проверка Nakama
curl http://localhost:7350
```

## 📝 Важные файлы

- `.env` - Конфигурация окружения (создаётся из `.env.example`)
- `docker-compose.yml` - Конфигурация Docker сервисов
- `logs/` - Логи всех сервисов

## 🛑 Остановка сервисов

**Ubuntu:**
```bash
./scripts/stop_all.sh
```

**Windows:**
```powershell
.\scripts\stop_all.ps1
```

## 📚 Дополнительная документация

- [INSTALLATION.md](INSTALLATION.md) - Подробная инструкция по установке
- [README.md](README.md) - Общее описание проекта

## ❓ Проблемы?

См. раздел "Устранение проблем" в [INSTALLATION.md](INSTALLATION.md)

---

**Приятной игры! 🌊⚓**

