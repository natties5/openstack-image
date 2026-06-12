# Odoo Image — Ubuntu 26.04  [พร้อม build]

> Image สำเร็จรูป: สร้าง VM → first boot สร้าง Odoo 18 + PostgreSQL 16 + Nginx → เปิด `http://<IP>` ใช้ได้ทันที

---

## เป้าหมาย

```text
ลูกค้าสร้าง VM จาก Image
→ systemd เรียก odoo-bootstrap.sh
→ สุ่ม PostgreSQL password + Odoo master/admin password
→ สร้าง /opt/odoo/.env + /opt/odoo/config/odoo.conf + /root/odoo-credentials.txt
→ init database odoo_prod แบบไม่มี demo data
→ start PostgreSQL + Odoo + Nginx
→ ลูกค้าเปิด http://<IP> login ด้วย admin password แล้วเปลี่ยน password เอง
```

| โหมด | รายละเอียด |
|---|---|
| HTTP | พร้อมใช้ทันที `http://<IP>` |
| HTTPS | วาง cert/key, `docker compose stop nginx && docker compose --profile https up -d nginx-https` |

---

## Design

| รายการ | ค่า |
|---|---|
| Base OS | Ubuntu 26.04 |
| Odoo | `odoo:18.0` ตอน dev, pin digest ตอน freeze |
| PostgreSQL | `postgres:16` |
| Reverse proxy | `nginx:1.27` |
| DB | fixed `odoo_prod` |
| Demo data | disabled `--without-demo=all` |
| Security defaults | `list_db = False`, `dbfilter = ^odoo_prod$`, `proxy_mode = True` |
| Minimum flavor | 2 vCPU / 2GB RAM |
| Workers | adaptive: 2GB ใช้ `workers = 1`, RAM มากค่อยเพิ่ม |
| Backup | `pg_dump` + filestore tar |

---

## ก่อนเริ่ม — Pre-flight Verification

> ก่อน SSH เข้า VM — verify จาก docs ที่มีอยู่แล้ว ห้ามถาม user ถ้าหาคำตอบได้เอง

| เช็ค | ได้จาก | ถ้ายังไม่พร้อม |
|---|---|---|
| Guest image Ubuntu 26.04 สร้างเสร็จแล้ว | `_guest-images.md` → Ubuntu 26.04 ✅ เสร็จ | ต้องสร้าง guest image ก่อน |
| VM สร้างจาก guest image ที่ผ่าน Set 1-3 ครบ | standalone build | สร้าง VM จาก guest image |
| Build guide พร้อม `[พร้อม build]` | header tag บน | ต้องสร้าง source files ก่อน |
| SSH credentials | `build/tmp/odoo-build.env` (gitignored) | — |

**เมื่อ SSH เข้า VM แล้ว — verify บน VM:**

[golden-image VM]

```bash
lsb_release -a | grep Release
grep URIs /etc/apt/sources.list.d/ubuntu.sources
curl -sI https://download.docker.com | head -1
df -h /
free -h
```

ต้องได้:
- Ubuntu 26.04 หรือ codename ที่ตรงกับ guide
- DNS ออก internet ได้
- disk free มากกว่า 5GB
- RAM ถ้า 2GB ระบบจะใช้ small mode

---

## โครงสร้างไฟล์

```text
/opt/odoo/docker-compose.yml
/opt/odoo/nginx/default.conf
/opt/odoo/nginx/default-https.conf
/opt/odoo/config/                         (ว่างใน golden image)
/opt/odoo/addons/                         custom addons
/opt/odoo/certs/                          cert user วางเอง
/opt/odoo/backups/                        backup output
/usr/local/sbin/odoo-bootstrap.sh
/usr/local/sbin/odoo-tune-workers.sh
/usr/local/sbin/odoo-backup.sh
/etc/systemd/system/odoo-bootstrap.service
/root/README-odoo-image.txt
/etc/update-motd.d/99-odoo-image
```

ไฟล์ที่ต้องไม่มีใน Golden Image:

```text
/opt/odoo/.env
/opt/odoo/config/odoo.conf
/root/odoo-credentials.txt
/var/log/odoo-bootstrap.log
Docker volumes odoo_*
running containers
```

---

## ขั้นตอน Build

### 1. ติดตั้ง base packages

[golden-image VM]

