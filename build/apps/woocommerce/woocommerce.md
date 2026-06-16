# WooCommerce Image — Ubuntu 26.04  [พร้อม build]
> Image สำเร็จรูปสำหรับร้านค้าออนไลน์: สร้าง VM -> bootstrap สร้าง WordPress + ติดตั้ง WooCommerce -> เข้า `/wp-admin/` เพื่อทำ setup ร้านค้า

---

## ภาพรวม

```text
Boot VM
-> systemd เรียก woocommerce-bootstrap.sh
-> generate DB/admin credentials ต่อ VM
-> start MariaDB + WordPress PHP-FPM + Nginx
-> WP-CLI install WordPress core
-> WP-CLI install + activate WooCommerce
-> systemd timer run WP-Cron/Action Scheduler ทุก 5 นาที
```

WooCommerce image นี้คือ **WordPress-derived ecommerce image** ไม่ใช่ platform แยกจาก WordPress

---

## Stack

| Component | Image / Service | เหตุผล |
|---|---|---|
| Database | `mariadb:lts` | ตรง WordPress/WooCommerce requirement และมี Docker healthcheck |
| WordPress | `wordpress:php8.3-fpm` | PHP 8.3+ ตาม upstream requirement |
| WP-CLI | `wordpress:cli-php8.3` | first boot install + maintenance commands |
| Proxy | `nginx:1.27` | static/proxy/HTTPS profile แยกจาก PHP-FPM |
| Cron | systemd timer | ไม่พึ่ง page-load WP-Cron สำหรับร้าน traffic ต่ำ |

Minimum VM: **2 vCPU / 2 GB RAM / 15 GB disk**

---

## Files Created

```text
/opt/woocommerce/docker-compose.yml
/opt/woocommerce/nginx/default.conf
/opt/woocommerce/nginx/default-https.conf
/opt/woocommerce/php/woocommerce.ini
/opt/woocommerce/certs/                         (ว่าง - รอวาง cert)
/usr/local/sbin/woocommerce-bootstrap.sh
/usr/local/sbin/woocommerce-cron.sh
/etc/systemd/system/woocommerce-bootstrap.service
/etc/systemd/system/woocommerce-cron.service
/etc/systemd/system/woocommerce-cron.timer
/root/README-woocommerce-image.txt
/etc/update-motd.d/99-woocommerce-image
```

Generated on first boot:

```text
/opt/woocommerce/.env
/root/woocommerce-credentials.txt
/var/log/woocommerce-bootstrap.log
/var/log/woocommerce-cron.log
```

---

## Phase 0 — Install Docker CE

> รันบน Ubuntu 26.04 golden VM

```bash
set -e
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release openssl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
. /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
docker version
docker compose version
```

---

## Phase 1 — Create App Directory

```bash
set -e
mkdir -p /opt/woocommerce/{nginx,php,certs}
chmod 700 /opt/woocommerce/certs
```

---

## Phase 2 — Write Source Files

> Source files ใน repo อยู่ที่ `build/apps/woocommerce/` ใช้ตรวจสอบหรือ copy โดยตรงได้ แต่ guide นี้ self-contained

### docker-compose.yml

```bash
cat > /opt/woocommerce/docker-compose.yml << 'EOF'
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
      - ./php/woocommerce.ini:/usr/local/etc/php/conf.d/zz-woocommerce.ini:ro
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_MEMORY_LIMIT', '512M');
        define('WP_MAX_MEMORY_LIMIT', '512M');
        define('DISABLE_WP_CRON', true);
        if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
            $_SERVER['HTTPS'] = 'on';
        }
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  cli:
    image: wordpress:cli-php8.3
    profiles:
      - tools
    volumes:
      - wp_data:/var/www/html
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
    depends_on:
      db:
        condition: service_healthy
      wordpress:
        condition: service_started

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
EOF
```

### nginx/default.conf

