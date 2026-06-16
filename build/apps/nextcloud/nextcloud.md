# Nextcloud Image — Ubuntu 26.04  [built: production-korry-gate2]
> Image สำเร็จรูป: สร้าง VM → auto-install → เปิด browser ใช้งานได้เลย, ใช้ IP ก่อน และเพิ่ม domain/HTTPS ภายหลัง

---

## เป้าหมาย

```text
ลูกค้าสร้าง VM จาก Image
→ systemd เรียก nextcloud-bootstrap.sh
→ detect IP/hostname → update trusted_domains
→ สุ่ม PostgreSQL password + admin password สำหรับ VM นั้น
→ สร้าง /opt/nextcloud/.env + /root/nextcloud-credentials.txt
→ docker compose up -d จาก Docker images ที่ pre-pull ไว้ใน golden image
→ เปิด http://<IP> ใช้งานได้เลย (admin pre-created, password สุ่ม)
```

| โหมด | รายละเอียด |
|---|---|
| HTTP | พร้อมใช้ทันที `http://<IP>` |
| Domain | เพิ่มภายหลังด้วย `occ config:system:set trusted_domains` |
| HTTPS | วาง cert/key เองที่ `/opt/nextcloud/certs/`, แล้วเปิด profile `https` |

## Rebuild Decision Baseline

| เรื่อง | ตัดสินใจ |
|---|---|
| Install flow | **Auto-install** ให้เสร็จตอน first boot |
| Admin user | `admin` |
| Admin password | สุ่มต่อ VM แล้วเก็บใน `/root/nextcloud-credentials.txt` (`chmod 600`) |
| Runtime data | Bind mount ที่ `/var/lib/nextcloud/` เพื่อให้เห็น data จริงใน VM และย้ายไป attached volume ง่าย |
| First boot internet | **ไม่พึ่ง internet 100%** — ห้าม `docker compose pull` ตอน runtime |
| Docker image pinning | Pin patch/minor ให้แน่นขึ้น ไม่ใช้ tag ลอยกว้าง |
| HTTPS | User วาง cert เองที่ `/opt/nextcloud/certs/fullchain.pem` และ `privkey.pem` |
| Backup | มีคู่มือก่อน ยังไม่เพิ่ม backup script |

> สถานะปัจจุบัน: source เดิมยังต้องปรับให้ครบตาม baseline นี้ก่อน rebuild/capture รอบใหม่

---

## ก่อนเริ่ม — Pre-flight Verification

> **ก่อน SSH เข้า VM** — image build เป็น standalone workflow ใช้ temp env ใต้ `build/tmp/` และลบทิ้งหลังจบงาน

| เช็ค | ได้จาก | ถ้ายังไม่พร้อม |
|---|---|---|
| Guest image Ubuntu 26.04 สร้างเสร็จแล้ว | `_guest-images.md` → Ubuntu 26.04 ✅ เสร็จ | ต้องสร้าง guest image ก่อน |
| VM สร้างจาก guest image ที่ผ่าน Set 1-3 ครบ | `build/tmp/nextcloud-build.env` หรือ output ที่ user ส่งมา | สร้าง VM จาก guest image |
| Build guide พร้อม `[รอ rebuild]` | header tag บน | ต้องปรับ source/docs ให้ตรง baseline นี้ก่อน build |
| SSH/OpenStack credentials | `build/tmp/nextcloud-build.env` | เติมเฉพาะตอน build แล้วลบทิ้ง |

**เมื่อ SSH เข้า VM แล้ว — verify บน VM:**

```bash
lsb_release -a | grep Release          # ต้อง: 26.04 หรือ codename "resolute"
grep URIs /etc/apt/sources.list.d/ubuntu.sources  # ต้อง: mirrors.openlandscape.cloud หรือ mirror1.ku.ac.th
curl -sI https://download.docker.com | head -1    # ต้อง: HTTP/2 200
df -h /                                   # ต้อง: Avail > 5G
```

---

