@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
chcp 65001 >nul

echo ============================================
echo   YouTube Downloader - Setup
echo ============================================
echo.

REM ---------- 1) Check Python ----------
echo [1/3] Checking Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo  ERROR: Python is not installed on this computer.
    echo.
    echo  Please install Python first:
    echo    https://www.python.org/downloads/
    echo.
    echo  IMPORTANT: During install, tick "Add Python to PATH".
    echo  Then run setup.bat again.
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('python --version') do echo  Found: %%v

REM ---------- 2) Create venv + install deps ----------
echo.
echo [2/3] Installing Python packages (Flask, yt-dlp)...
if not exist "venv\" (
    python -m venv venv
    if errorlevel 1 (
        echo  ERROR: Failed to create virtual environment.
        pause
        exit /b 1
    )
)
call "venv\Scripts\activate.bat"
python -m pip install --upgrade pip >nul
pip install -r requirements.txt
if errorlevel 1 (
    echo.
    echo  ERROR: Failed to install Python packages.
    pause
    exit /b 1
)

REM ---------- 3) Download ffmpeg ----------
echo.
echo [3/3] Checking ffmpeg...
if exist "bin\ffmpeg.exe" if exist "bin\ffprobe.exe" (
    echo  ffmpeg already installed.
    goto :done
)

if not exist "bin\" mkdir bin
echo  Downloading ffmpeg (~80 MB, this can take a few minutes)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ProgressPreference='SilentlyContinue';" ^
    "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
    "Invoke-WebRequest -Uri 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip' -OutFile 'ffmpeg.zip'"
if errorlevel 1 (
    echo  ERROR: Failed to download ffmpeg. Check your internet connection.
    pause
    exit /b 1
)

echo  Extracting...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ProgressPreference='SilentlyContinue';" ^
    "Expand-Archive -Path 'ffmpeg.zip' -DestinationPath 'ffmpeg-temp' -Force"
if errorlevel 1 (
    echo  ERROR: Failed to extract ffmpeg.
    pause
    exit /b 1
)

for /d %%D in ("ffmpeg-temp\ffmpeg-*") do (
    copy /y "%%D\bin\ffmpeg.exe"  "bin\ffmpeg.exe"  >nul
    copy /y "%%D\bin\ffprobe.exe" "bin\ffprobe.exe" >nul
)
rmdir /s /q "ffmpeg-temp"
del /q "ffmpeg.zip"

if not exist "bin\ffmpeg.exe" (
    echo  ERROR: ffmpeg copy failed.
    pause
    exit /b 1
)
echo  ffmpeg installed.

:done
echo.
echo ============================================
echo   Setup complete!
echo   Double-click run.bat to start the app.
echo ============================================
echo.
pause
