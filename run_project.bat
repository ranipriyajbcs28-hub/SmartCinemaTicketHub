@echo off
title Smart Cinema Ticket Hub (Local & Offline Server)
cls
echo =====================================================================
echo           SMART CINEMA TICKET HUB — WEB APPLICATION
echo =====================================================================
echo.
echo  * Local Offline URL: http://127.0.0.1:5000
echo  * Network Host URL:  http://localhost:5000
echo.
echo  * Default Login Credentials:
echo    - Admin Portal:    admin@cinema.com / Admin@123
echo    - Customer Login:  rani@cinema.com  / Password@123
echo.
echo  * Database Mode: Dual-Engine (MongoDB Atlas Cloud + Local Database)
echo =====================================================================
echo.
echo Launching your web browser at http://127.0.0.1:5000 ...
timeout /t 2 /nobreak >nul
start "" http://127.0.0.1:5000
python app.py
pause
