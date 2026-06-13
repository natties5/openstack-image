# Stack Components Catalog

> Component สำเร็จรูป — Engineer เลือกผสมตาม research  
> ทุก entry มี: snippet + When to use + When NOT + Real-world reference

---

## Database Components

### db: mariadb

**When to use:** app ต้องการ MySQL-compatible database, community แนะนำ MariaDB เร็วกว่า MySQL

**When NOT:** app ใช้ PostgreSQL, app มี SQLite ในตัว, app เป็น stateless

**docker-compose snippet:**
```yaml
db:
  image: mariadb:lts
  restart: unless-stopped
  volumes:
    - db_data:/var/lib/mysql
  environment:
    MARIADB_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
    MARIADB_DATABASE: ${DB_NAME}
    MARIADB_USER: ${DB_USER}
    MARIADB_PASSWORD: ${DB_PASSWORD}
  healthcheck:
    test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
    interval: 10s
    retries: 5
```

**Real-world:** WordPress

---

### db: postgres

**When to use:** app ต้องการ PostgreSQL (Odoo, n8n, Nextcloud, GitLab)

**When NOT:** app ใช้ MySQL (WordPress), app มี SQLite ในตัว

**docker-compose snippet:**
```yaml
db:
  image: postgres:17-alpine
  restart: unless-stopped
  volumes:
    - db_data:/var/lib/postgresql/data
  environment:
    POSTGRES_PASSWORD: ${DB_PASSWORD}
    POSTGRES_DB: ${DB_NAME}
    POSTGRES_USER: ${DB_USER}
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d {DB_NAME}"]
    interval: 10s
    retries: 5
```

**Version strategy:** Pin minor (17), ไม่ pin patch (alpine จะได้ security update)

**Real-world:** Odoo, n8n, Nextcloud

---

## Reverse Proxy Components

### proxy: nginx

**When to use:** app ต้องการ reverse proxy เพื่อ HTTPS, static file serving, gzip, webhook forwarding

**When NOT:** app serve HTTP ได้สมบูรณ์ในตัวและ HTTPS ไม่จำเป็น, app ใช้ Caddy auto-SSL

**docker-compose snippet:**
```yaml
proxy:
  image: nginx:stable-alpine
  restart: unless-stopped
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    - app_data:/var/www/html:ro  # ถ้า app เป็น PHP
```

**Nginx config requirements:**
- `client_max_body_size` ≥ upload limit ของ app
- `fastcgi_param HTTPS $https if_not_empty` — app รู้เองว่าใช้ HTTP/HTTPS
- ถ้า app เป็น PHP: `try_files` rewrite rules

**Real-world:** WordPress, Nextcloud

---

### proxy: caddy

