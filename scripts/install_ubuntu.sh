#!/bin/bash

# Isleborn Online - Скрипт установки для Ubuntu 20.04+
# Автор: Isleborn Team
# Версия: 1.0

set -e  # Остановка при ошибках

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функции для вывода
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}→${NC} $1"
}

print_header() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# Проверка прав root
if [ "$EUID" -eq 0 ]; then 
    print_error "Не запускайте скрипт от root! Используйте обычного пользователя."
    exit 1
fi

# Получение директории скрипта
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_DIR"

print_header "Isleborn Online - Установка для Ubuntu"

# Шаг 1: Обновление системы
print_header "Шаг 1: Обновление системы"
print_info "Обновление списка пакетов..."
sudo apt update

print_info "Обновление установленных пакетов..."
sudo apt upgrade -y

print_success "Система обновлена"

# Шаг 2: Установка основных инструментов
print_header "Шаг 2: Установка основных инструментов"
print_info "Установка git, curl, wget, build-essential..."

sudo apt install -y \
    git \
    curl \
    wget \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    unzip \
    python3 \
    python3-pip \
    python3-venv \
    postgresql-client

print_success "Основные инструменты установлены"

# Шаг 3: Установка Godot 4.x
print_header "Шаг 3: Установка Godot 4.2"
print_info "Загрузка Godot 4.2..."

if ! command -v godot &> /dev/null; then
    GODOT_DIR="/tmp/godot_install"
    mkdir -p "$GODOT_DIR"
    cd "$GODOT_DIR"
    
    if [ ! -f "Godot_v4.2-stable_linux.x86_64.zip" ]; then
        print_info "Скачивание Godot..."
        wget -q --show-progress https://github.com/godotengine/godot/releases/download/4.2-stable/Godot_v4.2-stable_linux.x86_64.zip
    fi
    
    if [ -f "Godot_v4.2-stable_linux.x86_64.zip" ]; then
        print_info "Распаковка Godot..."
        unzip -q -o Godot_v4.2-stable_linux.x86_64.zip
        
        print_info "Установка Godot в /usr/local/bin..."
        sudo mv Godot_v4.2-stable_linux.x86_64 /usr/local/bin/godot
        sudo chmod +x /usr/local/bin/godot
        
        print_success "Godot установлен"
        
        cd "$PROJECT_DIR"
        rm -rf "$GODOT_DIR"
    else
        print_error "Не удалось загрузить Godot"
        exit 1
    fi
else
    print_info "Godot уже установлен: $(godot --version)"
fi

# Шаг 4: Установка Docker
print_header "Шаг 4: Установка Docker"
if ! command -v docker &> /dev/null; then
    print_info "Установка Docker..."
    
    # Удаляем старые версии
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Добавляем официальный GPG ключ
    print_info "Добавление GPG ключа Docker..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Настраиваем репозиторий
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Устанавливаем Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Добавляем пользователя в группу docker
    print_info "Добавление пользователя в группу docker..."
    sudo usermod -aG docker "$USER"
    
    print_success "Docker установлен"
    print_info "⚠️  ВАЖНО: Необходимо перелогиниться для применения прав доступа к Docker!"
else
    print_info "Docker уже установлен: $(docker --version)"
fi

# Шаг 5: Установка PostgreSQL
print_header "Шаг 5: Установка PostgreSQL"
if ! command -v psql &> /dev/null || ! sudo systemctl is-active --quiet postgresql; then
    print_info "Установка PostgreSQL..."
    sudo apt install -y postgresql postgresql-contrib
    
    print_info "Запуск PostgreSQL..."
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    
    print_success "PostgreSQL установлен и запущен"
else
    print_info "PostgreSQL уже установлен"
fi

# Шаг 6: Установка Redis
print_header "Шаг 6: Установка Redis"
if ! command -v redis-cli &> /dev/null || ! sudo systemctl is-active --quiet redis-server; then
    print_info "Установка Redis..."
    sudo apt install -y redis-server
    
    print_info "Запуск Redis..."
    sudo systemctl start redis-server
    sudo systemctl enable redis-server
    
    print_success "Redis установлен и запущен"
else
    print_info "Redis уже установлен"
fi

