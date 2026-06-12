# WordPress Image — Ubuntu 26.04  [พร้อม build]

> Image สำเร็จรูป: สร้าง VM → เปิด browser setup WordPress ผ่าน web UI (5 นาที) รองรับ HTTPS

---

## เป้าหมาย

```text
ลูกค้าสร้าง VM จาก Image
→ systemd เรียก wordpress-bootstrap.sh
→ สุ่ม MariaDB root/user password
→ สร้าง /opt/wordpress/.env + /root/wordpress-credentials.txt
→ start MariaDB + WordPress + Nginx
→ ลูกค้าเปิด http://<IP> ทำ 5-minute install เอง
```

| โหมด | รายละเอียด |
|---|---|
| HTTP | พร้อมใช้ทันที `http://<IP>` |
| HTTPS | วาง cert/key, ตั้ง DOMAIN, `docker compose stop nginx && docker compose --profile https up -d` |

---

## ก่อนเริ่ม — Pre-flight Verification

> **ก่อน SSH เข้า VM** — verify จาก docs ที่มีอยู่แล้ว ห้ามถาม user ถ้าหาคำตอบได้เอง

| เช็ค | ได้จาก | ถ้ายังไม่พร้อม |
|---|---|---|
| Guest image Ubuntu 26.04 สร้างเสร็จแล้ว | `_guest-images.md` → Ubuntu 26.04 ✅ เสร็จ | ต้องสร้าง guest image ก่อน |
| VM สร้างจาก guest image ที่ผ่าน Set 1-3 ครบ | cluster `inventory/vm.md` | สร้าง VM จาก guest image |
| Build guide พร้อม `[พร้อม build]` | header tag บน | ต้องสร้าง source files ก่อน |
| SSH credentials | `clusters/{name}/.env` | — |

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
/opt/wordpress/docker-compose.yml
/opt/wordpress/nginx/default.conf
/opt/wordpress/nginx/default-https.conf
/opt/wordpress/php/wordpress.ini
/opt/wordpress/certs/                         (ว่าง — รอวาง cert)
/usr/local/sbin/wordpress-bootstrap.sh
/etc/systemd/system/wordpress-bootstrap.service
/root/README-wordpress-image.txt
/etc/update-motd.d/99-wordpress-image
```

ไฟล์ที่ต้องไม่มีใน Golden Image:
```text
/opt/wordpress/.env
/root/wordpress-credentials.txt
/var/log/wordpress-bootstrap.log
Docker volumes
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
mkdir -p /opt/wordpress/{nginx,php,certs}
chmod 700 /opt/wordpress/certs
```

### 4. คัดลอกไฟล์ static

> **Reference:** Source files อยู่ใน `build/wordpress/` — ใช้ตรวจสอบหรือ copy โดยตรงก็ได้

ไฟล์ที่ต้องวางบน VM ก่อน build image:
- `docker-compose.yml` → `/opt/wordpress/docker-compose.yml`
- `default.conf` → `/opt/wordpress/nginx/default.conf`
- `default-https.conf` → `/opt/wordpress/nginx/default-https.conf`
- `wordpress.ini` → `/opt/wordpress/php/wordpress.ini`
- `wordpress-bootstrap.sh` → `/usr/local/sbin/wordpress-bootstrap.sh` (chmod +x)
- `wordpress-bootstrap.service` → `/etc/systemd/system/wordpress-bootstrap.service`
- `README-wordpress-image.txt` → `/root/README-wordpress-image.txt`
- `99-wordpress-image` → `/etc/update-motd.d/99-wordpress-image` (chmod +x)

**docker-compose.yml**

```yaml
services:
  db:
    image: mariadb:lts
    volumes:
      - db_data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  wordpress:
    image: wordpress:php8.3-fpm
    volumes:
      - wp_data:/var/www/html
      - ./php/wordpress.ini:/usr/local/etc/php/conf.d/zz-wordpress.ini:ro
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  nginx:
    image: nginx:1.27
    ports:
      - "80:80"
    volumes:
      - wp_data:/var/www/html:ro
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - wordpress
    restart: unless-stopped

  nginx-https:
    image: nginx:1.27
    profiles:
      - https
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - wp_data:/var/www/html:ro
      - ./nginx/default-https.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certs/fullchain.pem:/etc/nginx/certs/fullchain.pem:ro
      - ./certs/privkey.pem:/etc/nginx/certs/privkey.pem:ro
    depends_on:
      - wordpress
    restart: unless-stopped

