/**
 * FIVEM HUB LAUNCHER - Discord Rich Presence Module
 * Connexion directe au client Discord via Named Pipe Windows
 * Aucune dépendance npm - protocole natif Discord IPC
 */

'use strict';

const net  = require('net');
const os   = require('os');
const path = require('path');

// Client ID de ton application Discord (à créer sur https://discord.com/developers)
// Pour l'instant on utilise un ID générique - l'app affichera "FiveM Hub Launcher"
const CLIENT_ID = '1379038200000000000'; // Remplace par ton vrai Client ID Discord

const OPCodes = { HANDSHAKE: 0, FRAME: 1, CLOSE: 2, PING: 3, PONG: 4 };

class DiscordRPC {
    constructor() {
        this.socket      = null;
        this.connected   = false;
        this.nonce       = 0;
        this.activity    = null;
        this.retryTimer  = null;
        this.startTime   = Math.floor(Date.now() / 1000);
        this._buf        = Buffer.alloc(0);
    }

    // ── Utilitaires ────────────────────────────────────────────────────────────

    _getPipePath(i) {
        if (process.platform === 'win32') {
            return `\\\\?\\pipe\\discord-ipc-${i}`;
        }
        const tmp = process.env.XDG_RUNTIME_DIR
                 || process.env.TMPDIR
                 || process.env.TMP
                 || process.env.TEMP
                 || '/tmp';
        return path.join(tmp, `discord-ipc-${i}`);
    }

    _encode(op, payload) {
        const data = JSON.stringify(payload);
        const len  = Buffer.byteLength(data);
        const buf  = Buffer.alloc(8 + len);
        buf.writeUInt32LE(op,  0);
        buf.writeUInt32LE(len, 4);
        buf.write(data,        8, 'utf8');
        return buf;
    }

    _send(op, payload) {
        if (!this.socket || !this.connected) return;
        try { this.socket.write(this._encode(op, payload)); } catch(e) {}
    }

    // ── Connexion ──────────────────────────────────────────────────────────────

    connect() {
        this._tryPipe(0);
    }

    _tryPipe(index) {
        if (index > 9) {
            // Aucun pipe trouvé — Discord n'est probablement pas ouvert
            this._scheduleRetry();
            return;
        }

        const pipePath = this._getPipePath(index);
        const socket   = net.createConnection(pipePath);

        socket.once('connect', () => {
            this.socket    = socket;
            this.connected = true;
            this._setupHandlers(socket);
            this._handshake();
        });

        socket.once('error', () => {
            this._tryPipe(index + 1);
        });
    }

    _setupHandlers(socket) {
        socket.on('data', (chunk) => {
            this._buf = Buffer.concat([this._buf, chunk]);
            this._processBuffer();
        });

        socket.on('close', () => {
            this.connected = false;
            this.socket    = null;
            this._buf      = Buffer.alloc(0);
            this._scheduleRetry();
        });

        socket.on('error', () => {
            this.connected = false;
            this.socket    = null;
        });
    }

    _handshake() {
        this._send(OPCodes.HANDSHAKE, { v: 1, client_id: CLIENT_ID });
    }

    _processBuffer() {
        while (this._buf.length >= 8) {
            const op  = this._buf.readUInt32LE(0);
            const len = this._buf.readUInt32LE(4);
            if (this._buf.length < 8 + len) break;

            const payload = JSON.parse(this._buf.slice(8, 8 + len).toString('utf8'));
            this._buf     = this._buf.slice(8 + len);

            this._onMessage(op, payload);
        }
    }

    _onMessage(op, payload) {
        if (op === OPCodes.FRAME) {
            const evt = payload.evt;
            const cmd = payload.cmd;

            if (cmd === 'DISPATCH' && evt === 'READY') {
                // Discord RPC est prêt - on peut envoyer l'activité
                this._setActivityNow();
            }
        }
        if (op === OPCodes.PING) {
            this._send(OPCodes.PONG, payload);
        }
    }

    // ── Rich Presence ──────────────────────────────────────────────────────────

    _setActivityNow() {
        if (!this.activity) return;
        const nonce = String(++this.nonce);
        this._send(OPCodes.FRAME, {
            cmd:  'SET_ACTIVITY',
            args: {
                pid:      process.pid,
                activity: this.activity
            },
            nonce
        });
    }

    /**
     * Met à jour la présence Discord
     * @param {Object} opts
     */
    setActivity(opts = {}) {
        this.activity = {
            details:    opts.details    || 'FiveM Hub Launcher',
            state:      opts.state      || 'En ligne',
            timestamps: {
                start: this.startTime
            },
            assets: {
                large_image: opts.largeImage || 'fivem_hub_logo',
                large_text:  opts.largeText  || 'FiveM Hub Master Launcher v4.0',
                small_image: opts.smallImage || 'discord_green',
                small_text:  opts.smallText  || '🟢 En ligne'
            },
            buttons: [
                {
                    label: '⬇️ Installer FiveM Hub',
                    url:   'https://fivem.net'
                },
                {
                    label: '💬 Rejoindre le Discord',
                    url:   opts.discordInvite || 'https://discord.gg/fivemhub'
                }
            ]
        };

        if (this.connected) {
            this._setActivityNow();
        }
    }

    clearActivity() {
        this.activity = null;
        const nonce = String(++this.nonce);
        this._send(OPCodes.FRAME, {
            cmd:  'SET_ACTIVITY',
            args: { pid: process.pid, activity: null },
            nonce
        });
    }

    destroy() {
        clearTimeout(this.retryTimer);
        if (this.socket) {
            try { this.socket.destroy(); } catch(e) {}
        }
        this.connected = false;
        this.socket    = null;
    }

    _scheduleRetry() {
        clearTimeout(this.retryTimer);
        // Tentative de reconnexion toutes les 15 secondes
        this.retryTimer = setTimeout(() => this.connect(), 15000);
    }
}

module.exports = DiscordRPC;
