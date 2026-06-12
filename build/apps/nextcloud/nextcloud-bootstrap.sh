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
    if [ -f "$COMPOSE_DIR/certs/fullchain.pem" ] && [ -f "$COMPOSE_DIR/certs/privkey.pem" ]; then
        docker compose --profile https up -d
    else
        docker compose --profile http up -d
    fi
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
cd "$COMPOSE_DIR"
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