```bash
apt update && apt install -y ca-certificates curl gnupg openssl jq vim htop net-tools
```

### 2. ติดตั้ง Docker

[golden-image VM]

```bash
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" > /etc/apt/sources.list.d/docker.list
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
```

### 2.5 Configure Docker log rotation

[golden-image VM]

```bash
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
systemctl restart docker
```

### 3. สร้าง directory

[golden-image VM]

```bash
mkdir -p /opt/odoo/{nginx,config,addons,certs,backups}
chmod 700 /opt/odoo/certs /opt/odoo/backups
```

### 4. คัดลอกไฟล์ static

> Reference: Source files อยู่ใน `build/apps/odoo/` — ใช้ตรวจสอบหรือ copy โดยตรงก็ได้

ไฟล์ที่ต้องวางบน VM ก่อน build image:
- `docker-compose.yml` → `/opt/odoo/docker-compose.yml`
- `default.conf` → `/opt/odoo/nginx/default.conf`
- `default-https.conf` → `/opt/odoo/nginx/default-https.conf`
- `odoo-bootstrap.sh` → `/usr/local/sbin/odoo-bootstrap.sh` (chmod +x)
- `odoo-tune-workers.sh` → `/usr/local/sbin/odoo-tune-workers.sh` (chmod +x)
- `odoo-backup.sh` → `/usr/local/sbin/odoo-backup.sh` (chmod +x)
- `odoo-bootstrap.service` → `/etc/systemd/system/odoo-bootstrap.service`
- `README-odoo-image.txt` → `/root/README-odoo-image.txt`
- `99-odoo-image` → `/etc/update-motd.d/99-odoo-image` (chmod +x)

#### 4.1 docker-compose.yml — Docker Compose definition สำหรับ 4 services: db, odoo, nginx, nginx-https

[golden-image VM]

```bash
cat > /opt/odoo/docker-compose.yml << 'EOF'
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 12
    restart: unless-stopped

  odoo:
    image: odoo:18.0
    environment:
      HOST: db
      PORT: 5432
      USER: ${POSTGRES_USER}
      PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - odoo_data:/var/lib/odoo
      - ./config/odoo.conf:/etc/odoo/odoo.conf:ro
      - ./addons:/mnt/extra-addons
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  nginx:
    image: nginx:1.27
    ports:
      - "80:80"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - odoo
    restart: unless-stopped

  nginx-https:
    image: nginx:1.27
    profiles:
      - https
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/default-https.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certs/fullchain.pem:/etc/nginx/certs/fullchain.pem:ro
      - ./certs/privkey.pem:/etc/nginx/certs/privkey.pem:ro
    depends_on:
      - odoo
    restart: unless-stopped

volumes:
  postgres_data:
  odoo_data:
EOF
```

#### 4.2 nginx/default.conf — HTTP reverse proxy + websocket/gevent route

[golden-image VM]

```bash
cat > /opt/odoo/nginx/default.conf << 'EOF'
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

upstream odoo {
    server odoo:8069;
}

upstream odoochat {
    server odoo:8072;
}

server {
    listen 80;
    server_name _;

    client_max_body_size 128m;
    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;

    location /websocket {
        proxy_pass http://odoochat;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }

    location /longpolling {
        proxy_pass http://odoochat;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }

    location / {
        proxy_pass http://odoo;
        proxy_redirect off;
    }
}
EOF
```

#### 4.3 nginx/default-https.conf — HTTPS reverse proxy ใช้ cert ที่ลูกค้าวางเอง

[golden-image VM]

```bash
cat > /opt/odoo/nginx/default-https.conf << 'EOF'
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

upstream odoo {
    server odoo:8069;
}

upstream odoochat {
    server odoo:8072;
}

server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name _;

    ssl_certificate /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;

    client_max_body_size 128m;
    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Proto https;

    location /websocket {
        proxy_pass http://odoochat;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }

    location /longpolling {
        proxy_pass http://odoochat;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }

    location / {
        proxy_pass http://odoo;
        proxy_redirect off;
    }
}
EOF
```

#### 4.4 odoo-tune-workers.sh — คำนวณ workers ตาม vCPU/RAM จริง รองรับขั้นต่ำ 2C/2G

[golden-image VM]

