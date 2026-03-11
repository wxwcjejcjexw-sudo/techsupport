@echo off
chcp 65001 >nul
title TechSupport Pro - Локальный сервер

echo.
echo  ╔═══════════════════════════════════════════════════════════╗
echo  ║                                                           ║
echo  ║           TechSupport Pro - Техническая поддержка         ║
echo  ║                                                           ║
echo  ╚═══════════════════════════════════════════════════════════╝
echo.
echo  Запуск локального веб-сервера...
echo.
echo  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo   Приложение будет доступно по адресу: http://localhost:8080
echo   Для остановки сервера нажмите Ctrl+C
echo  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

:: Check if PowerShell is available
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo  [ОШИБКА] PowerShell не найден. Установите PowerShell для работы приложения.
    pause
    exit /b 1
)

:: Run the PowerShell server
powershell -ExecutionPolicy Bypass -File "%~dp0server.ps1"

:: If PowerShell exits
echo.
echo  Сервер остановлен.
pause