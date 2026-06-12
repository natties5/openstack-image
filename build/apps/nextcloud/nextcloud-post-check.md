# Nextcloud Image — Post-Check Checklist

> Checklist กลางสำหรับตรวจ VM ที่สร้างจาก Nextcloud image ครั้งแรก
> ห้ามใส่ password, temp IP, server ID, Glance ID, หรือ runtime credentials ในไฟล์นี้

---

## Scope

ใช้เช็คว่า image ที่ capture แล้ว boot เป็น VM ใหม่ได้จริง และ Nextcloud ถูกติดตั้งเสร็จ ไม่ค้างที่ install wizard

ค่าจริงของรอบ test ให้มาจาก user หรือ `image/tmp/nextcloud-build.env` เท่านั้น ห้าม commit ลงเอกสารกลาง

---

## Runtime Data Policy

ไฟล์ต่อไปนี้เป็น runtime/temp data เท่านั้น:

| Path | เกิดเมื่อไหร่ | Policy |
|---|---|---|
| `/opt/nextcloud/.env` | bootstrap ตอน boot VM | ต้องลบก่อน capture, หลัง boot VM ใหม่ต้องถูกสร้างใหม่ |
| `/root/nextcloud-credentials.txt` | bootstrap ตอน boot VM | ต้องลบก่อน capture, ห้าม dump content ลง repo/chat |
| `/var/log/nextcloud-bootstrap.log` | bootstrap ตอน test/build | ลบก่อน capture ได้ |
| `/var/lib/nextcloud/*` | bootstrap ตอน container start | ต้องลบก่อน capture ถ้า image ต้องเป็น fresh first boot |
| Docker containers/volumes | bootstrap ตอน container start | ต้องลบก่อน capture ถ้า image ต้องเป็น fresh first boot |

---

## Post-Check — รันบน VM ที่สร้างจาก image

[nextcloud-test-vm]

### 1. Bootstrap service

```bash
systemctl is-enabled nextcloud-bootstrap.service
systemctl status nextcloud-bootstrap.service --no-pager
```

**ต้องได้:** service `enabled` และไม่ failed

### 2. Runtime files created after boot

```bash
test -s /opt/nextcloud/.env && echo ".env exists"
test -s /root/nextcloud-credentials.txt && echo "credentials exists"
test -s /var/log/nextcloud-bootstrap.log && echo "bootstrap log exists"
test -d /var/lib/nextcloud/app && echo "app data path exists"
test -d /var/lib/nextcloud/db && echo "db data path exists"
test -d /var/lib/nextcloud/redis && echo "redis data path exists"
```

**ห้าม:** เปิดหรือ dump content ของ `/root/nextcloud-credentials.txt` ลงเอกสาร/chat

### 3. Containers running

```bash
cd /opt/nextcloud
docker compose ps
```

**ต้องได้:** containers หลักขึ้นครบ — `db`, `redis`, `nextcloud`, `nginx`

> ⚠️ **ทุก `docker compose` command ต้องระบุ `--profile http`** — เพราะ nginx service อยู่ใน `profiles: [http, default]` ถ้าสั่ง `docker compose restart/down` โดยไม่มี `--profile http` จะไม่เห็น nginx → container ค้าง → port 80 ถูกจอง → start ใหม่ล้มเหลว

### 4. Nextcloud installed

```bash
docker compose exec -T -u www-data nextcloud sh -lc 'cd /var/www/html && php occ status'
```

**ต้องได้:** `installed: true`

**ห้ามถือว่า HTTP 200 อย่างเดียวผ่าน** เพราะ install wizard ก็คืน `200 OK` ได้

### 5. HTTP login page

```bash
curl -sI http://localhost | head -20
curl -sL http://localhost | grep -i -E 'Login - Nextcloud|Nextcloud' | head
```

**ต้องได้:** root redirect ไป login หรือ login page ตอบ `200` และมีข้อความ `Login - Nextcloud`

### 6. Docker images preserved

```bash
docker images | grep -E 'nextcloud|postgres|redis|nginx'
```

**ต้องได้:** มี image หลักครบ ไม่ต้อง pull ใหม่ตอน first boot

**ต้องไม่มี:** bootstrap log ที่บอกว่า first boot รัน `docker compose pull`

