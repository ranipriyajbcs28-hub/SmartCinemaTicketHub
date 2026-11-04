@echo off
title Smart Cinema Ticket Hub (Local & Offline Server)
cls
echo =====================================================================
echo           SMART CINEMA TICKET HUB — WEB APPLICATION
echo =====================================================================
echo.
echo  * Localhost URL:   http://127.0.0.1:5000
echo  * Alternative URL: http://localhost:5000
echo.
echo  * Default Login Credentials:
echo    - Admin Portal:    admin@cinema.com / Admin@123
echo    - Customer Login:  rani@cinema.com  / Password@123
echo.
echo  * Database Mode: Dual-Engine (MongoDB Atlas Cloud + Full Offline Fallback)
echo =====================================================================
echo.

REM Automatically free port 5000 if lingering from previous run
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":5000" ^| findstr "LISTENING"') do taskkill /F /PID %%a >nul 2>&1

echo Launching your web browser at http://127.0.0.1:5000 ...
start "" http://127.0.0.1:5000
python app.py
pause