volumes:
  db_data:
  wp_data:
```

> **ภาพรวม:** MariaDB:lts (11.4 LTS), WordPress:php8.3-fpm, Nginx:1.27 — ทั้งหมด Debian-based UID=33 (www-data) ตรงกัน → mount volume ข้าม container ได้ไม่มี permission issue

**nginx/default.conf**

```nginx
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.php;

    client_max_body_size 128m;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param HTTPS $https if_not_empty;
    }

    location ~ /\. {
        deny all;
    }

    location = /xmlrpc.php {
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

    root /var/www/html;
    index index.php;

    client_max_body_size 128m;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param HTTPS $https if_not_empty;
    }

    location ~ /\. {
        deny all;
    }

    location = /xmlrpc.php {
        deny all;
    }
}
```

> **`fastcgi_param HTTPS $https if_not_empty`** — Nginx ส่ง `$_SERVER['HTTPS']='on'` ให้ WordPress โดยอัตโนมัติเมื่อเชื่อมต่อผ่าน HTTPS ไม่ต้องแก้ wp-config และไม่ต้องใช้ X-Forwarded-Proto

**php/wordpress.ini**

```ini
; WordPress PHP Settings
; แก้ไฟล์นี้บน host → docker compose restart wordpress

memory_limit = 512M
upload_max_filesize = 128M
post_max_size = 128M
max_execution_time = 600
max_input_time = 600
max_input_vars = 3000
```

**wordpress-bootstrap.sh**

```bash
#!/bin/bash
set -e

ENV_FILE="/opt/wordpress/.env"
CRED_FILE="/root/wordpress-credentials.txt"
LOG_FILE="/var/log/wordpress-bootstrap.log"
COMPOSE_DIR="/opt/wordpress"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

# Already initialized — just start
if [ -f "$ENV_FILE" ]; then
    log "Bootstrap: .env exists — starting services"
    cd "$COMPOSE_DIR"
    docker compose up -d
    log "Bootstrap: done (reusing existing config)"
    exit 0
fi

log "Bootstrap: first boot — generating secrets"

MYSQL_ROOT_PASSWORD=$(openssl rand -base64 24)
MYSQL_DATABASE="wordpress"
MYSQL_USER="wordpress"
MYSQL_PASSWORD=$(openssl rand -base64 24)

cat > "$ENV_FILE" << EOF
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE=${MYSQL_DATABASE}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
EOF
chmod 600 "$ENV_FILE"

cat > "$CRED_FILE" << EOF
=== WordPress Docker Credentials ===
Generated: $(date)

Database:
  Host:     db (internal Docker network)
  Name:     ${MYSQL_DATABASE}
  User:     ${MYSQL_USER}
  Password: ${MYSQL_PASSWORD}

Root DB Password: ${MYSQL_ROOT_PASSWORD}

WordPress Setup:
  Open http://<VM-IP> in browser
  → Follow the 5-minute install wizard
  → Create your own admin account + password

Config Files (editable on host):
  /opt/wordpress/php/wordpress.ini    — PHP settings
  /opt/wordpress/nginx/default.conf   — Nginx config

Manage:
  cd /opt/wordpress
  docker compose ps        # check status
  docker compose logs -f   # view logs
  docker compose restart   # restart all
EOF
chmod 600 "$CRED_FILE"

log "Bootstrap: pulling images"
cd "$COMPOSE_DIR"
docker compose pull

log "Bootstrap: starting services"
docker compose up -d

log "Bootstrap: waiting for WordPress to be ready..."
for i in $(seq 1 30); do
    if docker compose exec -T wordpress php -r "echo 'ok';" 2>/dev/null | grep -q ok; then
        log "Bootstrap: WordPress is ready"
        break
    fi
    sleep 2
done

