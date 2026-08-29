@echo off
setlocal enabledelayedexpansion
title FiveM Hub Master Launcher v4.0
cd /d "%~dp0"
color 0A

echo.
echo  ================================================================
echo   FIVEM HUB MASTER LAUNCHER v4.0
echo  ================================================================
echo.

:: ── Detection de Node.js ──────────────────────────────────────────
set "NODE_EXE="
set "NPM_CMD="

:: 1. Verifier si node est dans le PATH
where node >nul 2>nul
if %errorlevel% equ 0 (
    for /f "delims=" %%i in ('where node') do (
        if not defined NODE_EXE set "NODE_EXE=%%i"
    )
)

:: 2. Verifier dans NVM LocalAppData v22
if not defined NODE_EXE (
    if exist "%LOCALAPPDATA%\nvm\v22.0.0\node.exe" (
        set "NODE_EXE=%LOCALAPPDATA%\nvm\v22.0.0\node.exe"
        set "PATH=%LOCALAPPDATA%\nvm\v22.0.0;!PATH!"
    )
)

:: 3. Verifier dans NVM LocalAppData v26
if not defined NODE_EXE (
    if exist "%LOCALAPPDATA%\nvm\v26.5.0\node.exe" (
        set "NODE_EXE=%LOCALAPPDATA%\nvm\v26.5.0\node.exe"
        set "PATH=%LOCALAPPDATA%\nvm\v26.5.0;!PATH!"
    )
)

:: 4. Verifier Program Files standard
if not defined NODE_EXE (
    if exist "%ProgramFiles%\nodejs\node.exe" (
        set "NODE_EXE=%ProgramFiles%\nodejs\node.exe"
        set "PATH=%ProgramFiles%\nodejs;!PATH!"
    )
)

:: 5. Verifier Program Files x86
if not defined NODE_EXE (
    if exist "%ProgramFiles(x86)%\nodejs\node.exe" (
        set "NODE_EXE=%ProgramFiles(x86)%\nodejs\node.exe"
        set "PATH=%ProgramFiles(x86)%\nodejs;!PATH!"
    )
)

:: 6. Verifier NVM_HOME ou NVM_SYMLINK
if not defined NODE_EXE (
    if defined NVM_SYMLINK (
        if exist "%NVM_SYMLINK%\node.exe" (
            set "NODE_EXE=%NVM_SYMLINK%\node.exe"
            set "PATH=%NVM_SYMLINK%;!PATH!"
        )
    )
)

:: Recuperer NPM
where npm >nul 2>nul
if %errorlevel% equ 0 (
    for /f "delims=" %%i in ('where npm.cmd') do (
        if not defined NPM_CMD set "NPM_CMD=%%i"
    )
)

set "ELECTRON_EXE=%~dp0node_modules\electron\dist\electron.exe"
set "ELECTRON_CLI=%~dp0node_modules\electron\cli.js"

:: ── Si Electron n'est pas installe, lancer l'installation ──────────
if not exist "%ELECTRON_EXE%" (
    echo  [INFO] Verification des dependances...
    if not defined NODE_EXE (
        echo  [ERREUR] Node.js est requis pour installer les modules.
        echo  Veuillez installer Node.js depuis https://nodejs.org
        pause
        exit /b 1
    )
    echo  [INFO] Installation automatique d'Electron et des dependances...
    call npm install
    if !errorlevel! neq 0 (
        echo.
        echo  [ERREUR] L'installation npm a echoue !
        pause
        exit /b 1
    )
    echo  [OK] Dependances installees avec succes.
)

:: ── Lancement de FiveM Hub ─────────────────────────────────────────
echo  [OK] Environnement valide.
echo  [LANCEMENT] Demarrage de FiveM Hub Launcher...
echo.

if exist "%ELECTRON_EXE%" (
    start "" "%ELECTRON_EXE%" "%~dp0."
    exit /b 0
)

if exist "%ELECTRON_CLI%" (
    if defined NODE_EXE (
        start "" "%NODE_EXE%" "%ELECTRON_CLI%" "%~dp0."
        exit /b 0
    )
)

echo  [ERREUR] Impossible de trouver l'executable Electron.
echo  Essayez d'executer 'npm install' dans ce dossier.
pause
exit /b 1
