# OpenStack Image Domain

> Domain สำหรับ build / manage OpenStack images — guest images, app images, cloud-init templates

---

## 📋 ภาพรวม

OpenStack Image คือ domain รวมศูนย์สำหรับการสร้าง และบริหารจัดการ **golden images** ที่ใช้งานจริง เช่น:

- **Guest images** — OS พื้นฐาน (Ubuntu, Debian, Rocky, AlmaLinux, etc.) ให้ลูกค้าสร้าง VM จาก
- **App images** — OS + application stack พร้อมใช้ (WordPress, Nextcloud, Odoo, Docker Platform, Grafana+Prometheus, n8n) และ candidate แยกตามหมวดใน catalog เช่น Vaultwarden, AnythingLLM, Umami
- **Build pipeline** — ขั้นตอน, automation, testing สำหรับการ capture images
- **References** — mirror config, cloud-init templates, troubleshooting

---

## 🗂️ โครงสร้าง Folder

```text
openstack-image/
├── agents/                    ← Agent Specs (สั่งงาน AI)
│   ├── aerith.md              (Aerith — วิจัย community, เขียน review)
│   ├── cid.md                 (Cid — ออกแบบ app, เขียน build guide)
│   ├── cloud.md               (Cloud — SSH build, verify, บันทึก errors)
│   ├── tifa.md                (Tifa — อัปเดต docs, ลบ temp)
│   └── nanaki.md              (Nanaki — สร้างคู่มือ end-user HTML)
├── docs/                        ← Documentation (คุณอยู่ที่นี่)
│   ├── README.md               (domain overview)
│   ├── AGENT-SPEC.md           (agent flow overview + links ไป 4 agents)
│   ├── AGENTS.md               (กติกากลาง — ทุก agent ต้องปฏิบัติตาม)
│   ├── AI-PIPELINE.md          (build pipeline framework — Cloud ใช้หลัก)
│   ├── DEPENDENCIES.md         (dependency map — ไฟล์ A ↔ ไฟล์ B)
│   ├── ARCHITECTURE.md         (visual folder structure + purpose)
│   ├── examples/               (ว่าง — สำหรับ step-by-step build examples ในอนาคต)
│   └── references/             (mirrors, cloud-init, stack components)
│       ├── mirrors.md
│       ├── cloud-init-scenarios.md
│       └── stack-components.md
├── scripts/                    ← Automation & Tools
│   ├── templates/              (ว่าง — shell script templates สำหรับ build)
│   └── utils/                  (ว่าง — reusable utilities)
├── build/                     ← Build Output & Source Files
│   ├── _app-catalog.md        (app status + wishlist)
│   ├── _build-manifest-template.md (template ประวัติ version หลัง build)
│   ├── _guest-images.md        (guest image pipeline: 9 OS)
│   ├── _guest-images-errors.md (AI mistakes log)
│   ├── _verify-template.md    (pre-capture gate checklist template)
│   ├── apps/                  (per-app source files)
│   │   ├── wordpress/
│   │   │   ├── wordpress.md
│   │   │   ├── wordpress-review.md
│   │   │   ├── wordpress-errors.md
│   │   │   ├── wordpress-build-manifest.md
│   │   │   ├── wordpress-post-check.md
│   │   │   ├── docker-compose.yml
│   │   │   ├── nginx/
│   │   │   ├── php/
│   │   │   ├── wordpress-bootstrap.sh
│   │   │   ├── wordpress-bootstrap.service
│   │   │   ├── README-wordpress-image.txt
│   │   │   └── 99-wordpress-image
│   │   ├── nextcloud/
│   │   ├── odoo/
│   │   ├── woocommerce/
│   │   ├── docker-platform/
│   │   ├── grafana-prometheus/
│   │   └── n8n/
│   ├── templates/              (ว่าง — reusable app templates)
│   └── tmp/                    (temp env files ระหว่าง build — gitignored)
│       └── {app}-build.env     (สร้างระหว่าง build, ลบหลังจบ)
├── inventory/                  ← Build Environment Config
│   ├── README.md
│   └── build.env              (SSH connection template เข้า VM)
├── problem/                   ← Troubleshooting Docs
│   ├── generic/
│   │   ├── nextcloud-docker-install-wizard-after-bootstrap.md
│   │   └── provider-interface-rename-cloud-init.md
│   └── _template.md            (template for new issues)
├── Makefile                   ← Automation Targets
├── CONTRIBUTING.md            ← Workflow Guide
├── .gitignore                 ← Updated for temp files
└── .git/
```