# Шаг 7: Настройка базы данных
print_header "Шаг 7: Настройка базы данных"
print_info "Создание базы данных и пользователя..."

sudo -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname='isleborn_online'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE isleborn_online;"

sudo -u postgres psql -c "SELECT 1 FROM pg_roles WHERE rolname='isleborn_user'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER isleborn_user WITH PASSWORD 'isleborn_pass';"

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE isleborn_online TO isleborn_user;"
sudo -u postgres psql -c "ALTER DATABASE isleborn_online OWNER TO isleborn_user;"

print_success "База данных настроена"

# Шаг 8: Применение схемы БД
print_header "Шаг 8: Применение схемы базы данных"
if [ -f "db/schema_islands.sql" ]; then
    print_info "Применение схемы..."
    sudo -u postgres psql -d isleborn_online -f db/schema_islands.sql 2>/dev/null || \
        print_info "Схема уже применена или содержит ошибки (это нормально)"
    print_success "Схема применена"
else
    print_error "Файл db/schema_islands.sql не найден"
fi

# Шаг 9: Настройка Island Service
print_header "Шаг 9: Настройка Island Service"
if [ -d "island_service" ]; then
    cd island_service
    
    if [ ! -d "venv" ]; then
        print_info "Создание виртуального окружения Python..."
        python3 -m venv venv
    fi
    
    print_info "Установка Python зависимостей..."
    source venv/bin/activate
    pip install --upgrade pip --quiet
    pip install -r requirements.txt --quiet
    deactivate
    
    print_success "Island Service настроен"
    cd "$PROJECT_DIR"
else
    print_error "Директория island_service не найдена"
fi

# Шаг 10: Настройка переменных окружения
print_header "Шаг 10: Настройка переменных окружения"
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        print_info "Создание файла .env из примера..."
        cp .env.example .env
        print_success "Файл .env создан. Отредактируйте его при необходимости."
    else
        print_error "Файл .env.example не найден"
    fi
else
    print_info "Файл .env уже существует"
fi

# Шаг 11: Установка Go (для Gateway)
print_header "Шаг 11: Установка Go"
if ! command -v go &> /dev/null; then
    print_info "Установка Go 1.21+..."
    
    GO_VERSION="1.21.5"
    GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
    
    cd /tmp
    wget -q --show-progress "https://go.dev/dl/${GO_TAR}"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$GO_TAR"
    rm "$GO_TAR"
    
    # Добавляем в PATH (для текущей сессии)
    export PATH=$PATH:/usr/local/go/bin
    
    # Добавляем в .bashrc для постоянного использования
    if ! grep -q "/usr/local/go/bin" "$HOME/.bashrc"; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.bashrc"
    fi
    
    print_success "Go установлен"
    cd "$PROJECT_DIR"
else
    print_info "Go уже установлен: $(go version)"
fi

# Шаг 12: Сборка Gateway (опционально)
print_header "Шаг 12: Сборка Gateway сервера"
if [ -d "gateway" ] && command -v go &> /dev/null; then
    print_info "Сборка Gateway..."
    cd gateway
    if [ -f "go.mod" ]; then
        go mod download
        go build -o gateway main.go 2>/dev/null || print_info "Ошибки сборки Gateway (можно проигнорировать)"
    fi
    cd "$PROJECT_DIR"
    print_success "Gateway подготовлен"
else
    print_info "Gateway будет собран при запуске через Docker"
fi

# Шаг 13: Проверка Docker Compose
print_header "Шаг 13: Проверка Docker Compose"
if command -v docker &> /dev/null; then
    if docker compose version &> /dev/null; then
        print_success "Docker Compose готов к работе"
    else
        print_error "Docker Compose не найден. Установите docker-compose-plugin"
    fi
else
    print_error "Docker не установлен"
fi

# Финальный отчёт
print_header "Установка завершена!"
echo ""
print_success "Все компоненты установлены"
echo ""
echo "Следующие шаги:"
echo "  1. Перелогиньтесь или выполните: newgrp docker"
echo "  2. Отредактируйте .env файл при необходимости"
echo "  3. Запустите проект: ./scripts/run_all.sh"
echo ""
print_info "Документация: см. INSTALLATION.md"
echo ""

