# Docker Platform Image — Ubuntu 26.04  [พร้อม build]
> Image สำเร็จรูป: สร้าง VM → Docker CE + Portainer + Nginx Proxy Manager พร้อมใช้ → ลูกค้าอ่าน credentials ใน VM แล้วเข้า Web UI ได้ทันที

---

## เป้าหมาย

```text
ลูกค้าสร้าง VM จาก Image
→ systemd เรียก docker-platform-bootstrap.sh
→ สุ่ม Portainer admin password และ Nginx Proxy Manager password
→ start Docker + Portainer + Nginx Proxy Manager
→ เขียน /root/docker-platform-credentials.txt
→ ลูกค้า SSH เข้า VM อ่าน README/credentials
→ เข้า https://<IP>:9443 และ http://<IP>:81 ใช้งานได้เลย
```

| รายการ | ค่า |
|---|---|
| Base OS | Ubuntu 26.04 |
| Docker | Docker CE จาก official Docker apt repo |
| Compose | Docker Compose plugin (`docker compose`) |
| Build tool | Docker Buildx plugin |
| Container UI | Portainer CE LTS |
| Domain/HTTPS UI | Nginx Proxy Manager |
| Minimum flavor | 1 vCPU / 2GB RAM / 15GB disk |

---

## Customer URLs

| Service | URL | Login |
|---|---|---|
| Portainer CE | `https://<VM-IP>:9443` | `/root/docker-platform-credentials.txt` |
| Nginx Proxy Manager | `http://<VM-IP>:81` | `/root/docker-platform-credentials.txt` |
| Public HTTP gateway | `http://<VM-IP>` | NPM proxy hosts |
| Public HTTPS gateway | `https://<VM-IP>` | NPM proxy hosts |

Security group:
- Public: TCP `80`, `443`
- Admin only: TCP `22`, `81`, `9443`

---

## Design

| เรื่อง | ตัดสินใจ |
|---|---|
| Docker package source | official Docker apt repo, ไม่ใช้ `snap`, ไม่ใช้ Ubuntu `docker.io` |
| Portainer | start ตอน first boot, bootstrap สุ่ม admin password ผ่าน API |
| Nginx Proxy Manager | start ตอน first boot, bootstrap พยายามเปลี่ยน default password ผ่าน API |
| Database | ให้ examples/templates, ไม่ start default |
| Docker group | ไม่ auto-add user เพราะ root-equivalent |
| Logging | `json-file` พร้อม `max-size=10m`, `max-file=3` |
| Golden image | pre-pull images ได้ แต่ห้ามเหลือ containers/volumes/runtime data |

---

## ก่อนเริ่ม — Pre-flight Verification

| เช็ค | ได้จาก | ถ้ายังไม่พร้อม |
|---|---|---|
| Guest image Ubuntu 26.04 สร้างเสร็จแล้ว | `_guest-images.md` → Ubuntu 26.04 เสร็จ | ต้องสร้าง guest image ก่อน |
| VM สร้างจาก guest image ที่ผ่าน Set 1-3 ครบ | standalone build | สร้าง VM จาก guest image |
| Build guide พร้อม `[พร้อม build]` | header tag บน | ต้องสร้าง source files ก่อน |
| SSH credentials | `build/tmp/docker-platform-build.env` (gitignored) | — |

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
- RAM อย่างน้อย 2GB

---

## โครงสร้างไฟล์

```text
/opt/docker-platform/docker-compose.yml
/opt/docker-platform/.env                         (first boot สร้างจริง)
/opt/docker-platform/examples/postgres/docker-compose.yml
/opt/docker-platform/examples/mariadb/docker-compose.yml
/opt/docker-platform/examples/redis/docker-compose.yml
/opt/docker-platform/examples/nginx-demo/docker-compose.yml
/usr/local/sbin/docker-platform-bootstrap.sh
/etc/systemd/system/docker-platform-bootstrap.service
/root/README-docker-platform-image.txt
/root/docker-platform-credentials.txt             (first boot สร้างจริง)
/etc/update-motd.d/99-docker-platform-image
/etc/docker/daemon.json
```

ไฟล์/สถานะที่ต้องไม่มีใน Golden Image:

```text
/opt/docker-platform/.env
/root/docker-platform-credentials.txt
/var/log/docker-platform-bootstrap.log
/var/lib/docker-platform-firstboot.done
running containers
Docker volumes portainer_data, npm_data, npm_letsencrypt
runtime credentials
```

---

