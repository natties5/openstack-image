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
