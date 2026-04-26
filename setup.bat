@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
chcp 65001 >nul

echo ============================================
echo   YouTube Downloader - One-Click Setup
echo ============================================
echo.
echo  This will automatically:
echo    1. Install Python (if needed)
echo    2. Install required packages
echo    3. Download ffmpeg
echo    4. Build YouTube-Downloader.exe
echo.
echo  Total time: about 5-10 minutes.
echo  Please leave this window open until you see DONE.
echo.
echo --------------------------------------------
echo.

REM ============================================
REM  STEP 1 / 4 : Ensure Python is available
REM ============================================
echo [1/4] Checking Python...
set "PYEXE="

REM 1a) Try the system PATH
python --version >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%v in ('python --version') do echo   Found %%v
    set "PYEXE=python"
    goto :have_python
)

REM 1b) Try common per-user install paths
call :find_python
if defined PYEXE goto :have_python

echo   Python not found. Installing automatically...
echo.

REM 1c) Try winget (built into Windows 10/11)
where winget >nul 2>&1
if not errorlevel 1 (
    echo   Installing Python via winget...
    winget install -e --id Python.Python.3.12 --silent --accept-source-agreements --accept-package-agreements --scope user
    call :find_python
    if defined PYEXE goto :have_python
)

REM 1d) Fallback: download official installer and install silently
echo   Downloading Python installer (~30 MB)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ProgressPreference='SilentlyContinue';" ^
    "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
    "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.6/python-3.12.6-amd64.exe' -OutFile 'python-installer.exe'"
if errorlevel 1 (
    echo.
    echo   ERROR: Failed to download Python installer.
    echo   Please check your internet connection and try again.
    pause
    exit /b 1
)

echo   Installing Python silently (this takes 1-2 minutes)...
python-installer.exe /quiet InstallAllUsers=0 PrependPath=1 Include_test=0 Include_pip=1
del /q python-installer.exe

call :find_python
if not defined PYEXE (
    echo.
    echo   ERROR: Python installation failed.
    echo   Please install Python manually from https://www.python.org/downloads/
    pause
    exit /b 1
)

:have_python
echo   Using: !PYEXE!

REM ============================================
REM  STEP 2 / 4 : Create venv + install packages
REM ============================================
echo.
echo [2/4] Setting up Python environment...
if not exist "venv\" (
    "!PYEXE!" -m venv venv
    if errorlevel 1 (
        echo   ERROR: Failed to create virtual environment.
        pause
        exit /b 1
    )
)
call "venv\Scripts\activate.bat"
python -m pip install --upgrade pip >nul 2>&1
echo   Installing Flask, yt-dlp, PyInstaller...
pip install -r requirements.txt pyinstaller
if errorlevel 1 (
    echo.
    echo   ERROR: Failed to install Python packages.
    pause
    exit /b 1
)
echo   Packages installed.

REM ============================================
REM  STEP 3 / 4 : Download ffmpeg
REM ============================================
echo.
echo [3/4] Checking ffmpeg...
if exist "bin\ffmpeg.exe" if exist "bin\ffprobe.exe" (
    echo   ffmpeg already present.
    goto :build
)

if not exist "bin\" mkdir bin
echo   Downloading ffmpeg (~80 MB, may take a few minutes)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ProgressPreference='SilentlyContinue';" ^
    "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
    "Invoke-WebRequest -Uri 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip' -OutFile 'ffmpeg.zip'"
if errorlevel 1 (
    echo   ERROR: Failed to download ffmpeg.
    pause
    exit /b 1
)
echo   Extracting...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ProgressPreference='SilentlyContinue';" ^
    "Expand-Archive -Path 'ffmpeg.zip' -DestinationPath 'ffmpeg-temp' -Force"
if errorlevel 1 (
    echo   ERROR: Failed to extract ffmpeg.
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
    echo   ERROR: ffmpeg copy failed.
    pause
    exit /b 1
)
echo   ffmpeg ready.

REM ============================================
REM  STEP 4 / 4 : Build the exe
REM ============================================
:build
echo.
echo [4/4] Building YouTube-Downloader.exe...
echo   This is the longest step (about 3-5 minutes). Please wait.
echo.
if exist "build\" rmdir /s /q "build"
if exist "dist\"  rmdir /s /q "dist"
if exist "YouTube-Downloader.spec" del /q "YouTube-Downloader.spec"

pyinstaller --onefile --console --noconfirm --clean ^
    --name "YouTube-Downloader" ^
    --add-data "templates;templates" ^
    --add-data "static;static" ^
    --add-binary "bin\ffmpeg.exe;bin" ^
    --add-binary "bin\ffprobe.exe;bin" ^
    app.py
if errorlevel 1 (
    echo.
    echo   ERROR: Build failed. See messages above.
    pause
    exit /b 1
)

if not exist "dist\YouTube-Downloader.exe" (
    echo   ERROR: Build completed but YouTube-Downloader.exe not found.
    pause
    exit /b 1
)

REM Move final exe to project root for easy double-click
move /y "dist\YouTube-Downloader.exe" "YouTube-Downloader.exe" >nul

REM Clean up build artifacts (keep venv for re-builds)
rmdir /s /q "build" 2>nul
rmdir /s /q "dist"  2>nul
del /q "YouTube-Downloader.spec" 2>nul

echo.
echo ============================================
echo                   DONE!
echo ============================================
echo.
echo   YouTube-Downloader.exe is ready in this folder.
echo   Just double-click it any time to use the app.
echo.
echo   You can move the exe anywhere - it works on its own.
echo.
echo --------------------------------------------
echo.

REM Open the folder so the user sees the exe immediately
start "" "%~dp0"

pause
exit /b 0


REM ============================================
REM  Subroutine: locate Python in known paths
REM ============================================
:find_python
for %%P in (
    "%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
    "%ProgramFiles%\Python313\python.exe"
    "%ProgramFiles%\Python312\python.exe"
    "%ProgramFiles%\Python311\python.exe"
) do (
    if exist %%P (
        set "PYEXE=%%~P"
        echo   Found Python at %%~P
        exit /b 0
    )
)
exit /b 1