---

## 📊 ประเภท Image & สถานะ

| ประเภท | คำอธิบาย | ไฟล์ | สถานะ |
|---|---|---|---|
| **Guest images** | OS พื้นฐาน (9 OS) — cleanup + cloud-init พร้อม | `build/_guest-images.md` | ⚠️ pipeline |
| **App catalog** | Overview app status + upstream signal + catalog by category | `build/_app-catalog.md` | ✅ updated 2026-06-15 |
| **WordPress** | CMS — MariaDB + PHP-FPM + Nginx | `build/apps/wordpress/` | ✅ built standalone; ต้องเลือก target line ก่อน rebuild |
| **WooCommerce** | E-Commerce — WordPress + WooCommerce bootstrap | `build/apps/woocommerce/` | ✅ พร้อม build |
| **Nextcloud** | File sync — PostgreSQL + Redis + Nginx | `build/apps/nextcloud/` | ⚠️ built เดิม แต่ source target เก่า ต้อง sync/rebuild |
| **Odoo** | ERP/CRM — PostgreSQL + Odoo 18 guide | `build/apps/odoo/` | ✅ พร้อม build; optional Odoo 19 review |
| **Docker Platform** | DevOps platform — Docker CE + Portainer + Nginx Proxy Manager | `build/apps/docker-platform/` | ✅ พร้อม build |
| **Grafana+Prometheus** | Monitoring — VM / Website / Service monitoring | `build/apps/grafana-prometheus/` | ✅ built standalone; post-test PASS; cleanup-ready; พร้อม capture/Glance ตาม admin workflow |
| **n8n** | Workflow automation — PostgreSQL + Nginx | `build/apps/n8n/` | ❌ รอเติม source |
| **Candidate images** | แยกหมวดใน catalog เช่น Vaultwarden, AnythingLLM, Umami, Chatwoot, NocoDB | `build/_app-catalog.md` | 🧭 ยังไม่มี source ต้องทำ review/source ก่อน build |

---

## 📖 ไฟล์ที่ต้องอ่านก่อนทำงาน

### 1️⃣ **เอกสารหลัก** (Essential)
- **`docs/README.md`** (คุณอยู่ที่นี่) — Domain overview, ประเภท image
- **`docs/AGENT-SPEC.md`** — Agent flow overview + links ไป 4 agent specs
- **`docs/AGENTS.md`** — กติกากลาง (ทุก agent ต้องปฏิบัติตาม)

### 2️⃣ **Agent Specs** (เลือกตามหน้าที่)
- **`agents/aerith.md`** — Aerith: วิจัย community + เขียน review
- **`agents/cid.md`** — Cid: ออกแบบ app + เขียน build guide
- **`agents/cloud.md`** — Cloud: SSH build + verify + บันทึก errors
- **`agents/tifa.md`** — Tifa: อัปเดต docs + ลบ temp

### 3️⃣ **Reference**
- **`docs/references/mirrors.md`** — Mirror availability matrix (TH mirrors)
- **`docs/references/stack-components.md`** — Stack component catalog (DB, Proxy, Cache, Runtime)
- **`docs/references/cloud-init-scenarios.md`** — User-data templates
- **`docs/ARCHITECTURE.md`** — Visual folder structure + purpose explanation
- **`docs/DEPENDENCIES.md`** — Dependency map (ถ้าแก้ไฟล์ A ต้องอัปเดต B)