```bash
cat > /usr/local/sbin/odoo-tune-workers.sh << 'EOF'
#!/bin/bash
set -euo pipefail

CONF_FILE="${1:-/opt/odoo/config/odoo.conf}"

CPU_COUNT=$(nproc)
RAM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)

if [ "$RAM_MB" -lt 3000 ]; then
    WORKERS=1
    MODE="small"
elif [ "$RAM_MB" -lt 5000 ]; then
    WORKERS=2
    MODE="light"
else
    CPU_WORKERS=$((CPU_COUNT * 2 + 1))
    RAM_WORKERS=$(((RAM_MB - 1024) / 768))
    if [ "$RAM_WORKERS" -lt 2 ]; then
        RAM_WORKERS=2
    fi
    if [ "$CPU_WORKERS" -lt "$RAM_WORKERS" ]; then
        WORKERS=$CPU_WORKERS
    else
        WORKERS=$RAM_WORKERS
    fi
    MODE="normal"
fi

if [ ! -f "$CONF_FILE" ]; then
    echo "ERROR: config not found: $CONF_FILE" >&2
    exit 1
fi

sed -i "s/^workers = .*/workers = ${WORKERS}/" "$CONF_FILE"
sed -i "s/^max_cron_threads = .*/max_cron_threads = 1/" "$CONF_FILE"

cat > /opt/odoo/worker-sizing.txt << WORKER_EOF
Mode: ${MODE}
Detected CPU: ${CPU_COUNT}
Detected RAM MB: ${RAM_MB}
Configured workers: ${WORKERS}
Generated: $(date -Is)
WORKER_EOF

echo "Configured Odoo workers=${WORKERS} mode=${MODE} cpu=${CPU_COUNT} ram_mb=${RAM_MB}"
EOF
chmod +x /usr/local/sbin/odoo-tune-workers.sh
```

#### 4.5 odoo-backup.sh — backup PostgreSQL + filestore

[golden-image VM]

```bash
cat > /usr/local/sbin/odoo-backup.sh << 'EOF'
#!/bin/bash
set -euo pipefail

COMPOSE_DIR="/opt/odoo"
BACKUP_DIR="/opt/odoo/backups"
ENV_FILE="/opt/odoo/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: missing $ENV_FILE" >&2
    exit 1
fi

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

cd "$COMPOSE_DIR"
set -a
. "$ENV_FILE"
set +a

TS=$(date +%Y%m%d-%H%M%S)
DB_OUT="$BACKUP_DIR/odoo-${POSTGRES_DB}-${TS}.sql.gz"
DATA_OUT="$BACKUP_DIR/odoo-filestore-${TS}.tar.gz"

docker compose exec -T db pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" | gzip > "$DB_OUT"
docker run --rm -v odoo_odoo_data:/data:ro -v "$BACKUP_DIR:/backup" alpine:3.20 \
    tar -czf "/backup/$(basename "$DATA_OUT")" -C /data .

chmod 600 "$DB_OUT" "$DATA_OUT"
echo "Backup created:"
echo "  $DB_OUT"
echo "  $DATA_OUT"
EOF
chmod +x /usr/local/sbin/odoo-backup.sh
```

#### 4.6 odoo-bootstrap.sh — first boot สร้าง secret, config, DB, admin user

[golden-image VM]

