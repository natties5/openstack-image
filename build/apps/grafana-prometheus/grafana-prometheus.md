# Grafana+Prometheus Image — Ubuntu 26.04 [พร้อม build]

> Image สำเร็จรูป: สร้าง VM → Grafana + Prometheus + Alertmanager พร้อมใช้ → ลูกค้าเพิ่ม VM/URL/port ที่ต้องการ monitor เองได้แบบ self-service

---

## เป้าหมาย

```text
ลูกค้าสร้าง VM จาก image
→ systemd เรียก grafana-prometheus-bootstrap.sh ตอน first boot
→ สุ่ม Grafana admin password ต่อ VM
→ start Grafana + Prometheus + Alertmanager + node_exporter + blackbox_exporter + Nginx
→ เขียน /root/README-grafana-prometheus-image.txt
→ ลูกค้าเปิด http://<VM-IP>/ ใช้งาน Grafana ได้ทันที
→ ลูกค้าเพิ่ม target เองด้วย monitoring-add-* commands
```

| รายการ | ค่า |
|---|---|
| Base OS | Ubuntu 26.04 |
| Runtime | Docker CE + Docker Compose plugin |
| UI | Grafana OSS |
| Metrics | Prometheus |
| Alerting | Alertmanager |
| Exporters | node_exporter, blackbox_exporter |
| Proxy | Nginx |
| Optional | cAdvisor profile สำหรับ Docker metrics |
| Minimum flavor | 2 vCPU / 2GB RAM / 15GB disk |

---

## Customer URLs

| Service | URL | Login |
|---|---|---|
| Grafana | `http://<VM-IP>/` | `sudo monitoring-info` |
| Prometheus | `http://127.0.0.1:9090` on VM only | local admin/debug |
| Alertmanager | `http://127.0.0.1:9093` on VM only | local admin/debug |

Security group / firewall:
- Public/customer: TCP `80`
- Admin SSH: TCP `22`
- Target node metrics: target VMs allow TCP `9100` from monitoring VM
- Target HTTP/TCP checks: monitoring VM must reach target URL/IP/port

---

## Self-Service Commands

| Command | Purpose |
|---|---|
| `sudo monitoring-info` | แสดง Grafana URL, username, generated password, quick commands |
| `sudo monitoring-status` | เช็ค container, health endpoint, target summary, disk |
| `sudo monitoring-list-targets` | ดู target files ที่กำลัง monitor |
| `sudo monitoring-add-http https://example.com website` | เพิ่ม HTTP/HTTPS uptime target |
| `sudo monitoring-add-node 10.0.0.12:9100 web-01` | เพิ่ม Linux VM metrics target ที่มี node_exporter |
| `sudo monitoring-add-tcp 10.0.0.20:5432 postgres-01` | เพิ่ม TCP port target |
| `sudo monitoring-add-ping 10.0.0.30 router-01` | เพิ่ม ICMP reachability target |
| `sudo monitoring-reset-grafana-password` | reset Grafana admin password โดยไม่ลบ data |

ไม่มี snapshot-prep command สำหรับลูกค้า เพราะ image นี้เป็น self-service สำหรับใช้งาน VM โดยตรง ไม่ใช่ admin golden-image lifecycle.

---

## ก่อนเริ่ม — Pre-flight Verification

| เช็ค | ได้จาก | ถ้ายังไม่พร้อม |
|---|---|---|
| Guest image Ubuntu 26.04 สร้างเสร็จแล้ว | `_guest-images.md` → Ubuntu 26.04 | ต้องสร้าง guest image ก่อน |
| VM สร้างจาก guest image ที่ผ่าน Set 1-3 ครบ | standalone build | สร้าง VM จาก guest image |
| Build guide พร้อม `[พร้อม build]` | header tag บน | ต้องสร้าง source files ก่อน |
| SSH credentials | `build/tmp/grafana-prometheus-build.env` (gitignored) | — |

เมื่อ SSH เข้า VM แล้ว verify:

```bash
lsb_release -a | grep Release
grep URIs /etc/apt/sources.list.d/ubuntu.sources
curl -sI https://download.docker.com | head -1
df -h /
free -h
```

ต้องได้:
- Ubuntu 26.04 หรือ codename ที่ตรงกับ guest image
- DNS ออก internet ได้
- disk free มากกว่า 8GB
- RAM อย่างน้อย 2GB

---

## โครงสร้างไฟล์บน VM

