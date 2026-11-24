# AgroChat Backend Launch Script for PowerShell
Set-Location "$PSScriptRoot\backend"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Starting AgroChat FastAPI Backend Server" -ForegroundColor Green
Write-Host "  API Docs: http://127.0.0.1:8000/docs" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan

& ".\.venv\Scripts\python.exe" -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
