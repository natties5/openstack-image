# Application Image Catalog

> Ubuntu 26.04-based ready-to-use application images for OpenStack
> **Build Pattern:** Docker Compose app stack + systemd bootstrap + pre-pull images -> QCOW2 -> Glance

**Last upstream check:** 2026-06-15

---

## Column Rules

Catalog นี้ใช้ข้อมูลที่ตรวจได้จริงเท่านั้น ไม่ใช้คะแนนความนิยม/ความง่ายแบบเดาเอง

| Column | ความหมาย |
|---|---|
| `Repo Status` | สถานะ source/guide ใน repo ตอนนี้ |
| `Image Target` | version/stack ที่ guide หรือ source ใน repo ตั้งใจ build จริง |
| `Upstream Signal` | version ล่าสุดหรือ signal ล่าสุดที่ตรวจจาก upstream วันนี้ ยังไม่ได้แปลว่า image build แล้ว |
| `Minimum Size` | baseline สำหรับ VM เล็กสุดที่ควรเริ่มทดสอบ ไม่ใช่ sizing สำหรับ production traffic |
| `Next Action` | สิ่งถัดไปที่ต้องทำเพื่อให้ build/rebuild ได้จริง |

---

## Current Repo Images

| App | Category | Repo Status | Repo Folder | Image Target | Upstream Signal | Stack | Minimum Size | Next Action |
|---|---|---|---|---|---|---|---|---|
| **WordPress** | CMS / Blog | built: standalone | `build/apps/wordpress/` | `wordpress:php8.3-fpm` + MariaDB + Nginx | WordPress 7.0 latest; 6.9.4 security branch | PHP-FPM + MariaDB + Nginx | 1 vCPU / 1 GB / 10 GB | Decide target line: latest 7.0 vs 6.9 security branch, then rebuild if needed |
| **WooCommerce** | E-Commerce | พร้อม build | `build/apps/woocommerce/` | WordPress + WooCommerce bootstrap | WooCommerce 10.8.1 | PHP-FPM + MariaDB + Nginx + WP-CLI | 2 vCPU / 2 GB / 15 GB | Build ecommerce image แยกจาก WordPress |
| **Nextcloud** | Collaboration / File Sharing | built เดิม แต่ source target เก่า | `build/apps/nextcloud/` | source ใช้ `nextcloud:30.0-apache` | Nextcloud 34.0.0 | Nextcloud Apache + PostgreSQL + Redis + Nginx | 2 vCPU / 2 GB / 20 GB | Sync source เป็น target ใหม่ก่อน rebuild |
| **Odoo** | Business / ERP / CRM | พร้อม build | `build/apps/odoo/` | `odoo:18.0` + PostgreSQL + Nginx | Odoo 19 stable/recommended ต้อง verify จาก official docs ก่อนเปลี่ยน target | Python/Odoo + PostgreSQL + Nginx | 2 vCPU / 2-4 GB / 20 GB | ใช้ Odoo 18 guide ต่อ หรือทำ review ก่อน upgrade เป็น 19 |
| **Docker Platform** | DevOps / Platform | พร้อม build | `build/apps/docker-platform/` | Docker CE + Portainer + Nginx Proxy Manager | Portainer 2.39.3 LTS; Nginx Proxy Manager 2.15.1 | Docker CE + Portainer + NPM | 1 vCPU / 2 GB / 15 GB | Verify image tags/pins แล้ว build |
| **Grafana+Prometheus** | Monitoring / Analytics | built: standalone | `build/apps/grafana-prometheus/` | guide/source เดิม | Grafana 13.0.2; Prometheus 3.12.0 | Grafana + Prometheus + Alertmanager + Exporters | 2 vCPU / 2 GB / 15 GB | Capture/Glance ตาม admin workflow |
| **n8n** | Automation / AI no-GPU | รอเติม source | `build/apps/n8n/` | skeleton guide only | n8n 2.25.7 | Node.js + PostgreSQL + Nginx | 1-2 vCPU / 2 GB / 10 GB | สร้าง source files ให้ครบก่อน build |

---

## Recommended Next Builds

> เรียงจากความพร้อมของ repo + value ของ image สำเร็จรูป + stack ที่ควรคุมได้ ไม่ใช่คะแนน popularity

