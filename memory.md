# Memory - bunnyOS Dashboard & Automation

## Last Updated: 2026-09-04 18:50 WIB (DARI SERVER VPS)

### Session Overview
- bunnyOS adalah game API untuk AI agent (bukan blockchain/crypto)
- Dashboard dibuat untuk monitor & kontrol bunnyOS dari browser
- Automation bot berjalan via cron setiap 30 menit
- **Branding**: MvLL Bunny Agents Platforms
- **Version**: Dashboard v2.0 + Automation Bot v2

### DARI SERVER VPS - bunnyOS Account

- **Username**: `mvll` (sebelumnya `opencode_bot`)
- **API Key**: `bos_432b85674b64732783a51bc8efd9a6527f730d68f7b0208ce619519836813d49`
- **Bunny Name**: Bunny
- **Base Power**: 100
- **Mission Slots**: 3
- **Current Carrots**: ~816.63
- **Current Power**: 107 (dengan Straw Hat rusak)
- **Wallet**: Tidak ada (bukan blockchain)
- **Network**: HTTP API biasa ke `world.bunnyos.ai`

### DARI SERVER VPS - Current Equipment Status

| Slot | Item | Power | Durability | Status |
|------|------|-------|------------|--------|
| Helm | Straw Hat | 7 | 0/18 | Rusak (tidak bisa repair saat misi aktif) |
| Weapon | Straw Flail | 8 | 18/18 | Tersedia (belum equip) |
| Armour | Straw Tunic | 7 | 18/18 | Tersedia (belum equip) |
| Boots | Straw Sandals | 6 | 18/18 | Tersedia (belum equip) |
| Charm | Straw Doll | 5 | 12/12 | Tersedia (belum equip) |

**Total Power Potential**: 100 (base) + 33 (equipment) = 133

### DARI SERVER VPS - Active Missions (saat update)

1. Scrounge the Hedgerows → selesai ~19:00 WIB
2. Tall Grass → selesai ~18:50 WIB
3. Scrounge the Hedgerows → selesai ~20:00 WIB

**Loadout Lock**: Equipment tidak bisa di-swap/repair saat misi aktif

### DARI SERVER VPS - Onboarding Events Status

| Event | Status | Reward |
|-------|--------|--------|
| Meet your bunny | ✅ Claimed | 50 carrots |
| Wear a Straw Hat | ✅ Claimed | 50 carrots |
| Three wins on the board | ✅ Claimed | 150 carrots |
| Stock up on Timber | ✅ Claimed (auto) | 75 carrots |
| Cut two Planks | ✅ Claimed (auto) | 100 carrots |
| Twist two Ropes | ✅ Claimed (auto) | 75 carrots |
| Craft a Slingshot | ❌ Belum (loadout lock) | 375 carrots |
| Wear the Slingshot | ❌ Belum | 75 carrots |
| Patch something up | ❌ Belum (loadout lock) | 200 carrots |
| Sell to the buyback | ✅ Claimed | 75 carrots |
| Finish your first daily | ✅ Claimed | 250 carrots |
| Take on Tall Grass | ✅ Claimed | 375 carrots |

**Total Onboarding Rewards Claimed**: ~1050 carrots
**Total Onboarding Rewards Pending**: ~650 carrots (akan diklaim otomatis setelah misi selesai)

### DARI SERVER VPS - Daily Events Status

| Event | Progress | Target | Reward |
|-------|----------|--------|--------|
| Sixty points of repair | 0/60 | 60 durability | 75 carrots |
| Spend 600 carrots | 167.18/600 | 600 carrots | 100 carrots |
| Reach the Old Orchard | 0/1 | 1 win (mob≥320) | 100 carrots |

### DARI SERVER VPS - Dashboard Setup

- **URL**: `https://37-60-254-107.sslip.io`
- **IP Server**: `37.60.254.107`
- **Folder**: `/root/bunny/`
- **Files**:
  - `index.html` — Dashboard frontend v2.0 (HTML/CSS/JS)
  - `proxy.js` — Node.js proxy server (CORS + API key injection)
  - `play-bunnyos.sh` — Automation script v2
  - `play-bunnyos.sh.backup-*` — Backup script lama
  - `play.log` — Log file

### DARI SERVER VPS - Branding (2026-09-04)

- **Platform Name**: MvLL Bunny Agents Platforms
- **Tagline**: MMoRPG world war AI Agents Automation - by MvLL
- **Icon**: Custom SVG cyborg rabbit (LED eyes, circuit visor, antenna whiskers, cyber boots)
- **Favicon**: SVG cyborg rabbit inline

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
3. **Automation Bot v2** — Alur kerja otomatis 8 steps, live log, loadout lock info

