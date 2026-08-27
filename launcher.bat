@echo off
title FiveM Hub Master Launcher
cd /d "%~dp0"

:: 1. AUTO-UPDATE EN TEMPS REEL DEPUIS GITHUB
git pull origin main >nul 2>&1

:: 2. DEMARRE LE SERVEUR NODE.JS S'IL N'EST PAS ENCORE ACTIF
netstat -ano | findstr :3000 | findstr LISTENING >nul
if %errorlevel% neq 0 (
    start /b "" node server.js
    timeout /t 1 /nobreak >nul
)

:: 2. DETECTE LE NAVIGATEUR DU PC POUR L'OUVERTURE EN VRAIE APPLICATION WINDOWS
set "APP_EXE="
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
    set "APP_EXE=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
) else if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
    set "APP_EXE=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
) else if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    set "APP_EXE=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
) else if exist "%LocalAppData%\Microsoft\Edge\Application\msedge.exe" (
    set "APP_EXE=%LocalAppData%\Microsoft\Edge\Application\msedge.exe"
)

:: 3. INSTALLE LE RACCOURCI APPLICATION SUR LE BUREAU WINDOWS
set "SCRIPT_JS=%temp%\create_fivem_shortcut.js"
if defined APP_EXE (
    echo var wsh = new ActiveXObject("WScript.Shell"^); var sc = wsh.CreateShortcut(wsh.SpecialFolders("Desktop"^)^ + "\\FiveM Hub Launcher.lnk"^); sc.TargetPath = "%APP_EXE%"; sc.Arguments = "--app=http://localhost:3000 --window-size=1500,920 --autoplay-policy=no-user-gesture-required"; sc.WorkingDirectory = "%~dp0"; sc.IconLocation = "%~dp0logo.ico, 0"; sc.Description = "FiveM Hub Launcher - Application Officielle"; sc.Save(^); > "%SCRIPT_JS%"
) else (
    echo var wsh = new ActiveXObject("WScript.Shell"^); var sc = wsh.CreateShortcut(wsh.SpecialFolders("Desktop"^)^ + "\\FiveM Hub Launcher.lnk"^); sc.TargetPath = "%~dp0launcher.bat"; sc.WorkingDirectory = "%~dp0"; sc.IconLocation = "%~dp0logo.ico, 0"; sc.Description = "FiveM Hub Launcher"; sc.WindowStyle = 7; sc.Save(^); > "%SCRIPT_JS%"
)
cscript //nologo "%SCRIPT_JS%" >nul 2>&1
del "%SCRIPT_JS%" >nul 2>&1

:: 4. OUVRE IMMEDIATEMENT L'APPLICATION EN FENETRE LOGICIELLE AUTONOME
rd /s /q "%temp%\FiveMHubApp" >nul 2>&1
if defined APP_EXE (
    start "" "%APP_EXE%" --app="http://localhost:3000" --window-size=1500,920 --user-data-dir="%temp%\FiveMHubApp" --autoplay-policy=no-user-gesture-required --disk-cache-size=1
) else (
    start "" msedge --app="http://localhost:3000" --window-size=1500,920 --user-data-dir="%temp%\FiveMHubApp" --autoplay-policy=no-user-gesture-required --disk-cache-size=1
)
exit