```text
/opt/monitoring/docker-compose.yml
/opt/monitoring/.env                                      (first boot สร้างจริง)
/opt/monitoring/nginx/default.conf
/opt/monitoring/prometheus/prometheus.yml
/opt/monitoring/prometheus/rules/alerts.yml
/opt/monitoring/prometheus/targets/{nodes,http,tcp,ping,cadvisor}.yml
/opt/monitoring/blackbox/blackbox.yml
/opt/monitoring/alertmanager/alertmanager.yml
/opt/monitoring/grafana/provisioning/datasources/prometheus.yml
/opt/monitoring/grafana/provisioning/dashboards/default.yml
/opt/monitoring/grafana/dashboards/self-service-overview.json
/usr/local/sbin/grafana-prometheus-bootstrap.sh
/usr/local/sbin/monitoring-*
/etc/systemd/system/grafana-prometheus-bootstrap.service
/root/README-grafana-prometheus-image.txt                 (first boot เขียน generated password)
/etc/update-motd.d/99-grafana-prometheus-image
```

ไฟล์/สถานะที่ต้องไม่มีใน Golden Image:

```text
/opt/monitoring/.env
/root/README-grafana-prometheus-image.txt ที่มี generated password จริง
/var/log/grafana-prometheus-bootstrap.log
/var/lib/grafana-prometheus-firstboot.done
running containers
Docker volumes grafana_data, prometheus_data, alertmanager_data
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
mkdir -p /opt/monitoring/{nginx,prometheus/rules,prometheus/targets,blackbox,alertmanager,grafana/provisioning/datasources,grafana/provisioning/dashboards,grafana/dashboards}
chmod 755 /opt/monitoring
```

### 4. วาง source files

> Source files อยู่ใน `build/apps/grafana-prometheus/` สำหรับตรวจสอบและ copy ได้โดยตรง
> ถ้าต้อง copy-paste บน VM ให้ใช้เนื้อหาไฟล์จาก source folder นี้วาง path ตามโครงสร้างด้านบน

ไฟล์ source ที่ต้องวาง:
- `docker-compose.yml` → `/opt/monitoring/docker-compose.yml`
- `nginx/default.conf` → `/opt/monitoring/nginx/default.conf`
- `prometheus/prometheus.yml` → `/opt/monitoring/prometheus/prometheus.yml`
- `prometheus/rules/alerts.yml` → `/opt/monitoring/prometheus/rules/alerts.yml`
- `prometheus/targets/*.yml` → `/opt/monitoring/prometheus/targets/`
- `blackbox/blackbox.yml` → `/opt/monitoring/blackbox/blackbox.yml`
- `alertmanager/alertmanager.yml` → `/opt/monitoring/alertmanager/alertmanager.yml`
- `grafana/provisioning/**` → `/opt/monitoring/grafana/provisioning/`
- `grafana/dashboards/*.json` → `/opt/monitoring/grafana/dashboards/`
- `grafana-prometheus-bootstrap.sh` → `/usr/local/sbin/grafana-prometheus-bootstrap.sh`
- `scripts/monitoring-*` → `/usr/local/sbin/`
- `grafana-prometheus-bootstrap.service` → `/etc/systemd/system/grafana-prometheus-bootstrap.service`
- `99-grafana-prometheus-image` → `/etc/update-motd.d/99-grafana-prometheus-image`

ตั้ง permission:

```bash
chmod +x /usr/local/sbin/grafana-prometheus-bootstrap.sh
chmod +x /usr/local/sbin/monitoring-*
chmod +x /etc/update-motd.d/99-grafana-prometheus-image
chmod 600 /opt/monitoring/alertmanager/alertmanager.yml
```

### 5. Enable bootstrap service

[golden-image VM]

```bash
systemctl daemon-reload
systemctl enable grafana-prometheus-bootstrap.service
```

### 6. Validate static configs ก่อน pull

[golden-image VM]

```bash
docker compose -f /opt/monitoring/docker-compose.yml config >/tmp/grafana-prometheus-compose.yml
docker run --rm -v /opt/monitoring/prometheus:/etc/prometheus:ro prom/prometheus:latest promtool check config /etc/prometheus/prometheus.yml
docker run --rm -v /opt/monitoring/prometheus/rules:/rules:ro prom/prometheus:latest promtool check rules /rules/alerts.yml
```

### 7. Pre-pull images

[golden-image VM]

```bash
docker compose -f /opt/monitoring/docker-compose.yml pull
```