```bash
cat > /opt/woocommerce/nginx/default.conf << 'EOF'
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
        fastcgi_param HTTP_X_FORWARDED_PROTO $scheme;
    }

    location ~ /\. {
        deny all;
    }

    location = /xmlrpc.php {
        deny all;
    }
}
EOF
```

### nginx/default-https.conf

```bash
cat > /opt/woocommerce/nginx/default-https.conf << 'EOF'
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
        fastcgi_param HTTPS on;
        fastcgi_param HTTP_X_FORWARDED_PROTO https;
    }

    location ~ /\. {
        deny all;
    }

    location = /xmlrpc.php {
        deny all;
    }
}
EOF
```

### php/woocommerce.ini

```bash
cat > /opt/woocommerce/php/woocommerce.ini << 'EOF'
; WooCommerce PHP Settings
; แก้ไฟล์นี้บน host -> docker compose restart wordpress nginx

memory_limit = 512M
upload_max_filesize = 128M
post_max_size = 128M
max_execution_time = 600
max_input_time = 600
max_input_vars = 5000
EOF
```

### Bootstrap Script

```bash
cat > /usr/local/sbin/woocommerce-bootstrap.sh << 'EOF'
#!/bin/bash
set -e

ENV_FILE="/opt/woocommerce/.env"
CRED_FILE="/root/woocommerce-credentials.txt"
LOG_FILE="/var/log/woocommerce-bootstrap.log"
COMPOSE_DIR="/opt/woocommerce"
SITE_TITLE="WooCommerce Store"
ADMIN_USER="storeadmin"
ADMIN_EMAIL="admin@localhost.invalid"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

primary_url() {
    local ip
    ip=$(hostname -I | awk '{print $1}')
    if [ -z "$ip" ]; then
        echo "http://localhost"
    else
        echo "http://${ip}"
    fi
}

run_wp() {
    cd "$COMPOSE_DIR"
    docker compose --profile tools run --rm cli "$@"
}

if [ -f "$ENV_FILE" ]; then
    log "Bootstrap: .env exists - starting services"
    cd "$COMPOSE_DIR"
    docker compose up -d
    systemctl enable --now woocommerce-cron.timer >/dev/null 2>&1 || true
    log "Bootstrap: done (reusing existing config)"
    exit 0
fi

log "Bootstrap: first boot - generating secrets"

MYSQL_ROOT_PASSWORD=$(openssl rand -base64 24)
MYSQL_DATABASE="wordpress"
MYSQL_USER="wordpress"
MYSQL_PASSWORD=$(openssl rand -base64 24)
WP_ADMIN_PASSWORD=$(openssl rand -base64 24)
SITE_URL=$(primary_url)

cat > "$ENV_FILE" << EOC
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE=${MYSQL_DATABASE}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
SITE_URL=${SITE_URL}
EOC
chmod 600 "$ENV_FILE"

log "Bootstrap: pulling images"
cd "$COMPOSE_DIR"
docker compose --profile tools pull

log "Bootstrap: starting database, wordpress, nginx"
docker compose up -d db wordpress nginx

log "Bootstrap: waiting for WordPress PHP-FPM"
for i in $(seq 1 60); do
    if docker compose exec -T wordpress php -r "echo 'ok';" 2>/dev/null | grep -q ok; then
        log "Bootstrap: WordPress PHP-FPM is ready"
        break
    fi
    sleep 2
done

log "Bootstrap: installing WordPress core"
if ! run_wp core is-installed >/dev/null 2>&1; then
    run_wp core install \
        --url="$SITE_URL" \
        --title="$SITE_TITLE" \
        --admin_user="$ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$ADMIN_EMAIL" \
        --skip-email
fi

log "Bootstrap: installing WooCommerce"
run_wp plugin install woocommerce --activate
run_wp rewrite structure '/%postname%/' --hard
run_wp option update blogdescription 'Online store powered by WooCommerce'

cat > "$CRED_FILE" << EOC
=== WooCommerce Docker Credentials ===
Generated: $(date)

Access:
  Store URL: ${SITE_URL}
  Admin URL: ${SITE_URL}/wp-admin/

WordPress Admin:
  User:     ${ADMIN_USER}
  Password: ${WP_ADMIN_PASSWORD}
  Email:    ${ADMIN_EMAIL}

Database:
  Host:     db (internal Docker network)
  Name:     ${MYSQL_DATABASE}
  User:     ${MYSQL_USER}
  Password: ${MYSQL_PASSWORD}

Root DB Password: ${MYSQL_ROOT_PASSWORD}

First Steps:
  1. Open Admin URL and log in
  2. Complete WooCommerce setup wizard
  3. Change admin email and password
  4. Configure HTTPS before enabling real payments
  5. Configure SMTP for order emails

Manage:
  cd /opt/woocommerce
  docker compose ps
  docker compose logs -f
  docker compose restart

Cron/Queue:
  systemctl status woocommerce-cron.timer --no-pager
  /usr/local/sbin/woocommerce-cron.sh
EOC
chmod 600 "$CRED_FILE"

systemctl enable --now woocommerce-cron.timer >/dev/null 2>&1 || true

log "Bootstrap: done - open ${SITE_URL}/wp-admin/ and complete WooCommerce setup"
EOF
chmod +x /usr/local/sbin/woocommerce-bootstrap.sh
```

