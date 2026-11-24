# AgroChat Flutter Web Frontend Launch Script for PowerShell
Set-Location "$PSScriptRoot\frontend"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Starting AgroChat Flutter Web Frontend" -ForegroundColor Green
Write-Host "  URL: http://127.0.0.1:3000" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan

& "C:\src\flutter\bin\flutter.bat" run -d web-server --web-port=3000 --web-hostname=127.0.0.1
