# Memory - bunnyOS Dashboard & Automation

## Last Updated: 2026-09-04 (DARI SERVER VPS)

### Session Overview
- bunnyOS adalah game API untuk AI agent (bukan blockchain/crypto)
- Dashboard dibuat untuk monitor & kontrol bunnyOS dari browser
- Automation bot berjalan via cron setiap 30 menit

### DARI SERVER VPS - bunnyOS Account

- **Username**: `mvll` (sebelumnya `opencode_bot`)
- **API Key**: `bos_432b85674b64732783a51bc8efd9a6527f730d68f7b0208ce619519836813d49`
- **Bunny Name**: Bunny
- **Base Power**: 100
- **Mission Slots**: 3
- **Wallet**: Tidak ada (bukan blockchain)
- **Network**: HTTP API biasa ke `world.bunnyos.ai`

### DARI SERVER VPS - Dashboard Setup

- **URL**: `https://37-60-254-107.sslip.io`
- **IP Server**: `37.60.254.107`
- **Folder**: `/root/bunny/`
- **Files**:
  - `index.html` — Dashboard frontend (HTML/CSS/JS)
  - `proxy.js` — Node.js proxy server (CORS + API key injection)
  - `play-bunnyos.sh` — Automation script
  - `play.log` — Log file

### DARI SERVER VPS - Services

| Service | Fungsi | Status |
|---------|--------|--------|
| `caddy-bunny.service` | HTTPS + static files + reverse proxy | active |
| `bunny-proxy.service` | API proxy (port 4664) | active |
| `cron */30 * * * *` | Automation bot | active |

### DARI SERVER VPS - Arsitektur

```
Browser → Caddy (HTTPS, port 443) → Proxy (Node.js, port 4664) → bunnyOS API
                                         ↓
                                    /api/log → baca play.log
```

### DARI SERVER VPS - Dashboard Tabs

1. **Dashboard** — Your Agent panel, Zone missions, Active missions, Events, Ledger, Leaderboard, Mission history
2. **Cara Bermain** — Penjelasan game untuk pemula
3. **Automation Bot** — Alur kerja otomatis, live log

### DARI SERVER VPS - Panel "Your Agent"

- Avatar sprite dari bunnyOS assets
- Equipment slots dengan sprite images (bukan emoji)
- Stats bar: Carrots, Missions, Wins, Rank
- Background: transparent + blur
- Data di-update dari API setiap load

### DARI SERVER VPS - Automation Bot

- **Interval**: 30 menit
- **Step 1**: Cek announcements
- **Step 2**: Claim event rewards
- **Step 3**: Jual loot dari misi selesai
- **Step 4**: Terima misi baru (jika ada slot)
- **Step 5**: Repair gear jika durability < 50%
- **Step 6**: Catat log ke play.log

### DARI SERVER VPS - Live Log

- Endpoint: `/api/log` (proxy baca play.log)
- Auto-refresh: setiap 30 detik
- Colorized: timestamp biru, success hijau, error merah
- 50 baris terakhir
- Timezone: WIB (UTC+7)

### DARI SERVER VPS - Caddy Config

```
37-60-254-107.sslip.io {
    root * /root/bunny
    route {
        handle /api/* { reverse_proxy 127.0.0.1:4664 }
        try_files {path} /index.html
        file_server
    }
    header {
        Cache-Control "no-cache, no-store, must-revalidate"
    }
}
```

### DARI SERVER VPS - Proxy.js

- Port: 4664
- Endpoint `/api/log` → baca `/root/bunny/play.log`
- Endpoint `/api/*` → proxy ke `https://world.bunnyos.ai/v1/*`
- API key di-inject otomatis (tidak perlu di browser)

### DARI SERVER VPS - Play-bunnyos.sh

- Log pakai timezone WIB (`TZ='Asia/Jakarta'`)
- Auto-claim event rewards
- Auto-sell materials dari inventory (bukan dari haul)
- Auto-accept missions (prioritas: gratis → murah → chance tinggi)
- Auto-repair gear
- Error handling: log failed attempts dengan pesan asli

### DARI SERVER VPS - Bug Fixes (2026-09-04)

**play-bunnyos.sh:**
1. `balance: error` setiap sell → Fix: cek HTTP status, tampilkan error asli
2. Sell dari haul (item tidak ada di inventory) → Fix: jual dari inventory materials
3. `while` loop subshell (variabel tidak ter-update) → Fix: pakai `<<< "$VAR"` (here-string)
4. `sort -t, -k4 -n` tidak work pada JSON compact → Fix: pakai jq `sort_by(.mobPower)`
5. `bc` error jika CHANCE null → Fix: tambah `2>/dev/null || echo "?"`
6. Redundant fetch inventory → Fix: hapus duplikat
7. Repair error tidak ter-log → Fix: cek `.error` field

**index.html:**
1. `switchTab()` pakai global `event` (tidak reliable) → Fix: pass `this` sebagai parameter
2. Countdown timer tidak work → Fix: tambah `data-resolve-at` attribute
3. `colorizeLog` tidak handle error baru → Fix: tambah pattern `Sell failed` & `Repair failed`

**Key Insight:**
- Haul items dari misi succeeded **tidak otomatis masuk ke inventory**
- Haul hanya record hasil, bukan item yang bisa dijual
- Item dijual dari inventory materials, bukan dari haul

### DARI SERVER VPS - Key Learnings

1. **CORS**: Browser blokir request cross-origin → solusi: proxy server
2. **API Key**: Jangan expose di frontend → simpan di server-side proxy
3. **Cache**: Browser cache HTML → tambah `Cache-Control: no-cache` header
4. **Timezone**: Script default UTC → set `TZ='Asia/Jakarta'` untuk WIB
5. **Sprites**: bunnyOS punya sprite assets di `https://assets.bunnyos.ai/sprites/`

### DARI SERVER VPS - Commands

```bash
# Restart services
systemctl restart bunny-proxy.service
systemctl restart caddy-bunny.service

# Cek status
systemctl status bunny-proxy.service
systemctl status caddy-bunny.service

# Cek log
tail -50 /root/bunny/play.log

# Manual run automation
/root/bunny/play-bunnyos.sh

# Cek cron
crontab -l | grep bunny

# Test endpoints
curl -s http://127.0.0.1:4664/v1/accounts/me
curl -s http://127.0.0.1:4664/api/log
```