## ขั้นตอน Build

### 1. ติดตั้ง base packages

[golden-image VM]

```bash
apt update && apt install -y ca-certificates curl gnupg openssl jq vim htop net-tools
```

### 2. ติดตั้ง Docker CE + plugins

[golden-image VM]

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

### 3. สร้าง directories

[golden-image VM]

```bash
mkdir -p /opt/docker-platform/examples/{postgres,mariadb,redis,nginx-demo}
chmod 755 /opt/docker-platform
```

### 4. วาง source files

#### `/opt/docker-platform/docker-compose.yml`

[golden-image VM]

```bash
cat > /opt/docker-platform/docker-compose.yml << 'EOF'
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
    networks:
      - platform

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
    networks:
      - platform

volumes:
  portainer_data:
    name: portainer_data
  npm_data:
    name: npm_data
  npm_letsencrypt:
    name: npm_letsencrypt

networks:
  platform:
    name: docker_platform
EOF
```

#### `/usr/local/sbin/docker-platform-bootstrap.sh`

[golden-image VM]

```bash
cat > /usr/local/sbin/docker-platform-bootstrap.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

APP_DIR=/opt/docker-platform
ENV_FILE="$APP_DIR/.env"
CREDENTIALS=/root/docker-platform-credentials.txt
LOG=/var/log/docker-platform-bootstrap.log
MARKER=/var/lib/docker-platform-firstboot.done

exec > >(tee -a "$LOG") 2>&1

random_secret() {
  openssl rand -base64 24 | tr -d '=+/' | cut -c1-24
}

wait_http() {
  local url="$1"
  local name="$2"
  local tries=60
  local i=1
  while [ "$i" -le "$tries" ]; do
    if curl -kfsS "$url" >/dev/null 2>&1; then
      echo "$name is ready"
      return 0
    fi
    sleep 3
    i=$((i + 1))
  done
  echo "WARNING: $name did not become ready in time"
  return 1
}

get_primary_ip() {
  hostname -I 2>/dev/null | awk '{print $1}'
}

echo "[$(date -Is)] Docker Platform bootstrap started"

if [ -e "$MARKER" ]; then
  echo "Bootstrap already completed; ensuring platform services are running"
  systemctl enable --now docker
  docker compose -f "$APP_DIR/docker-compose.yml" --env-file "$ENV_FILE" up -d
  exit 0
fi

mkdir -p "$APP_DIR" /var/lib
chmod 755 "$APP_DIR"

PORTAINER_ADMIN_PASSWORD="$(random_secret)"
NPM_UPSTREAM_EMAIL="admin@example.com"
NPM_UPSTREAM_PASSWORD="changeme"
NPM_ADMIN_PASSWORD="$(random_secret)"
NPM_EFFECTIVE_PASSWORD="$NPM_UPSTREAM_PASSWORD"
NPM_PASSWORD_NOTE="Default upstream password is still active. Change it immediately after first login."
VM_IP="$(get_primary_ip)"

cat > "$ENV_FILE" << EOV
TZ=Asia/Bangkok
EOV
chmod 600 "$ENV_FILE"

systemctl enable --now docker
docker compose -f "$APP_DIR/docker-compose.yml" --env-file "$ENV_FILE" up -d

if wait_http "https://127.0.0.1:9443/api/status" "Portainer"; then
  PORTAINER_INIT_CODE="$(curl -k -s -o /tmp/portainer-init.out -w '%{http_code}' \
    -H 'Content-Type: application/json' \
    -X POST https://127.0.0.1:9443/api/users/admin/init \
    -d '{"Username":"admin","Password":"'"$PORTAINER_ADMIN_PASSWORD"'"}')"
  if [ "$PORTAINER_INIT_CODE" = "200" ] || [ "$PORTAINER_INIT_CODE" = "204" ] || [ "$PORTAINER_INIT_CODE" = "409" ]; then
    echo "Portainer admin initialized or already initialized"
  else
    echo "WARNING: Portainer admin init returned HTTP $PORTAINER_INIT_CODE"
    cat /tmp/portainer-init.out || true
  fi
  rm -f /tmp/portainer-init.out
fi

if wait_http "http://127.0.0.1:81" "Nginx Proxy Manager"; then
  NPM_TOKEN="$(curl -s -X POST http://127.0.0.1:81/api/tokens \
    -H 'Content-Type: application/json' \
    -d '{"identity":"'"$NPM_UPSTREAM_EMAIL"'","secret":"'"$NPM_UPSTREAM_PASSWORD"'"}' | jq -r '.token // empty')"
  if [ -n "$NPM_TOKEN" ]; then
    NPM_AUTH_CODE="$(curl -s -o /tmp/npm-auth.out -w '%{http_code}' \
      -X PUT http://127.0.0.1:81/api/users/me/auth \
      -H "Authorization: Bearer $NPM_TOKEN" \
      -H 'Content-Type: application/json' \
      -d '{"type":"password","current":"'"$NPM_UPSTREAM_PASSWORD"'","secret":"'"$NPM_ADMIN_PASSWORD"'"}')"
    if [ "$NPM_AUTH_CODE" = "200" ] || [ "$NPM_AUTH_CODE" = "204" ]; then
      NPM_EFFECTIVE_PASSWORD="$NPM_ADMIN_PASSWORD"
      NPM_PASSWORD_NOTE="Password changed automatically during first boot."
      echo "Nginx Proxy Manager password changed"
    else
      echo "WARNING: NPM password change returned HTTP $NPM_AUTH_CODE"
      cat /tmp/npm-auth.out || true
    fi
    rm -f /tmp/npm-auth.out
  else
    echo "WARNING: Could not obtain NPM API token; default upstream password remains"
  fi
fi

cat > "$CREDENTIALS" << EOC
Docker Platform Credentials
===========================

VM IP:
  ${VM_IP:-<VM-IP>}

Portainer CE:
  URL: https://${VM_IP:-<VM-IP>}:9443
  Username: admin
  Password: $PORTAINER_ADMIN_PASSWORD

Nginx Proxy Manager:
  URL: http://${VM_IP:-<VM-IP>}:81
  Email: $NPM_UPSTREAM_EMAIL
  Password: $NPM_EFFECTIVE_PASSWORD
  Note: $NPM_PASSWORD_NOTE

Important:
  - Change the Nginx Proxy Manager password immediately after first login.
  - Browser will warn about Portainer self-signed TLS certificate on first access.
  - OpenStack security group should expose 80/443 publicly, and restrict 22/81/9443 to admin IPs.
EOC
chmod 600 "$CREDENTIALS"

touch "$MARKER"

echo "Credentials written to $CREDENTIALS"
echo "[$(date -Is)] Docker Platform bootstrap completed"
EOF
chmod +x /usr/local/sbin/docker-platform-bootstrap.sh
```

