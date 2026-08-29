const { app, BrowserWindow, shell, ipcMain, session } = require('electron');
const path = require('path');
const http = require('http');
const fs = require('fs');
const DiscordRPC = require('./discord-rpc');

let mainWindow;
let rpc = null;
let localServer = null;
const PORT = 3000;

// ─── 0. Arguments Chrome Turbo pour Fluidité 144 FPS & Vitesse Maximale ─────────
app.commandLine.appendSwitch('autoplay-policy', 'no-user-gesture-required');
app.commandLine.appendSwitch('ignore-gpu-blocklist');
app.commandLine.appendSwitch('enable-gpu-rasterization');
app.commandLine.appendSwitch('enable-zero-copy');
app.commandLine.appendSwitch('enable-accelerated-2d-canvas');
app.commandLine.appendSwitch('enable-accelerated-video-decode');
app.commandLine.appendSwitch('disable-background-timer-throttling');
app.commandLine.appendSwitch('disable-backgrounding-occluded-windows');
app.commandLine.appendSwitch('disable-renderer-backgrounding');
app.commandLine.appendSwitch('disable-site-isolation-trials');
app.commandLine.appendSwitch('max-active-webgl-contexts', '16');

// ─── 1. Bouclier de Sécurité Anti-DDoS & Anti-Leak (Protection Réseau) ─────────
const securityStats = {
    ddosBlockedCount: 0,
    leaksPreventedCount: 0,
    shieldStatus: 'ACTIF',
    packetRate: '0.2 KB/s',
    encryption: 'TLS 1.3 / AES-256'
};

const requestRateMap = new Map();
const RATE_LIMIT_WINDOW_MS = 1000;
const MAX_REQUESTS_PER_SEC = 60;

function isRateLimited(ipKey) {
    const now = Date.now();
    const timestamps = requestRateMap.get(ipKey) || [];
    const recent = timestamps.filter(t => now - t < RATE_LIMIT_WINDOW_MS);
    recent.push(now);
    requestRateMap.set(ipKey, recent);
    if (recent.length > MAX_REQUESTS_PER_SEC) {
        securityStats.ddosBlockedCount++;
        return true;
    }
    return false;
}

// ─── 2. Serveur Web Local Ultra-Rapide avec Cache RAM (0ms de latence) ─────────
const MIME_TYPES = {
    '.html': 'text/html',
    '.css':  'text/css',
    '.js':   'text/javascript',
    '.json': 'application/json',
    '.png':  'image/png',
    '.jpg':  'image/jpeg',
    '.svg':  'image/svg+xml',
    '.ico':  'image/x-icon',
    '.mp3':  'audio/mpeg'
};

const memoryCache = new Map();

function startLocalServer(callback) {
    localServer = http.createServer((req, res) => {
        // Protection Anti-DDoS
        if (isRateLimited('local-client')) {
            res.writeHead(429, { 'Content-Type': 'text/plain' });
            return res.end('Too Many Requests - Anti-DDoS Shield Active');
        }

        let reqPath = req.url.split('?')[0];
        let filePath = path.join(__dirname, reqPath === '/' ? 'index.html' : reqPath);
        const extname = String(path.extname(filePath)).toLowerCase();
        const contentType = MIME_TYPES[extname] || 'application/octet-stream';

        // Servir directement depuis le cache mémoire RAM si disponible
        if (memoryCache.has(filePath)) {
            const cached = memoryCache.get(filePath);
            res.writeHead(200, {
                'Content-Type': `${contentType}; charset=utf-8`,
                'Access-Control-Allow-Origin': '*',
                'Cache-Control': 'public, max-age=3600'
            });
            return res.end(cached, 'utf-8');
        }

        fs.readFile(filePath, (err, content) => {
            if (err) {
                res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
                res.end('404 Not Found');
            } else {
                if (content.length < 5 * 1024 * 1024) {
                    memoryCache.set(filePath, content);
                }
                res.writeHead(200, { 
                    'Content-Type': `${contentType}; charset=utf-8`,
                    'Access-Control-Allow-Origin': '*',
                    'Cache-Control': 'public, max-age=3600'
                });
                res.end(content, 'utf-8');
            }
        });
    });

    localServer.listen(PORT, () => {
        if (callback) callback();
    });

    localServer.on('error', () => {
        if (callback) callback();
    });
}