## โครงสร้างไฟล์

```text
/opt/nextcloud/docker-compose.yml
/opt/nextcloud/nginx/default.conf
/opt/nextcloud/nginx/default-https.conf
/opt/nextcloud/certs/                         (ว่าง — รอวาง cert)
/etc/nextcloud-image/image.conf               (metadata, no secret)
/usr/local/sbin/nextcloud-bootstrap.sh
/etc/systemd/system/nextcloud-bootstrap.service
/root/README-nextcloud-image.txt
/etc/update-motd.d/99-nextcloud-image

/var/lib/nextcloud/app/                       (Nextcloud app/data bind mount)
/var/lib/nextcloud/db/                        (PostgreSQL data bind mount)
/var/lib/nextcloud/redis/                     (Redis data bind mount)
```

แนวคิด path:

| Path | ใช้ทำอะไร | แก้บ่อยไหม |
|---|---|---|
| `/opt/nextcloud/` | compose/config/control files | บางครั้ง |
| `/var/lib/nextcloud/` | runtime data จริงทั้งหมด | ไม่ควรแก้ตรงถ้าไม่จำเป็น |
| `/root/nextcloud-credentials.txt` | admin/DB credentials ของ VM นั้น | อ่านเมื่อจำเป็น, ห้าม dump ลง repo/chat |
| `/etc/nextcloud-image/` | metadata ของ image ไม่มี secret | ใช้ช่วย debug |

ไฟล์ที่ต้องไม่มีใน Golden Image:
```text
/opt/nextcloud/.env
/root/nextcloud-credentials.txt
/var/log/nextcloud-bootstrap.log
Docker volumes
/var/lib/nextcloud/* runtime data จาก test
Docker containers จาก test
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
mkdir -p /opt/nextcloud/{nginx,certs} /etc/nextcloud-image /var/lib/nextcloud/{app,db,redis}
chmod 700 /opt/nextcloud/certs
```

### 4. คัดลอกไฟล์ static

> **Reference:** Source files อยู่ใน `build/apps/nextcloud/` — ใช้ตรวจสอบหรือ copy โดยตรงก็ได้

ไฟล์ที่ต้องวางบน VM ก่อน build image:
- `docker-compose.yml` → `/opt/nextcloud/docker-compose.yml`
- `nginx/default.conf` → `/opt/nextcloud/nginx/default.conf`
- `nginx/default-https.conf` → `/opt/nextcloud/nginx/default-https.conf`
- `nextcloud-bootstrap.sh` → `/usr/local/sbin/nextcloud-bootstrap.sh` (chmod +x)
- `nextcloud-bootstrap.service` → `/etc/systemd/system/nextcloud-bootstrap.service`
- `README-nextcloud-image.txt` → `/root/README-nextcloud-image.txt`
- `99-nextcloud-image` → `/etc/update-motd.d/99-nextcloud-image` (chmod +x)
- `image.conf` → `/etc/nextcloud-image/image.conf` (no secret)

**docker-compose.yml**

```yaml
services:
  db:
    image: postgres:16.9
    volumes:
      - /var/lib/nextcloud/db:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  redis:
    image: redis:7.4-alpine
    volumes:
      - /var/lib/nextcloud/redis:/data
    restart: unless-stopped

  nextcloud:
    image: nextcloud:30.0-apache
    volumes:
      - /var/lib/nextcloud/app:/var/www/html
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_HOST: db
      NEXTCLOUD_ADMIN_USER: ${NEXTCLOUD_ADMIN_USER}
      NEXTCLOUD_ADMIN_PASSWORD: ${NEXTCLOUD_ADMIN_PASSWORD}
      NEXTCLOUD_TRUSTED_DOMAINS: ${NEXTCLOUD_TRUSTED_DOMAINS}
      PHP_MEMORY_LIMIT: 512M
      PHP_UPLOAD_LIMIT: 512M
      REDIS_HOST: redis
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    restart: unless-stopped

  nginx:
    image: nginx:1.27-alpine
    ports:
      - "80:80"
    volumes:
      - /var/lib/nextcloud/app:/var/www/html:ro
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - nextcloud
    restart: unless-stopped
    profiles:
      - http
      - default

  nginx-https:
    image: nginx:1.27-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/lib/nextcloud/app:/var/www/html:ro
      - ./nginx/default-https.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certs/fullchain.pem:/etc/nginx/certs/fullchain.pem:ro
      - ./certs/privkey.pem:/etc/nginx/certs/privkey.pem:ro
    depends_on:
      - nextcloud
    restart: unless-stopped
    profiles:
      - https

```