```bash
cat > /usr/local/sbin/odoo-bootstrap.sh << 'EOF'
#!/bin/bash
set -euo pipefail

ENV_FILE="/opt/odoo/.env"
CRED_FILE="/root/odoo-credentials.txt"
LOG_FILE="/var/log/odoo-bootstrap.log"
COMPOSE_DIR="/opt/odoo"
CONF_FILE="/opt/odoo/config/odoo.conf"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

wait_for_http() {
    for _ in $(seq 1 90); do
        if curl -fsS http://127.0.0.1/web/login >/dev/null 2>&1; then
            return 0
        fi
        sleep 2
    done
    return 1
}

if [ -f "$ENV_FILE" ]; then
    log "Bootstrap: .env exists — starting services"
    cd "$COMPOSE_DIR"
    docker compose up -d
    log "Bootstrap: done (reusing existing config)"
    exit 0
fi

log "Bootstrap: first boot — generating secrets"

POSTGRES_DB="odoo_prod"
POSTGRES_USER="odoo"
POSTGRES_PASSWORD=$(openssl rand -base64 24 | tr -d '\n')
ODOO_MASTER_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
ODOO_ADMIN_LOGIN="admin"
ODOO_ADMIN_PASSWORD=$(openssl rand -base64 24 | tr -d '\n')

install -d -m 700 /opt/odoo/config /opt/odoo/addons /opt/odoo/backups /opt/odoo/certs

cat > "$ENV_FILE" << ENV_EOF
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
ODOO_MASTER_PASSWORD=${ODOO_MASTER_PASSWORD}
ODOO_ADMIN_LOGIN=${ODOO_ADMIN_LOGIN}
ODOO_ADMIN_PASSWORD=${ODOO_ADMIN_PASSWORD}
ENV_EOF
chmod 600 "$ENV_FILE"

cat > "$CONF_FILE" << CONF_EOF
[options]
admin_passwd = ${ODOO_MASTER_PASSWORD}
db_host = db
db_port = 5432
db_user = ${POSTGRES_USER}
db_password = ${POSTGRES_PASSWORD}
db_name = ${POSTGRES_DB}
dbfilter = ^${POSTGRES_DB}$
list_db = False
proxy_mode = True
without_demo = all
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons
data_dir = /var/lib/odoo
workers = 1
max_cron_threads = 1
gevent_port = 8072
limit_memory_soft = 1073741824
limit_memory_hard = 1610612736
limit_time_cpu = 600
limit_time_real = 1200
CONF_EOF
chmod 640 "$CONF_FILE"

/usr/local/sbin/odoo-tune-workers.sh "$CONF_FILE" | tee -a "$LOG_FILE"

cat > "$CRED_FILE" << CRED_EOF
=== Odoo Docker Credentials ===
Generated: $(date)

Web:
  URL: http://<VM-IP>/
  HTTPS cert path: /opt/odoo/certs/fullchain.pem + /opt/odoo/certs/privkey.pem

Odoo:
  Database: ${POSTGRES_DB}
  Admin login: ${ODOO_ADMIN_LOGIN}
  Admin password: ${ODOO_ADMIN_PASSWORD}
  Master password: ${ODOO_MASTER_PASSWORD}

PostgreSQL:
  Host: db (internal Docker network)
  Database: ${POSTGRES_DB}
  User: ${POSTGRES_USER}
  Password: ${POSTGRES_PASSWORD}

Manage:
  cd /opt/odoo
  docker compose ps
  docker compose logs -f
  docker compose restart

Backup:
  /usr/local/sbin/odoo-backup.sh

Security:
  Change the Odoo admin password after first login.
CRED_EOF
chmod 600 "$CRED_FILE"

cd "$COMPOSE_DIR"
log "Bootstrap: pulling images"
docker compose pull

log "Bootstrap: starting database"
docker compose up -d db
for _ in $(seq 1 60); do
    if docker compose exec -T db pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
        log "Bootstrap: PostgreSQL is ready"
        break
    fi
    sleep 2
done

log "Bootstrap: initializing Odoo database ${POSTGRES_DB} without demo data"
docker compose run --rm odoo odoo -d "$POSTGRES_DB" -i base --without-demo=all --stop-after-init

log "Bootstrap: setting initial admin password"
docker compose run --rm odoo odoo shell -d "$POSTGRES_DB" << SHELL_EOF
admin = env.ref('base.user_admin')
admin.write({'login': '${ODOO_ADMIN_LOGIN}', 'password': '${ODOO_ADMIN_PASSWORD}'})
env.cr.commit()
SHELL_EOF

log "Bootstrap: starting Odoo + Nginx"
docker compose up -d

if wait_for_http; then
    log "Bootstrap: Odoo is ready — open http://<VM-IP>/"
else
    log "Bootstrap: WARNING Odoo web did not become ready within timeout"
fi
EOF
chmod +x /usr/local/sbin/odoo-bootstrap.sh
```

#### 4.7 systemd service — รัน bootstrap ตอน first boot

[golden-image VM]

```bash
cat > /etc/systemd/system/odoo-bootstrap.service << 'EOF'
[Unit]
Description=Odoo first boot bootstrap
After=docker.service network-online.target
Wants=network-online.target
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/odoo-bootstrap.sh
RemainAfterExit=yes
TimeoutStartSec=900

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable odoo-bootstrap.service
```

