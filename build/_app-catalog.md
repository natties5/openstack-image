# Application Image Catalog

> Ubuntu 26.04-based ready-to-use application images for OpenStack
> **Build Pattern:** Docker Compose app stack + systemd bootstrap + pre-pull images → QCOW2 → Glance

---

## App Status

| App | Folder | Tech Stack | สถานะ |
|---|---|---|---|
| **Nextcloud** 30.x | `build/apps/nextcloud/` | PHP + PostgreSQL + Redis + Nginx | ⚠️ รอ rebuild |
| **WordPress** 6.7 | `build/apps/wordpress/` | PHP + MariaDB + Nginx (PHP-FPM) | ✅ built แล้ว (production-korry-gate2) |
| **Odoo** 18 | `build/apps/odoo/` | Python + PostgreSQL + Nginx | ✅ พร้อม build |
| **n8n** | `build/apps/n8n/` | Node.js + PostgreSQL + Nginx | ❌ รอเติมเนื้อหา |

## Planned / Wishlist

> Apps ที่สนใจทำในอนาคต — เรียงตามความนิยม ยังไม่มี source files

### Category Priority — เรียงตามความนิยมในตลาด

| # | หมวด | Apps | เพราะ |
|---|---|---|---|
| 1 | **CMS / Blog** | 2 | WordPress = 43% ของเว็บทั้งโลก |
| 2 | **E-Commerce** | 2 | WooCommerce ตลาดใหญ่ + PrestaShop standalone |
| 3 | **ERP / CRM / Business** | 3 | Odoo/ERPNext นิยมใน SME ไทย |
| 4 | **File Sharing / Collab** | 2 | Nextcloud = Google Drive ส่วนตัว |
| 5 | **Web Server / Stack** | 2 | LAMP + Docker — พื้นฐานทุกอย่าง |
| 6 | **Dev / DevOps** | 2 | GitLab/Gitea — dev team ไทยใช้เยอะ |
| 7 | **Monitoring** | 2 | Grafana + Uptime Kuma |
| 8 | **AI / Automation** | 1 | Ollama |
| 9 | **Database** | 1 | PostgreSQL |
| 10 | **Education** | 1 | Moodle — มหา'ลัย/โรงเรียนไทย |
| 11 | **Communication** | 2 | Mattermost + Discourse |

---

## Full Catalog — Ubuntu 26.04 Application Images

