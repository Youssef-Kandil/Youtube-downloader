@echo off
cd /d "%~dp0"
chcp 65001 >nul

REM Use venv Python if setup.bat was run, otherwise fall back to system Python
if exist "venv\Scripts\python.exe" (
    set "PYTHON=venv\Scripts\python.exe"
) else (
    set "PYTHON=python"
)

REM Quick sanity check: did the user run setup.bat?
if not exist "venv\Scripts\python.exe" (
    echo.
    echo  WARNING: It looks like setup.bat hasn't been run yet.
    echo  Please run setup.bat first (double-click it), then try again.
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   YouTube Downloader
echo ============================================
echo.
echo  Open in browser:  http://127.0.0.1:5000
echo.
echo  (Press Ctrl+C to stop)
echo.
start "" http://127.0.0.1:5000
"%PYTHON%" app.py
pause