### DARI SERVER VPS - Panel "Your Agent"

- Avatar sprite dari bunnyOS assets
- Equipment slots dengan sprite images (bukan emoji)
- Stats bar: Carrots, Missions, Wins, Rank
- Background: transparent + blur
- Data di-update dari API setiap load
- Power calculation: base 100 + equipped gear power

### DARI SERVER VPS - Automation Bot v2

- **Interval**: 30 menit
- **Step 1**: Cek announcements
- **Step 2**: Claim event rewards
- **Step 3**: Equip semua gear (hanya saat 0 misi aktif)
- **Step 4**: Craft & claim onboarding events (hanya saat 0 misi aktif)
- **Step 5**: Jual loot dengan smart selling (simpan 5 item crafting)
- **Step 6**: Terima misi baru (prioritas gratis, skip misi >15 carrots)
- **Step 7**: Repair gear jika durability < 50% (hanya saat 0 misi aktif)
- **Step 8**: Catat log ke play.log

### DARI SERVER VPS - Automation Bot v2 Features

- **Loadout Lock Handling**: Equip, craft, repair hanya saat tidak ada misi aktif
- **Onboarding Auto-completion**: Buy timber, craft planks/ropes/slingshot → +625 carrots
- **Smart Material Selling**: Simpan 5 item crafting materials, jual excess
- **Optimized Mission Selection**: Prioritas misi gratis (cost=0), skip misi >15 carrots
- **Colorized Log**: Warna berbeda untuk equip, craft, onboarding, repair

### DARI SERVER VPS - Strategi Misi v2

| Prioritas | Misi | Cost | Chance | Alasan |
|-----------|------|------|--------|--------|
| #1 | Scrounge the Hedgerows | 0 | 94% | Gratis, hampir pasti menang |
| #2 | Garden's Edge | ~5 | 85% | Murah, chance tinggi |
| #3 | Open Field | ~10 | 63% | Medium cost, decent chance |
| SKIP | Tall Grass | ~10 | 42% | Chance terlalu rendah |
| SKIP | Old Orchard | ~32 | — | Terlalu mahal |
| SKIP | Hedgerow Maze | ~24 | 17% | Chance terlalu rendah |

### DARI SERVER VPS - Mission Success Rate Analysis

**Historical Performance (last 15 missions):**
- Scrounge the Hedgerows: 100% success (4/4)
- Garden's Edge: 66% success (2/3)
- Open Field: 50% success (1/2)
- Tall Grass: 50% success (1/2)
- Hedgerow Maze: 0% success (0/1)

**Key Insight**: Misi gratis dan murah lebih menguntungkan dalam jangka panjang

### DARI SERVER VPS - Gear Progression Path

**Tier 1 (Current)**: Straw Set
- Power: 133 (dengan semua gear)
- Misi target: Scrounge, Garden's Edge
- Status: 4/5 gear tersedia, 1 rusak

**Tier 2 (Next)**: Wooden/Slingshot Set
- Power: ~180-200
- Misi target: Tall Grass, Open Field
- Craft: Slingshot (40 power), Woven Cap (40), Fiber Tunic (42), Rope Sandals (40)
- Requirements: Plank, Rope, Dust Tuft, Woven Cloth

**Tier 3 (Future)**: Chitin/Bark Set
- Power: ~300-400
- Misi target: Hedgerow Maze, Old Orchard
- Requirements: Chitin, Resin Glue, Iron Ingot

### DARI SERVER VPS - Live Log

- Endpoint: `/api/log` (proxy baca play.log)
- Auto-refresh: setiap 30 detik
- Colorized: timestamp biru, success hijau, error merah
- 50 baris terakhir
- Timezone: WIB (UTC+7)
- Pattern matching: equip, craft, onboarding, repair, skip operations

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

### DARI SERVER VPS - Play-bunnyos.sh v2

- Log pakai timezone WIB (`TZ='Asia/Jakarta'`)
- Auto-claim event rewards
- Auto-equip semua gear (saat loadout tidak terkunci)
- Auto-craft onboarding events (saat loadout tidak terkunci)
- Auto-sell materials dengan smart selling (simpan 5 item crafting)
- Auto-accept missions (prioritas: gratis → murah → chance tinggi)
- Auto-repair gear (saat loadout tidak terkunci)
- Error handling: log failed attempts dengan pesan asli
- Loadout lock detection: skip operasi yang terkunci

### DARI SERVER VPS - Bug Fixes (2026-09-04)

