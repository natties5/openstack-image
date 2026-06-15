# Application Image Catalog

> Ubuntu 26.04-based ready-to-use application images for OpenStack
> **Build Pattern:** Docker Compose app stack + systemd bootstrap + pre-pull images -> QCOW2 -> Glance

**Last upstream check:** 2026-06-14

---

## App Status

> `Image Target` = version/stack ที่ guide หรือ source ใน repo ตั้งใจ build จริง
> `Latest Upstream` = version ล่าสุดที่ตรวจจาก upstream วันนี้ ยังไม่ได้แปลว่า image build แล้ว

| App | Folder | Image Target | Latest Upstream | Tech Stack | Repo Status | Action |
|---|---|---|---|---|---|---|
| **WordPress** | `build/apps/wordpress/` | 6.7-era guide | 6.9.4 security release | PHP + MariaDB + Nginx (PHP-FPM) | ✅ built: standalone | Rebuild target latest หลัง review pins |
| **Nextcloud** | `build/apps/nextcloud/` | built `production-korry-gate2`; guide มี rebuild baseline | 34.0.0 | PHP + PostgreSQL + Redis + Nginx | ⚠️ built เดิม แต่รอ source sync/rebuild | ปรับ source ให้ตรง baseline แล้ว rebuild |
| **Odoo** | `build/apps/odoo/` | 18 | 19 stable/recommended | Python + PostgreSQL + Nginx | ✅ พร้อม build | Optional upgrade guide เป็น Odoo 19 |
| **Docker Platform** | `build/apps/docker-platform/` | Docker CE + Portainer + NPM | Docker Engine 29.5.3 | Docker CE + Portainer + Nginx Proxy Manager | ✅ พร้อม build | Verify image pins/current tags |
| **Grafana+Prometheus** | `build/apps/grafana-prometheus/` | guide/source เดิม | Grafana 13.0.2 + Prometheus 3.12.0 | Grafana + Prometheus + Alertmanager + Exporters | ✅ พร้อม build | Verify image pins/current tags |
| **n8n** | `build/apps/n8n/` | skeleton guide | stable 2.25.7 / beta 2.26.3 | Node.js + PostgreSQL + Nginx | ❌ รอเติม source | ทำ source files ให้ครบก่อน build |

---

## Candidate Images — ควรเพิ่มต่อ

> เกณฑ์เลือก: ฟรีพอใช้งาน, self-host ได้, เหมาะเป็น image สำเร็จรูป, resource ไม่สูงเกิน, bootstrap สร้าง secret ต่อ VM ได้ชัดเจน

| Priority | App | Category | Latest / Current Signal | Why | Suggested Size | Build Fit |
|---|---|---|---|---|---|---|
| 🔥🔥🔥 | **Vaultwarden** | Password Manager | 1.36.0 | คุณค่าสูงมาก, เบา, ใช้ official Bitwarden clients ได้, replacement 1Password/Bitwarden paid | 1 vCPU / 512 MB-1 GB / 5 GB | ดีมาก |
| 🔥🔥🔥 | **AnythingLLM** | AI / RAG no-GPU | v1.13.x docs signal | Document Q&A/RAG ใช้ง่าย, MIT, ใช้ external API หรือ Ollama CPU ได้ | 2 vCPU / 2-4 GB / 10 GB | ดีมาก |
| 🔥🔥 | **Umami** | Analytics | 3.1.0 | Google Analytics alternative, MIT, เบากว่า Plausible, ใช้ PostgreSQL | 1-2 vCPU / 1-2 GB / 10 GB | ดี |
| 🔥🔥 | **Chatwoot CE** | Helpdesk / Live Chat | 4.14.2 CE | replacement Intercom/Zendesk, SME ใช้จริง, CE MIT | 2-4 vCPU / 4 GB / 20 GB | ดีแต่ stack หนัก |
| 🔥🔥 | **NocoDB** | No-code DB / Airtable | ต้อง verify release | ใช้ง่ายกับ non-tech team, spreadsheet UI บน DB | 1-2 vCPU / 1-2 GB / 10 GB | ดี |
| 🔥🔥 | **Coolify** | Self-hosted PaaS | 4.1.2 | dev/agency deploy app/database/service ผ่าน UI, 280+ one-click services | 2 vCPU / 2-4 GB / 20 GB | ดีแต่ต้องระวัง Docker host security |
| 🔥 | **Flowise** | AI Agent Builder | ต้อง verify release | visual AI/RAG/agent builder เบา, no GPU ถ้าใช้ external API | 1-2 vCPU / 1-2 GB / 10 GB | ดีสำหรับ prototype/internal |
| 🔥 | **Dify CE** | AI App Platform | 1.14.2 | production AI workflow/RAG platform ครบกว่า Flowise | 2+ vCPU / 4-8 GB / 20 GB | ดีแต่หลาย services |
| 🔥 | **Plane CE** | Project Management | 1.3.1 | Jira/Linear alternative, project + wiki, AGPL CE | 2 vCPU / 4 GB / 20 GB | ดีแต่ stack หนัก |