| Order | App | Category | Why Now | Required Work |
|---|---|---|---|---|
| 1 | **n8n** | Automation / AI no-GPU | มี guide skeleton แล้วและ automation/AI workflow ใช้ demo ได้ดี | เติม `docker-compose.yml`, nginx config, bootstrap, service, README, MOTD |
| 2 | **Vaultwarden** | Security / Password Manager | stack เบา, value ชัด, bootstrap secret ต่อ VM ทำได้ตรงไปตรงมา | ทำ community review -> build guide/source |
| 3 | **AnythingLLM** | AI / RAG no-GPU | เหมาะเป็น AI image แบบไม่ต้องมี GPU ถ้าใช้ external LLM API | ทำ community review -> build guide/source |
| 4 | **Nextcloud rebuild** | Collaboration / File Sharing | มี image เดิม แต่ source target เก่าและ upstream ขยับไกล | ตัดสิน target แล้ว sync source/rebuild |
| 5 | **WooCommerce build** | E-Commerce | source พร้อมและเป็น variant ที่ชัดจาก WordPress | build + verify standalone |
| 6 | **Umami** | Monitoring / Analytics | analytics image เบา ใช้ PostgreSQL และเหมาะกับ self-host | ทำ community review -> build guide/source |
| 7 | **Chatwoot CE** | Support / Helpdesk | business value สูง แต่ stack หนักกว่า apps เบา | ทำ review เรื่อง sizing, email, storage, bootstrap |
| 8 | **NocoDB** | No-code DB | Airtable replacement ใช้กับทีม non-tech ได้ | ทำ review เรื่อง CE/free features และ database mode |

---

## Catalog By Category

### CMS / E-Commerce

| App | Purpose | Repo Status | Image Target | Upstream Signal | Stack | Minimum Size | Next Action |
|---|---|---|---|---|---|---|---|
| **WordPress** | CMS/blog/website | built: standalone | `wordpress:php8.3-fpm` | WordPress 7.0 latest; 6.9.4 security branch | PHP-FPM + MariaDB + Nginx | 1 vCPU / 1 GB / 10 GB | Decide target line then rebuild if needed |
| **WooCommerce** | Online store image | พร้อม build | WordPress + WooCommerce bootstrap | WooCommerce 10.8.1 | PHP-FPM + MariaDB + Nginx + WP-CLI | 2 vCPU / 2 GB / 15 GB | Build standalone ecommerce image |
| **Ghost** | Blog/newsletter | wishlist | ยังไม่มี source | ต้อง verify | Node.js + SQLite/MySQL | 1 vCPU / 1 GB / 10 GB | Research later |
| **PrestaShop** | Standalone online store | wishlist | ยังไม่มี source | ต้อง verify | PHP + MySQL/MariaDB + Nginx | 2 vCPU / 2 GB / 15 GB | Research later |

### Collaboration / File Sharing

| App | Purpose | Repo Status | Image Target | Upstream Signal | Stack | Minimum Size | Next Action |
|---|---|---|---|---|---|---|---|
| **Nextcloud** | File sharing + collaboration | built เดิม แต่ source target เก่า | `nextcloud:30.0-apache` in source | Nextcloud 34.0.0 | Nextcloud Apache + PostgreSQL + Redis + Nginx | 2 vCPU / 2 GB / 20 GB | Sync source target before rebuild |
| **Seafile** | File sync/share ที่เบากว่า Nextcloud | wishlist | ยังไม่มี source | ต้อง verify | Python + MySQL + Memcached | 1 vCPU / 2 GB / 20 GB | Research later |

### Automation / AI No-GPU