> **ภาพรวม:** nextcloud:30.0-apache + postgres:16.9 + redis:7.4-alpine + nginx:1.27-alpine
> Nextcloud รองรับ PostgreSQL 16 ตาม docs — PHP 8.4 built-in
> trusted_domains ถูก inject อัตโนมัติจาก env var NEXTCLOUD_TRUSTED_DOMAINS
> Pin patch/minor เป็น baseline; ก่อน build จริงต้อง verify tag/digest และ arch `linux/amd64`

**nginx/default.conf**

```nginx
server {
    listen 80;
    server_name _;

    client_max_body_size 512M;
    client_body_timeout 300s;

    location / {
        proxy_pass http://nextcloud;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location ~ /\. {
        deny all;
    }
}
```

**nginx/default-https.conf**

```nginx
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
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    client_max_body_size 512M;
    client_body_timeout 300s;

    location / {
        proxy_pass http://nextcloud;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location ~ /\. {
        deny all;
    }
}
```

> **`proxy_set_header X-Forwarded-Proto $scheme`** — Nextcloud ใช้ Detect HTTPS ผ่าน proxy header → ไม่ต้องแก้ config.php

**nextcloud-bootstrap.sh**

```bash
#!/bin/bash
set -e

ENV_FILE="/opt/nextcloud/.env"
CRED_FILE="/root/nextcloud-credentials.txt"
LOG_FILE="/var/log/nextcloud-bootstrap.log"
COMPOSE_DIR="/opt/nextcloud"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

get_floating_ip() {
    local ip=""
    ip=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || true)
    if [ -z "$ip" ]; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
    fi
    echo "$ip"
}

nextcloud_occ() {
    docker compose exec -T -u www-data nextcloud sh -lc "cd /var/www/html && php occ $*"
}

wait_for_install() {
    log "Bootstrap: waiting for Nextcloud install"
    for i in $(seq 1 60); do
        if nextcloud_occ status 2>/dev/null | grep -q "installed: true"; then
            log "Bootstrap: Nextcloud installed"
            return 0
        fi
        sleep 5
    done

    log "Bootstrap: Nextcloud install did not complete"
    return 1
}

set_trusted_domains() {
    local ip="$1"

    if [ -n "$ip" ]; then
        log "Bootstrap: configuring trusted domain: $ip"
        nextcloud_occ config:system:set trusted_domains 1 --value="$ip"
    fi
    nextcloud_occ config:system:set trusted_domains 2 --value="localhost"
    nextcloud_occ config:system:set trusted_domains 3 --value="127.0.0.1"
}

if [ -f "$ENV_FILE" ]; then
    log "Bootstrap: .env exists — reusing config"
    FLOATING_IP=$(get_floating_ip)
    CURRENT_DOMAINS=$(grep NEXTCLOUD_TRUSTED_DOMAINS "$ENV_FILE" | cut -d= -f2-)
    if ! echo "$CURRENT_DOMAINS" | grep -q "$FLOATING_IP"; then
        log "Bootstrap: IP changed to $FLOATING_IP — updating trusted_domains"
        sed -i "s/^NEXTCLOUD_TRUSTED_DOMAINS=.*/NEXTCLOUD_TRUSTED_DOMAINS=${FLOATING_IP} localhost 127.0.0.1/" "$ENV_FILE"
    fi
    cd "$COMPOSE_DIR"
    docker compose up -d
    wait_for_install
    set_trusted_domains "$FLOATING_IP"
    log "Bootstrap: done"
    exit 0
fi

log "Bootstrap: first boot — generating secrets"

FLOATING_IP=$(get_floating_ip)
log "Bootstrap: detected IP = $FLOATING_IP"

POSTGRES_DB="nextcloud"
POSTGRES_USER="nextcloud"
POSTGRES_PASSWORD=$(openssl rand -base64 24)
POSTGRES_HOST="db"
NEXTCLOUD_ADMIN_USER="admin"
NEXTCLOUD_ADMIN_PASSWORD=$(openssl rand -base64 18)

TRUSTED_DOMAINS="$FLOATING_IP localhost 127.0.0.1"

cat > "$ENV_FILE" << EOF
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_HOST=${POSTGRES_HOST}
NEXTCLOUD_ADMIN_USER=${NEXTCLOUD_ADMIN_USER}
NEXTCLOUD_ADMIN_PASSWORD=${NEXTCLOUD_ADMIN_PASSWORD}
NEXTCLOUD_TRUSTED_DOMAINS=${TRUSTED_DOMAINS}
EOF
chmod 600 "$ENV_FILE"

cat > "$CRED_FILE" << EOF
=== Nextcloud Docker Credentials ===
Generated: $(date)
VM IP: ${FLOATING_IP}

Nextcloud Admin:
  URL:      http://${FLOATING_IP}
  User:     ${NEXTCLOUD_ADMIN_USER}
  Password: ${NEXTCLOUD_ADMIN_PASSWORD}

PostgreSQL Database:
  Host:     ${POSTGRES_HOST}
  Name:     ${POSTGRES_DB}
  User:     ${POSTGRES_USER}
  Password: ${POSTGRES_PASSWORD}

Config Files (editable on host):
  /opt/nextcloud/nginx/default.conf       — HTTP Nginx config
  /opt/nextcloud/nginx/default-https.conf — HTTPS Nginx config

Manage:
  cd /opt/nextcloud
  docker compose ps                — check status
  docker compose logs -f           — view logs
  docker compose restart            — restart all

Enable HTTPS:
  1. Point DNS → VM floating IP (${FLOATING_IP})
  2. Place certs: /opt/nextcloud/certs/fullchain.pem + privkey.pem
  3. chmod 644 /opt/nextcloud/certs/fullchain.pem
  4. chmod 600 /opt/nextcloud/certs/privkey.pem
  5. cd /opt/nextcloud && docker compose --profile https up -d
EOF
chmod 600 "$CRED_FILE"

log "Bootstrap: starting services"
if [ -f "$COMPOSE_DIR/certs/fullchain.pem" ] && [ -f "$COMPOSE_DIR/certs/privkey.pem" ]; then
    log "Bootstrap: HTTPS certs found — using https profile"
    docker compose --profile https up -d
else
    log "Bootstrap: using http profile"
    docker compose --profile http up -d
fi

log "Bootstrap: waiting for Nextcloud to be ready..."
wait_for_install
set_trusted_domains "$FLOATING_IP"

log "Bootstrap: done"
```