#### `/etc/systemd/system/docker-platform-bootstrap.service`

[golden-image VM]

```bash
cat > /etc/systemd/system/docker-platform-bootstrap.service << 'EOF'
[Unit]
Description=Docker Platform first boot bootstrap
Wants=network-online.target docker.service
After=network-online.target docker.service cloud-init.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/docker-platform-bootstrap.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
```

#### `/root/README-docker-platform-image.txt`

[golden-image VM]

```bash
cat > /root/README-docker-platform-image.txt << 'EOF'
Docker Platform Image
=====================

This VM includes Docker CE, Docker Buildx, Docker Compose plugin, Portainer CE,
and Nginx Proxy Manager.

First steps:
  1. Open OpenStack security group ports 22, 80, 443, 81, and 9443.
  2. SSH into the VM.
  3. Read credentials:
       cat /root/docker-platform-credentials.txt
  4. Open Portainer:
       https://<VM-IP>:9443
  5. Open Nginx Proxy Manager:
       http://<VM-IP>:81

Roles:
  - Portainer manages containers, stacks, networks, and volumes.
  - Nginx Proxy Manager manages domains, reverse proxy rules, and Let's Encrypt certificates.

Security notes:
  - Change the Nginx Proxy Manager password immediately after first login.
  - Portainer mounts /var/run/docker.sock and can control this Docker host.
  - Docker group access is root-equivalent. Add users only when you trust them.
  - Published container ports are reachable from outside unless restricted by binding, OpenStack security groups, or DOCKER-USER rules.

Common commands:
  systemctl status docker
  systemctl status docker-platform-bootstrap.service
  docker compose -f /opt/docker-platform/docker-compose.yml ps
  docker compose -f /opt/docker-platform/docker-compose.yml logs -f

Update platform containers:
  docker compose -f /opt/docker-platform/docker-compose.yml --env-file /opt/docker-platform/.env pull
  docker compose -f /opt/docker-platform/docker-compose.yml --env-file /opt/docker-platform/.env up -d

Example templates are stored under:
  /opt/docker-platform/examples/
EOF
```

