# Nextcloud Docker — Bootstrap จบแต่ยังค้างหน้า install wizard

| Domain | image |
| Date | 2026-06-08 |
| Status | solved |

## Overview

Nextcloud container อาจขึ้นครบและ HTTP ตอบ `200/302` แล้ว แต่ app ยังไม่ได้ install จริง ทำให้ VM ที่ boot จาก image ค้างที่ install wizard แทนหน้า login

## Problem

### Symptom

- `docker compose ps` เห็น `db`, `redis`, `nextcloud`, `nginx` running
- `curl http://localhost` ตอบ HTTP ได้
- หน้าเว็บยังเป็น install wizard หรือไม่ใช่ login page
- `php occ status` ได้ `installed: false`
- log อาจมี `occ: executable file not found` หรือ `Installing of nextcloud failed`

### Root Cause

สาเหตุที่พบได้บ่อย:

- Compose env ปน database driver ผิด เช่นใส่ `MYSQL_*` ใน stack ที่ตั้งใจใช้ PostgreSQL
- Bootstrap เรียก `occ` ตรงๆ แต่ binary อยู่ที่ `/var/www/html/occ` และควรเรียกผ่าน PHP จาก working directory ของ Nextcloud
- Post-check ใช้ HTTP status อย่างเดียว ทำให้ install wizard ที่ตอบ `200 OK` ถูกนับว่าผ่านผิดๆ

## Reference

- Source bootstrap: `image/build/nextcloud/nextcloud-bootstrap.sh`
- Build guide: `image/build/nextcloud/nextcloud.md`
- Post-check: `image/build/nextcloud/nextcloud-post-check.md`
- Error log: `image/build/nextcloud/nextcloud-errors.md`

## Verify

รันบน `[nextcloud-test-vm]`:

```bash
cd /opt/nextcloud
docker compose ps
docker compose exec -T -u www-data nextcloud sh -lc 'cd /var/www/html && php occ status'
curl -sL http://localhost | grep -i -E 'Login - Nextcloud|Nextcloud' | head
```

ต้องได้:

- `php occ status` มี `installed: true`
- หน้าเว็บเป็น login page ไม่ใช่ install wizard

## Fix Pattern

1. ลบ env ของ database driver ที่ไม่ใช้ เช่น `MYSQL_*` ถ้าใช้ PostgreSQL
2. เรียก `occ` ด้วย pattern นี้:

```bash
docker compose exec -T -u www-data nextcloud sh -lc 'cd /var/www/html && php occ status'
```

3. Bootstrap ต้องรอ `installed: true` ก่อนจบ success
4. ถ้าต้อง retest first boot ให้ reset runtime state ก่อน:

```bash
cd /opt/nextcloud
docker compose down -v
rm -f /opt/nextcloud/.env /root/nextcloud-credentials.txt /var/log/nextcloud-bootstrap.log
```

## Action Items

- [x] บันทึก pattern ใน `nextcloud-errors.md`
- [x] เพิ่ม post-check ที่เช็ค `php occ status`
- [x] ปรับ bootstrap source ให้รอ `installed: true`

## Notes

ห้ามถือว่า `docker compose ps` หรือ HTTP status อย่างเดียวผ่าน สำหรับ Nextcloud ต้องเช็ค app install state ด้วย `php occ status` เสมอ

## วิธีใช้ซ้ำ

1. ถ้า Nextcloud เปิดเว็บได้แต่ยังค้าง wizard ให้รัน `php occ status`
2. ถ้า `installed: false` ให้ตรวจ DB env mismatch และ container logs
3. แก้ source/golden image แล้ว reset runtime volumes เพื่อ test first boot ใหม่
4. เก็บ evidence แบบ redact ห้าม dump credentials
