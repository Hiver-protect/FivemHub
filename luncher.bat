@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title FiveM Hub - Cloud Launcher v4.0 (GitHub Auto-Sync)
color 0B

echo.
echo  ========================================================================
echo    ███████╗██╗██╗   ██╗███████╗███╗   ███╗    ██╗  ██╗██╗   ██╗██████╗ 
echo    ██╔════╝██║██║   ██║██╔════╝████╗ ████║    ██║  ██║██║   ██║██╔══██╗
echo    █████╗  ██║██║   ██║█████╗  ██╔████╔██║    ███████║██║   ██║██████╔╝
echo    ██╔══╝  ██║╚██╗ ██╔╝██╔══╝  ██║╚██╔╝██║    ██╔══██║██║   ██║██╔══██╗
echo    ██║     ██║ ╚████╔╝ ███████╗██║ ╚═╝ ██║    ██║  ██║╚██████╔╝██████╔╝
echo  ========================================================================
echo    Portail Officiel FiveM Hub - Auto-Update & Synchronisation GitHub
echo  ========================================================================
echo.

:: ─────────────────────────────────────────────────────────────────────────────
:: DEFINITION DES REPERTOIRES & REPO GITHUB
:: ─────────────────────────────────────────────────────────────────────────────
set "GITHUB_REPO_URL=https://github.com/Hiver-protect/FivemHub.git"
set "GITHUB_ZIP_URL=https://github.com/Hiver-protect/FivemHub/archive/refs/heads/main.zip"
set "APP_DIR=%LOCALAPPDATA%\FivemHub"

:: Si ce script est deja execute dans le dossier complet du launcher
if exist "%~dp0index.html" (
    if exist "%~dp0main.js" (
        set "APP_DIR=%~dp0"
        if "%APP_DIR:~-1%"=="\" set "APP_DIR=%APP_DIR:~0,-1%"
    )
)

if not exist "%APP_DIR%" mkdir "%APP_DIR%" 2>nul
cd /d "%APP_DIR%"

:: ─────────────────────────────────────────────────────────────────────────────
:: 1. TELECHARGEMENT / SYNCHRONISATION VIA GITHUB
:: ─────────────────────────────────────────────────────────────────────────────
echo  [*] Verification des mises a jour depuis GitHub...

set "SYNC_OK="

:: Methode A : Git si installe
where git >nul 2>nul
if %errorlevel% equ 0 (
    if exist "%APP_DIR%\.git" (
        echo  [✓] Synchronisation Git Pull...
        git pull --quiet
        set "SYNC_OK=1"
    ) else (
        echo  [✓] Telechargement initial via Git Clone...
        git clone --depth 1 "%GITHUB_REPO_URL%" "%APP_DIR%\git_temp" >nul 2>nul
        if exist "%APP_DIR%\git_temp" (
            xcopy /E /Y /Q "%APP_DIR%\git_temp\*" "%APP_DIR%\" >nul 2>nul
            rmdir /S /Q "%APP_DIR%\git_temp" 2>nul
            set "SYNC_OK=1"
        )
    )
)

:: Methode B : Curl & PowerShell (100%% autonome sans Git)
if not defined SYNC_OK (
    echo  [*] Telechargement du code source depuis GitHub...
    set "ZIP_TEMP=%TEMP%\fivemhub_latest.zip"
    set "UNZIP_TEMP=%TEMP%\fivemhub_unzip"
    
    curl.exe -L -s -o "!ZIP_TEMP!" "%GITHUB_ZIP_URL%"
    
    if exist "!ZIP_TEMP!" (
        if exist "!UNZIP_TEMP!" rmdir /S /Q "!UNZIP_TEMP!" 2>nul
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '!ZIP_TEMP!' -DestinationPath '!UNZIP_TEMP!' -Force" >nul 2>nul
        
        if exist "!UNZIP_TEMP!\FivemHub-main" (
            xcopy /E /Y /Q "!UNZIP_TEMP!\FivemHub-main\*" "%APP_DIR%\" >nul 2>nul
            set "SYNC_OK=1"
        )
        
        del /f /q "!ZIP_TEMP!" 2>nul
        rmdir /S /Q "!UNZIP_TEMP!" 2>nul
    )
)

