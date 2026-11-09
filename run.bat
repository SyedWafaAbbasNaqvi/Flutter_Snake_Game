@echo off
echo Starting Flutter Project: Flutter Snake Game...
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    if exist "%USERPROFILE%\flutter\bin\flutter.bat" set "PATH=%USERPROFILE%\flutter\bin;%PATH%"
    if exist "C:\src\flutter\bin\flutter.bat" set "PATH=C:\src\flutter\bin;%PATH%"
    if exist "C:\flutter\bin\flutter.bat" set "PATH=C:\flutter\bin;%PATH%"
)
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter SDK not found in PATH. Install from https://flutter.dev
    pause
    exit /b 1
)
echo Fetching Flutter dependencies...
if not exist "web" if not exist "windows" if not exist "android" (
    echo Generating native platform targets...
    call flutter create . --suppress-analytics
)
call flutter pub get
echo Launching Flutter App...
call flutter run -d chrome || call flutter run
pause