#### `/etc/update-motd.d/99-docker-platform-image`

[golden-image VM]

```bash
cat > /etc/update-motd.d/99-docker-platform-image << 'EOF'
#!/bin/sh
cat << 'MOTD'

Docker Platform Image
---------------------
Portainer CE: https://<VM-IP>:9443
Nginx Proxy Manager: http://<VM-IP>:81

Read credentials:
  cat /root/docker-platform-credentials.txt

Docs:
  /root/README-docker-platform-image.txt

MOTD
EOF
chmod +x /etc/update-motd.d/99-docker-platform-image
```

### 5. วาง example templates

[golden-image VM]

```bash
cat > /opt/docker-platform/examples/postgres/docker-compose.yml << 'EOF'
services:
  postgres:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-app}
      POSTGRES_USER: ${POSTGRES_USER:-app}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?set POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "127.0.0.1:5432:5432"

volumes:
  postgres_data:
EOF

cat > /opt/docker-platform/examples/mariadb/docker-compose.yml << 'EOF'
services:
  mariadb:
    image: mariadb:lts
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: ${MARIADB_ROOT_PASSWORD:?set MARIADB_ROOT_PASSWORD}
      MARIADB_DATABASE: ${MARIADB_DATABASE:-app}
      MARIADB_USER: ${MARIADB_USER:-app}
      MARIADB_PASSWORD: ${MARIADB_PASSWORD:?set MARIADB_PASSWORD}
    volumes:
      - mariadb_data:/var/lib/mysql
    ports:
      - "127.0.0.1:3306:3306"

volumes:
  mariadb_data:
EOF

cat > /opt/docker-platform/examples/redis/docker-compose.yml << 'EOF'
services:
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: ["redis-server", "--appendonly", "yes"]
    volumes:
      - redis_data:/data
    ports:
      - "127.0.0.1:6379:6379"

volumes:
  redis_data:
EOF

cat > /opt/docker-platform/examples/nginx-demo/docker-compose.yml << 'EOF'
services:
  nginx-demo:
    image: nginx:stable-alpine
    restart: unless-stopped
    ports:
      - "8080:80"
EOF
```

### 6. Enable bootstrap service

[golden-image VM]

```bash
systemctl daemon-reload
systemctl enable docker-platform-bootstrap.service
```

### 7. Pre-pull images

[golden-image VM]

```bash
cat > /opt/docker-platform/.env << 'EOF'
TZ=Asia/Bangkok
EOF
chmod 600 /opt/docker-platform/.env

docker compose -f /opt/docker-platform/docker-compose.yml --env-file /opt/docker-platform/.env pull
docker pull hello-world:latest
docker pull postgres:17-alpine
docker pull mariadb:lts
docker pull redis:7-alpine
docker pull nginx:stable-alpine
```

### 8. Test bootstrap แล้ว cleanup runtime data

[golden-image VM]

```bash
/usr/local/sbin/docker-platform-bootstrap.sh
docker compose -f /opt/docker-platform/docker-compose.yml --env-file /opt/docker-platform/.env ps
curl -k -sI https://127.0.0.1:9443 | head -1
curl -sI http://127.0.0.1:81 | head -1

docker compose -f /opt/docker-platform/docker-compose.yml --env-file /opt/docker-platform/.env down -v
rm -f /opt/docker-platform/.env
rm -f /root/docker-platform-credentials.txt
rm -f /var/log/docker-platform-bootstrap.log
rm -f /var/lib/docker-platform-firstboot.done
```

> ต้องใช้ `down -v` เฉพาะตอน cleanup golden image เพื่อไม่ให้ Portainer/NPM runtime data จาก test ติดไปใน image

### 9. Pre-Capture Gate

[golden-image VM]