| Icon | App | Category | Description | Tech Stack | 🌏 | 🇹🇭 | 😊 | 🛠 | vCPU | RAM | Disk | Docker |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| <img src="https://s.w.org/style/images/about/WordPress-logotype-alternative.png" width="28"> | **WordPress** 6.7 | CMS | CMS #1 โลก — 43% ของเว็บทั้งหมด ปรับเป็น E-Commerce ได้ด้วย WooCommerce | PHP + MySQL + Nginx | ⭐5 | ⭐5 | 😊5 | 🛠🛠 | 1 | 1 GB | 10 GB | ✅ |
| <img src="https://raw.githubusercontent.com/TryGhost/Ghost/main/apps/admin-x-settings/public/ghost-logo.png" width="28"> | **Ghost** 5.x | CMS | Blog/Newsletter สมัยใหม่ — เร็วกว่า WP, SEO built-in | Node.js + SQLite | ⭐4 | ⭐2 | 😊4 | 🛠🛠 | 1 | 1 GB | 10 GB | ✅ |
| <img src="https://raw.githubusercontent.com/woocommerce/woocommerce/trunk/plugins/woocommerce/assets/images/woo-logo.svg" width="28"> | **WooCommerce** | E-Commerce | ใช้ร่วมกับ WordPress — plugin ที่เปลี่ยน WP เป็นร้านค้าออนไลน์ | PHP + MySQL | ⭐5 | ⭐5 | 😊4 | 🛠🛠🛠 | 2 | 2 GB | 15 GB | ✅ |
| <img src="https://www.prestashop.com/sites/default/files/logo/favicon-32x32.png" width="28"> | **PrestaShop** 9.x | E-Commerce | ร้านค้าออนไลน์ standalone — ไม่ต้องพึ่ง WP, features ครบ | PHP + MySQL + Nginx | ⭐3 | ⭐3 | 😊3 | 🛠🛠🛠 | 2 | 2 GB | 15 GB | ✅ |
| <img src="https://odoocdn.com/openerp_website/static/src/img/assets/png/odoo_logo.png" width="28"> | **Odoo** 18 | ERP/CRM | ERP ครบวงจร — CRM, Accounting, Inventory, HR, Website, E-Commerce | Python + PostgreSQL + Nginx | ⭐4 | ⭐5 | 😊4 | 🛠🛠🛠🛠 | 2 | 2 GB | 20 GB | ✅ |
| <img src="https://erpnext.com/assets/erpnext_logo_dark.svg" width="28"> | **ERPNext** 15.x | ERP/CRM | ERP ครบ — Manufacturing, Accounting, HR, CRM, Education | Python + MariaDB + Redis | ⭐3 | ⭐3 | 😊3 | 🛠🛠🛠🛠 | 2 | 4 GB | 20 GB | ✅ |
| <img src="https://raw.githubusercontent.com/invoiceninja/invoiceninja/v5-stable/public/images/invoiceninja-black-logo.png" width="28"> | **Invoice Ninja** 5.x | Business | ออกใบแจ้งหนี้, จัดการลูกค้า, รับชำระเงินออนไลน์ — ฟรีแลนซ์/SME | PHP + MySQL + Nginx | ⭐3 | ⭐3 | 😊4 | 🛠🛠 | 1 | 1 GB | 10 GB | ✅ |
| <img src="https://raw.githubusercontent.com/nextcloud/server/master/core/img/logo/logo.svg" width="28"> | **Nextcloud** 30.x | File Sharing | File sharing + Calendar + Contacts + Talk — แทน Google Workspace | PHP + PostgreSQL + Redis | ⭐5 | ⭐4 | 😊4 | 🛠🛠🛠 | 2 | 2 GB | 20 GB | ✅ |
| <img src="https://download.seafile.com/img/favicon.ico" width="28"> | **Seafile** 12.x | File Sharing | File sync & share — เร็วกว่า Nextcloud, client ทุก platform | Python + MySQL + Memcached | ⭐3 | ⭐3 | 😊4 | 🛠🛠🛠 | 1 | 2 GB | 20 GB | ✅ |
| <img src="https://httpd.apache.org/images/apache.gif" width="28"> | **LAMP Stack** | Web Stack | Apache + MySQL + PHP/Python/Perl — web hosting พื้นฐาน | Apache + MySQL + PHP | ⭐5 | ⭐5 | 😊3 | 🛠🛠 | 1 | 1 GB | 10 GB | ❌ |
| <img src="https://www.docker.com/wp-content/uploads/2022/03/vertical-logo-monochromatic.png" width="28"> | **Docker Host** | Web Stack | Docker CE + Compose + Portainer — รัน container อะไรก็ได้ | Docker + Portainer | ⭐5 | ⭐4 | 😊3 | 🛠 | 1 | 2 GB | 15 GB | ❌ |
| <img src="https://about.gitlab.com/nuxt-images/ico/favicon.svg" width="28"> | **GitLab CE** 17.x | DevOps | Self-hosted Git + CI/CD + Container Registry + Wiki | Ruby + PostgreSQL + Redis | ⭐5 | ⭐4 | 😊3 | 🛠🛠🛠🛠🛠 | 4 | 4 GB | 30 GB | ✅ |
| <img src="https://raw.githubusercontent.com/go-gitea/gitea/main/assets/logo.svg" width="28"> | **Gitea** 1.x | DevOps | Lightweight Git server — เบากว่า GitLab มาก ใช้ resource น้อย | Go + SQLite/PostgreSQL | ⭐4 | ⭐3 | 😊4 | 🛠🛠 | 1 | 1 GB | 10 GB | ✅ |
| <img src="https://grafana.com/static/assets/img/grafana_logo.svg" width="28"> | **Grafana+Prometheus** | Monitoring | Dashboard + Metrics + Alerting — มาตรฐาน monitoring ยุคใหม่ | Go + Go | ⭐5 | ⭐3 | 😊3 | 🛠🛠🛠 | 2 | 2 GB | 15 GB | ✅ |
| <img src="https://raw.githubusercontent.com/louislam/uptime-kuma/master/public/icon.svg" width="28"> | **Uptime Kuma** 1.x | Monitoring | Uptime monitor เบาๆ — monitor เว็บ/API, แจ้งเตือนผ่าน LINE/Telegram | Node.js + SQLite | ⭐4 | ⭐4 | 😊5 | 🛠 | 1 | 512 MB | 5 GB | ✅ |
| <img src="https://ollama.com/public/ollama.png" width="28"> | **Ollama+Open WebUI** | AI | รัน LLM ในเครื่องตัวเอง — Llama, Mistral, Gemma + Chat UI | Python + Go | ⭐5 | ⭐4 | 😊4 | 🛠🛠 | 2 | 4 GB | 30 GB | ✅ |