| App | Purpose | Repo Status | Image Target | Upstream Signal | Stack | Minimum Size | Next Action |
|---|---|---|---|---|---|---|---|
| **n8n** | Workflow automation + AI nodes | รอเติม source | skeleton guide only | n8n 2.25.7 | Node.js + PostgreSQL + Nginx | 1-2 vCPU / 2 GB / 10 GB | เติม source files |
| **AnythingLLM** | RAG / document Q&A / workspaces | candidate | ยังไม่มี source | AnythingLLM 1.14.0 | Node.js + SQLite/LanceDB; optional external LLM/Ollama | 2 vCPU / 2-4 GB / 10 GB | ทำ review + source |
| **Flowise** | Visual AI agent/RAG/chatflow builder | candidate | ยังไม่มี source | Flowise 3.1.2 | Node.js; optional DB/Redis by deployment | 1-2 vCPU / 1-2 GB / 10 GB | ทำหลัง AnythingLLM |
| **Dify CE** | Production AI app/RAG/workflow platform | candidate later | ยังไม่มี source | Dify 1.14.2 | Python + Node.js + PostgreSQL + Redis + Vector DB | 2+ vCPU / 4-8 GB / 20 GB | Review stack complexity ก่อนทำ |
| **Open WebUI + Ollama** | Local LLM web UI | wishlist | ยังไม่มี source | ต้อง verify | Open WebUI + Ollama | 4 vCPU / 8-16 GB / 30 GB for useful local model | Research license/performance ก่อน |
| **LiteLLM Proxy** | AI gateway/proxy | wishlist | ยังไม่มี source | ต้อง verify | Python + PostgreSQL/Redis optional | 1-2 vCPU / 1-2 GB / 10 GB | Research later |
| **Onyx** | Enterprise search/RAG | research later | ยังไม่มี source | ต้อง verify | Multi-service stack | 4+ vCPU / 8+ GB / 30 GB | Research later |

### Security / Password Manager

| App | Purpose | Repo Status | Image Target | Upstream Signal | Stack | Minimum Size | Next Action |
|---|---|---|---|---|---|---|---|
| **Vaultwarden** | Bitwarden-compatible password manager | candidate | ยังไม่มี source | Vaultwarden 1.36.0 | Rust + SQLite/PostgreSQL | 1 vCPU / 512 MB-1 GB / 5 GB | ทำ review + source |

### Business / ERP / CRM

| App | Purpose | Repo Status | Image Target | Upstream Signal | Stack | Minimum Size | Next Action |
|---|---|---|---|---|---|---|---|
| **Odoo** | ERP/CRM/Inventory/Website | พร้อม build | `odoo:18.0` | Odoo 19 stable/recommended ต้อง verify official docs | Python/Odoo + PostgreSQL + Nginx | 2 vCPU / 2-4 GB / 20 GB | Optional Odoo 19 research/upgrade |
| **ERPNext** | ERPNext/Frappe suite | wishlist | ยังไม่มี source | ต้อง verify | Python + MariaDB + Redis | 2 vCPU / 4 GB / 20 GB | Research later |
| **Invoice Ninja** | Invoicing + clients + payments | wishlist | ยังไม่มี source | ต้อง verify | PHP + MySQL + Nginx | 1 vCPU / 1 GB / 10 GB | Research later |
| **Twenty** | CRM | wishlist | ยังไม่มี source | ต้อง verify | Node.js + PostgreSQL | 1-2 vCPU / 2 GB / 10 GB | Research later |

### DevOps / Platform

| App | Purpose | Repo Status | Image Target | Upstream Signal | Stack | Minimum Size | Next Action |
|---|---|---|---|---|---|---|---|
| **Docker Platform** | Docker CE + management UI + proxy UI | พร้อม build | Docker CE + Portainer + NPM | Portainer 2.39.3 LTS; NPM 2.15.1 | Docker CE + Portainer + Nginx Proxy Manager | 1 vCPU / 2 GB / 15 GB | Verify pins/current tags |
| **Coolify** | Self-hosted PaaS | candidate | ยังไม่มี source | Coolify 4.1.2 | Docker + Laravel + PostgreSQL | 2 vCPU / 2-4 GB / 20 GB | Review Docker host security ก่อนทำ |
| **Gitea** | Lightweight Git server | wishlist | ยังไม่มี source | ต้อง verify | Go + SQLite/PostgreSQL | 1 vCPU / 1 GB / 10 GB | ทำก่อน GitLab ถ้าต้องการ Git image |
| **GitLab CE** | Git + CI/CD + registry | low priority / heavy | ยังไม่มี source | ต้อง verify | Ruby + PostgreSQL + Redis | 4 vCPU / 4 GB+ / 30 GB | ทำเฉพาะเมื่อต้องการ full CI/CD image |