### 6.1 VM login docs / MOTD

```bash
test -s /root/README-nextcloud-image.txt && echo "README exists"
test -x /etc/update-motd.d/99-nextcloud-image && echo "MOTD executable"
test -s /etc/nextcloud-image/image.conf && echo "image metadata exists"
/etc/update-motd.d/99-nextcloud-image
```

**ต้องได้:** MOTD บอก `Creds`, `Docs`, `Config`, `Data`, `Logs`, `Manage` ครบ

### 7. Logs without secret dump

```bash
docker compose -f /opt/nextcloud/docker-compose.yml logs --tail=60 nextcloud
docker compose -f /opt/nextcloud/docker-compose.yml logs --tail=40 db
docker compose -f /opt/nextcloud/docker-compose.yml logs --tail=40 redis
docker compose -f /opt/nextcloud/docker-compose.yml logs --tail=40 nginx
```

**ต้องได้:** ไม่มี install failure ซ้ำ เช่น `Installing of nextcloud failed`, DB driver ผิด, หรือ `occ: executable file not found`

---

## Success Criteria

| ข้อ | เกณฑ์ผ่าน | สถานะ |
|---|---|---|
| 1. Bootstrap service | enabled และไม่ failed | — |
| 2. Runtime files | `.env`, `credentials.txt`, bootstrap log ถูกสร้างหลัง boot | — |
| 3. Containers | `db`, `redis`, `nextcloud`, `nginx` running; db/redis healthy ถ้ามี healthcheck | — |
| 4. Nextcloud install | `php occ status` ได้ `installed: true` | — |
| 5. HTTP | login page ตอบได้ ไม่ใช่ install wizard | — |
| 6. Images | Docker images หลักยังอยู่ครบ | — |
| 7. VM docs | README/MOTD/image metadata อยู่ครบและบอก path สำคัญ | — |
| 8. Logs | ไม่มี install failure / occ path error | — |
| 9. Reboot survive | reboot → กลับมาเอง 4 containers, HTTP 302 | — |
| 10. Docker restart | `systemctl restart docker` → containers auto-recover | — |
| 11. WebDAV file | upload/download/delete ผ่าน WebDAV | — |
| 12. Data persist | ไฟล์อยู่รอด container restart + full restart | — |
| 13. Bind mount | `/var/lib/nextcloud/app/data/` มองเห็นจาก host | — |

ถ้าผ่านครบ = image boot ใช้งานจริงผ่าน post-test

---

## Latest Post-Test Results

| Date | Cluster | Server | IP | Result |
|---|---|---|---|---|
| 2026-06-10 | production-korry-gate2 | `nextcloud-test` (916f8fab) | 203.154.16.48 | ✅ Pass (12/13) |
| | | | | ⚠️ B3: `docker compose down` ต้อง `--profile http` — not a bug, fixed in docs |

---

## Cleanup ก่อน Capture

หลังทดสอบ bootstrap บน golden-image VM แล้ว ก่อน snapshot ต้องลบ runtime state:

```bash
cd /opt/nextcloud
docker compose --profile http down -v
rm -f /opt/nextcloud/.env /root/nextcloud-credentials.txt /var/log/nextcloud-bootstrap.log
rm -rf /var/lib/nextcloud/app/* /var/lib/nextcloud/db/* /var/lib/nextcloud/redis/*
```

แล้ว verify:

```bash
systemctl is-enabled nextcloud-bootstrap.service
cd /opt/nextcloud && docker compose ps
test ! -e /opt/nextcloud/.env && echo ".env removed"
test ! -e /root/nextcloud-credentials.txt && echo "credentials removed"
find /var/lib/nextcloud -mindepth 2 -maxdepth 2 -print -quit | grep -q . || echo "runtime data removed"
```

---

## วิธีใช้ซ้ำ

1. สร้าง VM ใหม่จาก Nextcloud image
2. SSH เข้า `[nextcloud-test-vm]`
3. รันคำสั่งในหัวข้อ Post-Check ทีละข้อ
4. อัปเดต `Success Criteria` เป็น `✅ pass` หรือ `❌ fail` ใน incident/post-test note เฉพาะรอบนั้น
5. ถ้า fail ให้บันทึกใน `image/problem/` โดยไม่ใส่ secret/temp IP
