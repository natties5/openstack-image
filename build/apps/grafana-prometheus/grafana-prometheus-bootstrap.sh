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

read_env_password() {
  if [ ! -f "$ENV_FILE" ]; then
    return 1
  fi
  awk -F= '$1 == "GRAFANA_ADMIN_PASSWORD" {sub(/^[^=]*=/, ""); print; exit}' "$ENV_FILE"
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
EOF
  cat >> "$INFO_FILE" << 'HEREDOC'

=========================================================================
ผังไฟล์ (อะไรอยู่ที่ไหน)
=========================================================================

[Directory หลัก]
  /opt/monitoring/
      โฟลเดอร์หลักของระบบ monitoring — ทุกอย่างอยู่ที่นี่

[Config — แก้ไขได้]
  /opt/monitoring/docker-compose.yml
      ตั้งค่า Docker containers ทั้งหมด เช่น port, volume, restart policy

  /opt/monitoring/nginx/default.conf
      ตั้งค่า Nginx reverse proxy — ใช้ตอนเพิ่ม TLS/HTTPS หรือเปลี่ยน route

  /opt/monitoring/prometheus/prometheus.yml
      ตั้งค่า Prometheus — scrape interval, retention, global setting

  /opt/monitoring/prometheus/rules/alerts.yml
      ตั้งค่าเงื่อนไข alert — threshold ต่างๆ เช่น CPU สูงเกิน 90%

  /opt/monitoring/alertmanager/alertmanager.yml
      ตั้งค่าการส่ง alert — email, LINE, Slack, webhook

  /opt/monitoring/blackbox/blackbox.yml
      ตั้งค่า blackbox exporter — วิธี probe HTTP, TCP, ICMP

  /opt/monitoring/grafana/provisioning/
      ตั้งค่า Grafana อัตโนมัติ — datasource และ dashboard provider

[Target files — helper command จัดการให้ ปกติไม่ต้องแก้]
  /opt/monitoring/prometheus/targets/nodes.yml
      รายชื่อเครื่องที่ monitor ผ่าน node_exporter

  /opt/monitoring/prometheus/targets/http.yml
      รายชื่อ URL ที่ monitor ผ่าน HTTP/HTTPS

  /opt/monitoring/prometheus/targets/tcp.yml
      รายชื่อ TCP port ที่ monitor

  /opt/monitoring/prometheus/targets/ping.yml
      รายชื่อ IP ที่ monitor ผ่าน ping

  /opt/monitoring/prometheus/targets/cadvisor.yml
      รายชื่อ container metrics (optional — ต้องเปิด profile เพิ่ม)

[Dashboard]
  /opt/monitoring/grafana/dashboards/
      วางไฟล์ dashboard JSON ได้ที่นี่ — Grafana จะโหลดให้อัตโนมัติ

[Runtime — ระบบสร้างและจัดการให้ ห้ามแก้ไข]

  /opt/monitoring/.env
      เก็บ password และ secret ต่างๆ

  /root/README-grafana-prometheus-image.txt
      ไฟล์ที่คุณกำลังอ่านอยู่นี้

  /var/lib/grafana-prometheus-firstboot.done
      marker — บอกว่าระบบ boot ครั้งแรกแล้ว

[ข้อมูล — Docker volumes อย่าลบ]

  grafana_data
      เก็บ Grafana settings, dashboards, users

  prometheus_data
      เก็บ metrics ย้อนหลังทั้งหมด

  alertmanager_data
      เก็บ alert state และ silences

[ดู Log]

  docker logs grafana
  docker logs prometheus
  docker logs alertmanager
  docker logs node-exporter
  docker logs blackbox-exporter
  docker logs monitoring-nginx

[Scripts — คำสั่งต่างๆ]

  /usr/local/sbin/monitoring-*
      helper commands ทั้งหมด (monitoring-info, monitoring-add-* ฯลฯ)

  /usr/local/sbin/grafana-prometheus-bootstrap.sh
      script ที่รันตอนเปิดเครื่องครั้งแรก

  /etc/systemd/system/grafana-prometheus-bootstrap.service
      systemd service — ควบคุมการเปิด/ปิดระบบ

  /etc/update-motd.d/99-grafana-prometheus-image
      MOTD — ข้อความที่เห็นตอน login

=========================================================================
HEREDOC
  chmod 600 "$INFO_FILE"
}

echo "[$(date -Is)] Grafana+Prometheus bootstrap started"

if [ -e "$MARKER" ]; then
  echo "Bootstrap already completed; ensuring monitoring services are running"
  systemctl enable --now docker
  docker compose -f "$APP_DIR/docker-compose.yml" --env-file "$ENV_FILE" up -d
  if [ ! -s "$INFO_FILE" ] || ! grep -q '^  Password: ' "$INFO_FILE"; then
    EXISTING_GRAFANA_ADMIN_PASSWORD="$(read_env_password || true)"
    if [ -n "$EXISTING_GRAFANA_ADMIN_PASSWORD" ]; then
      write_info_file "$(get_primary_ip)" "$EXISTING_GRAFANA_ADMIN_PASSWORD"
      echo "Info file repaired at $INFO_FILE"
    else
      echo "WARNING: cannot repair $INFO_FILE because $ENV_FILE has no GRAFANA_ADMIN_PASSWORD"
    fi
  fi
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
