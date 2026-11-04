@echo off
title Smart Cinema Ticket Hub (100% Offline Mode)
cls
echo =====================================================================
echo       SMART CINEMA TICKET HUB — 100% OFFLINE MODE
echo =====================================================================
echo.
echo  * Local Offline URL: http://127.0.0.1:5000
echo  * Hostname URL:      http://localhost:5000
echo.
echo  * Database: Full Offline Cinema Database (25 Movies, 1000+ Shows)
echo.
echo  * Default Accounts:
echo    - Admin Portal:    admin@cinema.com / admin123
echo    - Customer Login:  rani@cinema.com  / user123
echo.
echo  No internet connection or external cluster needed!
echo =====================================================================
echo.

REM Automatically free port 5000 if lingering from previous run
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":5000" ^| findstr "LISTENING"') do taskkill /F /PID %%a >nul 2>&1

set OFFLINE_MODE=1
echo Opening browser at http://127.0.0.1:5000 ...
start "" http://127.0.0.1:5000
python app.py
pause