### 3️⃣ **Build Output**
- **`build/_app-catalog.md`** — App status (สร้างแล้ว/พร้อม build/รอเติม)
- **`build/_build-manifest-template.md`** — Template สำหรับ `{app}-build-manifest.md` หลัง build สำเร็จ
- **`build/_guest-images.md`** — Guest image pipeline (OS checklist)
- **`build/apps/{app}/{app}.md`** — Per-app build guide (self-contained, copy-paste ได้)
- **`build/apps/{app}/{app}-build-manifest.md`** — Version history ล่าสุดของ golden image build แบบ non-secret

### 4️⃣ **Automation**
- **`scripts/templates/`** — Shell script templates (ยังว่าง, สำหรับอนาคต)
- **`scripts/utils/`** — Utilities (ยังว่าง, สำหรับอนาคต)
- **`Makefile`** — Quick targets (make build-app, make validate-env, etc.)

### 5️⃣ **Troubleshooting**
- **`problem/generic/`** — Generic issues (docker-pull, cloud-init, etc.)
- **`build/_verify-template.md`** — Pre-capture gate checklist template

---

## 🔄 Workflow: สร้าง App Image ใหม่

```
1. User บอก requirement
   → AI ปรึกษากับ user (Step 0: Clarify User Intent)
   → ประมวลความต้องการ + แนะนำ approach

2. AI สร้าง {app}-review.md
   → Community research (Reddit, StackOverflow, GitHub)
   → 5 ขั้น: Clarify → Search → Score → Competitive → Pitfalls → Production Gaps
   → Self-Upgrade: queries / scoring ถ้าเจอวิธีใหม่

3. User เลือก features + deployment strategy
   → AI เลือก component จาก stack-components.md → ผสมเป็น stack
   → AI สร้าง/อัปเดต build/apps/{app}/{app}.md
   → Self-contained guide: copy-paste commands ได้เลยบน VM
   → Self-Upgrade: stack-components.md ถ้าพบ component ใหม่

4. ระหว่าง build
   → Cloud รัน guide ทีละขั้น — verify ทุกคำสั่ง
   → ถ้าสั่งผิด → บันทึกใน build/apps/{app}/{app}-errors.md
   → คำสั่ง + fix + root cause
   → Self-Upgrade: mirror matrix / cloud-init ถ้าเจอ behavior ใหม่

5. หลัง build เสร็จ
    → Tifa อัปเดต build/_app-catalog.md (status)
    → อัปเดต build/apps/{app}/{app}.md (header tag: [built: ...])
    → Cloud/Tifa อัปเดต build/apps/{app}/{app}-build-manifest.md (version history, no runtime/OpenStack context)
    → Backfill Lessons Learned → {app}-review.md
   → อัปเดต stack-components.md ถ้าพบ component ใหม่
   → ลบ temp env file (build/tmp/{app}-build.env)
   → Self-Upgrade: DEPENDENCIES.md ถ้าพบ dependency ใหม่

6. Troubleshooting
   → Generic issue → problem/generic/{issue}.md
```

---

## 🎯 Per-App Structure (1 App = 1 Folder)

```text
build/apps/{app}/
├── {app}.md                   ← Build guide — self-contained
├── {app}-review.md            ← Community research (not AI test scenario)
├── {app}-errors.md            ← AI mistakes log (commands that failed + fixes)
├── {app}-post-check.md        ← Post-check checklist (optional)
├── docker-compose.yml          ← Source file (ถ้าใช้ Docker)
├── {app}-bootstrap.sh          ← First-boot script (generates secrets, starts app)
├── {app}-bootstrap.service     ← systemd oneshot unit
├── nginx/                      ← (ถ้าใช้ proxy)
│   ├── default.conf           ← HTTP config
│   └── default-https.conf     ← HTTPS config
├── php/ (if applicable)
├── README-{app}-image.txt      ← User-facing documentation
└── 99-{app}-image              ← Custom cloud-init config (if needed)
```

