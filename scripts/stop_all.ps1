# Isleborn Online - Скрипт остановки всех сервисов (Windows)

$ErrorActionPreference = "Stop"

function Write-Success { Write-Host "✓ $args" -ForegroundColor Green }
function Write-Info { Write-Host "→ $args" -ForegroundColor Yellow }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
Set-Location $ProjectDir

Write-Host ""
Write-Host "Остановка всех сервисов Isleborn Online..."
Write-Host ""

# Остановка фоновых процессов (Jobs)
$jobIds = @()

if (Test-Path "logs\island_service.pid") {
    $jobId = Get-Content "logs\island_service.pid" -ErrorAction SilentlyContinue
    if ($jobId) {
        $jobIds += $jobId
    }
    Remove-Item "logs\island_service.pid" -ErrorAction SilentlyContinue
}

if (Test-Path "logs\gateway.pid") {
    $jobId = Get-Content "logs\gateway.pid" -ErrorAction SilentlyContinue
    if ($jobId) {
        $jobIds += $jobId
    }
    Remove-Item "logs\gateway.pid" -ErrorAction SilentlyContinue
}

if (Test-Path "logs\godot_server.pid") {
    $jobId = Get-Content "logs\godot_server.pid" -ErrorAction SilentlyContinue
    if ($jobId) {
        $jobIds += $jobId
    }
    Remove-Item "logs\godot_server.pid" -ErrorAction SilentlyContinue
}

# Остановка всех Jobs
foreach ($jobId in $jobIds) {
    $job = Get-Job -Id $jobId -ErrorAction SilentlyContinue
    if ($job) {
        Stop-Job -Id $jobId -ErrorAction SilentlyContinue
        Remove-Job -Id $jobId -ErrorAction SilentlyContinue
        Write-Success "Процесс остановлен (Job ID: $jobId)"
    }
}

# Остановка Docker контейнеров
Write-Info "Остановка Docker контейнеров..."
docker compose down

Write-Success "Все сервисы остановлены"
Write-Host ""