log "Bootstrap: done — open http://<VM-IP> to complete WordPress setup"
```

**wordpress-bootstrap.service**

```ini
[Unit]
Description=WordPress Docker Bootstrap
After=docker.service network-online.target
Wants=docker.service network-online.target
ConditionPathExists=/opt/wordpress/docker-compose.yml

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/wordpress-bootstrap.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**README-wordpress-image.txt**

```text
=== WordPress Docker Image — Ubuntu 26.04 ===

Access:  http://<VM-IP>
Setup:   Open in browser → follow 5-minute WordPress install wizard

Credentials:
  DB credentials: /root/wordpress-credentials.txt
  WordPress admin: YOU create during setup wizard

Directory:
  /opt/wordpress/                     Main directory
    docker-compose.yml                Service definitions
    nginx/default.conf                Nginx config (editable)
    nginx/default-https.conf          HTTPS template
    php/wordpress.ini                 PHP settings (editable)
    certs/                            Place TLS certs here

Common Commands:
  cd /opt/wordpress
  docker compose ps                   Check status
  docker compose logs -f              View logs
  docker compose restart              Restart ALL services (wordpress + nginx + db)
  docker compose restart wordpress    Restart after editing php/wordpress.ini
  docker compose restart nginx        Restart after editing nginx/default.conf

Restart ทั้ง stack ทำยังไง:
  docker compose restart               # restart ทั้งหมด
  docker compose restart nginx        # restart แค่ nginx
  docker compose restart wordpress    # restart แค่ wordpress

หลังแก้ php หรือ nginx → restart ตัวที่แก้ + อีกตัวด้วยเสมอ:
  แก้ wordpress.ini  →  docker compose restart wordpress nginx
  แก้ nginx config   →  docker compose restart nginx wordpress

Enable HTTPS:
  1. Point DNS → VM floating IP
  2. Place certs: /opt/wordpress/certs/fullchain.pem + privkey.pem
  3. chmod 644 fullchain.pem && chmod 600 privkey.pem
  4. Set domain:  echo "DOMAIN=yourdomain.com" >> /opt/wordpress/.env
  5. Stop HTTP:   docker compose stop nginx
  6. Start HTTPS: docker compose --profile https up -d
  7. WordPress auto-detects HTTPS via $_SERVER['HTTPS'] — no DB change needed

Backup:
  DB:   docker compose exec db mysqldump -u root -p"$(grep MYSQL_ROOT_PASSWORD .env | cut -d= -f2)" wordpress > db-backup.sql
  Files: tar czf wp-backup.tar.gz -C /opt/wordpress .env php/ nginx/
```

**99-wordpress-image**

```bash
#!/bin/bash
echo ""
echo "  WordPress Docker — Ubuntu 26.04"
echo "  ================================"
echo "  Setup:    http://<YOUR-VM-IP>"
echo "  Creds:    /root/wordpress-credentials.txt"
echo "  Dir:      /opt/wordpress"
echo "  Manage:   cd /opt/wordpress && docker compose ps"
if [ -f /opt/wordpress/.env ] && grep -q "^DOMAIN=" /opt/wordpress/.env 2>/dev/null; then
    DOMAIN=$(grep "^DOMAIN=" /opt/wordpress/.env | cut -d= -f2)
    echo "  HTTPS:    https://${DOMAIN}"
fi
echo ""
```

### 5. เปิด systemd service

[golden-image VM]

```bash
systemctl daemon-reload
systemctl enable wordpress-bootstrap.service

# ⚠️ ต้อง verify ว่า enable สำเร็จ — ถ้า disabled snapshot จะไม่ทำงาน!
systemctl is-enabled wordpress-bootstrap.service
# ต้องได้ output: enabled
```

### 6. ทดสอบ bootstrap + pull images

[golden-image VM]

```bash
# ทดสอบ bootstrap (จะสร้าง .env, start services)
# ถ้าสำเร็จจะเห็น: Bootstrap: done — open http://<VM-IP>
/usr/local/sbin/wordpress-bootstrap.sh

# Pre-pull images — ทำไว้ก่อน snapshot
# ประโยชน์: ลูกค้า boot VM ครั้งแรกใช้งานได้ทันที ไม่ต้องรอ 3-4 นาที
# ห้ามลบ images ตอน cleanup! (docker compose down -v ลบ container/volume ไม่ลบ images)
docker pull mariadb:lts
docker pull wordpress:php8.3-fpm
docker pull nginx:1.27
```