**nextcloud-bootstrap.service**

```ini
[Unit]
Description=Nextcloud Docker Bootstrap
After=docker.service network-online.target
Wants=docker.service network-online.target
ConditionPathExists=/opt/nextcloud/docker-compose.yml

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/nextcloud-bootstrap.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**README-nextcloud-image.txt**

```text
=== Nextcloud Docker Image — Ubuntu 26.04 ===

Access:  http://<YOUR-VM-IP>
Setup:   Login with admin credentials below

Credentials:
  Admin URL:  http://<YOUR-VM-IP>
  Admin user: admin
  Password:   /root/nextcloud-credentials.txt

Database credentials: /root/nextcloud-credentials.txt

Directory:
  /opt/nextcloud/                     Compose/config/control files
    docker-compose.yml                Service definitions
    nginx/default.conf                HTTP Nginx config
    nginx/default-https.conf          HTTPS template
    certs/                            Place TLS certs here

Data:
  /var/lib/nextcloud/app              Nextcloud app + user files
  /var/lib/nextcloud/db               PostgreSQL data
  /var/lib/nextcloud/redis            Redis data

Metadata:
  /etc/nextcloud-image/image.conf     Image layout/mode info, no secret

Common Commands:
  cd /opt/nextcloud
  docker compose ps                   Check status
  docker compose logs -f              View logs
  docker compose restart              Restart all services
  docker compose restart nextcloud    Restart Nextcloud only

