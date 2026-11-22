@echo off
setlocal
title Roblox CDN Fix - Remove

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

if not exist "%~dp0RobloxCDNFix.ps1" (
    echo RobloxCDNFix.ps1 not found next to this file.
    pause
    exit /b 1
)

echo.
echo  Roblox CDN Fix - removing hosts entry...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0RobloxCDNFix.ps1" -Mode Remove
echo.
pause
endlocal