### 7. Cleanup ก่อน capture

[golden-image VM]

```bash
cd /opt/wordpress

# Stop nginx-https profile (if tested)
docker compose --profile https down --remove-orphans 2>/dev/null

# Stop all services + remove volumes (ไม่ลบ images)
docker compose down -v
rm -f /opt/wordpress/.env /root/wordpress-credentials.txt /var/log/wordpress-bootstrap.log
docker volume prune -f

# ⚠️ ห้ามใช้ docker image prune -a !!!
# เพราะจะลบ pulled images ที่ pre-pull ไว้ — ต้องเก็บไว้ใน image สุดท้าย
```

### 8. Final check + poweroff

[golden-image VM]

```bash
# 1. ต้องมี service enabled
systemctl is-enabled wordpress-bootstrap.service
# ต้องได้: enabled (ถ้าได้ disabled → ทำใหม่ที่ข้อ 5)

# 2. ตรวจสอบไฟล์ที่ต้องมี
ls -l /opt/wordpress/docker-compose.yml
ls -l /opt/wordpress/nginx/default.conf
ls -l /opt/wordpress/php/wordpress.ini
ls -l /usr/local/sbin/wordpress-bootstrap.sh

# 3. ตรวจสอบว่า containers ไม่มีรันอยู่ (docker compose down ทำงานแล้ว)
docker compose -f /opt/wordpress/docker-compose.yml ps
# ต้องไม่มี container แสดง

# 4. ตรวจสอบ Docker images ที่ pre-pull ไว้ (ต้องยังอยู่)
docker images | grep -E "mariadb|wordpress|nginx"
# ต้องเห็น: mariadb:lts, wordpress:php8.3-fpm, nginx:1.27

# 5. ตรวจสอบว่าไม่มี .env หรือ credentials
ls -la /opt/wordpress/.env 2>/dev/null || echo ".env: ไม่มี (ถูกต้อง)"
ls -la /root/wordpress-credentials.txt 2>/dev/null || echo "credentials: ไม่มี (ถูกต้อง)"

# ทุกอย่างถูกต้อง → ปิดเครื่อง
poweroff
```

จากนั้น snapshot/create image ใน OpenStack:

[OpenStack client]

```text
ubuntu-26.04-wordpress-php8.3-YYYYMM
```

---

## Bootstrap Logic

| สถานะ | พฤติกรรม |
|---|---|
| VM ใหม่ (ไม่มี `.env`) | สุ่ม DB password → สร้าง .env + credentials → start services |
| Reboot (มี `.env` แล้ว) | ใช้ค่าเดิม, start services |
| Snapshot + สร้าง VM ใหม่ | ใช้ข้อมูลเดิม — DB credentials คงเดิม |

---

## วิธีเปิด HTTPS

### ขั้นตอน

1. ชี้ DNS ไป Floating IP
2. วาง cert: `/opt/wordpress/certs/fullchain.pem`, `/opt/wordpress/certs/privkey.pem`
3. `chmod 644 /opt/wordpress/certs/fullchain.pem && chmod 600 /opt/wordpress/certs/privkey.pem`
4. ตั้ง DOMAIN:
   ```bash
   echo "DOMAIN=yourdomain.com" >> /opt/wordpress/.env
   ```
5. หยุด HTTP nginx, เปิด HTTPS:
   ```bash
   cd /opt/wordpress
   docker compose stop nginx
   docker compose --profile https up -d
   ```
6. ตรวจสอบ:
   ```bash
   curl -sI https://yourdomain.com | head -1
   # HTTP/2 200
   ```

> WordPress ใช้ HTTPS URL อัตโนมัติ — Nginx ส่ง `$_SERVER['HTTPS']` ผ่าน FastCGI → ไม่ต้องแก้ DB หรือ wp-config

### ได้ Certificate จากไหน

เลือกวิธีที่เหมาะสม:

