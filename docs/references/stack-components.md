# Stack Components Catalog

> Component สำเร็จรูป — Cid เลือกผสมตาม research  
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

### monitoring: prometheus-grafana

**When to use:** image ต้องการ self-service VM / website / service monitoring พร้อม dashboard และ alerting

**When NOT:** user ต้องการ log aggregation/tracing เป็นหลัก, หรือ monitoring ถูกผูกกับ provider control plane/credential เฉพาะ

**docker-compose pattern:**
```yaml
services:
  grafana:
    image: grafana/grafana:latest
    restart: unless-stopped
    environment:
      GF_SECURITY_ADMIN_USER: ${GRAFANA_ADMIN_USER:-admin}
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_ADMIN_PASSWORD}
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro

  prometheus:
    image: prom/prometheus:latest
    restart: unless-stopped
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.retention.time=30d
      - --web.enable-lifecycle
    volumes:
      - prometheus_data:/prometheus
      - ./prometheus:/etc/prometheus:ro

  alertmanager:
    image: prom/alertmanager:latest
    restart: unless-stopped

  node-exporter:
    image: prom/node-exporter:latest
    restart: unless-stopped
    pid: host
    command:
      - --path.rootfs=/host
    volumes:
      - /:/host:ro,rslave

  blackbox-exporter:
    image: prom/blackbox-exporter:latest
    restart: unless-stopped
```

**Self-service requirements:**
- First boot generate random Grafana admin password ต่อ VM
- Reboot ห้ามเปลี่ยน password
- มี `monitoring-reset-grafana-password` สำหรับกรณีลืม password
- เพิ่ม targets ผ่าน file_sd + helper scripts ไม่บังคับ user แก้ YAML เองตั้งแต่แรก
- Public expose เฉพาะ reverse proxy; Prometheus/Alertmanager/exporters ไม่ควร expose public
- Prometheus TSDB ใช้ local volume/disk ไม่ใช้ NFS/SMB/EFS-like storage

**Real-world:** Grafana+Prometheus

---

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

## Research-Backed Candidate Patterns

> Pattern กลุ่มนี้มาจาก catalog research วันที่ 2026-06-14 ยังไม่ถือเป็น real-world built component จนกว่าจะมี `build/apps/{app}/` ที่ build สำเร็จ

### pattern: ai-rag-no-gpu

**When to use:** app image กลุ่ม AI/RAG ที่ต้องใช้ได้บน VM ไม่มี GPU โดยใช้ external LLM API เป็น default และ optional local Ollama CPU สำหรับโมเดลเล็ก

**When NOT:** user คาดหวัง inference เร็วระดับ production local LLM, ต้องรัน 7B+ หลาย concurrent users, หรือต้องการ air-gapped performance สูงโดยไม่มี GPU

**Candidate apps:** AnythingLLM, Flowise, Dify CE, Open WebUI, LiteLLM Proxy

**Design rules:**
- Default image ต้อง boot ได้โดยไม่ต้องมี GPU และไม่ pull model ใหญ่ตอน first boot
- แยก `APP_SECRET`, API keys, model provider config ออกจาก golden image; สร้าง/รับค่าตอน first boot
- ถ้าใช้ external API ให้เปิด UI เพื่อใส่ key ภายหลัง หรือเก็บ key ใน `/root/{app}-credentials.txt` เฉพาะตอน user ตั้งเอง
- ถ้า optional Ollama CPU ให้ระบุชัดว่า 1B-4B model เหมาะกับ 4-8 GB RAM; 7B ต้อง 8-16 GB RAM และช้า
- ห้ามโฆษณาว่า “offline AI เร็ว” ถ้าไม่มี GPU; ให้ใช้คำว่า “CPU-capable / API-provider ready”

**Base compose shape:**
```yaml
services:
  app:
    image: <ai-app-image>:<version>
    restart: unless-stopped
    environment:
      APP_SECRET: ${APP_SECRET}
      # Provider keys are optional and should be added after first boot.
    volumes:
      - app_data:/app/data
    ports:
      - "3000:3000"

volumes:
  app_data:
```

**Resource floor:** UI/RAG app only 1-2 vCPU, 2-4 GB RAM; Dify-class full stack 2+ vCPU, 4-8 GB RAM

**Research references:** AnythingLLM, Flowise, Dify, Open WebUI docs/release pages checked 2026-06-14

---

### pattern: lightweight-saas-replacement

**When to use:** app image ที่แทน SaaS per-seat/per-usage ได้ชัด เช่น password manager, analytics, helpdesk, Airtable-like DB, project management

**When NOT:** app ต้องผูก domain/SMTP/payment provider จำนวนมากจน first boot ใช้งานไม่ได้, หรือ CE มี feature จำกัดจนไม่พอใช้งานจริง

**Candidate apps:** Vaultwarden, Umami, Chatwoot CE, NocoDB, Plane CE, Cal.com, Coolify

**Design rules:**
- First boot ต้องสร้าง admin password/token ต่อ VM และเขียน credential ไว้ที่ `/root/{app}-credentials.txt` ด้วย `chmod 600`
- ถ้า browser feature บังคับ HTTPS เช่น Vaultwarden Web Crypto ให้บอกชัดว่า HTTP ใช้ evaluate ได้ แต่ production ต้องมี domain/HTTPS
- ถ้า app ต้อง SMTP ให้ boot ได้ก่อนโดย SMTP optional; UI/admin ค่อยตั้งภายหลัง
- ใช้ SQLite เมื่อ upstream แนะนำและเหมาะกับ small team; ใช้ PostgreSQL เมื่อ app/scale ต้องการ
- ไม่เปิด admin/internal ports public ถ้าไม่จำเป็น; bind DB/Redis เฉพาะ Docker network

