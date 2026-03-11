@echo off
chcp 65001 >nul
title TechSupport Pro Server
color 0A

echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║                                                              ║
echo  ║           TechSupport Pro - Local Server                     ║
echo  ║                                                              ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.
echo  [INFO] Запуск локального сервера...
echo  [INFO] Порт: 8080
echo  [INFO] URL: http://localhost:8080
echo.

:: Check if PowerShell is available
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo  [ERROR] PowerShell не найден!
    echo  [ERROR] Убедитесь, что PowerShell установлен.
    pause
    exit /b 1
)

:: Check if server.ps1 exists
if not exist "server.ps1" (
    echo  [ERROR] Файл server.ps1 не найден!
    echo  [ERROR] Убедитесь, что файл server.ps1 находится в той же папке.
    pause
    exit /b 1
)

echo  [OK] PowerShell найден
echo  [OK] Server.ps1 найден
echo.
echo  [INFO] Запуск сервера...
echo  [INFO] Нажмите Ctrl+C для остановки сервера
echo.

:: Start the server
powershell -ExecutionPolicy Bypass -File "server.ps1"

echo.
echo  [INFO] Сервер остановлен.
echo.
pause