#### 4.8 README และ MOTD

[golden-image VM]

```bash
cat > /root/README-odoo-image.txt << 'EOF'
Odoo 18 Image — Quick Start
===========================

This VM starts Odoo automatically on first boot.

Open:
  http://<VM-IP>/

Credentials:
  /root/odoo-credentials.txt

Important paths:
  /opt/odoo/docker-compose.yml
  /opt/odoo/.env
  /opt/odoo/config/odoo.conf
  /opt/odoo/addons/
  /opt/odoo/certs/fullchain.pem
  /opt/odoo/certs/privkey.pem
  /opt/odoo/backups/

HTTPS:
  1. Put certificate files here:
     /opt/odoo/certs/fullchain.pem
     /opt/odoo/certs/privkey.pem
  2. Run:
     cd /opt/odoo
     docker compose stop nginx
     docker compose --profile https up -d nginx-https

Manage:
  cd /opt/odoo
  docker compose ps
  docker compose logs -f
  docker compose restart

Backup:
  /usr/local/sbin/odoo-backup.sh

Worker tuning after resize:
  /usr/local/sbin/odoo-tune-workers.sh
  cd /opt/odoo && docker compose restart odoo

Notes:
  - Database name is fixed: odoo_prod
  - Demo data is disabled
  - Database listing is disabled
  - Change the Odoo admin password after first login
EOF

cat > /etc/update-motd.d/99-odoo-image << 'EOF'
#!/bin/sh
cat << 'MOTD_EOF'

Odoo 18 image
-------------
URL: http://<this-vm-ip>/
Credentials: /root/odoo-credentials.txt
App dir: /opt/odoo
Certs: /opt/odoo/certs/fullchain.pem + /opt/odoo/certs/privkey.pem
Backup: /usr/local/sbin/odoo-backup.sh

Commands:
  cd /opt/odoo && docker compose ps
  cd /opt/odoo && docker compose logs -f

MOTD_EOF
EOF
chmod +x /etc/update-motd.d/99-odoo-image
```

### 5. Pull images ล่วงหน้า

[golden-image VM]

```bash
cd /opt/odoo
docker compose pull
docker images | grep -E 'odoo|postgres|nginx'
```

ก่อน freeze ควร verify/pin digest:

[image-build-host]

```bash
docker manifest inspect odoo:18.0
docker manifest inspect postgres:16
docker manifest inspect nginx:1.27
```

### 6. Test bootstrap บน golden image

[golden-image VM]

```bash
/usr/local/sbin/odoo-bootstrap.sh
cd /opt/odoo
docker compose ps
curl -sI http://127.0.0.1/web/login | head -5
cat /opt/odoo/worker-sizing.txt
```

ห้าม dump `/root/odoo-credentials.txt` ลงเอกสารหรือ chat

### 7. Verify dependency ใน official Odoo image

[golden-image VM]

```bash
docker compose run --rm odoo wkhtmltopdf --version
docker compose run --rm odoo fc-list | grep -i 'noto' | head
docker compose run --rm odoo id odoo
```

ต้องยืนยัน:
- `wkhtmltopdf` ใช้งานได้
- มี font กลุ่ม Noto สำหรับ report ภาษาไทย/CJK
- container runtime user เป็น `odoo`

### 8. Verify HTTPS mode

[golden-image VM]

```bash
openssl req -x509 -nodes -days 1 -newkey rsa:2048 \
  -keyout /opt/odoo/certs/privkey.pem \
  -out /opt/odoo/certs/fullchain.pem \
  -subj '/CN=odoo-test.local'
cd /opt/odoo
docker compose stop nginx
docker compose --profile https up -d nginx-https
curl -k -sI https://127.0.0.1/web/login | head -5
```

หลัง test ต้องลบ cert test ก่อน capture:

[golden-image VM]

```bash
rm -f /opt/odoo/certs/fullchain.pem /opt/odoo/certs/privkey.pem
```

### 9. Cleanup ก่อน snapshot

[golden-image VM]

```bash
cd /opt/odoo
docker compose --profile https down --volumes --remove-orphans
rm -f /opt/odoo/.env
rm -f /opt/odoo/config/odoo.conf
rm -f /root/odoo-credentials.txt
rm -f /var/log/odoo-bootstrap.log
rm -f /opt/odoo/worker-sizing.txt
rm -f /opt/odoo/certs/fullchain.pem /opt/odoo/certs/privkey.pem
```

