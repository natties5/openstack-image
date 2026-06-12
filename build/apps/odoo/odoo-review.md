# Odoo — Community Research & Image Decisions  [มี review]

> Research จาก community + official docs สำหรับตัดสินใจ feature ของ Odoo image
> ใช้เป็น decision log ก่อน build image จริง

---

## กลุ่มผู้ใช้

### Beginner — SME เจ้าของธุรกิจ

ต้องการหลัก:
- เปิด `http://IP` แล้วใช้ได้เลย
- ไม่ต้องตั้ง PostgreSQL เอง
- ไม่มี demo data
- ลง module เองจาก Odoo Apps ได้
- ใช้งานภาษาไทยและ PDF ภาษาไทยได้

ปัญหาที่เจอบ่อย:
- หน้า login/CSS แปลก หรือ notification/live chat ไม่ทำงาน เพราะ websocket/longpolling proxy ไม่ถูก
- `Permission denied` บน `/var/lib/odoo/sessions` จาก volume owner ไม่ตรง
- Odoo start ก่อน PostgreSQL พร้อม
- สร้าง database ผิดชื่อ หรือเปิด demo data โดยไม่ตั้งใจ

### Intermediate — Implementer / IT Consultant

ต้องการหลัก:
- SMTP ใส่ทีหลังได้
- custom addons ที่ `/mnt/extra-addons`
- backup database + filestore
- HTTPS ด้วย cert จริง
- workers tuning ตาม VM size

ปัญหาที่เจอบ่อย:
- custom module ไม่ขึ้นเพราะ `addons_path` ไม่ถูก
- backup database อย่างเดียว แต่ลืม filestore
- เปิด port 8069 public ตรงๆ โดยไม่ผ่าน reverse proxy
- เปลี่ยน major version แล้ว database migration พัง ต้องใช้ Odoo Upgrade/OpenUpgrade

### Advanced — Enterprise / SaaS Provider

ต้องการหลัก:
- workers + gevent/websocket
- PostgreSQL tuning
- shared filestore ถ้า scale หลาย replica
- SSO/LDAP หรือ Enterprise modules ในบางเคส

สิ่งที่ไม่ใส่ใน image v1:
- HA/Kubernetes/RWX storage
- Redis/session shared store
- Odoo Enterprise modules
- auto major upgrade

---

## Decisions Made

| เรื่อง | Decision | เหตุผล |
|---|---|---|
| Base OS | Ubuntu 26.04 | ตาม app catalog ของ repo |
| Runtime | Docker Compose | pattern เดิมของ image domain |
| Odoo | `odoo:18.0` ตอน dev, pin digest ตอน freeze | stable กว่า `latest`, upstream official |
| PostgreSQL | `postgres:16` | compatible และ supported ยาว |
| Reverse proxy | Nginx | รองรับ HTTP/HTTPS + websocket path |
| DB name | `odoo_prod` | กันสร้าง DB ผิดชื่อ, backup ง่าย |
| Demo data | disabled | image ใช้งานจริง ไม่ใช่ demo |
| `list_db` | `False` | ลด database manager exposure |
| `dbfilter` | `^odoo_prod$` | single DB production-ish |
| Admin user | auto-create `admin` + random password | ลูกค้า login ได้ทันที แล้วเปลี่ยน password เอง |
| Secrets | first boot generate only | golden image ห้ามมี secret |
| Minimum flavor | 2 vCPU / 2GB RAM | ตามแพ็กเกจขั้นต่ำที่ขาย |
| Workers | adaptive | 2GB ใช้ safe mode, RAM มากค่อยเพิ่ม workers |
| Backup | `pg_dump` + filestore tar | Odoo ต้อง backup ทั้ง DB และ `/var/lib/odoo` |

---

## Worker Policy

| RAM | Mode | Config |
|---|---|---|
| `< 3GB` | small | `workers = 1`, `max_cron_threads = 1` |
| `3GB - <5GB` | light | `workers = 2`, `max_cron_threads = 1` |
| `>= 5GB` | normal | `min(2*vCPU+1, RAM cap)` |

เหตุผล: สูตร official `2*vCPU+1` ดีสำหรับ production แต่ VM 2GB มีโอกาส OOM ถ้าเปิด workers เต็ม

---

## Conscious Omissions

| Feature | เหตุผล |
|---|---|
| Demo data | ไม่เหมาะกับ image ใช้งานจริง |
| Multi-database | เพิ่ม support burden, image นี้ fixed `odoo_prod` |
| Redis/HA | ไม่เหมาะกับ single VM v1 |
| Kubernetes/Helm | คนละ deployment model |
| Enterprise modules | ต้องมี license และ proprietary code |
| Auto major upgrade | Odoo major migration ต้องเป็น project แยก |
| SMTP preconfigured | ไม่รู้ provider ลูกค้า ให้เตรียมช่องแก้ config ทีหลัง |

---

## Verify ก่อน freeze

ต้อง verify บนเครื่อง build จริงก่อนประกาศพร้อมใช้:
- `docker pull --platform linux/amd64 odoo:18.0`
- `docker pull --platform linux/amd64 postgres:16`
- `docker pull --platform linux/amd64 nginx:1.27`
- `wkhtmltopdf --version` ใน official Odoo container
- font Noto/CJK/Thai ใน official Odoo container
- init DB `odoo_prod` แบบ `--without-demo=all`
- set admin password ผ่าน `odoo shell` ได้จริง
- Nginx `/websocket` และ fallback `/longpolling` ไม่ทำให้หน้าเว็บ blank
- backup/restore ทั้ง DB และ filestore

---

## วิธีใช้ซ้ำ

1. อ่าน decision table ก่อนเปลี่ยน feature
2. ถ้าเปลี่ยน Odoo major ให้ทดสอบ init/backup/restore ใหม่ทั้งหมด
3. ถ้าเจอปัญหาใหม่ ให้เพิ่ม `odoo-errors.md` หรือ `problem/generic/` ตามขอบเขต
4. ถ้า build ผ่านจริง ค่อยอัปเดต `odoo-post-check.md` และ `_app-catalog.md`
