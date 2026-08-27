@echo off
title FiveM Hub Master Launcher
cd /d "%~dp0"

:: 1. CREE AUTOMATIQUEMENT LE RACCOURCI APPLICATION SUR LE VRAI BUREAU WINDOWS
set "SCRIPT_JS=%temp%\create_fivem_shortcut.js"
echo var wsh = new ActiveXObject("WScript.Shell"^); var sc = wsh.CreateShortcut(wsh.SpecialFolders("Desktop"^)^ + "\\FiveM Hub Universe.lnk"^); sc.TargetPath = "%~dp0launcher.bat"; sc.WorkingDirectory = "%~dp0"; sc.IconLocation = "%~dp0logo.ico, 0"; sc.Description = "FiveM Hub Universe - Master Launcher"; sc.WindowStyle = 7; sc.Save(^); > "%SCRIPT_JS%"
cscript //nologo "%SCRIPT_JS%" >nul 2>&1
del "%SCRIPT_JS%" >nul 2>&1

:: 2. VERIFIE ET DEMARRE LE SERVEUR NODE.JS EN ARRIERE-PLAN
netstat -ano | findstr :3000 | findstr LISTENING >nul
if %errorlevel% neq 0 (
    start /b "" node server.js
    timeout /t 1 /nobreak >nul
)

:: 3. NETTOIE LE CACHE TEMPORAIRE POUR CHARGER TOUJOURS LA DERNIERE VERSION
rd /s /q "%temp%\FiveMHubApp" >nul 2>&1

:: 4. OUVRE L'APPLICATION EN LOGICIEL AUTONOME HD SUR VOTRE PC
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
    start "" "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" --app="http://localhost:3000" --window-size=1500,920 --user-data-dir="%temp%\FiveMHubApp" --autoplay-policy=no-user-gesture-required --disk-cache-size=1
) else if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
    start "" "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" --app="http://localhost:3000" --window-size=1500,920 --user-data-dir="%temp%\FiveMHubApp" --autoplay-policy=no-user-gesture-required --disk-cache-size=1
) else if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    start "" "%ProgramFiles%\Google\Chrome\Application\chrome.exe" --app="http://localhost:3000" --window-size=1500,920 --user-data-dir="%temp%\FiveMHubApp" --autoplay-policy=no-user-gesture-required --disk-cache-size=1
) else (
    start "" msedge --app="http://localhost:3000" --window-size=1500,920 --user-data-dir="%temp%\FiveMHubApp" --autoplay-policy=no-user-gesture-required --disk-cache-size=1
)
exit