Restart ทั้ง stack ทำยังไง:
  docker compose restart              # restart ทั้งหมด
  docker compose restart nginx        # restart แค่ nginx

Enable HTTPS:
  1. Point DNS → VM floating IP
  2. Place certs: /opt/nextcloud/certs/fullchain.pem + privkey.pem
  3. chmod 644 /opt/nextcloud/certs/fullchain.pem
  4. chmod 600 /opt/nextcloud/certs/privkey.pem
  5. docker compose --profile https up -d

Backup:
   DB:   docker compose exec db pg_dump -U nextcloud nextcloud > nc-backup.sql
   Data: tar czf nc-data-backup.tar.gz -C /var/lib nextcloud

Restore:
  DB:   docker compose exec -T db psql -U nextcloud nextcloud < nc-backup.sql

SMTP:
  Use Nextcloud Mail SMTP plugin → configure external SMTP server

Upgrade Nextcloud:
   docker compose exec -u33 nextcloud ./occ maintenance:mode --on
   docker compose pull nextcloud
   docker compose up -d
   docker compose exec -u33 nextcloud ./occ maintenance:mode --off
```

**image.conf**

```ini
APP_NAME=nextcloud
IMAGE_BASE=ubuntu-26.04
INSTALL_MODE=auto-install
ADMIN_USER=admin
COMPOSE_DIR=/opt/nextcloud
DATA_DIR=/var/lib/nextcloud
APP_DATA_DIR=/var/lib/nextcloud/app
DB_DATA_DIR=/var/lib/nextcloud/db
REDIS_DATA_DIR=/var/lib/nextcloud/redis
CREDENTIAL_FILE=/root/nextcloud-credentials.txt
BOOTSTRAP_LOG=/var/log/nextcloud-bootstrap.log
FIRST_BOOT_INTERNET_REQUIRED=false
HTTPS_MODE=user-provided-cert
```

**99-nextcloud-image**

```bash
#!/bin/bash
echo ""
echo "  Nextcloud Docker — Ubuntu 26.04"
echo "  ================================"
echo "  Access:   http://<YOUR-VM-IP>"
echo "  Admin:    admin"
echo "  Creds:    /root/nextcloud-credentials.txt"
echo "  Docs:     /root/README-nextcloud-image.txt"
echo "  Config:   /opt/nextcloud"
echo "  Data:     /var/lib/nextcloud"
echo "  Manage:   cd /opt/nextcloud && docker compose ps"
echo ""
```

### 5. เปิด systemd service

[golden-image VM]

```bash
systemctl daemon-reload
systemctl enable nextcloud-bootstrap.service

# ⚠️ ต้อง verify ว่า enable สำเร็จ — ถ้า disabled snapshot จะไม่ทำงาน!
systemctl is-enabled nextcloud-bootstrap.service
# ต้องได้ output: enabled
```

### 6. Pre-pull images + ทดสอบ bootstrap

[golden-image VM]

```bash
# Pre-pull images — ทำไว้ก่อน snapshot
# ประโยชน์: VM ที่สร้างจาก image boot ครั้งแรกได้โดยไม่พึ่ง internet
# ห้ามลบ images ตอน cleanup!
docker pull postgres:16.9
docker pull redis:7.4-alpine
docker pull nextcloud:30.0-apache
docker pull nginx:1.27-alpine