### Monitoring / Analytics

| App | Purpose | Repo Status | Image Target | Upstream Signal | Stack | Minimum Size | Next Action |
|---|---|---|---|---|---|---|---|
| **Grafana+Prometheus** | VM / website / service monitoring | built: standalone | guide/source เดิม | Grafana 13.0.2; Prometheus 3.12.0 | Grafana + Prometheus + Alertmanager + Exporters | 2 vCPU / 2 GB / 15 GB | Capture/Glance ตาม admin workflow |
| **Umami** | Privacy-friendly web analytics | candidate | ยังไม่มี source | Umami 3.1.0 | Node.js + PostgreSQL | 1 vCPU / 1-2 GB / 10 GB | ทำ review + source |
| **Uptime Kuma** | Uptime monitoring + alerts | wishlist | ยังไม่มี source | ต้อง verify | Node.js + SQLite | 1 vCPU / 512 MB / 5 GB | Research later |
| **Plausible** | Web analytics | wishlist | ยังไม่มี source | ต้อง verify | Elixir + PostgreSQL + ClickHouse | 2 vCPU / 2-4 GB / 20 GB | Research later |

### Support / Helpdesk

| App | Purpose | Repo Status | Image Target | Upstream Signal | Stack | Minimum Size | Next Action |
|---|---|---|---|---|---|---|---|
| **Chatwoot CE** | Live chat + helpdesk | candidate | ยังไม่มี source | Chatwoot 4.14.2 | Rails + PostgreSQL + Redis | 2-4 vCPU / 4 GB / 20 GB | Review email/storage/bootstrap requirements |

### No-Code / Project Management

| App | Purpose | Repo Status | Image Target | Upstream Signal | Stack | Minimum Size | Next Action |
|---|---|---|---|---|---|---|---|
| **NocoDB** | Airtable-like UI on database | candidate | ยังไม่มี source | NocoDB 2026.06.0 | Node.js + PostgreSQL/MySQL/SQLite | 1-2 vCPU / 1-2 GB / 10 GB | Review CE/free feature split |
| **Plane CE** | Project management + docs/wiki | candidate later | ยังไม่มี source | Plane 1.3.1 | Python + Node.js + PostgreSQL + Redis | 2 vCPU / 4 GB / 20 GB | Review official compose/bootstrap |

### Communication / Community

| App | Purpose | Repo Status | Image Target | Upstream Signal | Stack | Minimum Size | Next Action |
|---|---|---|---|---|---|---|---|
| **Mattermost** | Team chat / Slack alternative | wishlist | ยังไม่มี source | ต้อง verify | Go + PostgreSQL | 1-2 vCPU / 2 GB / 15 GB | Research later |
| **Discourse** | Forum/community | wishlist | ยังไม่มี source | ต้อง verify | Ruby + PostgreSQL + Redis | 2 vCPU / 2 GB / 15 GB | Research later |

### Database / Base Stack

| App | Purpose | Repo Status | Image Target | Upstream Signal | Stack | Minimum Size | Next Action |
|---|---|---|---|---|---|---|---|
| **PostgreSQL** | Standalone RDBMS image | low priority | ยังไม่มี source | ต้อง verify | PostgreSQL | 1 vCPU / 1 GB / 10 GB | ทำเมื่อมี use case ชัดกว่า app image |
| **LAMP Stack** | Apache + MySQL + PHP base stack | low priority | ยังไม่มี source | ต้อง verify | Apache + MySQL/MariaDB + PHP | 1 vCPU / 1 GB / 10 GB | Low value เพราะ dev ตั้งเองได้ง่าย |

### Education

| App | Purpose | Repo Status | Image Target | Upstream Signal | Stack | Minimum Size | Next Action |
|---|---|---|---|---|---|---|---|
| **Moodle** | LMS สำหรับโรงเรียน/มหาวิทยาลัย | wishlist | ยังไม่มี source | ต้อง verify | PHP + PostgreSQL/MySQL | 2 vCPU / 2 GB / 15 GB | Research later |

---

## AI / RAG No-GPU Notes