**Base compose shape:**
```yaml
services:
  app:
    image: <saas-replacement-image>:<version>
    restart: unless-stopped
    environment:
      APP_URL: ${APP_URL:-http://localhost}
      ADMIN_PASSWORD: ${ADMIN_PASSWORD}
    volumes:
      - app_data:/data
    ports:
      - "80:80"

volumes:
  app_data:
```

**Resource floor:** lightweight single-container apps 1 vCPU, 512 MB-1 GB RAM; Rails/Django multi-service apps 2-4 vCPU, 4 GB RAM

**Research references:** Vaultwarden, Umami, Chatwoot, Plane, Coolify docs/release pages checked 2026-06-14

---

## Host / Non-Docker Components

### host: docker-ce

**When to use:** image เป็น general-purpose Docker host หรือ app guide ต้องการ Docker Engine บน VM โดยตรง

**When NOT:** app ใช้ systemd-native โดยไม่ต้องรัน container, หรือ platform ใช้ managed Kubernetes/container service อยู่แล้ว

**Install snippet:**
```bash
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
cat > /etc/apt/sources.list.d/docker.sources << EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
```

**Daemon defaults:**
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

**Security notes:** Docker group เป็น root-equivalent; Docker published ports อาจ bypass UFW rules ให้ใช้ OpenStack security group และ `DOCKER-USER` เมื่อต้อง restrict source

**Real-world:** Docker Platform, WordPress, Nextcloud, Odoo

---

### ui: portainer-ce

**When to use:** ต้องการ Web UI สำหรับจัดการ Docker host ให้ beginner/SMB ใช้ง่าย

**When NOT:** ต้องการ minimal hardened host, ไม่ต้องการ expose admin UI, หรือใช้ orchestrator/management platform อื่นแล้ว

**docker-compose snippet:**
```yaml
services:
  portainer:
    image: portainer/portainer-ce:lts
    container_name: portainer
    restart: always
    ports:
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data

volumes:
  portainer_data:
    name: portainer_data
```

**Security notes:** Portainer mount `/var/run/docker.sock` จึงควบคุม Docker host ได้ทั้งหมด; เปิดเฉพาะ `9443` default, ไม่เปิด `8000` Edge tunnel ถ้าไม่ได้ใช้ Edge Agents

**Real-world:** Docker Platform

---

### ui: nginx-proxy-manager

**When to use:** ลูกค้าทั่วไปต้องการ Web UI สำหรับจัด domain, reverse proxy, และ Let's Encrypt cert โดยไม่ต้องเขียน Nginx config เอง

**When NOT:** ต้องการ minimal host, ต้องการ config-as-code ล้วน, หรือทีมถนัด Caddy/Traefik มากกว่า Web UI

**docker-compose snippet:**
```yaml
services:
  nginx-proxy-manager:
    image: jc21/nginx-proxy-manager:latest
    container_name: nginx-proxy-manager
    restart: unless-stopped
    ports:
      - "80:80"
      - "81:81"
      - "443:443"
    environment:
      TZ: ${TZ:-Asia/Bangkok}
      DISABLE_IPV6: "true"
    volumes:
      - npm_data:/data
      - npm_letsencrypt:/etc/letsencrypt

volumes:
  npm_data:
  npm_letsencrypt:
```

**Security notes:** เปิด `80/443` public สำหรับเว็บ, จำกัด `81` เฉพาะ admin IP; upstream default login คือ `admin@example.com` / `changeme` และควรให้ bootstrap เปลี่ยนผ่าน API ก่อนส่ง credentials ให้ลูกค้า

**Real-world:** Docker Platform

---

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
  "aerith": { "tools": { "playwright_*": true } },
  "cid": { "tools": { "playwright_*": true } }
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

**Agent:** `aerith` (search issues/PRs), `cid` (check releases/tags)

**Real-world:** Aerith ค้น community issues ก่อนเขียน review, Cid เช็ค release tags ก่อน pin version

---

### tool: ssh-mcp

**When to use:** Cloud ต้องการ SSH เข้า VM รัน build pipeline อัตโนมัติ — แทนการ copy-paste คำสั่ง

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

**Agent:** `cloud`

**Real-world:** Cloud SSH build Odoo/WordPress/Nextcloud image บน VM แบบ end-to-end

---

## How to Add New Component

เมื่อ build app ใหม่แล้วพบว่าต้องมี component ที่ยังไม่มีใน catalog:

1. เขียน snippet — จากของจริงที่ build สำเร็จแล้ว
2. ใส่ When to use / When NOT — อ้างอิง research
3. ใส่ Real-world reference — อย่างน้อย 1 app
4. ใส่ที่นี่ — `docs/references/stack-components.md`

**หลักการ:** เพิ่มเมื่อมี app จริงที่ใช้ ไม่เพิ่มจากทฤษฎี

---

**Version:** 2026-06-16
**Referenced by:** `agents/cid.md`