### AI / RAG / Automation — No GPU Policy

| App | Recommendation | No-GPU Reality | License Notes |
|---|---|---|---|
| **AnythingLLM** | ทำก่อน | ตัว app ไม่ต้องใช้ GPU; ใช้ external LLM API ได้ทันที หรือ Ollama CPU ได้แต่ช้า | MIT |
| **Flowise** | ทำหลัง AnythingLLM | ตัว builder เบา; local inference ต้องมี Ollama/LLM backend แยก | Apache-2.0 core; enterprise modules แยก |
| **Dify CE** | ทำเมื่ออยากได้ production AI app platform | ใช้ external API ได้โดยไม่ใช้ GPU; stack ต้องการ RAM มากกว่า | Dify Open Source License based on Apache-2.0 with conditions |
| **Open WebUI + Ollama** | Wishlist | CPU-only ได้กับ 1B-4B model, 7B ต้อง 8-16 GB RAM และช้า | custom/non-OSI license ต้อง review |
| **LiteLLM Proxy** | Wishlist/devops | ไม่ใช้ GPU เพราะเป็น AI gateway/proxy | OSS free; enterprise features แยก |
| **Onyx** | Research later | ใช้ external/self-host LLM ได้ แต่ stack/operations หนักกว่า AnythingLLM | CE free; verify license before build |

---

## Planned / Wishlist

> Apps ที่สนใจทำในอนาคต — เรียงตาม value สำหรับ OpenStack app image ไม่ใช่แค่ความนิยม upstream

### Category Priority

| # | หมวด | Apps | เพราะ |
|---|---|---|---|
| 1 | **Automation / AI no-GPU** | n8n, AnythingLLM, Flowise, Dify | demand ใหม่สูง, demo value ดี, ไม่ต้องมี GPU ถ้าใช้ API provider |
| 2 | **SME SaaS Replacement** | Vaultwarden, Chatwoot, NocoDB, Plane, Cal.com | ลด SaaS per-seat cost ชัดเจน |
| 3 | **CMS / Blog / E-Commerce** | WordPress, WooCommerce, Ghost, PrestaShop | WordPress ยัง demand สูงสุด; WooCommerce เป็น variant ของ WordPress |
| 4 | **File Sharing / Collab** | Nextcloud, Seafile | องค์กรต้องการ data sovereignty |
| 5 | **ERP / CRM / Business** | Odoo, ERPNext, Invoice Ninja, Twenty | SME ไทยใช้จริง แต่บาง stack หนัก |
| 6 | **Dev / DevOps** | Docker Platform, Coolify, Gitea, GitLab CE | Coolify/Gitea คุ้มกว่า GitLab สำหรับ image เบา |
| 7 | **Monitoring / Analytics** | Grafana+Prometheus, Uptime Kuma, Umami, Plausible | monitoring + web analytics ใช้ได้ทุกลูกค้า |
| 8 | **Communication / Community** | Mattermost, Discourse | ใช้เฉพาะบางองค์กร/ชุมชน |
| 9 | **Database / Base Stack** | PostgreSQL, LAMP | Dev ตั้งเองได้ จึง priority ต่ำกว่า app สำเร็จรูป |
| 10 | **Education** | Moodle | demand เฉพาะโรงเรียน/มหาวิทยาลัย |

---

## Full Catalog — Ubuntu 26.04 Application Images