**กฎ 3 ไฟล์:**
1. **`{app}.md`** — Self-contained, ผู้ใช้ copy commands ไปรันบน VM ได้เลย
2. **`{app}-review.md`** — Community research จริง (อ้างอิง Reddit/StackOverflow/GitHub)
3. **`{app}-errors.md`** — AI log: คำสั่งที่ผิด + fix + root cause

---

## 🔧 วิธีใช้ซ้ำ (สร้าง Image ใหม่)

### สำหรับ Guest Image
1. เปิด `build/_guest-images.md` → เลือก OS
2. ทำตาม **Phase A → Set 1 → Set 2 → Set 3** (Reusable framework)
3. ใช้ mirror ไทยจาก `docs/references/mirrors.md`
4. Capture image → `openstack server image create --name "<OS>-guest-YYYYMMDD" <SERVER_ID>`

### สำหรับ App Image
1. เปิด `build/_app-catalog.md` → เลือก app
2. อ่าน `build/apps/{app}/{app}.md` → ดู status + prerequisites
3. อ่าน `docs/AI-PIPELINE.md` → เข้าใจ Pre-flight + Build + Verify + Post-build phases
4. ถ้ามี templates ใน `scripts/templates/` → copy → sed replace → run
5. หลัง build → อัปเดต docs + ลบ temp env

---

## 📌 Rules & Policies

### Standalone Domain
- Image build เป็น **standalone** ไม่ผูก environment ใดๆ
- ห้ามบันทึก temp IP, server ID, floating IP, Glance ID ลง docs กลาง
- ห้ามเก็บ password, token, private key, credentials
- Temp env อยู่ใน `build/tmp/{app}-build.env` (gitignored, ลบหลังจบ)

### Environment Ownership
```text
Build-specific (temp, ลบหลังจบ):
  build/tmp/{app}-build.env              ← gitignored
  /opt/{app}/.env (บน VM)                ← delete ก่อน capture

Golden-image persistent:
  /opt/{app}/docker-compose.yml          ← เก็บ (template only)
  /opt/{app}/bootstrap.sh                ← เก็บ (generates secrets on first boot)
  /opt/{app}/bootstrap.service           ← เก็บ (systemd unit)
  Docker images                          ← เก็บ (pre-pulled, reduce inter bandwidth)
```

### Package Cache Policy
- ✅ **Keep** — `apt list`, `docker images`, cached packages (reduce inter bandwidth)
- ❌ **Remove** — runtime configs, logs, volumes, `.env` files, secrets

---

## 🚀 Getting Started

1. **หากเป็น AI agent — จุดเริ่มต้น:**
   - `docs/AGENT-SPEC.md` — อ่านก่อน: agent flow + links ไป 4 agents
   - `docs/AGENTS.md` — กติกากลาง (ทุก agent ต้องปฏิบัติตาม)
   - เลือก agent ตามหน้าที่:
     - วิจัย → `agents/aerith.md`
      - ออกแบบ → `agents/cid.md`
      - Build → `agents/cloud.md` + `docs/AI-PIPELINE.md`
      - อัปเดต docs → `agents/tifa.md` + `docs/DEPENDENCIES.md`

2. **หาก user ต้องการสร้าง app image ใหม่:**
   - AI อ่าน `build/_app-catalog.md`
   - AI อ่าน `build/apps/{app}/{app}.md` (ถ้ามี)
   - AI ถาม user requirements
   - AI สร้าง/อัปเดต guide

3. **หากเจอปัญหา:**
   - บันทึกใน `problem/generic/` (reusable pattern)
   - หรือ `problem/generic/` (reusable pattern)

---

## 🔗 Quick Links

- **Agent Spec:** `docs/AGENT-SPEC.md`
- **Build Pipeline:** `docs/AI-PIPELINE.md`
- **Mirror Config:** `docs/references/mirrors.md`
- **Stack Components:** `docs/references/stack-components.md`
- **Troubleshooting:** `problem/`
- **Automation:** `scripts/` + `Makefile`

---

**Last updated:** 2026-06-14
**Format:** OpenStack Image Domain (Restructured)
