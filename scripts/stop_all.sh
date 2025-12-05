#!/bin/bash

# Isleborn Online - Скрипт остановки всех сервисов (Ubuntu)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${YELLOW}→${NC} $1"; }

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_DIR"

echo ""
echo "Остановка всех сервисов Isleborn Online..."
echo ""

# Остановка фоновых процессов
if [ -f "logs/island_service.pid" ]; then
    PID=$(cat logs/island_service.pid)
    if ps -p $PID > /dev/null 2>&1; then
        kill $PID 2>/dev/null && print_success "Island Service остановлен (PID: $PID)" || print_info "Island Service уже остановлен"
    fi
    rm -f logs/island_service.pid
fi

if [ -f "logs/gateway.pid" ]; then
    PID=$(cat logs/gateway.pid)
    if ps -p $PID > /dev/null 2>&1; then
        kill $PID 2>/dev/null && print_success "Gateway остановлен (PID: $PID)" || print_info "Gateway уже остановлен"
    fi
    rm -f logs/gateway.pid
fi

if [ -f "logs/godot_server.pid" ]; then
    PID=$(cat logs/godot_server.pid)
    if ps -p $PID > /dev/null 2>&1; then
        kill $PID 2>/dev/null && print_success "Godot Server остановлен (PID: $PID)" || print_info "Godot Server уже остановлен"
    fi
    rm -f logs/godot_server.pid
fi

# Остановка Docker контейнеров
print_info "Остановка Docker контейнеров..."
docker compose down

print_success "Все сервисы остановлены"
echo ""

