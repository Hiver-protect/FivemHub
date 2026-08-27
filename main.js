const { app, BrowserWindow, shell, ipcMain } = require('electron');
const path = require('path');

let mainWindow;

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1440,
        height: 900,
        minWidth: 1100,
        minHeight: 700,
        frame: true, // Fenêtre logicielle native
        title: "FiveM Hub Universe - Master Launcher",
        backgroundColor: '#0a0b10',
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false,
            webSecurity: false
        },
        icon: path.join(__dirname, 'icon.ico')
    });

    // Charge directement index.html comme une véritable application logicielle PC
    mainWindow.loadFile('index.html');

    // Intercepte les protocoles FiveM pour les lancer directement sur Windows
    mainWindow.webContents.setWindowOpenHandler(({ url }) => {
        if (url.startsWith('fivem://') || url.startsWith('http')) {
            shell.openExternal(url);
            return { action: 'deny' };
        }
        return { action: 'allow' };
    });

    mainWindow.on('closed', function () {
        mainWindow = null;
    });
}

app.whenReady().then(() => {
    createWindow();

    app.on('activate', function () {
        if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
});

app.on('window-all-closed', function () {
    if (process.platform !== 'darwin') app.quit();
});