| Icon | App | Category | Description | Tech Stack | 🌏 | 🇹🇭 | 😊 | 🛠 | vCPU | RAM | Disk | Docker | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| <img src="https://s.w.org/style/images/about/WordPress-logotype-alternative.png" width="28"> | **WordPress** 6.9.x | CMS | CMS #1 โลก; WooCommerce variant ได้ | PHP + MariaDB + Nginx | ⭐5 | ⭐5 | 😊5 | 🛠🛠 | 1 | 1 GB | 10 GB | ✅ | built target เก่าต้อง rebuild |
| <img src="https://raw.githubusercontent.com/woocommerce/woocommerce/trunk/plugins/woocommerce/assets/images/woo-logo.svg" width="28"> | **WooCommerce** | E-Commerce | WordPress plugin สำหรับร้านค้าออนไลน์ | PHP + MariaDB | ⭐5 | ⭐5 | 😊4 | 🛠🛠🛠 | 2 | 2 GB | 15 GB | ✅ | variant ของ WordPress |
| <img src="https://raw.githubusercontent.com/nextcloud/server/master/core/img/logo/logo.svg" width="28"> | **Nextcloud** 34.x | File Sharing | File sharing + Calendar + Contacts + Talk | PHP + PostgreSQL + Redis | ⭐5 | ⭐4 | 😊4 | 🛠🛠🛠 | 2 | 2 GB | 20 GB | ✅ | built เดิม รอ rebuild latest |
| <img src="https://odoocdn.com/openerp_website/static/src/img/assets/png/odoo_logo.png" width="28"> | **Odoo** 19 | ERP/CRM | ERP/CRM/Inventory/Website/E-Commerce | Python + PostgreSQL + Nginx | ⭐4 | ⭐5 | 😊4 | 🛠🛠🛠🛠 | 2 | 2-4 GB | 20 GB | ✅ | guide target 18 |
| <img src="https://raw.githubusercontent.com/n8n-io/n8n/master/assets/n8n-logo.png" width="28"> | **n8n** 2.25.x stable | Automation | Workflow automation + AI nodes; Zapier/Make replacement | Node.js + PostgreSQL | ⭐5 | ⭐4 | 😊4 | 🛠🛠 | 1-2 | 2 GB | 10 GB | ✅ | รอเติม source |
| <img src="https://raw.githubusercontent.com/Mintplex-Labs/anything-llm/master/frontend/public/favicon.png" width="28"> | **AnythingLLM** 1.13.x | AI/RAG | Chat with documents, workspaces, Ollama/API provider | Node.js + SQLite/LanceDB | ⭐4 | ⭐4 | 😊5 | 🛠🛠 | 2 | 2-4 GB | 10 GB | ✅ | candidate |
| <img src="https://raw.githubusercontent.com/dani-garcia/vaultwarden/main/resources/vaultwarden-icon.svg" width="28"> | **Vaultwarden** 1.36.x | Security | Lightweight Bitwarden-compatible password manager | Rust + SQLite/PostgreSQL | ⭐5 | ⭐4 | 😊5 | 🛠 | 1 | 512 MB | 5 GB | ✅ | candidate |
| <img src="https://raw.githubusercontent.com/umami-software/umami/master/public/icon.svg" width="28"> | **Umami** 3.1.x | Analytics | Privacy-friendly Google Analytics alternative | Node.js + PostgreSQL | ⭐4 | ⭐3 | 😊5 | 🛠🛠 | 1 | 1-2 GB | 10 GB | ✅ | candidate |
| <img src="https://www.chatwoot.com/favicon.ico" width="28"> | **Chatwoot CE** 4.14.x | Support | Live chat + helpdesk; Intercom/Zendesk alternative | Rails + PostgreSQL + Redis | ⭐4 | ⭐4 | 😊4 | 🛠🛠🛠 | 2-4 | 4 GB | 20 GB | ✅ | candidate |
| <img src="https://raw.githubusercontent.com/nocodb/nocodb/develop/packages/nc-gui/assets/img/icons/512x512.png" width="28"> | **NocoDB** | No-code DB | Airtable alternative บน PostgreSQL/MySQL | Node.js + PostgreSQL | ⭐4 | ⭐3 | 😊5 | 🛠🛠 | 1-2 | 1-2 GB | 10 GB | ✅ | research needed |
| <img src="https://coolify.io/favicon.ico" width="28"> | **Coolify** 4.1.x | DevOps/PaaS | Self-hosted Vercel/Heroku/Netlify alternative | Docker + Laravel + PostgreSQL | ⭐5 | ⭐4 | 😊4 | 🛠🛠🛠 | 2 | 2-4 GB | 20 GB | ✅ | candidate |
| <img src="https://raw.githubusercontent.com/FlowiseAI/Flowise/main/images/flowise_logo.png" width="28"> | **Flowise** | AI Builder | Visual AI agent/RAG/chatflow builder | Node.js | ⭐4 | ⭐3 | 😊4 | 🛠🛠 | 1-2 | 1-2 GB | 10 GB | ✅ | candidate |
| <img src="https://raw.githubusercontent.com/langgenius/dify/main/web/public/favicon.ico" width="28"> | **Dify CE** 1.14.x | AI Platform | Production AI app/RAG/workflow platform | Python + Node + PostgreSQL + Redis + Vector DB | ⭐5 | ⭐3 | 😊3 | 🛠🛠🛠🛠 | 2+ | 4-8 GB | 20 GB | ✅ | candidate later |
| <img src="https://raw.githubusercontent.com/makeplane/plane/preview/web/public/favicon/favicon-32x32.png" width="28"> | **Plane CE** 1.3.x | Project Management | Jira/Linear alternative + docs/wiki | Python + Node + PostgreSQL + Redis | ⭐4 | ⭐3 | 😊4 | 🛠🛠🛠 | 2 | 4 GB | 20 GB | ✅ | candidate later |
| <img src="https://www.docker.com/wp-content/uploads/2022/03/vertical-logo-monochromatic.png" width="28"> | **Docker Platform** | Web Stack | Docker CE + Portainer + Nginx Proxy Manager | Docker + Portainer + NPM | ⭐5 | ⭐4 | 😊4 | 🛠🛠 | 1 | 2 GB | 15 GB | ✅ | พร้อม build |
| <img src="https://grafana.com/static/assets/img/grafana_logo.svg" width="28"> | **Grafana+Prometheus** | Monitoring | VM / Website / Service monitoring + dashboards | Go + Go | ⭐5 | ⭐3 | 😊3 | 🛠🛠🛠 | 2 | 2 GB | 15 GB | ✅ | พร้อม build |
| <img src="https://raw.githubusercontent.com/louislam/uptime-kuma/master/public/icon.svg" width="28"> | **Uptime Kuma** 1.x | Monitoring | Uptime monitor เบา, LINE/Telegram alert | Node.js + SQLite | ⭐4 | ⭐4 | 😊5 | 🛠 | 1 | 512 MB | 5 GB | ✅ | wishlist |
| <img src="https://raw.githubusercontent.com/TryGhost/Ghost/main/apps/admin-x-settings/public/ghost-logo.png" width="28"> | **Ghost** 5.x | CMS | Blog/newsletter สมัยใหม่ | Node.js + SQLite/MySQL | ⭐4 | ⭐2 | 😊4 | 🛠🛠 | 1 | 1 GB | 10 GB | ✅ | wishlist |
| <img src="https://www.prestashop.com/sites/default/files/logo/favicon-32x32.png" width="28"> | **PrestaShop** 9.x | E-Commerce | ร้านค้าออนไลน์ standalone | PHP + MySQL + Nginx | ⭐3 | ⭐3 | 😊3 | 🛠🛠🛠 | 2 | 2 GB | 15 GB | ✅ | wishlist |
| <img src="https://erpnext.com/assets/erpnext_logo_dark.svg" width="28"> | **ERPNext** 15.x | ERP/CRM | ERPNext/Frappe suite | Python + MariaDB + Redis | ⭐3 | ⭐3 | 😊3 | 🛠🛠🛠🛠 | 2 | 4 GB | 20 GB | ✅ | wishlist |
| <img src="https://raw.githubusercontent.com/invoiceninja/invoiceninja/v5-stable/public/images/invoiceninja-black-logo.png" width="28"> | **Invoice Ninja** 5.x | Business | Invoicing + clients + payments | PHP + MySQL + Nginx | ⭐3 | ⭐3 | 😊4 | 🛠🛠 | 1 | 1 GB | 10 GB | ✅ | wishlist |
| <img src="https://download.seafile.com/img/favicon.ico" width="28"> | **Seafile** 12.x | File Sharing | File sync/share เบากว่า Nextcloud | Python + MySQL + Memcached | ⭐3 | ⭐3 | 😊4 | 🛠🛠🛠 | 1 | 2 GB | 20 GB | ✅ | wishlist |
| <img src="https://www.postgresql.org/media/img/about/press/elephant.png" width="28"> | **PostgreSQL** 17 | Database | RDBMS enterprise-grade | C | ⭐5 | ⭐4 | 😊2 | 🛠 | 1 | 1 GB | 10 GB | ✅ | low priority |
| <img src="https://moodle.org/theme/moodleorg/pix/moodle_logo_TM.svg" width="28"> | **Moodle** 4.x | Education | LMS สำหรับโรงเรียน/มหาวิทยาลัย | PHP + PostgreSQL/MySQL | ⭐5 | ⭐5 | 😊3 | 🛠🛠🛠🛠 | 2 | 2 GB | 15 GB | ✅ | wishlist |
| <img src="https://mattermost.com/wp-content/uploads/2022/02/logo-mattermost.svg" width="28"> | **Mattermost** 10.x | Communication | Slack alternative | Go + PostgreSQL + Redis | ⭐4 | ⭐3 | 😊4 | 🛠🛠🛠 | 1-2 | 2 GB | 15 GB | ✅ | wishlist |
| <img src="https://raw.githubusercontent.com/discourse/discourse/main/public/images/discourse-logo-sketch.png" width="28"> | **Discourse** 3.x | Communication | Modern forum | Ruby + PostgreSQL + Redis | ⭐4 | ⭐3 | 😊5 | 🛠🛠🛠 | 2 | 2 GB | 15 GB | ✅ | wishlist |
| <img src="https://raw.githubusercontent.com/go-gitea/gitea/main/assets/logo.svg" width="28"> | **Gitea** 1.x | DevOps | Lightweight Git server | Go + SQLite/PostgreSQL | ⭐4 | ⭐3 | 😊4 | 🛠🛠 | 1 | 1 GB | 10 GB | ✅ | wishlist |
| <img src="https://about.gitlab.com/nuxt-images/ico/favicon.svg" width="28"> | **GitLab CE** 17.x+ | DevOps | Git + CI/CD + registry | Ruby + PostgreSQL + Redis | ⭐5 | ⭐4 | 😊3 | 🛠🛠🛠🛠🛠 | 4 | 4 GB+ | 30 GB | ✅ | low priority/heavy |
| <img src="https://httpd.apache.org/images/apache.gif" width="28"> | **LAMP Stack** | Web Stack | Apache + MySQL + PHP | Apache + MySQL + PHP | ⭐5 | ⭐5 | 😊3 | 🛠🛠 | 1 | 1 GB | 10 GB | ❌ | low priority |

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
| 🔥🔥🔥 | **n8n** | มี skeleton อยู่แล้วและ demand automation/AI workflow สูง |
| 🔥🔥🔥 | **Vaultwarden** | เบามาก, value สูง, ใช้ได้ทุกทีม, bootstrap secret ชัด |
| 🔥🔥🔥 | **AnythingLLM** | AI no-GPU ที่เหมาะสุดสำหรับ image แรก: RAG/doc Q&A + external API/Ollama |
| 🔥🔥 | **Nextcloud rebuild** | มี built เดิมแต่ต้อง sync source กับ upstream/baseline |
| 🔥🔥 | **WordPress rebuild** | demand สูงสุด แต่ current image target เก่า |
| 🔥🔥 | **Umami** | analytics image เบาและใช้ฟรี MIT |
| 🔥🔥 | **Chatwoot CE** | helpdesk/live chat ใช้เชิงธุรกิจได้จริง |
| 🔥🔥 | **NocoDB** | Airtable replacement ใช้ง่ายและ resource ไม่สูง |
| 🔥 | **Flowise** | AI builder เบา เหมาะกับ prototype/internal tools |
| 🔥 | **Coolify** | PaaS/dev image high value แต่ต้อง harden Docker host |
| 🔥 | **Dify CE** | AI platform ครบแต่ stack หนักกว่า |
| 🔥 | **Plane CE** | project management ดีแต่ resource/stack หนัก |
| — | **Odoo 19 upgrade** | guide Odoo 18 ยังใช้ได้ แต่ latest target ควร research ก่อน upgrade |
| — | **Grafana+Prometheus** | พร้อม build แล้ว; ทำหลัง app ที่ยังไม่มี source |
| — | **Docker Platform** | พร้อม build แล้ว; verify pins เป็นรอบๆ |
| — | **Gitea** | ควรทำก่อน GitLab ถ้าต้องการ Git image เบา |
| — | **GitLab CE** | หนัก เหมาะเฉพาะลูกค้าที่ต้องการ CI/CD ครบ |
| — | **PostgreSQL / LAMP** | dev ตั้งเองได้ value ต่ำกว่า app สำเร็จรูป |

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

## License

| App | License | หมายเหตุ |
|---|---|---|
| WordPress, Ghost, WooCommerce | GPLv2/MIT | ฟรีทั้งหมด |
| PrestaShop, Odoo | OSL-3.0 / LGPL-3.0 | Community edition ฟรี |
| ERPNext, Nextcloud, Seafile | GPLv3 / AGPLv3 | ฟรีทั้งหมด |
| GitLab CE, Gitea | MIT | CE ฟรี — EE จ่ายเงิน |
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