| วิธี | เหมาะกับ | ขั้นตอน |
|---|---|---|
| **ซื้อ cert** | องค์กร, ต้องการ trusted CA | ซื้อจาก DigiCert, GoDaddy, Namecheap ฯลฯ |
| **Let's Encrypt (แนะนำ)** | ทุกคน — ฟรี, trusted | `certbot certonly --manual -d yourdomain.com` |
| **Cert จากองค์กร** | มี wildcard cert อยู่แล้ว | copy cert ไปวางที่ `certs/` |

### Let's Encrypt วิธีทำ (manual)

```bash
# 1. ติดตั้ง certbot
apt install certbot

# 2. ขอ cert (ต้องมี DNS ชี้มาที่ IP แล้ว)
certbot certonly --manual -d yourdomain.com --preferred-challenges dns

# 3. จะได้ไฟล์ 2 ไฟล์:
#   /etc/letsencrypt/live/yourdomain.com/fullchain.pem
#   /etc/letsencrypt/live/yourdomain.com/privkey.pem

# 4. copy ไปวาง
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem /opt/wordpress/certs/
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem /opt/wordpress/certs/

# 5. ทำขั้นตอน 3-6 ข้างบนได้เลย
```

### Auto-renew Let's Encrypt (optional)

```bash
# สร้าง renew script
cat > /usr/local/sbin/wp-cert-renew.sh << 'EOF'
#!/bin/bash
certbot renew --quiet --deploy-hook "docker compose -f /opt/wordpress/docker-compose.yml restart nginx-https"
chmod +x /usr/local/sbin/wp-cert-renew.sh

# เพิ่ม cron job (ทุกวันเช้า 03:00)
echo "0 3 * * * /usr/local/sbin/wp-cert-renew.sh" >> /etc/crontab
```

---

## ข้อควรระวัง

- `/opt/wordpress/.env` มี DB password — ห้ามลบหลังใช้งานแล้ว
- ห้าม `docker compose down -v` บนเครื่องลูกค้า — ลบ volume data ทั้งหมด
- ถ้าสลับระหว่าง HTTP ↔ HTTPS ต้อง `docker compose stop nginx` ก่อนเปลี่ยน profile
- Snapshot VM → VM ใหม่เป็น clone (data เดิม) ไม่ใช่ fresh instance
- ลูกค้าสร้าง WordPress admin account เองผ่าน web UI — เราไม่มีข้อมูลนี้
- หลังแก้ config ใดๆ → restart ทั้ง stack เสมอ (`docker compose restart`) ไม่ใช่แค่ container เดียว
- Email/Password Reset → ถ้าส่ง mail ไม่ได้ ใช้ plugin "WP Mail SMTP" ตั้งค่า SMTP ภายนอก

---

## Snapshot — Clone Behavior

### หลักการ

**Snapshot = clone** ไม่ใช่ fresh install

เมื่อ snapshot VM `.1 แล้วสร้าง VM ใหม่ `.2:
- `.2 ได้ data ทั้งหมดจาก `.1 รวมถึง content, plugin, DB, settings
- `.2 มี IP ใหม่ แต่ WordPress ยังใช้ URL เดิม (ถ้าเคย setup ไปแล้ว)

### กรณีได้ Clone แทน Fresh

ถ้า boot VM ใหม่แล้วเจอ WordPress มี content ค้างอยู่ (ไม่ใช่ fresh):

```bash
# 1. ลบ .env เพื่อให้ bootstrap สร้างใหม่
rm -f /opt/wordpress/.env /root/wordpress-credentials.txt

# 2. reboot — bootstrap จะสร้าง DB password ใหม่
reboot

# 3. หลัง reboot — เปิด http://<VM-IP> จะเจอ setup wizard ใหม่
```

> **หมายเหตุ:** วิธีนี้จะ reset DB credentials ใหม่ แต่ content ภายใน WordPress ยังอยู่ (ถ้าต้องการ content ใหม่ด้วย → ต้องลบ container ก่อน snapshot)

---

## Email / Password Reset

### กรณีลืม WordPress Admin Password

**วิธีที่ 1 — ผ่าน WP CLI (แนะนำ)**

```bash
cd /opt/wordpress
docker compose exec wordpress wp user update admin --user_email=your@email.com --send-email
# หรือ reset password โดยตรง:
docker compose exec wordpress wp user update admin --user_pass=NewPassword123
```

**วิธีที่ 2 — ผ่าน MySQL**

```bash
cd /opt/wordpress