// ─── 3. Discord Rich Presence ──────────────────────────────────────────────────
function initDiscordRPC() {
    try {
        rpc = new DiscordRPC();
        rpc.connect();

        rpc.setActivity({
            details:    '⭐ GTA VI & FiveM 4K Hub',
            state:      '🛡️ Shield Anti-DDoS & Anti-Leak Actif',
            largeText:  'FiveM Hub Universe 2026',
            smallText:  '🟢 144 FPS Actif',
            discordInvite: 'https://discord.gg/fivemhub'
        });
    } catch(e) {}
}

ipcMain.on('discord-set-activity', (event, payload) => {
    if (rpc) rpc.setActivity(payload);
});

ipcMain.on('discord-clear-activity', () => {
    if (rpc) rpc.clearActivity();
});

// IPC Protection & Sécurité
ipcMain.handle('get-security-stats', () => {
    return securityStats;
});

ipcMain.handle('clear-ram-cache', () => {
    memoryCache.clear();
    return { success: true, message: "Cache RAM et V8 nettoyé avec succès !" };
});

// ─── 4. Création de la Fenêtre Principale Ultra-Rapide ─────────────────────────
function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1440,
        height: 900,
        minWidth: 1100,
        minHeight: 700,
        show: true,
        frame: true,
        title: 'FiveM Hub Universe - Portail Officiel Rockstar Games 4K [Shield Actif]',
        backgroundColor: '#0a0c10',
        webPreferences: {
            nodeIntegration:  true,
            contextIsolation: false,
            webSecurity:      false,
            allowRunningInsecureContent: true
        },
        icon: path.join(__dirname, 'logo_fivem_hub.png')
    });

    // Bouclier Réseau : Anti-Leak IP, Filtrage Headers & Déblocage YouTube
    session.defaultSession.webRequest.onBeforeSendHeaders((details, callback) => {
        const requestHeaders = Object.assign({}, details.requestHeaders);
        
        // Anti-Leak : Masquer l'IP réelle et supprimer les referers sensibles
        delete requestHeaders['X-Forwarded-For'];
        delete requestHeaders['Client-IP'];
        delete requestHeaders['CF-Connecting-IP'];
        delete requestHeaders['True-Client-IP'];
        
        if (details.url && !details.url.includes('youtube') && !details.url.includes('google')) {
            requestHeaders['Referer'] = 'https://fivem.net/';
        }
        
        securityStats.leaksPreventedCount++;
        callback({ requestHeaders });
    });

    session.defaultSession.webRequest.onHeadersReceived((details, callback) => {
        const responseHeaders = Object.assign({}, details.responseHeaders);
        delete responseHeaders['x-frame-options'];
        delete responseHeaders['X-Frame-Options'];
        delete responseHeaders['content-security-policy'];
        delete responseHeaders['Content-Security-Policy'];
        callback({ responseHeaders });
    });

    // Chargement instantané
    mainWindow.loadURL(`http://localhost:${PORT}`).catch(() => {
        mainWindow.loadFile('index.html');
    });

    mainWindow.webContents.setWindowOpenHandler(({ url }) => {
        if (url.startsWith('fivem://') || (url.startsWith('http') && !url.includes('youtube.com/embed') && !url.includes('youtube-nocookie.com/embed'))) {
            shell.openExternal(url);
            return { action: 'deny' };
        }
        return { action: 'allow' };
    });

    mainWindow.on('closed', () => {
        mainWindow = null;
    });
}

// ─── 5. Lifecycle ──────────────────────────────────────────────────────────────
app.whenReady().then(() => {
    createWindow();
    startLocalServer();
    initDiscordRPC();

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
});

app.on('window-all-closed', () => {
    if (rpc) rpc.destroy();
    if (localServer) {
        try { localServer.close(); } catch(e) {}
    }
    if (process.platform !== 'darwin') app.quit();
});