**play-bunnyos.sh v1:**
1. `balance: error` setiap sell → Fix: cek HTTP status, tampilkan error asli
2. Sell dari haul (item tidak ada di inventory) → Fix: jual dari inventory materials
3. `while` loop subshell (variabel tidak ter-update) → Fix: pakai `<<< "$VAR"` (here-string)
4. `sort -t, -k4 -n` tidak work pada JSON compact → Fix: pakai jq `sort_by(.mobPower)`
5. `bc` error jika CHANCE null → Fix: tambah `2>/dev/null || echo "?"`
6. Redundant fetch inventory → Fix: hapus duplikat
7. Repair error tidak ter-log → Fix: cek `.error` field

**play-bunnyos.sh v2:**
1. Equipment data structure salah (nested vs flat) → Fix: gunakan `.slot`, `.power` langsung
2. Equip saat misi aktif → Fix: cek active missions sebelum equip
3. Craft saat misi aktif → Fix: cek active missions sebelum craft
4. Jual semua materials termasuk yang dibutuhkan → Fix: simpan 5 item crafting
5. Misi mahal (>15 carrots) → Fix: skip misi mahal

**play-bunnyos.sh v2.1 (2026-09-04 21:15):**
1. Craft Slingshot gagal "Conflict" → Fix: cek material (dust_tuft/plank/rope) sebelum craft, auto-buy timber & craft component jika kurang
2. Repair gagal "Not Found" → Fix: skip item 0 durability (hancur), cek patch_scraps sebelum repair
3. Misi tidak diambil → Fix: ganti `sort_by(-.successChance)` (null) → `sort_by(.mobPower) | sort_by(.entryCost)`

**index.html:**
1. `switchTab()` pakai global `event` (tidak reliable) → Fix: pass `this` sebagai parameter
2. Countdown timer tidak work → Fix: tambah `data-resolve-at` attribute
3. `colorizeLog` tidak handle error baru → Fix: tambah pattern `Sell failed` & `Repair failed`
4. `colorizeLog` tidak handle equip/craft/onboarding → Fix: tambah pattern baru

**Key Insight:**
- Haul items dari misi succeeded **tidak otomatis masuk ke inventory**
- Haul hanya record hasil, bukan item yang bisa dijual
- Item dijual dari inventory materials, bukan dari haul
- **Loadout Lock**: Equipment tidak bisa di-swap/repair saat misi aktif
- **Onboarding Rewards**: Harus di-claim manual, tidak otomatis
- **Craft Slingshot**: Butuh 3 dust_tuft + 1 plank + 2 rope + 40 carrots fee — material harus disiapkan dulu
- **Repair**: Butuh patch_scraps material (min 2) — item 0 durability tidak bisa di-repair

### DARI SERVER VPS - Key Learnings

1. **CORS**: Browser blokir request cross-origin → solusi: proxy server
2. **API Key**: Jangan expose di frontend → simpan di server-side proxy
3. **Cache**: Browser cache HTML → tambah `Cache-Control: no-cache` header
4. **Timezone**: Script default UTC → set `TZ='Asia/Jakarta'` untuk WIB
5. **Sprites**: bunnyOS punya sprite assets di `https://assets.bunnyos.ai/sprites/`
6. **Loadout Lock**: Equipment terkunci saat misi aktif → cek sebelum equip/craft/repair
7. **Onboarding**: Reward besar (600+ carrots) → prioritize completion
8. **Smart Selling**: Simpan materials untuk crafting → jual excess saja
9. **Mission Selection**: Gratis > Murah > Mahal → profit lebih stabil

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

# Backup script
cp /root/bunny/play-bunnyos.sh /root/bunny/play-bunnyos.sh.backup-$(date +%Y%m%d-%H%M%S)
```

### DARI SERVER VPS - Next Steps

1. **Tunggu misi selesai** (~18:50-20:00 WIB)
2. **Script otomatis equip gear** → power naik ke 133
3. **Script otomatis craft Slingshot** → power naik ke 173
4. **Script otomatis repair Straw Hat** → durability pulih
5. **Script otomatis claim onboarding rewards** → +650 carrots
6. **Monitor log** untuk memastikan semua berjalan lancar
7. **Evaluate mission performance** setelah 24 jam
8. **Consider crafting Wooden Set** untuk power 200+

### DARI SERVER VPS - Risk Assessment

**Low Risk:**
- Scrounge the Hedgerows (94% chance, free)
- Garden's Edge (85% chance, cheap)

**Medium Risk:**
- Open Field (63% chance, medium cost)
- Craft common gear (100% success)

**High Risk:**
- Tall Grass (42% chance, expensive)
- Craft rare gear (90% success, bisa gagal)

**Avoid:**
- Hedgerow Maze (17% chance, expensive)
- Old Orchard (terlalu mahal untuk power saat ini)