# หา password ปัจจุบัน (MD5 hash)
docker compose exec db mysql -u root -p"$MYSQL_ROOT_PASSWORD" wordpress \
  -e "SELECT user_login, user_email FROM wp_users WHERE user_login = 'admin';"

# reset password (MD5)
docker compose exec db mysql -u root -p"$MYSQL_ROOT_PASSWORD" wordpress \
  -e "UPDATE wp_users SET user_pass = MD5('NewPassword123') WHERE user_login = 'admin';"
```

**วิธีที่ 3 — ส่ง email reset จาก login page**

1. เปิด `http://<VM-IP>/wp-login.php`
2. คลิก "Lost your password?"
3. ใส่ email ของ admin account
4. ถ้า mail ไม่ได้ → ติดตั้ง plugin "WP Mail SMTP" แล้วตั้งค่า SMTP ก่อน

### กรณีส่ง mail ไม่ได้ (SMTP)

```bash
# ติดตั้ง WP Mail SMTP ผ่าน WP CLI
cd /opt/wordpress
docker compose exec wordpress wp plugin install wp-mail-smtp --activate

# ตั้งค่า SMTP (ใช้ Gmail / SendGrid / SMTP อื่น)
# แก้ไขที่ WordPress admin → Settings → WP Mail SMTP
```

**ตัวอย่าง SMTP ด้วย Gmail:**
```bash
docker compose exec wordpress wp option update wp_mail_smtp_from_email "your@email.com"
docker compose exec wordpress wp option update wp_mail_smtp_from_name "WordPress"
```

---

## Backup Instance — ลูกค้าไม่ต้องทำเอง

> Backup instance คือ VM แยกที่รัน scheduled backup ให้ทุก app instance อัตโนมัติ

### Backup Schedule (แนะนำ)

| ข้อมูล | ความถี่ | เก็บไว้ |
|---|---|---|
| Database (mysqldump) | ทุกวัน 02:00 | 7 วัน |
| WordPress files (/var/www/html) | ทุกวัน 02:00 | 7 วัน |
| Full VM snapshot | ทุกสัปดาห์ | 4 สัปดาห์ |

### Backup Script (รันบน Backup Instance)

```bash
#!/bin/bash
# /opt/backup/wordpress-backup.sh
# รันโดย cron: 0 2 * * * /opt/backup/wordpress-backup.sh

TARGET_IP="<wordpress-vm-ip>"
BACKUP_DIR="/opt/backups/wordpress"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR/$DATE"

# 1. Backup DB
ssh -o StrictHostKeyChecking=no ubuntu@"$TARGET_IP" \
  "cd /opt/wordpress && \
   docker compose exec -T db mysqldump -u root -p\"\$(grep MYSQL_ROOT_PASSWORD .env | cut -d= -f2)\" wordpress" \
  > "$BACKUP_DIR/$DATE/wp-db.sql"

# 2. Backup files
ssh -o StrictHostKeyChecking=no ubuntu@"$TARGET_IP" \
  "sudo tar czf - -C /opt/wordpress ." \
  > "$BACKUP_DIR/$DATE/wp-files.tar.gz"

# 3. Cleanup old backups (keep 7 days)
find "$BACKUP_DIR" -type d -mtime +7 -exec rm -rf {} \;

echo "[$(date)] WordPress backup completed: $DATE"
```

### Restore (กรณี VM พัง)

```bash
# 1. สร้าง VM ใหม่จาก WordPress image

# 2. บน VM ใหม่ — stop services ก่อน restore
cd /opt/wordpress
docker compose down

# 3. จาก backup instance — restore DB
cat wp-db.sql | docker compose exec -T db mysql -u root -p"<root_password>"

# 4. จาก backup instance — restore files
cat wp-files.tar.gz | docker compose exec -T wordpress tar xzf - -C /var/www/html

# 5. Restart
docker compose up -d
```

> **สรุป:** ลูกค้าไม่ต้องทำ backup/restore เอง — เป็นหน้าที่ของ backup instance
