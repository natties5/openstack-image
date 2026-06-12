# Nextcloud — Community Research & User Needs

> Research จาก community (Reddit, Discourse, GitHub, Hacker News) — สิ่งที่ผู้ใช้ต้องการและปัญหาที่เจอบ่อย
> ใช้ตัดสินใจ feature ที่ต้องมีใน image

---

## กลุ่มผู้ใช้

### Beginner — Personal file sync

| ต้องการ | ความถี่ | Source |
|---|---|---|
| GDrive/Dropbox replacement — sync โฟลเดอร์อัตโนมัติ | 🔴 สูงมาก | r/Nextcloud top FAQ |
| Setup ง่าย — `http://IP` แล้วใช้ได้เลย ไม่ต้อง config | 🔴 สูงมาก | r/selfhosted |
| Mobile sync — iOS/Android app เชื่อมต่อได้ | 🟠 สูง | Nextcloud forums |
| เปลี่ยน admin password หลังสร้าง account | 🟠 บ่อย | r/Nextcloud |

**ปัญหาที่เจอบ่อย:**
- "Trusted domain" error หลังเปลี่ยน IP — มือใหม่ไม่รู้จัก `occ` (nextcloud community #1 issue)
- PHP memory limit ต่ำไป — อัปโหลดไฟล์ใหญ่ไม่ผ่าน
- `docker compose down -v` แล้วข้อมูลหาย — ไม่เข้าใจ Docker volumes

### Intermediate — Small team / organization

| ต้องการ | ความถี่ | Source |
|---|---|---|
| External storage — mount S3, NFS, SMB | 🟠 สูง | r/Nextcloud, Nextcloud docs |
| LDAP/Active Directory integration | 🟡 ปานกลาง | Enterprise deployments |
| Collabora/OnlyOffice — edit docs ใน browser | 🟠 สูง | r/selfhosted |
| SMTP — system emails, notifications | 🟡 ปานกลาง | Nextcloud forums |
| Redis caching — speed up UI | 🟡 ปานกลาง | Nextcloud performance guide |
| Preview generation — thumbnail รูป/วิดีโอ | 🟡 low | r/Nextcloud |

**ปัญหาที่เจอบ่อย:**
- `occ` commands ต้องรันเป็น user `www-data` (UID 33) — มือใหม่รัน root แล้ว permission พัง
- Cron ไม่ทำงาน — default AJAX cron ช้า → ต้องเปลี่ยนเป็น system cron
- Collabora ต้องการ domain จริง + HTTPS — localhost ไม่ได้

### Advanced — Production / high availability

| ต้องการ | ความถี่ | Source |
|---|---|---|
| PostgreSQL (ไม่ใช่ MySQL) — Nextcloud 30+ official recommendation | 🔴 สูงมาก | Nextcloud developer docs |
| Redis — file locking + session + cache | 🟠 สูง | Nextcloud admin manual |
| HA — multiple Nextcloud containers + shared storage | 🟢 ต่ำ | Enterprise |
| S3 as primary storage | 🟡 ปานกลาง | Nextcloud performance guide |
| Backup strategy — DB + files + config | 🟠 สูง | r/selfhosted |
| Auto-update via `occ upgrade` | 🟡 ปานกลาง | Nextcloud admin manual |

---

## Best Practices จาก Community

### Database: PostgreSQL → MySQL
- Nextcloud 30 ประกาศ PostgreSQL เป็นค่าเริ่มต้นใน Docker image — official docs แนะนำ PostgreSQL
- MariaDB/MySQL still supported but PostgreSQL is future-proof

### Runtime data layout
- Community best practice มักใช้ Docker named volumes เพราะ permission พังยาก
- สำหรับ OpenStack app image นี้เลือก bind mount ที่ `/var/lib/nextcloud/` เพื่อให้ user เห็น data จริง, backup ง่าย, และย้ายไป attached volume ภายหลังได้โดยไม่แก้ compose
- ต้องชดเชยความเสี่ยง permission ด้วย post-check และห้ามให้ user แก้ไฟล์ใต้ `/var/lib/nextcloud` ถ้าไม่จำเป็น

### Nginx reverse proxy
- Nginx หน้า Nextcloud Apache — ลด resource, จัดการ SSL จุดเดียว
- `X-Forwarded-Proto` header — Nextcloud detect HTTPS อัตโนมัติ
- `client_max_body_size` ต้อง ≥ upload limit (default 512M ก็พอ)

### Security
- `.env` file — ต้อง `chmod 600`
- Admin password — auto-generate, ไม่ใช้ default
- SMTP — ใช้ plugin หรือ configure ใน `config.php`

---

## สิ่งที่ควรมีใน Image (Recommended)

| Feature | Priority | Reason |
|---|---|---|
| PostgreSQL เป็น default DB | 🔴 Must | Nextcloud 30+ recommendation |
| Redis built-in | 🟠 Should | Performance — ถ้ามี docker-compose.yml รองรับแล้ว |
| `occ` alias ใน README | 🟠 Should | มือใหม่ใช้ `occ` บ่อย — ต้องบอกวิธีรัน (`docker compose exec -u33 nextcloud ./occ`) |
| `NEXTCLOUD_TRUSTED_DOMAINS` inject auto via bootstrap | 🔴 Must | แก้ปัญหา #1 ของมือใหม่ (trusted domain error) |
| HTTPS via nginx reverse proxy | 🔴 Must | แยก cert management จาก Nextcloud Apache |
| Pre-configured PHP memory/upload limit | 🟠 Should | 512M — มือใหม่แก้ไม่เป็น |
| Auto-renew cert script | 🟡 Could | Let's Encrypt cert ทุก 90 วัน |

---

## สิ่งที่ตัดสินใจไม่ใส่ (Conscious Omissions)

| Feature | Reason |
|---|---|
| Collabora/OnlyOffice | หนัก — ต้องอีก container + domain จริง + HTTPS — ไม่เหมาะกับ image สำเร็จรูป |
| LDAP | เฉพาะ enterprise — config ต่างกันมาก |
| S3 primary storage | ต้อง setup S3 endpoint — ทำหลัง deploy ดีกว่า |
| ElasticSearch (full-text search) | หนักมาก — RAM อย่างน้อย 2GB — ไม่เหมาะกับ image สำเร็จรูป |