# ทดสอบ bootstrap (จะสร้าง .env, start services)
# ถ้าสำเร็จจะเห็น: Bootstrap: done และ occ status ต้อง installed: true
/usr/local/sbin/nextcloud-bootstrap.sh
```

### 7. Cleanup ก่อน capture

[golden-image VM]

Runtime files เช่น `.env`, `nextcloud-credentials.txt`, bootstrap log และ `/var/lib/nextcloud/*` เป็น temp data จากการทดสอบ ต้องลบก่อน capture เสมอ เพื่อให้ VM ใหม่ที่สร้างจาก image bootstrap แล้วสร้าง secrets/data ชุดใหม่เอง

```bash
cd /opt/nextcloud

# Stop HTTPS profile (if tested)
docker compose --profile https down --remove-orphans 2>/dev/null

# Stop all services + remove volumes (ไม่ลบ images)
docker compose down -v

# ลบ runtime/temp data ก่อน capture — ห้ามเก็บ secret เข้า image
rm -f /opt/nextcloud/.env /root/nextcloud-credentials.txt /var/log/nextcloud-bootstrap.log
rm -rf /var/lib/nextcloud/app/* /var/lib/nextcloud/db/* /var/lib/nextcloud/redis/*
docker volume prune -f

# ⚠️ ห้ามใช้ docker image prune -a !!!
# เพราะจะลบ pulled images ที่ pre-pull ไว้ — ต้องเก็บไว้ใน image สุดท้าย
```

### 8. Final check + poweroff

[golden-image VM]

```bash
# 1. ต้องมี service enabled
systemctl is-enabled nextcloud-bootstrap.service
# ต้องได้: enabled (ถ้าได้ disabled → ทำใหม่ที่ข้อ 5)

# 2. ตรวจสอบไฟล์ที่ต้องมี
ls -l /opt/nextcloud/docker-compose.yml
ls -l /opt/nextcloud/nginx/default.conf
ls -l /opt/nextcloud/nginx/default-https.conf
ls -l /usr/local/sbin/nextcloud-bootstrap.sh
ls -l /root/README-nextcloud-image.txt
ls -l /etc/update-motd.d/99-nextcloud-image
ls -l /etc/nextcloud-image/image.conf

# 3. ตรวจสอบว่า containers ไม่มีรันอยู่
docker compose -f /opt/nextcloud/docker-compose.yml ps
# ต้องไม่มี container แสดง

# 4. ตรวจสอบ Docker images ที่ pre-pull ไว้ (ต้องยังอยู่)
docker images | grep -E "postgres|redis|nextcloud|nginx"
# ต้องเห็น: postgres:16.9, redis:7.4-alpine, nextcloud:30.0-apache, nginx:1.27-alpine

# 5. ตรวจสอบว่าไม่มี .env หรือ credentials
ls -la /opt/nextcloud/.env 2>/dev/null || echo ".env: ไม่มี (ถูกต้อง)"
ls -la /root/nextcloud-credentials.txt 2>/dev/null || echo "credentials: ไม่มี (ถูกต้อง)"

# 6. ตรวจสอบว่าไม่มี volumes จาก test bootstrap
if docker volume ls --format '{{.Name}}' | grep -qi nextcloud; then
  echo "ERROR: runtime volumes remain"
  exit 1
fi
echo "volumes: ไม่มี (ถูกต้อง)"

# ทุกอย่างถูกต้อง → ปิดเครื่อง
poweroff
```

จากนั้น snapshot/create image ใน OpenStack:

[OpenStack client]

```text
ubuntu-26.04-nextcloud-30-YYYYMMDD
```

---

## Bootstrap Logic

| สถานะ | พฤติกรรม |
|---|---|
| VM ใหม่ (ไม่มี `.env`) | ตรวจ floating IP → สุ่ม secrets → สร้าง .env + credentials → start |
| Reboot (มี `.env` แล้ว) | ใช้ค่าเดิม, start containers |
| ก่อน capture image | ต้องลบ `.env`, `nextcloud-credentials.txt`, bootstrap log, และ volumes |
| VM ใหม่จาก image ที่ cleanup แล้ว | bootstrap สร้าง `.env` + credentials ชุดใหม่ตอน boot ครั้งแรก |
| Snapshot VM ที่ใช้งานแล้ว | clone data เดิม — ไม่ใช่ golden image fresh boot |
| HTTPS | วาง cert + `docker compose --profile https up -d` |

---

## วิธีเปิด HTTPS

### ขั้นตอน

1. ชี้ DNS ไป Floating IP
2. วาง cert: `/opt/nextcloud/certs/fullchain.pem`, `/opt/nextcloud/certs/privkey.pem`
3. `[nextcloud-vm]` `chmod 644 /opt/nextcloud/certs/fullchain.pem && chmod 600 /opt/nextcloud/certs/privkey.pem`
4. เปิด HTTPS:
   ```bash
   cd /opt/nextcloud
   docker compose --profile https up -d
   ```
5. ตรวจสอบ:
   ```bash
   curl -sI https://yourdomain.com | head -1
   # HTTP/2 200
   ```

> Nextcloud รู้จัก HTTPS อัตโนมัติผ่าน `X-Forwarded-Proto` จาก nginx → ไม่ต้องแก้ config หรือ DB

### ได้ Certificate จากไหน

| วิธี | เหมาะกับ | ขั้นตอน |
|---|---|---|
| **ซื้อ cert** | องค์กร, ต้องการ trusted CA | ซื้อจาก DigiCert, GoDaddy, Namecheap ฯลฯ |
| **Let's Encrypt (แนะนำ)** | ทุกคน — ฟรี, trusted | `certbot certonly --manual -d yourdomain.com` |
| **Cert จากองค์กร** | มี wildcard cert อยู่แล้ว | copy cert ไปวางที่ `certs/` |

### Let's Encrypt วิธีทำ (manual, optional)

```bash
# 1. ติดตั้ง certbot
apt install certbot

# 2. ขอ cert (ต้องมี DNS ชี้มาที่ IP แล้ว)
certbot certonly --manual -d yourdomain.com --preferred-challenges dns

# 3. จะได้ไฟล์ 2 ไฟล์:
#   /etc/letsencrypt/live/yourdomain.com/fullchain.pem
#   /etc/letsencrypt/live/yourdomain.com/privkey.pem

# 4. copy ไปวาง
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem /opt/nextcloud/certs/
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem /opt/nextcloud/certs/

# 5. ทำขั้นตอน 3-5 ข้างบนได้เลย
```

### Auto-renew Let's Encrypt (optional)

> รอบ rebuild นี้ยังไม่ใส่ certbot helper เป็น default ใน image; ถ้าต้องการ auto-renew ให้ user ทำเพิ่มเองหลังมี domain/HTTPS พร้อมแล้ว

```bash
# สร้าง renew script
cat > /usr/local/sbin/nc-cert-renew.sh << 'EOF'
#!/bin/bash
certbot renew --quiet --deploy-hook "docker compose -f /opt/nextcloud/docker-compose.yml restart nginx-https"
EOF
chmod +x /usr/local/sbin/nc-cert-renew.sh

# เพิ่ม cron job (ทุกวันเช้า 03:00)
echo "0 3 * * * /usr/local/sbin/nc-cert-renew.sh" >> /etc/crontab
```

---

## Backup & Restore

### Backup

```bash
# Backup database
cd /opt/nextcloud
docker compose exec db pg_dump -U nextcloud nextcloud > nc-db-backup-$(date +%Y%m%d).sql

# Backup runtime data ทั้งหมด
tar czf nc-data-backup-$(date +%Y%m%d).tar.gz -C /var/lib nextcloud

# Backup config/control files แบบไม่เปิด secret ใน chat/repo
tar czf nc-config-backup-$(date +%Y%m%d).tar.gz -C /opt nextcloud
```

### Restore

```bash
# Restore database
cd /opt/nextcloud
docker compose exec -T db psql -U nextcloud nextcloud < nc-db-backup-YYYYMMDD.sql

# Restore data
tar xzf nc-data-backup-YYYYMMDD.tar.gz -C /var/lib
docker compose restart
```

---

## Upgrade Nextcloud

```bash
cd /opt/nextcloud

# Put in maintenance mode
docker compose exec -u33 nextcloud ./occ maintenance:mode --on

# Pull new image
docker compose pull nextcloud

# Restart with new image
docker compose up -d

# Turn off maintenance mode
docker compose exec -u33 nextcloud ./occ maintenance:mode --off
```

---

## ข้อควรระวัง

- `/opt/nextcloud/.env` มี password — ห้ามลบหลังใช้งานแล้ว
- ห้ามลบ `/var/lib/nextcloud` บนเครื่องลูกค้า — เป็น data จริงทั้งหมด
- ถ้าจะย้ายไป attached volume ให้ stop containers, rsync `/var/lib/nextcloud/`, แล้ว mount volume ใหม่ที่ path เดิม `/var/lib/nextcloud`
- ถ้าสลับระหว่าง HTTP ↔ HTTPS ต้อง `docker compose stop nginx` ก่อนเปลี่ยน profile
- Snapshot VM → VM ใหม่เป็น clone (data เดิม) ไม่ใช่ fresh instance
- SMTP → ใช้ Nextcloud Mail SMTP plugin ตั้งค่า SMTP ภายนอก
- หลังแก้ config ใดๆ → restart ทั้ง stack เสมอ (`docker compose restart`) ไม่ใช่แค่ container เดียว
- ถ้า trusted_domains ไม่ถูกต้อง → เปิดเว็บไม่ได้ → bootstrap รีเฟรชอัตโนมัติตอน reboot; แก้ manual: `NEXTCLOUD_TRUSTED_DOMAINS` ใน `.env` แล้ว `docker compose restart nextcloud`
- ⚠️ **ทุก `docker compose` command ต้อง `--profile http`** — nginx อยู่ใน profile ถ้าใช้ `docker compose down/restart` โดยไม่มี `--profile http` → nginx ไม่ถูก manage → port 80 ถูกจอง → container ใหม่ล้มเหลว

---

## Admin Password Reset

### วิธี 1: `occ` (แนะนำ)

```bash
cd /opt/nextcloud
docker compose exec -u33 nextcloud ./occ user:resetpassword admin
# ใส่ password ใหม่
```

### วิธี 2: ผ่าน Web UI

1. เปิด `http://<IP>/login`
2. กด "Forgot password?"
3. ใส่ admin username → ส่ง reset link ไป email (ต้องตั้ง SMTP ก่อน)

## Glance Image Properties

| Property | ค่า |
|---|---|
| ชื่อ | `ubuntu-26.04-nextcloud-30-YYYYMMDD` |
| OS distro | `ubuntu` |
| OS version | `26.04` |
| Architecture | `x86_64` |
| Min disk | `20 GB` |
| Min RAM | `2048 MB` |
| Image type | `app` |
| Tags | `nextcloud, file-sharing, docker, postgresql, redis` |

---

## Record Build Manifest

หลัง pre-capture gate ผ่าน ให้สร้าง/อัปเดต `build/apps/nextcloud/nextcloud-build-manifest.md` ด้วยข้อมูล version ที่ verify จาก golden-image VM เท่านั้น:

```bash
lsb_release -ds
docker version
docker compose version
docker buildx version
dpkg-query -W docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker images --digests --format '{{.Repository}}:{{.Tag}} {{.Digest}}'
```

เก็บเฉพาะ Base OS, Docker stack package versions แบบ minimal, Docker/Compose/Buildx versions, container image tag + digest และ build notes สั้นๆ. ห้ามเก็บ image name, Glance ID, server ID, floating IP, VM IP, hostname, OpenStack context หรือ credentials.
