# n8n Workflow Automation Image — Ubuntu 26.04  [รอเติมเนื้อหา]
> Image สำเร็จรูป: สร้าง VM → n8n พร้อมใช้ทันทีที่ `http://<IP>:5678` รองรับ HTTPS

---

## เป้าหมาย

```text
ลูกค้าสร้าง VM จาก Image
→ systemd เรียก n8n-bootstrap.sh
→ สุ่ม PostgreSQL password + N8N_ENCRYPTION_KEY ใหม่
→ สร้าง /opt/n8n/.env + /root/n8n-credentials.txt
→ start PostgreSQL + n8n
→ เข้าเว็บได้ทันที
```

| โหมด | รายละเอียด |
|---|---|
| HTTP | พร้อมใช้ทันที `http://<IP>:5678` |
| HTTPS | วาง cert/key, แก้ `.env`, `docker compose --profile https up -d` |

---

## โครงสร้างไฟล์

```text
/opt/n8n/docker-compose.yml
/opt/n8n/certs/                         (ว่าง — รอวาง cert)
/opt/n8n/nginx/n8n.conf
/usr/local/sbin/n8n-bootstrap.sh
/etc/systemd/system/n8n-bootstrap.service
/root/README-n8n-image.txt
/etc/update-motd.d/99-n8n-image
```

> หมายเหตุ: ถ้า template file ยังไม่มีใน repo ให้ถือว่า task ยังไม่พร้อม build ซ้ำแบบอัตโนมัติ ต้องสร้าง source files ก่อน เช่น `docker-compose.yml`, `n8n-bootstrap.sh`, `n8n-bootstrap.service`

ไฟล์ที่ต้องไม่มีใน Golden Image:
```text
/opt/n8n/.env
/root/n8n-credentials.txt
/var/log/n8n-bootstrap.log
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
```

### 3. สร้าง directory

[golden-image VM]

```bash
mkdir -p /opt/n8n/certs /opt/n8n/nginx
chmod 700 /opt/n8n/certs
```

### 4. คัดลอกไฟล์ static

ไฟล์ที่ต้องวางบน VM ก่อน build image:
- `docker-compose.yml` → `/opt/n8n/docker-compose.yml`
- `n8n.conf` → `/opt/n8n/nginx/n8n.conf`
- `n8n-bootstrap.sh` → `/usr/local/sbin/n8n-bootstrap.sh` (chmod +x)
- `n8n-bootstrap.service` → `/etc/systemd/system/n8n-bootstrap.service`
- `README-n8n-image.txt` → `/root/README-n8n-image.txt`
- `99-n8n-image` → `/etc/update-motd.d/99-n8n-image` (chmod +x)

### 5. เปิด systemd service

[golden-image VM]

```bash
systemctl daemon-reload
systemctl enable n8n-bootstrap.service
```

### 6. ทดสอบ bootstrap + pull images

[golden-image VM]

```bash
/usr/local/sbin/n8n-bootstrap.sh
docker pull nginx:stable
```

### 7. Cleanup ก่อน capture

[golden-image VM]

```bash
cd /opt/n8n
docker compose --profile https down -v
rm -f /opt/n8n/.env /root/n8n-credentials.txt /var/log/n8n-bootstrap.log
docker volume prune -f

# ห้ามใช้ docker image prune -a !!!
```

### 8. Final check + poweroff

[golden-image VM]

```bash
systemctl is-enabled n8n-bootstrap.service
ls -l /opt/n8n/docker-compose.yml /opt/n8n/nginx/n8n.conf /usr/local/sbin/n8n-bootstrap.sh
# ต้องมี Docker images: n8n, postgres:16, nginx:stable
# ต้องไม่มี .env, credentials.txt, containers, volumes
poweroff
```

จากนั้น snapshot/create image ใน OpenStack:

[OpenStack client]

```text
ubuntu-24.04-n8n-workflow-https-ready-YYYYMM
```

---

## Bootstrap Logic

| สถานะ | พฤติกรรม |
|---|---|
| VM ใหม่ (ไม่มี `.env`) | สุ่ม password + key ใหม่, start n8n |
| Reboot (มี `.env` แล้ว) | ใช้ค่าเดิม, start n8n |
| Snapshot + สร้าง VM ใหม่ | ใช้ข้อมูลเดิม, HTTP: update IP, HTTPS: คง domain |
| HTTPS | IP คงที่ตาม domain — bootstrap ไม่เปลี่ยน WEBHOOK_URL |

---

## วิธีเปิด HTTPS

1. ชี้ DNS ไป Floating IP
2. วาง cert: `/opt/n8n/certs/fullchain.pem`, `/opt/n8n/certs/privkey.pem`
3. `chmod 644 /opt/n8n/certs/fullchain.pem && chmod 600 /opt/n8n/certs/privkey.pem`
4. แก้ `/opt/n8n/.env`:
   ```env
   N8N_HOST=n8n.customer.com
   N8N_PROTOCOL=https
   WEBHOOK_URL=https://n8n.customer.com/
   N8N_SECURE_COOKIE=true
   N8N_PROXY_HOPS=1
   ```
5. `cd /opt/n8n && docker compose --profile https up -d`

---

## ข้อควรระวัง

- `/opt/n8n/.env` มี secret — ห้ามลบหลังใช้งานแล้ว
- ห้ามเปลี่ยน `N8N_ENCRYPTION_KEY` หลังสร้าง credentials ใน n8n
- ห้าม `docker compose down -v` บนเครื่องลูกค้า — ลบ volume PostgreSQL/n8n data
- Snapshot VM → VM ใหม่จะเป็น clone (data เดิม) ไม่ใช่ fresh instance

---

## Record Build Manifest

หลัง pre-capture gate ผ่าน ให้สร้าง/อัปเดต `build/apps/n8n/n8n-build-manifest.md` ด้วยข้อมูล version ที่ verify จาก golden-image VM เท่านั้น:

```bash
lsb_release -ds
docker version
docker compose version
docker buildx version
dpkg-query -W docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker images --digests --format '{{.Repository}}:{{.Tag}} {{.Digest}}'
```

เก็บเฉพาะ Base OS, Docker stack package versions แบบ minimal, Docker/Compose/Buildx versions, container image tag + digest และ build notes สั้นๆ. ห้ามเก็บ image name, Glance ID, server ID, floating IP, VM IP, hostname, OpenStack context หรือ credentials.