| App | Recommendation | No-GPU Reality | License Notes |
|---|---|---|---|
| **AnythingLLM** | ทำก่อน | ตัว app ไม่ต้องใช้ GPU; ใช้ external LLM API ได้ทันที หรือ Ollama CPU ได้แต่ช้า | MIT |
| **Flowise** | ทำหลัง AnythingLLM | ตัว builder เบา; local inference ต้องมี Ollama/LLM backend แยก | Apache-2.0 core; enterprise modules แยก |
| **Dify CE** | ทำเมื่ออยากได้ production AI app platform | ใช้ external API ได้โดยไม่ใช้ GPU; stack ต้องการ RAM มากกว่า | Dify Open Source License based on Apache-2.0 with conditions |
| **Open WebUI + Ollama** | Wishlist | CPU-only ได้กับ 1B-4B model, 7B ต้อง 8-16 GB RAM และช้า | custom/non-OSI license ต้อง review |
| **LiteLLM Proxy** | Wishlist/devops | ไม่ใช้ GPU เพราะเป็น AI gateway/proxy | OSS free; enterprise features แยก |
| **Onyx** | Research later | ใช้ external/self-host LLM ได้ แต่ stack/operations หนักกว่า AnythingLLM | CE free; verify license before build |

---

## วิธี Build

ทุก app image ใช้ framework กลางจาก [`AI-PIPELINE.md`](../docs/AI-PIPELINE.md) แล้วอ่าน checklist ของแต่ละ app เช่น [`wordpress/wordpress.md`](apps/wordpress/wordpress.md):

```text
Phase 0: Ubuntu guest image ตาม guide ของ app นั้น
Phase A: SSH -> apt install docker-ce + compose plugin
Phase 1: วาง docker-compose.yml + bootstrap.sh + systemd service
Phase 2: Pull images ล่วงหน้า (docker compose pull)
Phase 3: ทดสอบ bootstrap -> cleanup .env/credentials -> poweroff -> capture
```

### Docker Compose ทั่วไป

```yaml
services:
  app:      # application (PHP-FPM / Node.js / Python / Go)
  db:       # database (MySQL / PostgreSQL / SQLite volume)
  proxy:    # reverse proxy (Nginx / Caddy / Traefik)

volumes:
  app_data:
  db_data:
```

บาง app อาจมี service/profile เพิ่ม เช่น WordPress มี optional `nginx-https` profile ให้ยึดไฟล์ app นั้นเป็น source of truth

---

## License Notes

| App | License | หมายเหตุ |
|---|---|---|
| WordPress, Ghost, WooCommerce | GPLv2/MIT | ฟรีทั้งหมด |
| PrestaShop, Odoo | OSL-3.0 / LGPL-3.0 | Community edition ฟรี |
| ERPNext, Nextcloud, Seafile | GPLv3 / AGPLv3 | ฟรีทั้งหมด |
| GitLab CE, Gitea | MIT | CE ฟรี; EE จ่ายเงิน |
| Grafana, Prometheus, Uptime Kuma | AGPLv3 / Apache-2.0 / MIT | ฟรีทั้งหมด |
| PostgreSQL, Moodle | PostgreSQL License / GPLv3 | ฟรีทั้งหมด |
| Mattermost, Discourse | MIT / GPLv2 | Community edition ฟรี |
| Docker CE, Portainer | Apache-2.0 / Zlib | ฟรีทั้งหมด |
| n8n | Sustainable Use License | self-host free แต่ไม่ใช่ OSI open source |
| Vaultwarden, Plane | GPL-3.0 / AGPL-3.0 | ฟรี self-host; ต้องระวัง AGPL เมื่อแก้ source |
| AnythingLLM, Umami, Chatwoot CE, Coolify | MIT / Apache-2.0 | ฟรี self-host |
| Flowise | Apache-2.0 core | enterprise modules/license แยก |
| Dify CE | Dify Open Source License | based on Apache-2.0 with additional conditions |
| Open WebUI | Custom license | ต้อง review เงื่อนไขก่อนใช้เชิงพาณิชย์/large team |

> Catalog นี้เลือกเฉพาะ app ที่ใช้ฟรี/self-host ได้พอสำหรับ image สำเร็จรูป แต่ license บางตัวไม่ใช่ OSI open source 100% ต้อง review ก่อนนำไปขายเป็น managed service
