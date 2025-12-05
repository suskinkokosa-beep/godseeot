# Isleborn Online - Скрипт установки для Windows
# Автор: Isleborn Team
# Версия: 1.0
# Требования: PowerShell 5.1+ (Windows 10+)

$ErrorActionPreference = "Stop"

# Цвета для вывода
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

# Получение директории проекта
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

Set-Location $ProjectDir

Write-Header "Isleborn Online - Установка для Windows"

# Проверка прав администратора
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Запустите PowerShell от имени администратора!"
    exit 1
}

# Шаг 1: Проверка версии Windows
Write-Header "Шаг 1: Проверка системы"
$osVersion = [System.Environment]::OSVersion.Version
if ($osVersion.Major -lt 10) {
    Write-Error "Требуется Windows 10 или выше"
    exit 1
}
Write-Success "Windows $($osVersion.Major).$($osVersion.Minor) обнаружена"

# Шаг 2: Проверка и установка Chocolatey
Write-Header "Шаг 2: Установка Chocolatey"
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Info "Установка Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Обновление PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Success "Chocolatey установлен"
} else {
    Write-Info "Chocolatey уже установлен: $(choco --version)"
}

# Шаг 3: Установка Git
Write-Header "Шаг 3: Установка Git"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Info "Установка Git через Chocolatey..."
    choco install git -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Success "Git установлен"
} else {
    Write-Info "Git уже установлен: $(git --version)"
}

# Шаг 4: Установка Docker Desktop
Write-Header "Шаг 4: Установка Docker Desktop"
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Info "Установка Docker Desktop через Chocolatey..."
    choco install docker-desktop -y
    
    Write-Info "Ожидание запуска Docker..."
    Write-Warning "Пожалуйста, запустите Docker Desktop после установки и дождитесь его полной загрузки."
    Write-Warning "Нажмите любую клавишу после запуска Docker Desktop..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Проверка Docker
    $maxAttempts = 30
    $attempt = 0
    do {
        Start-Sleep -Seconds 2
        $attempt++
        try {
            docker version 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Docker запущен"
                break
            }
        } catch {
            # Продолжаем попытки
        }
    } while ($attempt -lt $maxAttempts)
    
    if ($attempt -ge $maxAttempts) {
        Write-Error "Docker не запустился. Запустите Docker Desktop вручную и перезапустите скрипт."
        exit 1
    }
} else {
    Write-Info "Docker уже установлен: $(docker --version)"
    
    # Проверка работы Docker
    try {
        docker ps | Out-Null
        Write-Success "Docker работает"
    } catch {
        Write-Error "Docker не запущен. Запустите Docker Desktop."
        exit 1
    }
}

# Шаг 5: Установка Godot
Write-Header "Шаг 5: Установка Godot 4.2"
$godotPath = "$env:ProgramFiles\Godot"
if (-not (Test-Path "$godotPath\Godot.exe")) {
    Write-Info "Скачивание Godot 4.2..."
    $godotUrl = "https://github.com/godotengine/godot/releases/download/4.2-stable/Godot_v4.2-stable_win64.exe.zip"
    $godotZip = "$env:TEMP\Godot_v4.2-stable_win64.exe.zip"
    
    Invoke-WebRequest -Uri $godotUrl -OutFile $godotZip
    
    Write-Info "Распаковка Godot..."
    New-Item -ItemType Directory -Force -Path $godotPath | Out-Null
    Expand-Archive -Path $godotZip -DestinationPath $godotPath -Force
    Remove-Item $godotZip
    
    # Добавление в PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($currentPath -notlike "*$godotPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$godotPath", "Machine")
        $env:Path += ";$godotPath"
    }
    
    Write-Success "Godot установлен в $godotPath"
} else {
    Write-Info "Godot уже установлен"
}

# Шаг 6: Установка PostgreSQL
Write-Header "Шаг 6: Установка PostgreSQL"
if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Info "Установка PostgreSQL через Chocolatey..."
    choco install postgresql15 -y
    
    # Добавление в PATH
    $pgPath = "C:\Program Files\PostgreSQL\15\bin"
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($currentPath -notlike "*$pgPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$pgPath", "Machine")
        $env:Path += ";$pgPath"
    }
    
    Write-Info "Ожидание запуска PostgreSQL..."
    Start-Sleep -Seconds 5
    
    Write-Success "PostgreSQL установлен"
    Write-Warning "Настройте пароль для пользователя postgres при первом подключении!"
} else {
    Write-Info "PostgreSQL уже установлен: $(psql --version)"
}