### Cron Script

```bash
cat > /usr/local/sbin/woocommerce-cron.sh << 'EOF'
#!/bin/bash
set -e

COMPOSE_DIR="/opt/woocommerce"
LOG_FILE="/var/log/woocommerce-cron.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

cd "$COMPOSE_DIR"

if [ ! -f .env ]; then
    log "skip: .env not found"
    exit 0
fi

if ! docker compose ps --status running wordpress >/dev/null 2>&1; then
    log "skip: wordpress container is not running"
    exit 0
fi

log "run: wp cron event run --due-now"
docker compose --profile tools run --rm cli cron event run --due-now || true

if docker compose --profile tools run --rm cli help action-scheduler >/dev/null 2>&1; then
    log "run: wp action-scheduler run"
    docker compose --profile tools run --rm cli action-scheduler run --batch-size=25 || true
fi
EOF
chmod +x /usr/local/sbin/woocommerce-cron.sh
```

### systemd units

```bash
cat > /etc/systemd/system/woocommerce-bootstrap.service << 'EOF'
[Unit]
Description=WooCommerce Docker bootstrap
After=docker.service network-online.target
Wants=network-online.target
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/woocommerce-bootstrap.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/woocommerce-cron.service << 'EOF'
[Unit]
Description=WooCommerce WP-Cron and Action Scheduler runner
After=docker.service woocommerce-bootstrap.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/woocommerce-cron.sh
EOF

cat > /etc/systemd/system/woocommerce-cron.timer << 'EOF'
[Unit]
Description=Run WooCommerce cron and queue every 5 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min
Unit=woocommerce-cron.service

[Install]
WantedBy=timers.target
EOF
```

### README + MOTD

