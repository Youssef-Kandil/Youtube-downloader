@echo off
cd /d "%~dp0"
chcp 65001 >nul

echo ============================================
echo   Rebuilding YouTube-Downloader.exe
echo ============================================
echo.

if not exist "venv\Scripts\activate.bat" (
    echo  ERROR: venv not found. Run setup.bat first.
    pause
    exit /b 1
)
if not exist "bin\ffmpeg.exe" (
    echo  ERROR: ffmpeg not found in bin\. Run setup.bat first.
    pause
    exit /b 1
)

call "venv\Scripts\activate.bat"

if exist "build\" rmdir /s /q "build"
if exist "dist\"  rmdir /s /q "dist"
if exist "YouTube-Downloader.spec" del /q "YouTube-Downloader.spec"
if exist "YouTube-Downloader.exe"  del /q "YouTube-Downloader.exe"

echo  Building (3-5 minutes)...
pyinstaller --onefile --console --noconfirm --clean ^
    --name "YouTube-Downloader" ^
    --add-data "templates;templates" ^
    --add-data "static;static" ^
    --add-binary "bin\ffmpeg.exe;bin" ^
    --add-binary "bin\ffprobe.exe;bin" ^
    app.py
if errorlevel 1 (
    echo  ERROR: Build failed.
    pause
    exit /b 1
)

move /y "dist\YouTube-Downloader.exe" "YouTube-Downloader.exe" >nul
rmdir /s /q "build" 2>nul
rmdir /s /q "dist"  2>nul
del /q "YouTube-Downloader.spec" 2>nul

echo.
echo  DONE! YouTube-Downloader.exe rebuilt.
echo.
pause