# Шаг 7: Установка Redis
Write-Header "Шаг 7: Установка Redis"
Write-Info "Запуск Redis через Docker..."
docker run -d --name redis -p 6379:6379 redis:latest 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Success "Redis запущен в Docker контейнере"
} else {
    # Проверка, возможно контейнер уже существует
    docker start redis 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Redis контейнер перезапущен"
    } else {
        Write-Error "Не удалось запустить Redis"
    }
}

# Шаг 8: Установка Python
Write-Header "Шаг 8: Установка Python"
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Info "Установка Python через Chocolatey..."
    choco install python -y
    
    # Обновление PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Success "Python установлен"
} else {
    Write-Info "Python уже установлен: $(python --version)"
}

# Шаг 9: Установка Go
Write-Header "Шаг 9: Установка Go"
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Info "Установка Go через Chocolatey..."
    choco install golang -y
    
    # Обновление PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Success "Go установлен"
} else {
    Write-Info "Go уже установлен: $(go version)"
}

# Шаг 10: Настройка Island Service
Write-Header "Шаг 10: Настройка Island Service"
if (Test-Path "island_service") {
    Set-Location island_service
    
    if (-not (Test-Path "venv")) {
        Write-Info "Создание виртуального окружения Python..."
        python -m venv venv
    }
    
    Write-Info "Установка Python зависимостей..."
    & .\venv\Scripts\Activate.ps1
    python -m pip install --upgrade pip --quiet
    pip install -r requirements.txt --quiet
    deactivate
    
    Write-Success "Island Service настроен"
    Set-Location $ProjectDir
} else {
    Write-Error "Директория island_service не найдена"
}

# Шаг 11: Настройка базы данных
Write-Header "Шаг 11: Настройка базы данных"
Write-Info "Создание базы данных и пользователя..."
Write-Warning "Вам потребуется ввести пароль для пользователя postgres"

$dbScript = @"
CREATE DATABASE isleborn_online;
CREATE USER isleborn_user WITH PASSWORD 'isleborn_pass';
GRANT ALL PRIVILEGES ON DATABASE isleborn_online TO isleborn_user;
ALTER DATABASE isleborn_online OWNER TO isleborn_user;
"@

$dbScript | psql -U postgres 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Success "База данных создана"
} else {
    Write-Info "База данных может уже существовать или требуется ввод пароля"
}

# Применение схемы
if (Test-Path "db\schema_islands.sql") {
    Write-Info "Применение схемы базы данных..."
    Get-Content "db\schema_islands.sql" | psql -U postgres -d isleborn_online 2>$null
    Write-Success "Схема применена"
}

# Шаг 12: Настройка переменных окружения
Write-Header "Шаг 12: Настройка переменных окружения"
if (-not (Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Success "Файл .env создан из примера"
        Write-Info "Отредактируйте файл .env при необходимости"
    } else {
        Write-Error "Файл .env.example не найден"
    }
} else {
    Write-Info "Файл .env уже существует"
}

# Шаг 13: Сборка Docker образов
Write-Header "Шаг 13: Подготовка Docker образов"
Write-Info "Сборка Docker образов (это может занять несколько минут)..."
docker compose build
if ($LASTEXITCODE -eq 0) {
    Write-Success "Docker образы собраны"
} else {
    Write-Error "Ошибка при сборке Docker образов"
}

# Финальный отчёт
Write-Header "Установка завершена!"
Write-Success "Все компоненты установлены"
Write-Host ""
Write-Host "Следующие шаги:"
Write-Host "  1. Убедитесь, что Docker Desktop запущен"
Write-Host "  2. Отредактируйте файл .env при необходимости"
Write-Host "  3. Запустите проект: .\scripts\run_all.ps1"
Write-Host ""
Write-Info "Документация: см. INSTALLATION.md"
Write-Host ""