ถ้าต้องการ pre-pull optional cAdvisor:

```bash
docker compose -f /opt/monitoring/docker-compose.yml --profile cadvisor pull
```

### 8. Test first boot bootstrap บน build VM

[golden-image VM]

```bash
/usr/local/sbin/grafana-prometheus-bootstrap.sh
docker compose -f /opt/monitoring/docker-compose.yml --env-file /opt/monitoring/.env ps
curl -fsS http://127.0.0.1/ >/dev/null && echo grafana-ok
curl -fsS http://127.0.0.1:9090/-/healthy >/dev/null && echo prometheus-ok
curl -fsS http://127.0.0.1:9093/-/healthy >/dev/null && echo alertmanager-ok
sudo monitoring-status
```

### 9. Cleanup runtime state ก่อน capture

[golden-image VM]

> ขั้นตอนนี้สำหรับ build golden image เท่านั้น ไม่ใช่ command ที่ลูกค้าต้องใช้

```bash
docker compose -f /opt/monitoring/docker-compose.yml --env-file /opt/monitoring/.env down -v
rm -f /opt/monitoring/.env
rm -f /root/README-grafana-prometheus-image.txt
rm -f /var/log/grafana-prometheus-bootstrap.log
rm -f /var/lib/grafana-prometheus-firstboot.done
docker volume rm grafana_data prometheus_data alertmanager_data 2>/dev/null || true
docker system prune -f
systemctl daemon-reload
```

ห้ามใช้ `apt autoremove` หรือ `apt clean` เพราะต้องเก็บ package cache ตาม policy domain.

### 10. Final verification ก่อน shutdown/capture

[golden-image VM]

```bash
test ! -f /opt/monitoring/.env
test ! -f /root/README-grafana-prometheus-image.txt
test ! -f /var/lib/grafana-prometheus-firstboot.done
docker ps --format '{{.Names}}'
docker volume ls
systemctl is-enabled grafana-prometheus-bootstrap.service
```

ต้องได้:
- ไม่มี running containers
- ไม่มี generated `.env`
- ไม่มี generated password file
- bootstrap service enabled

จากนั้น shutdown และ capture image.

---

## วิธีใช้งานหลังลูกค้าสร้าง VM

```bash
sudo monitoring-info
sudo monitoring-status
sudo monitoring-add-http https://example.com website
sudo monitoring-add-node 10.0.0.12:9100 web-01
sudo monitoring-add-tcp 10.0.0.20:5432 db-01
sudo monitoring-list-targets
```

ถ้าลืม Grafana password:

```bash
sudo monitoring-reset-grafana-password
sudo monitoring-info
```

ถ้าลูกค้า snapshot VM ที่ใช้งานแล้วไปขึ้นเครื่องใหม่ password และ state เดิมจะติดไปตาม snapshot. ถ้าต้องการ password ใหม่ให้รัน reset script ข้างต้น.

---

## Troubleshooting

| อาการ | เช็ค | วิธีแก้ |
|---|---|---|
| เข้า Grafana ไม่ได้ | `sudo monitoring-status` | ดู Nginx/Grafana container logs |
| target ขึ้น DOWN | `sudo monitoring-list-targets` และ Prometheus Targets UI | ตรวจ IP/URL/port/firewall |
| node metrics ไม่มา | target VM มี node_exporter ไหม | เปิด TCP 9100 จาก monitoring VM ไป target |
| reset password ไม่ได้ | `docker ps`, `docker logs grafana` | ตรวจ Grafana container running |
| disk ใกล้เต็ม | `df -h`, Prometheus data volume | ลด retention หรือเพิ่ม disk |

---

## ส่งต่อ Maker

Maker ต้อง verify:
- Docker Compose config valid
- Prometheus config/rules valid
- first boot generate password จริง
- reboot แล้ว password ไม่เปลี่ยน
- `monitoring-reset-grafana-password` เปลี่ยน password จริงโดยไม่ลบ dashboard/targets/metrics
- public expose เฉพาะ TCP 80
- Prometheus/Alertmanager bind localhost เท่านั้น

Deploy/post-test references:
- Deploy guide: `build/apps/grafana-prometheus/grafana-prometheus-deploy.md`
- Post-check: `build/apps/grafana-prometheus/grafana-prometheus-post-check.md`

OpenStack capture/Glance/server ID/image ID อยู่นอกขอบเขต guide นี้ ให้ user/admin จัดการเอง และห้ามบันทึกค่าจริงลง repo.
