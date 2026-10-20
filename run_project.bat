@echo off
title Smart Cinema Ticket Hub
echo ===================================================
echo   Starting Smart Cinema Ticket Hub Web Server
echo ===================================================
echo Opening your browser at http://127.0.0.1:5000 ...
timeout /t 2 /nobreak >nul
start "" http://127.0.0.1:5000
python app.py
pause
