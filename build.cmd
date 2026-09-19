@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo [1/2] Building Flutter Web for OneDev Track...
echo Base Href: /track/
echo ===================================================
call flutter build web --base-href "/track/"
if %errorlevel% neq 0 (
    echo [ERROR] Flutter build web failed!
    exit /b %errorlevel%
)

echo.
echo ===================================================
echo [2/2] Build Successful!
echo Web Output Directory: %~dp0build\web
echo ===================================================
echo.
echo Deployment Instructions:
echo  1. Upload contents of "build\web" to VPS path: /home/debian/public_html/track/
echo  2. Upload contents of "api\" to VPS path: /home/debian/public_html/api/
echo Completion Time: %date% - %time:~0,8%
echo.
pause