| <img src="https://www.postgresql.org/media/img/about/press/elephant.png" width="28"> | **PostgreSQL** 17 | Database | RDBMS ระดับ enterprise — ACID, JSON, Full-text search | C | ⭐5 | ⭐4 | 😊2 | 🛠 | 1 | 1 GB | 10 GB | ✅ |
| <img src="https://moodle.org/theme/moodleorg/pix/moodle_logo_TM.svg" width="28"> | **Moodle** 4.6 | Education | LMS #1 โลก — มหา'ลัย/โรงเรียนไทยใช้เยอะ | PHP + PostgreSQL/MySQL | ⭐5 | ⭐5 | 😊3 | 🛠🛠🛠🛠 | 2 | 2 GB | 15 GB | ✅ |
| <img src="https://mattermost.com/wp-content/uploads/2022/02/logo-mattermost.svg" width="28"> | **Mattermost** 10.x | Communication | Chat แบบ Slack — self-hosted, integrations + bots | Go + PostgreSQL + Redis | ⭐4 | ⭐3 | 😊4 | 🛠🛠🛠 | 1 | 2 GB | 15 GB | ✅ |
| <img src="https://raw.githubusercontent.com/discourse/discourse/main/public/images/discourse-logo-sketch.png" width="28"> | **Discourse** 3.x | Communication | Forum สมัยใหม่ — ใช้โดยชุมชน dev ทั่วโลก (Python, Rust, Golang) | Ruby + PostgreSQL + Redis | ⭐4 | ⭐3 | 😊5 | 🛠🛠🛠 | 2 | 2 GB | 15 GB | ✅ |

---

## ความหมายของ rating

| Column | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| 🌏 Global | น้อย (<100K) | — | ปานกลาง (1M) | — | ทั่วโลก (100M+) |
| 🇹🇭 ไทย | ไม่มี demand | — | มีบ้าง | — | demand สูงมาก |
| 😊 ใช้ง่าย | ต้อง setup เยอะ | — | พอใช้ได้ | — | login ใช้เลย |
| 🛠 สร้างยาก | ชั่วโมงเดียว | — | ครึ่งวัน | — | 2+ วัน |

---

## Build Priority (แนะนำให้ทำก่อน)

