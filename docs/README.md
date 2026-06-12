# OpenStack Image Domain

> Domain สำหรับ build / manage OpenStack images — guest images, app images, cloud-init templates

---

## 📋 ภาพรวม

OpenStack Image คือ domain รวมศูนย์สำหรับการสร้าง และบริหารจัดการ **golden images** ที่ใช้งานจริง เช่น:

- **Guest images** — OS พื้นฐาน (Ubuntu, Debian, Rocky, AlmaLinux, etc.) ให้ลูกค้าสร้าง VM จาก
- **App images** — OS + application stack พร้อมใช้ (WordPress, Nextcloud, Odoo, n8n)
- **Build pipeline** — ขั้นตอน, automation, testing สำหรับการ capture images
- **References** — mirror config, cloud-init templates, troubleshooting

---

## 🗂️ โครงสร้าง Folder

```text
openstack-image/
├── docs/                        ← Documentation (คุณอยู่ที่นี่)
│   ├── README.md               (domain overview)
│   ├── AGENT-SPEC.md           (agent role & responsibilities)
│   ├── AGENTS.md               (image-specific rules & patterns)
│   ├── AI-PIPELINE.md          (build pipeline framework)
│   ├── DEPENDENCIES.md         (dependency map — ไฟล์ A ↔ ไฟล์ B)
│   ├── ARCHITECTURE.md         (visual folder structure + purpose)
│   ├── examples/               (step-by-step build examples)
│   │   ├── build-wordpress.md
│   │   ├── build-nextcloud.md
│   │   └── build-odoo.md
│   └── references/             (mirrors, cloud-init templates)
│       ├── mirrors.md
│       └── cloud-init-scenarios.md
├── scripts/                    ← Automation & Tools
│   ├── templates/             (shell script templates for build)
│   │   ├── step2_install_base.sh.tmpl
│   │   ├── step3_install_docker.sh.tmpl
│   │   ├── ... (7 steps total)
│   │   └── README.md
│   └── utils/                 (reusable utilities)
│       ├── ssh-runner.py
│       ├── env-validator.py
│       └── image-capturer.py
├── build/                     ← Build Output & Source Files
│   ├── _app-catalog.md        (app status + wishlist)
│   ├── _guest-images.md       (guest image pipeline: 9 OS)
│   ├── _guest-images-errors.md (AI mistakes log)
│   ├── _verify-template.md    (pre-capture gate checklist template)
│   ├── apps/                  (per-app source files)
│   │   ├── wordpress/
│   │   │   ├── wordpress.md
│   │   │   ├── wordpress-review.md
│   │   │   ├── wordpress-errors.md
│   │   │   ├── docker-compose.yml
│   │   │   ├── nginx/
│   │   │   ├── php/
│   │   │   └── ... (bootstrap.sh, service, MOTD, etc.)
│   │   ├── nextcloud/
│   │   ├── odoo/
│   │   └── n8n/
│   └── templates/             (reusable app templates)
│       ├── .env.example
│       ├── bootstrap.service.tmpl
│       ├── docker-compose.yml.tmpl
│       └── cloud-init.tmpl
├── inventory/                 ← Build Output Metadata
│   └── images/
│       ├── guest-images.env
│       └── app-images.env
├── problem/                   ← Troubleshooting Docs
│   ├── generic/
│   │   ├── docker-pull-failed-proxy.md
│   │   └── ...
│   └── _template.md           (template for new issues)
├── clusters/                  ← Cluster-Specific (Future)
│   └── README.md              (placeholder)
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
| **App catalog** | Overview app status + wishlist + priority | `build/_app-catalog.md` | ✅ |
| **WordPress** | CMS — MariaDB + PHP-FPM + Nginx | `build/apps/wordpress/` | ✅ พร้อม build |
| **Nextcloud** | File sync — PostgreSQL + Redis + Nginx | `build/apps/nextcloud/` | ⚠️ รอ rebuild |
| **Odoo** | ERP/CRM — PostgreSQL + Odoo 18 + Nginx | `build/apps/odoo/` | ✅ พร้อม build |
| **n8n** | Workflow automation — PostgreSQL + Nginx | `build/apps/n8n/` | ❌ รอเติมเนื้อหา |

---

## 📖 ไฟล์ที่ต้องอ่านก่อนทำงาน

### 1️⃣ **เอกสารหลัก** (Essential)
- **`docs/README.md`** (คุณอยู่ที่นี่) — Domain overview, ประเภท image
- **`docs/AGENT-SPEC.md`** — Agent role, scope, responsibilities, output format
- **`docs/AGENTS.md`** — Image-specific rules (mirror, sed, cloud-init, package cache)
- **`docs/AI-PIPELINE.md`** — Build pipeline framework (phases, pre-flight, post-build)

### 2️⃣ **Reference & Examples**
- **`docs/references/mirrors.md`** — Mirror availability matrix (TH mirrors)
- **`docs/references/cloud-init-scenarios.md`** — User-data templates
- **`docs/examples/*.md`** — Step-by-step build examples per app
- **`docs/ARCHITECTURE.md`** — Visual folder structure + purpose explanation
- **`docs/DEPENDENCIES.md`** — Dependency map (ถ้าแก้ไฟล์ A ต้องอัปเดต B)

### 3️⃣ **Build Output**
- **`build/_app-catalog.md`** — App status (สร้างแล้ว/พร้อม build/รอเติม)
- **`build/_guest-images.md`** — Guest image pipeline (OS checklist)
- **`build/apps/{app}/{app}.md`** — Per-app build guide (self-contained, copy-paste ได้)

### 4️⃣ **Automation**
- **`scripts/README.md`** — How to use templates (copy → sed replace → run)
- **`scripts/templates/*.sh.tmpl`** — Shell script templates (7 steps)
- **`scripts/utils/*.py`** — Utilities (SSH runner, env validator, image capturer)
- **`Makefile`** — Quick targets (make build-app, make validate-env, etc.)

### 5️⃣ **Troubleshooting**
- **`problem/`** — Generic issues (docker-pull, mirror-404, etc.)
- **`build/_verify-template.md`** — Pre-capture gate checklist template

---

## 🔄 Workflow: สร้าง App Image ใหม่

```
1. User บอก requirement
   → AI อ่าน build/_app-catalog.md + app specific guide
   → ประมวลความต้องการ + แนะนำ approach

2. AI สร้าง <app>-review.md
   → Community research (Reddit, StackOverflow, GitHub)
   → Best practices + beginner/intermediate/advanced recommendations

3. User เลือก features
   → AI สร้าง/อัปเดต build/apps/{app}/{app}.md
   → Self-contained guide: copy-paste commands ได้เลยบน VM

4. ระหว่าง build
   → ถ้า AI สั่งผิด → บันทึกใน build/apps/{app}/{app}-errors.md
   → คำสั่ง + fix + root cause

5. หลัง build เสร็จ
   → อัปเดต build/_app-catalog.md (status)
   → อัปเดต build/apps/{app}/{app}.md (header tag: [built: ...])
   → ลบ temp env file (image/tmp/{app}-build.env)

6. Troubleshooting
   → Generic issue → problem/generic/{issue}.md (reusable)
   → Cluster-specific → clusters/{name}/problem/{date}-{issue}.md
```

---

## 🎯 Per-App Structure (1 App = 1 Folder)

```text
build/apps/{app}/
├── {app}.md                   ← Build guide — self-contained
├── {app}-review.md            ← Community research (not AI test scenario)
├── {app}-errors.md            ← AI mistakes log (commands that failed + fixes)
├── {app}-post-check.md        ← Post-check checklist (optional)
├── docker-compose.yml         ← Source file (reference)
├── bootstrap.sh               ← First-boot script (generates secrets, starts app)
├── bootstrap.service          ← systemd oneshot unit
├── nginx/
│   ├── default.conf          ← HTTP config
│   └── default-https.conf    ← HTTPS config
├── php/ (if applicable)
├── README-{app}-image.txt     ← User-facing documentation
└── 99-{app}-image             ← Custom cloud-init config (if needed)
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
4. ใช้ shell scripts from `scripts/templates/` → copy → sed replace → run
5. หลัง build → อัปเดต docs + ลบ temp env

---

## 📌 Rules & Policies

### Standalone Domain
- Image build เป็น **standalone** ไม่ผูก cluster
- ห้ามบันทึก temp IP, server ID, floating IP, Glance ID ลง docs กลาง
- ห้ามเก็บ password, token, private key, credentials
- Temp env อยู่ใน `image/tmp/{app}-build.env` (gitignored, ลบหลังจบ)

### Environment Ownership
```text
Build-specific (temp, ลบหลังจบ):
  image/tmp/{app}-build.env              ← gitignored
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

1. **หากเป็น AI agent:** อ่านลำดับนี้:
   - `docs/AGENT-SPEC.md` (role + responsibilities)
   - `docs/AGENTS.md` (image-specific rules)
   - `docs/AI-PIPELINE.md` (build framework)
   - `docs/DEPENDENCIES.md` (if updating dependencies)

2. **หาก user ต้องการสร้าง app image ใหม่:**
   - AI อ่าน `build/_app-catalog.md`
   - AI อ่าน `build/apps/{app}/{app}.md` (ถ้ามี)
   - AI ถาม user requirements
   - AI สร้าง/อัปเดต guide

3. **หากเจอปัญหา:**
   - บันทึกใน `problem/generic/` (reusable pattern)
   - หรือ `clusters/{name}/problem/` (incident log เฉพาะ cluster)

---

## 📞 Cross-Domain

| Domain | ความสัมพันธ์ |
|---|---|
| **osa** | Glance service deploy/config → owner หลัก |
| **network** | Guest network, VLAN, provider connectivity → owner หลัก |
| **cluster** | VM, IP, endpoint, OpenStack deployment → reference |
| **monitor** | Image metrics, monitoring → reference |

---

## 🔗 Quick Links

- **Agent Spec:** `docs/AGENT-SPEC.md`
- **Build Pipeline:** `docs/AI-PIPELINE.md`
- **Mirror Config:** `docs/references/mirrors.md`
- **Examples:** `docs/examples/build-*.md`
- **Troubleshooting:** `problem/`
- **Automation:** `scripts/` + `Makefile`

---

**Last updated:** 2026-06-12  
**Format:** OpenStack Image Domain (Restructured)