```bash
cat > /root/README-woocommerce-image.txt << 'EOF'
=== WooCommerce Docker Image — Ubuntu 26.04 ===

Access:
  Store:  http://<VM-IP>
  Admin:  http://<VM-IP>/wp-admin/

Credentials:
  Generated on first boot: /root/woocommerce-credentials.txt
  Change WordPress admin password and email after first login.

Directory:
  /opt/woocommerce/                    Main directory
    docker-compose.yml                 Service definitions
    nginx/default.conf                 Nginx config (editable)
    nginx/default-https.conf           HTTPS template
    php/woocommerce.ini                PHP settings (editable)
    certs/                             Place TLS certs here

Common Commands:
  cd /opt/woocommerce
  docker compose ps                    Check status
  docker compose logs -f               View logs
  docker compose restart               Restart all services
  docker compose restart wordpress     Restart after editing php/woocommerce.ini
  docker compose restart nginx         Restart after editing nginx/default.conf

WP-CLI:
  docker compose --profile tools run --rm cli plugin list
  docker compose --profile tools run --rm cli wc system_status list

Cron/Queue:
  systemctl status woocommerce-cron.timer --no-pager
  /usr/local/sbin/woocommerce-cron.sh

Enable HTTPS:
  1. Point DNS to VM floating IP
  2. Place certs: /opt/woocommerce/certs/fullchain.pem + privkey.pem
  3. chmod 644 fullchain.pem && chmod 600 privkey.pem
  4. Stop HTTP:   docker compose stop nginx
  5. Start HTTPS: docker compose --profile https up -d
  6. Update WordPress Address and Site Address in wp-admin if domain changes

WooCommerce Notes:
  - Complete WooCommerce setup wizard before accepting orders.
  - Configure HTTPS before enabling real payments.
  - Configure SMTP for order emails.
  - HPOS is default for new WooCommerce installs, but old extensions may be incompatible.

Backup:
  DB:    docker compose exec db mysqldump -u root -p"$(grep MYSQL_ROOT_PASSWORD .env | cut -d= -f2)" wordpress > woocommerce-db.sql
  Files: docker run --rm -v woocommerce_wp_data:/data -v "$PWD":/backup alpine tar czf /backup/woocommerce-wp-data.tar.gz -C /data .
EOF

cat > /etc/update-motd.d/99-woocommerce-image << 'EOF'
#!/bin/sh
cat << 'EOM'

WooCommerce image
  Store:       http://<VM-IP>
  Admin:       http://<VM-IP>/wp-admin/
  Credentials: /root/woocommerce-credentials.txt
  App dir:     /opt/woocommerce
  Readme:      /root/README-woocommerce-image.txt

Useful commands:
  cd /opt/woocommerce && docker compose ps
  systemctl status woocommerce-cron.timer --no-pager

EOM
EOF
chmod +x /etc/update-motd.d/99-woocommerce-image
```

---

## Phase 3 — Enable Services And Pull Images

```bash
set -e
systemctl daemon-reload
systemctl enable woocommerce-bootstrap.service
cd /opt/woocommerce

cat > .env << 'EOF'
MYSQL_ROOT_PASSWORD=prepull-only-root
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
MYSQL_PASSWORD=prepull-only-user
SITE_URL=http://localhost
EOF
chmod 600 .env
docker compose --profile tools pull
rm -f .env
```

> `.env` ด้านบนใช้เพื่อ pre-pull เท่านั้น ต้องลบก่อน capture เพื่อให้ VM ใหม่ generate secret เอง

---

## Phase 4 — Test Bootstrap On Build VM

```bash
set -e
systemctl start woocommerce-bootstrap.service
systemctl status woocommerce-bootstrap.service --no-pager
cd /opt/woocommerce
docker compose ps
curl -I http://localhost
docker compose --profile tools run --rm cli plugin is-active woocommerce
systemctl status woocommerce-cron.timer --no-pager
```

ต้องได้:

| Check | Expected |
|---|---|
| `docker compose ps` | `db`, `wordpress`, `nginx` running; `db` healthy |
| HTTP | `200` หรือ redirect/HTML จาก WordPress |
| Plugin | WooCommerce active |
| Credentials | `/root/woocommerce-credentials.txt` มี admin credential |
| Timer | `woocommerce-cron.timer` enabled/running |

---

## Phase 5 — Cleanup Before Capture

> ต้องลบ state ที่ generate จาก test VM เพื่อให้ image เป็น standalone ต่อ VM

```bash
set -e
cd /opt/woocommerce
docker compose down -v
rm -f /opt/woocommerce/.env
rm -f /root/woocommerce-credentials.txt
rm -f /var/log/woocommerce-bootstrap.log /var/log/woocommerce-cron.log
systemctl reset-failed woocommerce-bootstrap.service woocommerce-cron.service || true
history -c || true
```

ห้าม `apt autoremove` หรือ `apt clean` เพราะต้องเก็บ package cache ตาม policy ของ repo

---

## First Boot User Flow