**When to use:** ต้องการ auto-SSL (Let's Encrypt) โดยไม่ต้อง config เพิ่ม

**When NOT:** ไม่มี domain จริง (IP-only VM), ต้องการ custom SSL cert

> Caddy ยังไม่มี real-world reference ใน catalog นี้ — ใช้เมื่อ research แนะนำ

---

## Cache Components

### cache: redis

**When to use:** app ต้องการ object cache หรือ session cache (Nextcloud, WordPress กรณี traffic สูง)

**When NOT:** app ไม่มี cache adapter, research ไม่พูดถึง, traffic ต่ำ

**docker-compose snippet:**
```yaml
cache:
  image: redis:7-alpine
  restart: unless-stopped
  volumes:
    - cache_data:/data
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 10s
    retries: 3
```

**Real-world:** Nextcloud

---

## App Runtime Components

### app: php-fpm

**When to use:** app เขียนด้วย PHP (WordPress, Nextcloud, Moodle)

**Base pattern:**
```yaml
app:
  image: <app-image>:<version>
  restart: unless-stopped
  volumes:
    - app_data:/var/www/html
  environment:
    - APACHE_RUN_USER=#33
    - APACHE_RUN_GROUP=#33
```

**UID/GID:** PHP-FPM มักใช้ UID 33 (www-data) — nginx ต้อง mount volume ด้วย UID ตรงกัน

---

### app: node

**When to use:** app เขียนด้วย Node.js (n8n, Ghost, Uptime Kuma)

**Base pattern:**
```yaml
app:
  image: <app-image>:<version>
  restart: unless-stopped
  volumes:
    - app_data:/home/node/.n8n  # example
  environment:
    - NODE_ENV=production
```

**Real-world:** n8n

---

### app: python

**When to use:** app เขียนด้วย Python (Odoo)

**Base pattern:**
```yaml
app:
  image: <app-image>:<version>
  restart: unless-stopped
  volumes:
    - app_data:/var/lib/odoo
  ports:
    - "8069:8069"
```

**Real-world:** Odoo

---

### app: go

**When to use:** app เขียนด้วย Go (Gitea, Grafana, Prometheus, Ollama)

**Base pattern:**
```yaml
app:
  image: <app-image>:<version>
  restart: unless-stopped
  volumes:
    - app_data:/data
  ports:
    - "3000:3000"
```

**Real-world:** — (ยังไม่มีใน catalog นี้ จะเพิ่มเมื่อ build app จริง)

---

### app: generic

**When to use:** app runtime ที่ไม่มีใน catalog นี้ — ใช้ base pattern, ดัดแปลงตาม research

**Base pattern:**
```yaml
app:
  image: <app-image>:<version>
  restart: unless-stopped
  volumes:
    - app_data:/data
```

**Real-world:** สำหรับ app ที่ runtime อยู่นอก php-fpm, node, python, go

---

## Non-Docker Components

### systemd-native

**When to use:** research บอกว่า Docker ไม่เหมาะ, app ต้องการ bare-metal performance, หรือ app architecture ไม่เข้า Docker pattern

**When NOT:** app มี Docker image อย่างเป็นทางการและ Docker ทำให้ deploy ง่ายกว่า

**Base pattern:**
```bash
# Install script — install app โดยตรง ไม่ผ่าน container
# ตัวอย่าง: apt install <app>, configure, systemctl enable

# Systemd unit
cat > /etc/systemd/system/<app>.service << 'EOF'
[Unit]
Description=<App>
After=network.target

[Service]
ExecStart=/usr/bin/<app>
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable <app>
```

**Real-world:** — (ยังไม่มีใน catalog นี้ จะเพิ่มเมื่อ build app จริง)

---

## MCP / Tooling Components

### tool: playwright-cloudflare-bypass

**When to use:** website ที่ research ต้องการมี Cloudflare, WAF, JS challenge — `webfetch` โดน 403

**When NOT:** website ปกติไม่มี WAF (ใช้ `webfetch` พอแล้ว), website มี CAPTCHA รูปภาพ (Playwright ก็ไม่ผ่าน)

**MCP config snippet (`opencode.json`):**
```json
"playwright": {
  "type": "local",
  "command": [
    "npx", "-y", "@playwright/mcp",
    "--browser", "chromium",
    "--user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "--viewport-size", "1920x1080",
    "--ignore-https-errors"
  ],
  "enabled": true
}
```

| Flag | เหตุผล |
|---|---|
| `--user-agent` | เลียนแบบ Chrome จริง — Cloudflare บล็อก `HeadlessChrome` default |
| `--viewport-size` | เลียนแบบจอปกติ — 800x600 ถูก fingerprint ได้ |
| `--ignore-https-errors` | เผื่อ cert issue (พบบ่อยกับเว็บไทย) |

**Agent tools ที่ต้องเปิด:** `playwright_*`
```json
"agent": {
  "image-sleuth": { "tools": { "playwright_*": true } },
  "image-engineer": { "tools": { "playwright_*": true } }
}
```

**ใช้งาน:** `browser_navigate` แทน `webfetch` — Chromium จริงรัน JS + bypass Cloudflare ได้

**Real-world:** openlandscape.cloud (Cloudflare, 403 via webfetch, ผ่านด้วย Playwright)

---

### tool: github-mcp

**When to use:** ต้องการค้นข้อมูลจาก GitHub API โดยตรง — search code, issues, PRs, releases, file contents

**When NOT:** ข้อมูลไม่ได้อยู่บน GitHub, ต้องการ read/write repo (ใช้ git CLI ผ่าน bash ดีกว่า)

**MCP config snippet:**
```json
"github": {
  "type": "local",
  "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
  "enabled": true
}
```

**Prerequisite:** `GITHUB_PERSONAL_ACCESS_TOKEN` env var (ฟรี สร้างที่ GitHub → Settings → Developer settings)

**Agent:** `image-sleuth` (search issues/PRs), `image-engineer` (check releases/tags)

**Real-world:** Sleuth ค้น community issues ก่อนเขียน review, Engineer เช็ค release tags ก่อน pin version

---

### tool: ssh-mcp

**When to use:** Maker ต้องการ SSH เข้า VM รัน build pipeline อัตโนมัติ — แทนการ copy-paste คำสั่ง

**When NOT:** build แบบ manual (user รันเองตาม guide), ไม่มี VM ให้ SSH

**MCP config snippet:**
```json
"ssh": {
  "type": "local",
  "command": ["npx", "-y", "ssh-mcp",
    "--host", "${env:BUILD_VM_HOST}",
    "--port", "22",
    "--user", "${env:BUILD_VM_USER}",
    "--password", "${env:BUILD_VM_PASS}",
    "--timeout", "300000"],
  "enabled": true
}
```

**Credentials:** ตั้ง env vars ก่อน start opencode — ไม่เขียนลงไฟล์, ปิด terminal = หาย:
```powershell
$env:BUILD_VM_HOST="10.0.0.5"
$env:BUILD_VM_USER="ubuntu"
$env:BUILD_VM_PASS="temp123"
```

**Agent:** `image-maker`

**Real-world:** Maker SSH build Odoo/WordPress/Nextcloud image บน VM แบบ end-to-end

---

## How to Add New Component

เมื่อ build app ใหม่แล้วพบว่าต้องมี component ที่ยังไม่มีใน catalog:

1. เขียน snippet — จากของจริงที่ build สำเร็จแล้ว
2. ใส่ When to use / When NOT — อ้างอิง research
3. ใส่ Real-world reference — อย่างน้อย 1 app
4. ใส่ที่นี่ — `docs/references/stack-components.md`

**หลักการ:** เพิ่มเมื่อมี app จริงที่ใช้ ไม่เพิ่มจากทฤษฎี

---

**Version:** 2026-06-12
**Referenced by:** `agents/image-engineer.md`
