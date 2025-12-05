#!/bin/bash

# Isleborn Online - Скрипт запуска всех сервисов (Ubuntu)
# Автор: Isleborn Team
# Версия: 1.0

set -e

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Функции
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${YELLOW}→${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_header() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# Директория проекта
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_DIR"

print_header "Isleborn Online - Запуск всех сервисов"

# Проверка Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker не установлен. Запустите скрипт установки."
    exit 1
fi

if ! docker ps &> /dev/null; then
    print_error "Docker не запущен. Запустите Docker и попробуйте снова."
    exit 1
fi

# Проверка файла .env
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        print_info "Создание .env из примера..."
        cp .env.example .env
        print_info "Файл .env создан. Отредактируйте его при необходимости."
    else
        print_error "Файл .env не найден"
        exit 1
    fi
fi

# Шаг 1: Запуск инфраструктуры
print_header "Шаг 1: Запуск инфраструктуры (PostgreSQL, Redis, Nakama)"
print_info "Запуск Docker контейнеров..."
docker compose up -d postgres redis nakama

print_info "Ожидание запуска сервисов..."
sleep 5

# Проверка PostgreSQL
print_info "Проверка PostgreSQL..."
max_attempts=30
attempt=0
while ! docker compose exec -T postgres pg_isready -U postgres &> /dev/null; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        print_error "PostgreSQL не запустился"
        exit 1
    fi
    sleep 1
done
print_success "PostgreSQL готов"

# Проверка Redis
print_info "Проверка Redis..."
if docker compose exec -T redis redis-cli ping | grep -q "PONG"; then
    print_success "Redis готов"
else
    print_error "Redis не отвечает"
    exit 1
fi

# Шаг 2: Применение схемы БД
print_header "Шаг 2: Применение схемы базы данных"
if [ -f "db/schema_islands.sql" ]; then
    print_info "Применение схемы..."
    docker compose exec -T postgres psql -U postgres -d isleborn_online -f /docker-entrypoint-initdb.d/schema_islands.sql 2>/dev/null || \
        docker compose exec -T postgres psql -U postgres -d isleborn_online -c "\dt" &> /dev/null && print_info "Схема уже применена"
    print_success "База данных готова"
fi

# Шаг 3: Запуск Island Service
print_header "Шаг 3: Запуск Island Service"
if [ -d "island_service" ]; then
    print_info "Запуск Island Service в фоне..."
    
    # Создаём виртуальное окружение, если его нет
    if [ ! -d "island_service/venv" ]; then
        print_info "Создание виртуального окружения..."
        cd island_service
        python3 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip --quiet
        pip install -r requirements.txt --quiet
        deactivate
        cd "$PROJECT_DIR"
    fi
    
    # Запуск в фоне
    cd island_service
    source venv/bin/activate
    nohup python app.py > ../logs/island_service.log 2>&1 &
    ISLAND_SERVICE_PID=$!
    echo $ISLAND_SERVICE_PID > ../logs/island_service.pid
    deactivate
    cd "$PROJECT_DIR"
    
    print_info "Ожидание запуска Island Service..."
    sleep 3
    
    # Проверка
    if curl -s http://localhost:5000/health &> /dev/null; then
        print_success "Island Service запущен (PID: $ISLAND_SERVICE_PID)"
    else
        print_error "Island Service не отвечает. Проверьте логи: logs/island_service.log"
    fi
else
    print_error "Директория island_service не найдена"
fi

# Шаг 4: Запуск Gateway
print_header "Шаг 4: Запуск Gateway сервера"
if [ -d "gateway" ]; then
    print_info "Запуск Gateway в фоне..."
    
    cd gateway
    if command -v go &> /dev/null; then
        go mod download &> /dev/null || true
        nohup go run main.go > ../logs/gateway.log 2>&1 &
        GATEWAY_PID=$!
        echo $GATEWAY_PID > ../logs/gateway.pid
        cd "$PROJECT_DIR"
        
        print_info "Ожидание запуска Gateway..."
        sleep 3
        
        if curl -s http://localhost:8080/health &> /dev/null; then
            print_success "Gateway запущен (PID: $GATEWAY_PID)"
        else
            print_error "Gateway не отвечает. Проверьте логи: logs/gateway.log"
        fi
    else
        print_error "Go не установлен. Установите Go для запуска Gateway."
        cd "$PROJECT_DIR"
    fi
else
    print_error "Директория gateway не найдена"
fi

# Шаг 5: Запуск Godot Server
print_header "Шаг 5: Запуск Godot Server"
if [ -d "godot_server" ] && command -v godot &> /dev/null; then
    print_info "Запуск Godot Server в фоне..."
    
    cd godot_server
    nohup godot --headless --path . src/main/server_main.tscn > ../logs/godot_server.log 2>&1 &
    GODOT_SERVER_PID=$!
    echo $GODOT_SERVER_PID > ../logs/godot_server.pid
    cd "$PROJECT_DIR"
    
    print_success "Godot Server запущен (PID: $GODOT_SERVER_PID)"
else
    print_error "Godot Server не найден или Godot не установлен"
fi

# Создание директории для логов
mkdir -p logs

# Финальный отчёт
print_header "Все сервисы запущены!"
echo ""
print_success "Сервисы готовы к работе"
echo ""
echo "Запущенные сервисы:"
echo "  • PostgreSQL:     localhost:5432"
echo "  • Redis:          localhost:6379"
echo "  • Nakama:         localhost:7350"
echo "  • Island Service: http://localhost:5000"
echo "  • Gateway:        http://localhost:8080"
echo "  • Godot Server:   ws://localhost:8090/ws"
echo ""
echo "Логи находятся в директории: logs/"
echo ""
echo "Для остановки всех сервисов:"
echo "  ./scripts/stop_all.sh"
echo ""
echo "Для запуска клиента:"
echo "  cd godot_client_3d && godot"
echo ""

# Сохранение PID файлов
echo "PID файлы сохранены в logs/"
echo ""