| Priority | App | เหตุผล |
|---|---|---|
| 🔥🔥🔥 | **WordPress** | Demand สูงสุดในไทย — สร้าง 1 ครั้งใช้ซ้ำได้ยาว |
| 🔥🔥🔥 | **Nextcloud** | องค์กรไทยต้องการ file sharing ส่วนตัว |
| 🔥🔥🔥 | **Odoo** | ERP ยอดฮิต SME ไทย — recurring revenue |
| 🔥🔥 | **Docker Host** | General purpose — รันอะไรก็ได้ ง่ายสุด |
| 🔥🔥 | **Moodle** | E-Learning — มหา'ลัย/โรงเรียน demand แน่นอน |
| 🔥🔥 | **GitLab CE** | Dev team ทุกที่ต้องมี |
| 🔥🔥 | **Uptime Kuma** | เบามาก ใช้เอง + ลูกค้าต้องการ |
| 🔥 | **Grafana+Prometheus** | Monitoring พื้นฐานสำหรับทุก project |
| 🔥 | **Ollama+Open WebUI** | AI trend — ดึงดูดลูกค้า new tech |
| 🔥 | **Ghost** | Blog เบาๆ ง่าย — คู่แข่ง Medium/Substack |
| — | **WooCommerce** | Build บน WordPress — same VM |
| — | **PrestaShop** | E-Commerce standalone — เฉพาะกลุ่ม |
| — | **ERPNext** | หนัก แต่ครบ — องค์กรใหญ่ |
| — | **Invoice Ninja** | เฉพาะกลุ่ม freelance |
| — | **LAMP Stack** | พื้นฐาน — dev ตั้งเองได้ |
| — | **Seafile** | ซ้อนกับ Nextcloud |
| — | **Gitea** | ซ้อนกับ GitLab — เล็กกว่า |
| — | **Mattermost** | องค์กรมีอยู่แล้ว (Slack/Teams) |
| — | **Discourse** | Forum — ชุมชนเท่านั้น |
| — | **PostgreSQL** | Dev ตั้งเองได้ |


---

## วิธี Build

ทุก app image ใช้ framework กลางจาก [`AI-PIPELINE.md`](../docs/AI-PIPELINE.md) แล้วอ่าน checklist ของแต่ละ app เช่น [`wordpress/wordpress.md`](apps/wordpress/wordpress.md):

```text
Phase 0: Ubuntu guest image ตาม guide ของ app นั้น
Phase A: SSH → apt install docker-ce + compose plugin
Phase 1: วาง docker-compose.yml + bootstrap.sh + systemd service
Phase 2: Pull images ล่วงหน้า (docker compose pull)
Phase 3: ทดสอบ bootstrap → cleanup .env/credentials → poweroff → capture
```

### Docker Compose ทั่วไป

```yaml
services:
  app:      # application (PHP-FPM / Node.js / Python)
  db:       # database (MySQL / PostgreSQL)
  proxy:    # reverse proxy (Nginx / Caddy / Traefik)

volumes:
  app_data:
  db_data:
```

บาง app อาจมี service/profile เพิ่ม เช่น WordPress มี optional `nginx-https` profile ให้ยึดไฟล์ app นั้นเป็น source of truth

---

## License

| App | License | หมายเหตุ |
|---|---|---|
| WordPress, Ghost, WooCommerce | GPLv2/MIT | ✅ ฟรีทั้งหมด |
| PrestaShop, Odoo | OSL-3.0 / LGPL-3.0 | ✅ Community edition ฟรี |
| ERPNext, Nextcloud, Seafile | GPLv3 / AGPLv3 | ✅ ฟรีทั้งหมด |
| GitLab CE, Gitea | MIT | ✅ CE ฟรี — EE จ่ายเงิน |
| Grafana, Prometheus, Uptime Kuma | AGPLv3 / MIT | ✅ ฟรีทั้งหมด |
| Ollama, PostgreSQL, Moodle | MIT / GPLv3 | ✅ ฟรีทั้งหมด |
| Mattermost, Discourse | MIT / GPLv2 | ✅ Community edition ฟรี |
| Docker CE, Portainer | Apache-2.0 / Zlib | ✅ ฟรีทั้งหมด |

> ทุก app ใน catalog เป็น open source — ใช้เชิงพาณิชย์ได้ฟรี ไม่มีค่า license
