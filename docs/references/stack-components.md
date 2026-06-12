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
