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
echo  * Database: In-Memory Offline Cinema Database (Full 9 Tables & Data)
echo.
echo  * Default Accounts:
echo    - Admin Portal:    admin@cinema.com / Admin@123
echo    - Customer Login:  rani@cinema.com  / Password@123
echo.
echo  No internet connection or external cluster needed!
echo =====================================================================
echo.
set OFFLINE_MODE=1
echo Opening browser at http://127.0.0.1:5000 ...
timeout /t 2 /nobreak >nul
start "" http://127.0.0.1:5000
python app.py
pause
