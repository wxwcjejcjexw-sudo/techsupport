# TechSupport Pro - Главный сервер
# Загружает модули и обрабатывает запросы

# Кодировка
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Проверка прав администратора
$script:IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Путь к модулям
$modulesPath = Join-Path $PSScriptRoot "modules"

# Загрузка всех модулей
function Load-Modules {
    $allCommands = @{}
    
    $moduleFiles = @(
        "commands-system.ps1",
        "commands-network.ps1", 
        "commands-management.ps1",
        "commands-info.ps1",
        "commands-security.ps1"
    )
    
    foreach ($file in $moduleFiles) {
        $modulePath = Join-Path $modulesPath $file
        if (Test-Path $modulePath) {
            try {
                . $modulePath
                
                switch ($file) {
                    "commands-system.ps1" { $fn = "Get-SystemCommands" }
                    "commands-network.ps1" { $fn = "Get-NetworkCommands" }
                    "commands-management.ps1" { $fn = "Get-ManagementCommands" }
                    "commands-info.ps1" { $fn = "Get-InfoCommands" }
                    "commands-security.ps1" { $fn = "Get-SecurityCommands" }
                }
                
                $commands = & $fn
                foreach ($key in $commands.Keys) {
                    $allCommands[$key] = $commands[$key]
                }
                Write-Host "  Loaded: $file ($($commands.Count) commands)" -ForegroundColor Gray
            } catch {
                Write-Host "  Error loading $file : $_" -ForegroundColor Red
            }
        }
    }
    
    return $allCommands
}

# Инициализация путей
$script:BackupPath = Join-Path $PSScriptRoot "backups"
$script:DataPath = Join-Path $PSScriptRoot "data"

if (-not (Test-Path $script:BackupPath)) {
    New-Item -ItemType Directory -Path $script:BackupPath -Force | Out-Null
}
if (-not (Test-Path $script:DataPath)) {
    New-Item -ItemType Directory -Path $script:DataPath -Force | Out-Null
}

# Загружаем команды
$script:Commands = Load-Modules

# HTTP сервер с автоматическим поиском свободного порта
$listener = New-Object System.Net.HttpListener
$port = 8080
$maxPort = 8090
$started = $false

while (-not $started -and $port -le $maxPort) {
    try {
        $listener.Prefixes.Clear()
        $listener.Prefixes.Add("http://localhost:$port/")
        $listener.Start()
        $started = $true
    } catch {
        Write-Host "  Port $port is busy, trying next..." -ForegroundColor Yellow
        $port++
    }
}

