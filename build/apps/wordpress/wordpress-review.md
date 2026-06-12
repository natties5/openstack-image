# WordPress — Community Research & User Needs

> Research จาก community (Reddit, StackExchange, WordPress.org, Hacker News, WPBeginner) — 
> สิ่งที่ผู้ใช้ WordPress ต้องการและปัญหาที่เจอบ่อย
> ใช้ตัดสินใจ feature ที่ต้องมีใน image

---

## กลุ่มผู้ใช้

### Beginner — สร้างเว็บไซต์แรก

| ต้องการ | ความถี่ | Source |
|---|---|---|
| Setup ง่าย — `http://IP` แล้วเจอ 5-minute install | 🔴 สูงมาก | r/WordPress, WPBeginner |
| ไม่ต้อง config database เอง — bootstrap ทำ auto | 🔴 สูงมาก | r/webhosting |
| Upload theme/plugin ได้ ไม่ติด limit | 🔴 สูงมาก | WordPress.org forums top FAQ |
| เปลี่ยนภาษาเป็นไทย | 🟡 ปานกลาง | คนไทยใช้ WP |
| ลืม password — reset ได้ | 🟠 สูง | WordPress.org support |

**ปัญหาที่เจอบ่อย:**
- "413 Request Entity Too Large" — nginx `client_max_body_size` เล็กไป (WPBeginner #1 nginx issue)
- "The uploaded file exceeds the upload_max_filesize directive in php.ini" — มือใหม่แก้ไม่เป็น
- White screen of death หลังอัปเดต plugin — ไม่รู้วิธีเปิด debug mode
- "Error establishing a database connection" — DB container down หรือ password ผิด
- Permalink 404 หลังเปลี่ยน — nginx ไม่มี `.htaccess` support → ต้องใช้ nginx rewrite rules

### Intermediate — ทำเว็บไซต์ธุรกิจ / บล็อกจริงจัง

| ต้องการ | ความถี่ | Source |
|---|---|---|
| HTTPS — ฟรี, ขั้นตอนง่าย | 🔴 สูงมาก | r/WordPress, Google ranking |
| Backup + restore — DB + files | 🔴 สูงมาก | r/WordPress top concern |
| PHP memory/upload limit ปรับได้ | 🟠 สูง | WordPress.org |
| SMTP — form submission, password reset email | 🟠 สูง | WPBeginner, wp-mail-smtp downloads |
| Redis object cache — เร่งความเร็ว | 🟡 ปานกลาง | WordPress performance guides |
| WP-CLI — จัดการผ่าน command line | 🟡 ปานกลาง | WP-CLI handbook |
| Multisite — หลายเว็บใน install เดียว | 🟢 ต่ำ | Specific use cases |

**ปัญหาที่เจอบ่อย:**
- `docker compose restart wordpress` แล้ว nginx cache ยังจำค่าเดิม → ต้อง restart nginx ด้วย
- MariaDB vs MySQL — community แนะนำ MariaDB (เร็วกว่า, open-source แท้)
- PHP-FPM vs Apache — community แนะนำ FPM + Nginx (เร็วกว่า, resource น้อยกว่า)
- XML-RPC brute force attack — community แนะนำ disable `xmlrpc.php`
- `wp-config.php` permission — user ผิด → WordPress อ่านไม่ได้

### Advanced — Agency / production deployment

| ต้องการ | ความถี่ | Source |
|---|---|---|
| Staging → production workflow | 🟡 ปานกลาง | Agency workflows |
| Git-based deployment | 🟡 ปานกลาง | r/ProWordPress |
| Redis page cache (ไม่ใช่แค่ object cache) | 🟢 ต่ำ | High traffic sites |
| CDN integration | 🟡 ปานกลาง | Performance optimization |
| Security hardening — disable file editor, restrict xmlrpc | 🟠 สูง | WordPress security best practices |
| Log monitoring — PHP errors, access logs | 🟡 ปานกลาง | Production ops |

**ปัญหาที่เจอบ่อย:**
- Docker containers ต้องใช้ UID เดียวกันเพื่อ volume mount — `wordpress:php8.3-fpm` = Debian-based (UID 33) ตรงกับ `nginx:1.27` → mount volume ได้ไม่มี permission issue
- ใช้ `nginx:alpine` (UID 100) + `wordpress:php8.3-fpm` (UID 33) → permission mismatch — community เน้นย้ำเรื่องนี้มากใน Docker setups

---

## Best Practices จาก Community

### Database: MariaDB → MySQL
- MariaDB เร็วกว่า MySQL ใน workload ทั่วไป (community consensus)
- MariaDB LTS (11.4) → support ยาว 5 ปี
- `healthcheck.sh --connect --innodb_initialized` — healthcheck ที่ถูกต้องสำหรับ MariaDB Docker

### PHP: FPM → Apache
- PHP-FPM + Nginx เร็วกว่า PHP-Apache 30-40% ใน benchmark (r/WordPress consensus)
- FPM แยก process pool — resource management ดีกว่า
- Nginx จัดการ static files, SSL, gzip — เร็วกว่า Apache มาก

### Nginx config
- `client_max_body_size` ≥ upload limit — ป้องกัน 413 error
- `try_files $uri $uri/ /index.php?$args` — WordPress permalink ทำงานได้ (ไม่ต้องใช้ .htaccess)
- `fastcgi_param HTTPS $https if_not_empty` — WordPress detect HTTPS อัตโนมัติ ไม่ต้องแก้ wp-config
- Disable `xmlrpc.php` — ป้องกัน brute force (WordPress security best practice #3)

### Docker volumes
- ใช้ named volumes, ไม่ใช่ bind mounts — Docker จัดการ permission ให้ดีกว่า
- `db_data` + `wp_data` แยกกัน — backup/restore สะดวก

### Security
- `.env` file ต้อง `chmod 600` — มี DB password
- ลูกค้าสร้าง admin account เองผ่าน web UI — เราไม่มี password นี้
- SMTP → community แนะนำ WP Mail SMTP plugin (ฟรี, ใช้กับ Gmail/Outlook/SMTP ได้)

---

## สิ่งที่ควรมีใน Image (Recommended)

| Feature | Priority | Reason |
|---|---|---|
| MariaDB LTS แทน MySQL | 🔴 Must | Community consensus — เร็วกว่า, LTS ยาวกว่า |
| PHP-FPM + Nginx | 🔴 Must | Community consensus — เร็วกว่า Apache 30-40% |
| `client_max_body_size` = PHP `upload_max_filesize` | 🔴 Must | แก้ปัญหา 413 upload error (#1 nginx issue) |
| `try_files` rewrite rules | 🔴 Must | WordPress permalink ไม่พัง (ไม่มี .htaccess) |
| Disable `xmlrpc.php` | 🟠 Should | Security best practice |
| `fastcgi_param HTTPS` auto-detect | 🟠 Should | WordPress รู้เองว่าใช้ HTTP หรือ HTTPS |
| php.ini แยกไฟล์ แก้บน host ได้ | 🟠 Should | มือใหม่แก้ PHP settings ได้โดยไม่เข้า container |
| Restart ทั้ง stack docs | 🟠 Should | มือใหม่รู้ว่าแก้ php.ini ต้อง restart ทั้ง nginx + wordpress |
| WP-CLI | 🟡 Could | Advanced users — ใช้ `docker compose exec wordpress wp` |
| Redis object cache | 🟡 Could | ต้องการ Redis container เพิ่ม — หนักขึ้น |
| WP Mail SMTP plugin pre-installed | 🟡 Could | แต่ plugin update บ่อย — ดีกว่าให้ลูกค้าติดตั้งเอง |

---

## สิ่งที่ตัดสินใจไม่ใส่ (Conscious Omissions)

| Feature | Reason |
|---|---|
| Theme/Plugin pre-installed | ไม่รู้ว่าลูกค้าจะใช้ theme อะไร — ให้ติดตั้งเองดีกว่า |
| Multisite | เฉพาะ use case — config ต่างกันมาก |
| Page cache plugin | ดีกว่าให้ลูกค้าเลือกเอง (Redis/LiteSpeed/W3 Total Cache) |
| SSL auto-provision (Caddy/Traefik) | ต้องการ DNS challenge — ลูกค้าต้องมี domain จริง |
| Staging workflow | ซับซ้อน — ทำหลัง deploy ดีกว่า |