if not exist "%APP_DIR%\index.html" (
    echo  [ERREUR] Impossible de recuperer les fichiers depuis GitHub.
    echo  Verifiez votre connexion Internet.
    pause
    exit /b 1
)

echo  [✓] Fichiers FiveM Hub a jour !
echo.

:: ─────────────────────────────────────────────────────────────────────────────
:: 2. VERIFICATION DE L'ENVIRONNEMENT ELECTRON / NODE.JS
:: ─────────────────────────────────────────────────────────────────────────────
set "ELECTRON_EXE=%APP_DIR%\node_modules\electron\dist\electron.exe"
set "ELECTRON_CLI=%APP_DIR%\node_modules\electron\cli.js"

:: Si Electron existe deja, lancement direct ultra-rapide
if exist "%ELECTRON_EXE%" (
    echo  [🚀] Lancement de FiveM Hub en mode Bureau 144 FPS...
    start "" "%ELECTRON_EXE%" "%APP_DIR%"
    timeout /t 2 >nul
    exit /b 0
)

:: Recherche de Node.js
set "NODE_EXE="
where node >nul 2>nul
if %errorlevel% equ 0 (
    for /f "delims=" %%i in ('where node') do (
        if not defined NODE_EXE set "NODE_EXE=%%i"
    )
)

if not defined NODE_EXE if exist "%LOCALAPPDATA%\nvm\v22.0.0\node.exe" set "NODE_EXE=%LOCALAPPDATA%\nvm\v22.0.0\node.exe"
if not defined NODE_EXE if exist "%LOCALAPPDATA%\nvm\v26.5.0\node.exe" set "NODE_EXE=%LOCALAPPDATA%\nvm\v26.5.0\node.exe"
if not defined NODE_EXE if exist "%ProgramFiles%\nodejs\node.exe" set "NODE_EXE=%ProgramFiles%\nodejs\node.exe"
if not defined NODE_EXE if exist "%ProgramFiles(x86)%\nodejs\node.exe" set "NODE_EXE=%ProgramFiles(x86)%\nodejs\node.exe"
if not defined NODE_EXE if defined NVM_SYMLINK if exist "%NVM_SYMLINK%\node.exe" set "NODE_EXE=%NVM_SYMLINK%\node.exe"

if defined NODE_EXE (
    for %%p in ("%NODE_EXE%") do set "NODE_DIR=%%~dpp"
    set "PATH=!NODE_DIR!;!PATH!"
    
    echo  [*] Installation / Verification des dependances requises...
    call npm install --no-audit --no-fund
    
    if exist "%ELECTRON_EXE%" (
        echo  [🚀] Lancement de FiveM Hub Desktop...
        start "" "%ELECTRON_EXE%" "%APP_DIR%"
        timeout /t 2 >nul
        exit /b 0
    )
    
    if exist "%ELECTRON_CLI%" (
        echo  [🚀] Lancement via CLI...
        start "" "%NODE_EXE%" "%ELECTRON_CLI%" "%APP_DIR%"
        timeout /t 2 >nul
        exit /b 0
    )
)

:: ─────────────────────────────────────────────────────────────────────────────
:: 3. MODE INSTANTANE ZERO-INSTALLATION (POUR N'IMPORTE QUEL PC)
:: ─────────────────────────────────────────────────────────────────────────────
echo.
echo  ========================================================================
echo   [★] Lancement automatique en Mode Web Portable Ultra-Fluide...
echo  ========================================================================
echo.

set "LAUNCHED="

if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
    start "" "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" --app="%APP_DIR%\index.html"
    set "LAUNCHED=1"
)

if not defined LAUNCHED if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
    start "" "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" --app="%APP_DIR%\index.html"
    set "LAUNCHED=1"
)

if not defined LAUNCHED if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    start "" "%ProgramFiles%\Google\Chrome\Application\chrome.exe" --app="%APP_DIR%\index.html"
    set "LAUNCHED=1"
)

if not defined LAUNCHED (
    start "" "%APP_DIR%\index.html"
)

echo  [✓] FiveM Hub demarre avec succes !
echo.
echo  [CONSEIL] Pour le mode Bureau et Discord RPC, installez Node.js :
echo            https://nodejs.org/
echo.
timeout /t 3 >nul
exit /b 0
