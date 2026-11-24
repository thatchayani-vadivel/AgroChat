@echo off
title AgroChat Platform Launcher
echo ==================================================
echo   Starting AgroChat Platform (Backend + Frontend)
echo ==================================================

echo Launching FastAPI Backend Server...
start "AgroChat Backend (:8000)" powershell -NoExit -ExecutionPolicy Bypass -File "%~dp0run_backend.ps1"

timeout /t 3 /nobreak >nul

echo Launching Flutter Web App...
start "AgroChat Frontend (:3000)" powershell -NoExit -ExecutionPolicy Bypass -File "%~dp0run_frontend.ps1"

echo.
echo ==================================================
echo   AgroChat is running!
echo   - App:      http://127.0.0.1:3000
echo   - API Docs: http://127.0.0.1:8000/docs
echo ==================================================
echo You can keep this window open or close it.
echo Press any key to exit this launcher...
pause >nul
