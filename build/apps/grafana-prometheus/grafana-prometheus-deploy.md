# Grafana+Prometheus — Deploy Guide

> ใช้ deploy stack ลง VM ที่มีอยู่แล้ว หรือใช้เป็น checklist ระหว่าง build image
> ขอบเขต: deploy + post-test เท่านั้น ไม่รวม OpenStack capture, Glance, server ID, image ID, floating IP

---

## เป้าหมาย

```text
SSH เข้า VM
→ ติดตั้ง Docker CE + Compose plugin
→ วาง source files ใต้ /opt/monitoring
→ enable grafana-prometheus-bootstrap.service
→ run bootstrap
→ ทดสอบ self-service commands
→ ส่งต่อ post-check
```

---

## Assumptions

| เรื่อง | ค่า |
|---|---|
| OS | Ubuntu 26.04 |
| User | root หรือ user ที่มี sudo |
| App dir | `/opt/monitoring` |
| Public UI | `http://<VM-IP>/` |
| Runtime data | Docker volumes: `grafana_data`, `prometheus_data`, `alertmanager_data` |

---

## Step 1 — Pre-flight บน VM

```bash
lsb_release -a | grep Release
df -h /
free -h
curl -sI https://download.docker.com | head -1
```

ต้องได้:
- Ubuntu 26.04 หรือ guest image ที่รองรับ
- disk free มากกว่า 8GB
- RAM อย่างน้อย 2GB
- DNS/internet ใช้งานได้

---

## Step 2 — Install Docker CE

```bash
apt update && apt install -y ca-certificates curl gnupg openssl jq vim htop net-tools
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

Configure Docker log rotation:

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

---

## Step 3 — Deploy Source Files

สร้าง directories:

```bash
mkdir -p /opt/monitoring/{nginx,prometheus/rules,prometheus/targets,blackbox,alertmanager,grafana/provisioning/datasources,grafana/provisioning/dashboards,grafana/dashboards}
chmod 755 /opt/monitoring
```

Copy source files จาก repo ไปยัง VM ตาม mapping นี้:

| Source | Destination |
|---|---|
| `docker-compose.yml` | `/opt/monitoring/docker-compose.yml` |
| `nginx/default.conf` | `/opt/monitoring/nginx/default.conf` |
| `prometheus/prometheus.yml` | `/opt/monitoring/prometheus/prometheus.yml` |
| `prometheus/rules/alerts.yml` | `/opt/monitoring/prometheus/rules/alerts.yml` |
| `prometheus/targets/*.yml` | `/opt/monitoring/prometheus/targets/` |
| `blackbox/blackbox.yml` | `/opt/monitoring/blackbox/blackbox.yml` |
| `alertmanager/alertmanager.yml` | `/opt/monitoring/alertmanager/alertmanager.yml` |
| `grafana/provisioning/**` | `/opt/monitoring/grafana/provisioning/` |
| `grafana/dashboards/*.json` | `/opt/monitoring/grafana/dashboards/` |
| `grafana-prometheus-bootstrap.sh` | `/usr/local/sbin/grafana-prometheus-bootstrap.sh` |
| `scripts/monitoring-*` | `/usr/local/sbin/` |
| `grafana-prometheus-bootstrap.service` | `/etc/systemd/system/grafana-prometheus-bootstrap.service` |
| `99-grafana-prometheus-image` | `/etc/update-motd.d/99-grafana-prometheus-image` |

Set permissions:

```bash
chmod +x /usr/local/sbin/grafana-prometheus-bootstrap.sh
chmod +x /usr/local/sbin/monitoring-*
chmod +x /etc/update-motd.d/99-grafana-prometheus-image
chmod 600 /opt/monitoring/alertmanager/alertmanager.yml
```

---

## Step 4 — Validate Configs

```bash
docker compose -f /opt/monitoring/docker-compose.yml config >/tmp/grafana-prometheus-compose.yml
```

ถ้า Docker daemon พร้อมและ internet พร้อม สามารถตรวจ Prometheus config/rules เพิ่มได้:

```bash
docker run --rm -v /opt/monitoring/prometheus:/etc/prometheus:ro prom/prometheus:latest promtool check config /etc/prometheus/prometheus.yml
docker run --rm -v /opt/monitoring/prometheus/rules:/rules:ro prom/prometheus:latest promtool check rules /rules/alerts.yml
```

---

## Step 5 — Enable + Run Bootstrap

```bash
systemctl daemon-reload
systemctl enable grafana-prometheus-bootstrap.service
systemctl start grafana-prometheus-bootstrap.service
systemctl status grafana-prometheus-bootstrap.service --no-pager
```

Bootstrap ต้องสร้าง:
- `/opt/monitoring/.env`
- `/root/README-grafana-prometheus-image.txt`
- `/var/lib/grafana-prometheus-firstboot.done`

---

## Step 6 — Quick Smoke Test

```bash
sudo monitoring-info
sudo monitoring-status
sudo monitoring-list-targets
curl -fsS http://127.0.0.1/ >/dev/null && echo grafana-ok
curl -fsS http://127.0.0.1:9090/-/healthy && echo prometheus-ok
curl -fsS http://127.0.0.1:9093/-/healthy && echo alertmanager-ok
```

---

## Step 7 — ส่งต่อ Post-Check

หลัง deploy เสร็จให้รัน checklist:

```text
build/apps/grafana-prometheus/grafana-prometheus-post-check.md
```

ถ้าผ่าน post-check = VM พร้อมให้ลูกค้าใช้งาน self-service monitoring

---

## Notes

- คู่มือนี้ไม่จัดการ OpenStack capture/Glance
- ห้ามบันทึก IP, server ID, image ID, password, token ลงเอกสาร repo
- ถ้า deploy ลง VM ที่ snapshot มาจาก VM ใช้งานแล้ว password/state เดิมอาจติดมาด้วย ให้รัน `sudo monitoring-reset-grafana-password` ถ้าต้องการ password ใหม่
