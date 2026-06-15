#!/usr/bin/env bash
set -euo pipefail

APP_DIR=/opt/monitoring
ENV_FILE="$APP_DIR/.env"
INFO_FILE=/root/README-grafana-prometheus-image.txt
LOG=/var/log/grafana-prometheus-bootstrap.log
MARKER=/var/lib/grafana-prometheus-firstboot.done

exec > >(tee -a "$LOG") 2>&1

random_secret() {
  openssl rand -base64 32 | tr -d '=+/' | cut -c1-32
}

get_primary_ip() {
  hostname -I 2>/dev/null | awk '{print $1}'
}

wait_http() {
  local url="$1"
  local name="$2"
  local tries=60
  local i=1
  while [ "$i" -le "$tries" ]; do
    if curl -fsS "$url" >/dev/null 2>&1; then
      echo "$name is ready"
      return 0
    fi
    sleep 3
    i=$((i + 1))
  done
  echo "WARNING: $name did not become ready in time"
  return 1
}

write_info_file() {
  local vm_ip="$1"
  local password="$2"
  cat > "$INFO_FILE" << EOF
Grafana+Prometheus Monitoring Image
====================================

Grafana URL:
  http://${vm_ip:-<VM-IP>}/

Login:
  Username: admin
  Password: $password

Quick commands:
  monitoring-info
  monitoring-status
  monitoring-list-targets
  monitoring-add-http https://example.com website
  monitoring-add-node 10.0.0.12:9100 web-01
  monitoring-add-tcp 10.0.0.20:5432 postgres-01
  monitoring-add-ping 10.0.0.30 router-01
  monitoring-reset-grafana-password

Network notes:
  - To monitor HTTP/HTTPS/TCP/ICMP, this VM must reach the target IP/URL/port.
  - To monitor Linux CPU/RAM/Disk on another VM, install node_exporter there and allow TCP 9100 from this VM.
  - Prometheus and Alertmanager bind to localhost only on this VM.

Data locations:
  App directory: /opt/monitoring
  Target files: /opt/monitoring/prometheus/targets
  Docker volumes: grafana_data, prometheus_data, alertmanager_data

If this VM was created from a snapshot of another already-used VM, the old password and monitoring state may be copied too.
Run monitoring-reset-grafana-password if you want a new Grafana admin password.
EOF
  chmod 600 "$INFO_FILE"
}

echo "[$(date -Is)] Grafana+Prometheus bootstrap started"

if [ -e "$MARKER" ]; then
  echo "Bootstrap already completed; ensuring monitoring services are running"
  systemctl enable --now docker
  docker compose -f "$APP_DIR/docker-compose.yml" --env-file "$ENV_FILE" up -d
  exit 0
fi

mkdir -p "$APP_DIR" /var/lib
chmod 755 "$APP_DIR"

GRAFANA_ADMIN_PASSWORD="$(random_secret)"
GRAFANA_SECRET_KEY="$(random_secret)$(random_secret)"
VM_IP="$(get_primary_ip)"

cat > "$ENV_FILE" << EOF
TZ=Asia/Bangkok
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD
GRAFANA_SECRET_KEY=$GRAFANA_SECRET_KEY
GRAFANA_ROOT_URL=http://${VM_IP:-localhost}/
EOF
chmod 600 "$ENV_FILE"

systemctl enable --now docker
docker compose -f "$APP_DIR/docker-compose.yml" --env-file "$ENV_FILE" up -d

wait_http "http://127.0.0.1/" "Grafana via Nginx"
write_info_file "$VM_IP" "$GRAFANA_ADMIN_PASSWORD"

touch "$MARKER"
echo "Info written to $INFO_FILE"
echo "[$(date -Is)] Grafana+Prometheus bootstrap completed"