1. สร้าง VM จาก image
2. รอ bootstrap จบ 2-5 นาที
3. SSH เข้า VM แล้วอ่าน `/root/woocommerce-credentials.txt`
4. เปิด `http://<VM-IP>/wp-admin/`
5. Login ด้วย `storeadmin` แล้วเปลี่ยน password/email ทันที
6. ทำ WooCommerce setup wizard
7. ตั้ง HTTPS ก่อนเปิด payment จริง
8. ตั้ง SMTP เพื่อส่ง order email

---

## HTTPS Notes

เปิด HTTPS หลังมี domain/cert:

```bash
cd /opt/woocommerce
cp /path/to/fullchain.pem certs/fullchain.pem
cp /path/to/privkey.pem certs/privkey.pem
chmod 644 certs/fullchain.pem
chmod 600 certs/privkey.pem
docker compose stop nginx
docker compose --profile https up -d
```

หลังเปลี่ยน domain ให้แก้ใน WordPress admin:

```text
Settings -> General -> WordPress Address (URL)
Settings -> General -> Site Address (URL)
```

---

## Backup Notes

Backup ต้องเก็บ **DB + wp_data** พร้อมกัน:

```bash
cd /opt/woocommerce
docker compose exec db mysqldump -u root -p"$(grep MYSQL_ROOT_PASSWORD .env | cut -d= -f2)" wordpress > woocommerce-db.sql
docker run --rm -v woocommerce_wp_data:/data -v "$PWD":/backup alpine tar czf /backup/woocommerce-wp-data.tar.gz -C /data .
```

ก่อน update WordPress/WooCommerce/theme/plugin ให้ snapshot หรือ backup ทุกครั้ง

---

## Build Gate

ก่อน capture ต้องผ่าน 6 ข้อ:

| Gate | Command | Expected |
|---|---|---|
| Docker | `docker version && docker compose version` | command ผ่าน |
| Bootstrap enabled | `systemctl is-enabled woocommerce-bootstrap.service` | `enabled` |
| Containers | `cd /opt/woocommerce && docker compose ps` | db healthy + wordpress/nginx running ตอน test |
| WooCommerce active | `docker compose --profile tools run --rm cli plugin is-active woocommerce` | exit 0 |
| Cron timer | `systemctl is-enabled woocommerce-cron.timer` | `enabled` หลัง bootstrap test |
| Clean state | `test ! -f /opt/woocommerce/.env && test ! -f /root/woocommerce-credentials.txt` | ผ่านก่อน capture |

---

## Source Files

ไฟล์ source ที่ mirror guide นี้อยู่ใน repo:

```text
build/apps/woocommerce/docker-compose.yml
build/apps/woocommerce/nginx/default.conf
build/apps/woocommerce/nginx/default-https.conf
build/apps/woocommerce/php/woocommerce.ini
build/apps/woocommerce/woocommerce-bootstrap.sh
build/apps/woocommerce/woocommerce-cron.sh
build/apps/woocommerce/woocommerce-bootstrap.service
build/apps/woocommerce/woocommerce-cron.service
build/apps/woocommerce/woocommerce-cron.timer
build/apps/woocommerce/README-woocommerce-image.txt
build/apps/woocommerce/99-woocommerce-image
```

---

## Record Build Manifest

หลัง pre-capture gate ผ่าน ให้สร้าง/อัปเดต `build/apps/woocommerce/woocommerce-build-manifest.md` ด้วยข้อมูล version ที่ verify จาก golden-image VM เท่านั้น:

```bash
lsb_release -ds
docker version
docker compose version
docker buildx version
dpkg-query -W docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker images --digests --format '{{.Repository}}:{{.Tag}} {{.Digest}}'
```

เก็บเฉพาะ Base OS, Docker stack package versions แบบ minimal, Docker/Compose/Buildx versions, container image tag + digest และ build notes สั้นๆ. ห้ามเก็บ image name, Glance ID, server ID, floating IP, VM IP, hostname, OpenStack context หรือ credentials.