```bash
set -e

systemctl is-enabled docker-platform-bootstrap.service
systemctl is-enabled docker
docker version
docker compose version
docker images portainer/portainer-ce:lts --format '{{.Repository}}:{{.Tag}}' | grep -q '^portainer/portainer-ce:lts$'
docker images jc21/nginx-proxy-manager:latest --format '{{.Repository}}:{{.Tag}}' | grep -q '^jc21/nginx-proxy-manager:latest$'
docker images postgres:17-alpine --format '{{.Repository}}:{{.Tag}}' | grep -q '^postgres:17-alpine$'
docker images mariadb:lts --format '{{.Repository}}:{{.Tag}}' | grep -q '^mariadb:lts$'
docker images redis:7-alpine --format '{{.Repository}}:{{.Tag}}' | grep -q '^redis:7-alpine$'
docker images nginx:stable-alpine --format '{{.Repository}}:{{.Tag}}' | grep -q '^nginx:stable-alpine$'

if docker ps -q | grep -q .; then
  echo "ERROR: running containers remain"
  docker ps
  exit 1
fi
echo "containers: stopped"

if docker volume ls --format '{{.Name}}' | grep -E '^(portainer_data|npm_data|npm_letsencrypt)$'; then
  echo "ERROR: runtime volumes remain"
  exit 1
fi
echo "volumes: absent"

test ! -e /opt/docker-platform/.env && echo ".env: absent"
test ! -e /root/docker-platform-credentials.txt && echo "credentials: absent"
test ! -e /var/log/docker-platform-bootstrap.log && echo "bootstrap log: absent"
test ! -e /var/lib/docker-platform-firstboot.done && echo "firstboot marker: absent"
test -f /opt/docker-platform/docker-compose.yml && echo "compose: present"
test -f /root/README-docker-platform-image.txt && echo "README: present"
```

ห้าม capture ถ้า:
- bootstrap service disabled
- Docker service disabled
- required images ไม่ถูก pull ไว้
- containers ยังรัน
- runtime volumes ยังอยู่
- `.env`, credentials, first boot marker, bootstrap log ยังอยู่

### 10. Golden image cleanup

[golden-image VM]

```bash
truncate -s 0 /etc/machine-id || true
rm -f /var/lib/dbus/machine-id || true
ln -sf /etc/machine-id /var/lib/dbus/machine-id
cloud-init clean --logs
history -c || true
poweroff
```

> ห้าม `apt clean`, `apt autoremove`, `docker image prune -a` เพราะ image นี้ตั้งใจเก็บ package cache และ Docker images ที่ pre-pull ไว้

---

## หลังลูกค้าสร้าง VM จาก Image

### อ่าน credentials

[customer VM]

```bash
cat /root/README-docker-platform-image.txt
cat /root/docker-platform-credentials.txt
```

### ตรวจ services

[customer VM]

```bash
systemctl status docker --no-pager
systemctl status docker-platform-bootstrap.service --no-pager
docker compose -f /opt/docker-platform/docker-compose.yml --env-file /opt/docker-platform/.env ps
```

### เข้า Web UI

```text
Portainer CE: https://<VM-IP>:9443
Nginx Proxy Manager: http://<VM-IP>:81
```

### ใช้ Nginx Proxy Manager ขอ HTTPS

1. ชี้ DNS เช่น `app.example.com` ไปที่ floating IP ของ VM
2. เข้า NPM `http://<VM-IP>:81`
3. Add Proxy Host
4. ใส่ Domain Names: `app.example.com`
5. ใส่ Forward Hostname/IP: ชื่อ container หรือ IP/port ภายใน
6. ไป tab SSL แล้วกด Request a new SSL Certificate
7. เปิด `https://app.example.com`

---

## Source Files

```text
build/apps/docker-platform/docker-platform.md
build/apps/docker-platform/docker-platform-review.md
build/apps/docker-platform/docker-platform-errors.md
build/apps/docker-platform/docker-compose.yml
build/apps/docker-platform/docker-platform-bootstrap.sh
build/apps/docker-platform/docker-platform-bootstrap.service
build/apps/docker-platform/README-docker-platform-image.txt
build/apps/docker-platform/99-docker-platform-image
build/apps/docker-platform/examples/postgres/docker-compose.yml
build/apps/docker-platform/examples/mariadb/docker-compose.yml
build/apps/docker-platform/examples/redis/docker-compose.yml
build/apps/docker-platform/examples/nginx-demo/docker-compose.yml
```

---

## Record Build Manifest

หลัง pre-capture gate ผ่าน ให้สร้าง/อัปเดต `build/apps/docker-platform/docker-platform-build-manifest.md` ด้วยข้อมูล version ที่ verify จาก golden-image VM เท่านั้น:

```bash
lsb_release -ds
docker version
docker compose version
docker buildx version
dpkg-query -W docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker images --digests --format '{{.Repository}}:{{.Tag}} {{.Digest}}'
```

เก็บเฉพาะ Base OS, Docker stack package versions แบบ minimal, Docker/Compose/Buildx versions, container image tag + digest และ build notes สั้นๆ. ห้ามเก็บ image name, Glance ID, server ID, floating IP, VM IP, hostname, OpenStack context หรือ credentials.