if (-not $started) {
    Write-Host "  ERROR: Could not find available port (8080-8090)" -ForegroundColor Red
    Write-Host "  Please check if another application is using these ports." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   TechSupport Pro - Server Started" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  URL: http://localhost:8080" -ForegroundColor Yellow
Write-Host "  Commands loaded: $($script:Commands.Count)" -ForegroundColor Gray
Write-Host "  Admin rights: $($script:IsAdmin)" -ForegroundColor $(if ($script:IsAdmin) { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "  Press Ctrl+C to stop" -ForegroundColor DarkGray
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Обработка запросов
while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        # CORS
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
        
        $path = $request.Url.AbsolutePath
        
        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            continue
        }
        
        # Static files
        if ($path -eq "/" -or $path -eq "/index.html") {
            $filePath = Join-Path $PSScriptRoot "index.html"
            if (Test-Path $filePath) {
                $content = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentType = "text/html; charset=utf-8"
                $response.ContentLength64 = $content.Length
                $response.OutputStream.Write($content, 0, $content.Length)
            }
        }
        elseif ($path -eq "/styles.css") {
            $filePath = Join-Path $PSScriptRoot "styles.css"
            if (Test-Path $filePath) {
                $content = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentType = "text/css; charset=utf-8"
                $response.ContentLength64 = $content.Length
                $response.OutputStream.Write($content, 0, $content.Length)
            }
        }
        elseif ($path -eq "/script.js") {
            $filePath = Join-Path $PSScriptRoot "script.js"
            if (Test-Path $filePath) {
                $content = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentType = "application/javascript; charset=utf-8"
                $response.ContentLength64 = $content.Length
                $response.OutputStream.Write($content, 0, $content.Length)
            }
        }
        elseif ($path -eq "/header.mp4") {
            $filePath = Join-Path $PSScriptRoot "header.mp4"
            if (Test-Path $filePath) {
                $content = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentType = "video/mp4"
                $response.ContentLength64 = $content.Length
                $response.OutputStream.Write($content, 0, $content.Length)
            }
        }
        # API: Admin check
        elseif ($path -eq "/api/admin-check") {
            $responseBody = @{
                isAdmin = $script:IsAdmin
                username = $env:USERNAME
                computer = $env:COMPUTERNAME
            } | ConvertTo-Json
            
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseBody)
            $response.ContentType = "application/json; charset=utf-8"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        # API: System info
        elseif ($path -eq "/api/system-info") {
            try {
                $cpu = Get-CimInstance Win32_Processor
                $os = Get-CimInstance Win32_OperatingSystem
                $ram = Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum
                $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
                
                $totalRAM = [math]::Round($ram.Sum / 1GB, 1)
                $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
                $usedRAM = [math]::Round($totalRAM - ($freeRAM / 1024), 1)
                
                $totalDisk = [math]::Round($disk.Size / 1GB, 1)
                $freeDisk = [math]::Round($disk.FreeSpace / 1GB, 1)
                
                $responseBody = @{
                    success = $true
                    cpu = "$($cpu.Name)"
                    ram = "$usedRAM GB / $totalRAM GB used"
                    disk = "$freeDisk GB / $totalDisk GB free"
                    os = "$($os.Caption) $($os.Version)"
                } | ConvertTo-Json
            } catch {
                $responseBody = @{
                    success = $false
                    error = $_.Exception.Message
                } | ConvertTo-Json
            }
            
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseBody)
            $response.ContentType = "application/json; charset=utf-8"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        # API: Execute command
        elseif ($path -eq "/api/execute" -and $request.HttpMethod -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream)
            $body = $reader.ReadToEnd()
            $data = $body | ConvertFrom-Json
            
            $command = $data.command
            $params = $data.params
            
            Write-Host "Executing: $command" -ForegroundColor Cyan
            
            if ($script:Commands.ContainsKey($command)) {
                try {
                    $scriptBlock = $script:Commands[$command]
                    
                    if ($params) {
                        $result = & $scriptBlock $params
                    } else {
                        $result = & $scriptBlock
                    }
                    
                    $responseBody = @{
                        success = $true
                        result = $result
                        command = $command
                    } | ConvertTo-Json -Depth 10
                } catch {
                    $responseBody = @{
                        success = $false
                        error = $_.Exception.Message
                        command = $command
                    } | ConvertTo-Json
                }
            } else {
                $responseBody = @{
                    success = $false
                    error = "Unknown command: $command"
                } | ConvertTo-Json
            }
            
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseBody)
            $response.ContentType = "application/json; charset=utf-8"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        # API: Backup create
        elseif ($path -eq "/api/backup/create" -and $request.HttpMethod -eq "POST") {
            try {
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                
                $backup = @{
                    timestamp = $timestamp
                    computer = $env:COMPUTERNAME
                    user = $env:USERNAME
                    system = (Get-CimInstance Win32_OperatingSystem).Caption
                    services = @(Get-Service | Where-Object { $_.Status -eq "Running" } | Select-Object Name, Status, StartType -First 50)
                    network = @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object InterfaceAlias, IPAddress)
                }
                
                $responseBody = @{
                    success = $true
                    data = $backup
                    message = "Backup created successfully"
                } | ConvertTo-Json -Depth 4
            } catch {
                $responseBody = @{
                    success = $false
                    error = $_.Exception.Message
                } | ConvertTo-Json
            }
            
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseBody)
            $response.ContentType = "application/json; charset=utf-8"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        # API: Backup restore
        elseif ($path -eq "/api/backup/restore" -and $request.HttpMethod -eq "POST") {
            try {
                $reader = New-Object System.IO.StreamReader($request.InputStream)
                $body = $reader.ReadToEnd()
                $data = $body | ConvertFrom-Json
                
                # В реальном приложении здесь была бы логика восстановления
                $responseBody = @{
                    success = $true
                    result = "Backup restore simulated. In production, this would restore system settings."
                } | ConvertTo-Json
            } catch {
                $responseBody = @{
                    success = $false
                    error = $_.Exception.Message
                } | ConvertTo-Json
            }
            
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseBody)
            $response.ContentType = "application/json; charset=utf-8"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        else {
            $response.StatusCode = 404
            $response.Close()
        }
        
        $response.Close()
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

$listener.Stop()