### 10. Final check ก่อน poweroff/capture

[golden-image VM]

```bash
systemctl is-enabled odoo-bootstrap.service
docker compose -f /opt/odoo/docker-compose.yml ps
docker images | grep -E 'odoo|postgres|nginx'
test ! -e /opt/odoo/.env && echo '.env: absent'
test ! -e /opt/odoo/config/odoo.conf && echo 'odoo.conf: absent'
test ! -e /root/odoo-credentials.txt && echo 'credentials: absent'
test ! -e /var/log/odoo-bootstrap.log && echo 'bootstrap log: absent'
if docker volume ls --format '{{.Name}}' | grep -qi odoo; then
  echo 'ERROR: runtime volumes remain'
  exit 1
fi
echo 'volumes: absent'
```

ห้าม capture ถ้า:
- service disabled
- containers ยังรันอยู่
- images หาย
- `.env`, `odoo.conf`, credentials, bootstrap log ยังอยู่
- Docker volumes `odoo_*` ยังมี runtime data จากการทดสอบ

---

## หลังลูกค้าสร้าง VM จาก image

[target-VM]

```bash
systemctl status odoo-bootstrap.service --no-pager
cd /opt/odoo
docker compose ps
curl -sI http://127.0.0.1/web/login | head -5
ls -l /root/odoo-credentials.txt
```

เปิดเว็บ:

```text
http://<VM-IP>/
```

อ่าน credentials บน VM เท่านั้น:

[target-VM]

```bash
less /root/odoo-credentials.txt
```

---

## HTTPS หลัง deploy

[target-VM]

```bash
install -d -m 700 /opt/odoo/certs
# copy cert จริงไปที่:
# /opt/odoo/certs/fullchain.pem
# /opt/odoo/certs/privkey.pem
chmod 600 /opt/odoo/certs/fullchain.pem /opt/odoo/certs/privkey.pem
cd /opt/odoo
docker compose stop nginx
docker compose --profile https up -d nginx-https
curl -k -sI https://127.0.0.1/web/login | head -5
```

---

## Resize / Tune Workers

หลัง resize VM ให้รัน:

[target-VM]

```bash
/usr/local/sbin/odoo-tune-workers.sh
cat /opt/odoo/worker-sizing.txt
cd /opt/odoo
docker compose restart odoo
```

---

## Backup

[target-VM]

```bash
/usr/local/sbin/odoo-backup.sh
ls -lh /opt/odoo/backups/
```

Backup ต้องมีทั้ง:
- PostgreSQL dump: `odoo-odoo_prod-*.sql.gz`
- Filestore/data volume: `odoo-filestore-*.tar.gz`

---

## Troubleshooting เร็ว

### เว็บไม่ขึ้น

[target-VM]

```bash
systemctl status odoo-bootstrap.service --no-pager
cd /opt/odoo
docker compose ps
docker compose logs --tail=100 odoo
docker compose logs --tail=100 nginx
```

### DB ยังไม่พร้อม

[target-VM]

```bash
cd /opt/odoo
docker compose exec -T db pg_isready -U odoo -d odoo_prod
docker compose logs --tail=100 db
```

### Websocket / notification พัง

[target-VM]

```bash
curl -i -H 'Connection: Upgrade' -H 'Upgrade: websocket' http://127.0.0.1/websocket | head -20
docker compose logs --tail=100 nginx
docker compose logs --tail=100 odoo
```

### Custom addons ไม่ขึ้น

[target-VM]

```bash
ls -la /opt/odoo/addons
find /opt/odoo/addons -maxdepth 2 -name __manifest__.py
cd /opt/odoo
docker compose restart odoo
```

ใน Odoo UI ให้ update apps list หลังเพิ่ม module

---

## วิธีใช้ซ้ำ

1. อ่าน `AI-PIPELINE.md` ก่อน build VM จริง
2. รัน pre-flight บน `[golden-image VM]`
3. ทำ steps 1-10 ตามลำดับ
4. Boot VM test จาก image แล้วรัน `odoo-post-check.md`
5. ถ้าผ่าน ค่อยอัปเดต `_app-catalog.md` เป็น built standalone
