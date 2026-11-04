@echo off
title Smart Cinema Ticket Hub (100% Offline Mode)
cls
echo =====================================================================
echo           SMART CINEMA TICKET HUB — 100% OFFLINE MODE
echo =====================================================================
echo.
echo  * Localhost URL:   http://127.0.0.1:5000
echo  * Alternative URL: http://localhost:5000
echo.
echo  * Default Accounts:
echo    - Admin Portal:    admin@cinema.com / admin123
echo    - Customer Login:  rani@cinema.com  / user123
echo.
echo  No internet connection or external cluster required!
echo =====================================================================
echo.

cd /d "%~dp0"

REM 1. Detect Working Python Executable
set PYTHON_EXE=
if exist "%LOCALAPPDATA%\Programs\Python\Python313\python.exe" set PYTHON_EXE="%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
if "%PYTHON_EXE%"=="" if exist "C:\Users\RANI PRIYA\AppData\Local\Programs\Python\Python313\python.exe" set PYTHON_EXE="C:\Users\RANI PRIYA\AppData\Local\Programs\Python\Python313\python.exe"
if "%PYTHON_EXE%"=="" if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" set PYTHON_EXE="%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
if "%PYTHON_EXE%"=="" if exist "C:\Python313\python.exe" set PYTHON_EXE="C:\Python313\python.exe"
if "%PYTHON_EXE%"=="" set PYTHON_EXE=python

echo [1/3] Using Python: %PYTHON_EXE%
%PYTHON_EXE% --version
if errorlevel 1 (
    echo.
    echo [ERROR] Python failed to start.
    echo Please make sure Python 3.10+ is installed on your computer.
    pause
    exit /b 1
)

REM 2. Free port 5000 if occupied
echo [2/3] Checking port 5000...
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":5000" ^| findstr "LISTENING"') do taskkill /F /PID %%a >nul 2>&1

REM 3. Set Offline Mode & Start Server
echo [3/3] Starting offline cinema server...
set OFFLINE_MODE=1
set FLASK_ENV=production
set FLASK_DEBUG=0
set PYTHONIOENCODING=utf-8

echo.
echo  ===================================================================
echo   Server is running successfully!
echo   Click or open in your browser:
echo   --> http://127.0.0.1:5000
echo   --> http://localhost:5000
echo  ===================================================================
echo.

REM Automatically open browser in 2 seconds
start "" cmd /c "timeout /t 2 /nobreak >nul && start http://127.0.0.1:5000"

%PYTHON_EXE% app.py
if errorlevel 1 (
    echo.
    echo [ERROR] The server stopped with an error.
    pause
)
