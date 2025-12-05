# Isleborn Online - Скрипт запуска всех сервисов (Windows)
# Автор: Isleborn Team
# Версия: 1.0

$ErrorActionPreference = "Stop"

# Функции для вывода
function Write-Success { Write-Host "✓ $args" -ForegroundColor Green }
function Write-Error { Write-Host "✗ $args" -ForegroundColor Red }
function Write-Info { Write-Host "→ $args" -ForegroundColor Yellow }
function Write-Header {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "$args" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
}

# Директория проекта
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
Set-Location $ProjectDir

Write-Header "Isleborn Online - Запуск всех сервисов"

# Проверка Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker не установлен. Запустите скрипт установки."
    exit 1
}

try {
    docker ps | Out-Null
} catch {
    Write-Error "Docker не запущен. Запустите Docker Desktop."
    exit 1
}

# Проверка файла .env
if (-not (Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Write-Info "Создание .env из примера..."
        Copy-Item ".env.example" ".env"
        Write-Info "Файл .env создан. Отредактируйте его при необходимости."
    } else {
        Write-Error "Файл .env не найден"
        exit 1
    }
}

# Создание директории для логов
if (-not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}

# Шаг 1: Запуск инфраструктуры
Write-Header "Шаг 1: Запуск инфраструктуры (PostgreSQL, Redis, Nakama)"
Write-Info "Запуск Docker контейнеров..."
docker compose up -d postgres redis nakama

Write-Info "Ожидание запуска сервисов..."
Start-Sleep -Seconds 5

# Проверка PostgreSQL
Write-Info "Проверка PostgreSQL..."
$maxAttempts = 30
$attempt = 0
do {
    Start-Sleep -Seconds 1
    $attempt++
    try {
        docker compose exec -T postgres pg_isready -U postgres 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "PostgreSQL готов"
            break
        }
    } catch {
        # Продолжаем попытки
    }
} while ($attempt -lt $maxAttempts)

if ($attempt -ge $maxAttempts) {
    Write-Error "PostgreSQL не запустился"
    exit 1
}

# Проверка Redis
Write-Info "Проверка Redis..."
try {
    $redisCheck = docker compose exec -T redis redis-cli ping 2>$null
    if ($redisCheck -like "*PONG*") {
        Write-Success "Redis готов"
    } else {
        Write-Error "Redis не отвечает"
        exit 1
    }
} catch {
    Write-Error "Redis не отвечает"
    exit 1
}

# Шаг 2: Применение схемы БД
Write-Header "Шаг 2: Применение схемы базы данных"
if (Test-Path "db\schema_islands.sql") {
    Write-Info "Применение схемы..."
    Get-Content "db\schema_islands.sql" | docker compose exec -T postgres psql -U postgres -d isleborn_online 2>$null
    Write-Success "База данных готова"
}

# Шаг 3: Запуск Island Service
Write-Header "Шаг 3: Запуск Island Service"
if (Test-Path "island_service") {
    Set-Location island_service
    
    if (-not (Test-Path "venv")) {
        Write-Info "Создание виртуального окружения..."
        python -m venv venv
        & .\venv\Scripts\Activate.ps1
        python -m pip install --upgrade pip --quiet
        pip install -r requirements.txt --quiet
        deactivate
    }
    
    Write-Info "Запуск Island Service в фоне..."
    & .\venv\Scripts\Activate.ps1
    
    $islandJob = Start-Job -ScriptBlock {
        Set-Location $using:ProjectDir\island_service
        & .\venv\Scripts\python.exe app.py
    }
    
    $islandJob.Id | Out-File -FilePath "..\logs\island_service.pid" -Encoding ASCII
    
    deactivate
    Set-Location $ProjectDir
    
    Write-Info "Ожидание запуска Island Service..."
    Start-Sleep -Seconds 3
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/health" -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Success "Island Service запущен (Job ID: $($islandJob.Id))"
        }
    } catch {
        Write-Error "Island Service не отвечает. Проверьте логи: logs\island_service.log"
    }
} else {
    Write-Error "Директория island_service не найдена"
}

# Шаг 4: Запуск Gateway
Write-Header "Шаг 4: Запуск Gateway сервера"
if (Test-Path "gateway") {
    if (Get-Command go -ErrorAction SilentlyContinue) {
        Set-Location gateway
        
        Write-Info "Установка зависимостей Go..."
        go mod download 2>$null
        
        Write-Info "Запуск Gateway в фоне..."
        $gatewayJob = Start-Job -ScriptBlock {
            Set-Location $using:ProjectDir\gateway
            go run main.go
        }
        
        $gatewayJob.Id | Out-File -FilePath "..\logs\gateway.pid" -Encoding ASCII
        Set-Location $ProjectDir
        
        Write-Info "Ожидание запуска Gateway..."
        Start-Sleep -Seconds 3
        
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Success "Gateway запущен (Job ID: $($gatewayJob.Id))"
            }
        } catch {
            Write-Error "Gateway не отвечает. Проверьте логи: logs\gateway.log"
        }
    } else {
        Write-Error "Go не установлен. Установите Go для запуска Gateway."
    }
} else {
    Write-Error "Директория gateway не найдена"
}

# Шаг 5: Запуск Godot Server
Write-Header "Шаг 5: Запуск Godot Server"
if (Test-Path "godot_server") {
    if (Get-Command godot -ErrorAction SilentlyContinue) {
        Write-Info "Запуск Godot Server в фоне..."
        
        Set-Location godot_server
        $godotJob = Start-Job -ScriptBlock {
            Set-Location $using:ProjectDir\godot_server
            & godot --headless --path . src/main/server_main.tscn
        }
        
        $godotJob.Id | Out-File -FilePath "..\logs\godot_server.pid" -Encoding ASCII
        Set-Location $ProjectDir
        
        Write-Success "Godot Server запущен (Job ID: $($godotJob.Id))"
    } else {
        Write-Error "Godot не установлен"
    }
} else {
    Write-Error "Директория godot_server не найдена"
}

Set-Location $ProjectDir

# Финальный отчёт
Write-Header "Все сервисы запущены!"
Write-Success "Сервисы готовы к работе"
Write-Host ""
Write-Host "Запущенные сервисы:"
Write-Host "  • PostgreSQL:     localhost:5432"
Write-Host "  • Redis:          localhost:6379"
Write-Host "  • Nakama:         localhost:7350"
Write-Host "  • Island Service: http://localhost:5000"
Write-Host "  • Gateway:        http://localhost:8080"
Write-Host "  • Godot Server:   ws://localhost:8090/ws"
Write-Host ""
Write-Host "Логи находятся в директории: logs\"
Write-Host ""
Write-Host "Для остановки всех сервисов:"
Write-Host "  .\scripts\stop_all.ps1"
Write-Host ""
Write-Host "Для запуска клиента:"
Write-Host "  cd godot_client_3d"
Write-Host "  godot"
Write-Host ""

