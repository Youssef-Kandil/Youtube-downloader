@echo off
cd /d "%~dp0"
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
python app.py
pause
