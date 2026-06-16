# Project Architecture — Folder Structure & Purpose

---

## 📁 Full Folder Tree

```text
openstack-image/
│
├── 📂 agents/                       [AI Agent Specs — Operational]
│   ├── aerith.md                 (Aerith — วิจัย community, เขียน review)
│   ├── cid.md                    (Cid — ออกแบบ app, เขียน build guide)
│   ├── cloud.md                  (Cloud — SSH build, verify, บันทึก errors)
│   ├── tifa.md                   (Tifa — อัปเดต docs, ลบ temp)
│   └── nanaki.md                 (Nanaki — สร้างคู่มือ end-user HTML)
│
├── 📂 docs/                          [Documentation Centralized]
│   ├── README.md                    (Domain overview + quick start)
│   ├── AGENT-SPEC.md                (Agent flow overview + links ไป 4 agents)
│   ├── AGENTS.md                    (กติกากลาง — ทุก agent ต้องปฏิบัติตาม)
│   ├── AI-PIPELINE.md               (Build pipeline framework)
│   ├── DEPENDENCIES.md              (File dependency map)
│   ├── ARCHITECTURE.md              (This file - visual structure)
│   └── references/                  (Reusable references)
│       ├── mirrors.md               (Thai mirror matrix per OS)
│       └── cloud-init-scenarios.md  (Cloud-init user-data templates)
│
├── 📂 scripts/                       [Automation & Tools — Planned]
│   ├── templates/                   (Shell script templates — empty)
│   └── utils/                       (Reusable utilities — empty)
│
├── 📂 build/                        [Build Output & Source Files]
│   ├── _app-catalog.md              (App status + wishlist overview)
│   ├── _guest-images.md             (Guest image pipeline: 9 OS)
│   ├── _guest-images-errors.md      (AI mistakes log for guest builds)
│   ├── _verify-template.md          (Pre-capture gate checklist template)
│   ├── apps/                        [Per-App Source Files]
│   │   ├── wordpress/               (CMS — MariaDB + PHP-FPM + Nginx)
│   │   │   ├── wordpress.md         (Build guide)
│   │   │   ├── wordpress-review.md  (Community research)
│   │   │   ├── wordpress-errors.md  (AI mistakes log)
│   │   │   ├── wordpress-post-check.md (Post-check checklist)
│   │   │   ├── docker-compose.yml   (Source: 3 services)
│   │   │   ├── nginx/
│   │   │   │   ├── default.conf     (HTTP)
│   │   │   │   └── default-https.conf (HTTPS)
│   │   │   ├── php/
│   │   │   │   └── wordpress.ini    (PHP config)
│   │   │   ├── wordpress-bootstrap.service
│   │   │   ├── wordpress-bootstrap.sh
│   │   │   ├── README-wordpress-image.txt
│   │   │   └── 99-wordpress-image
│   │   │
│   │   ├── nextcloud/               (File sync — PostgreSQL + Redis + Nginx)
│   │   │   ├── nextcloud.md
│   │   │   ├── nextcloud-review.md
│   │   │   ├── nextcloud-errors.md
│   │   │   ├── nextcloud-post-check.md
│   │   │   ├── docker-compose.yml
│   │   │   ├── nginx/
│   │   │   │   ├── default.conf
│   │   │   │   └── default-https.conf
│   │   │   ├── nextcloud-bootstrap.service
│   │   │   ├── nextcloud-bootstrap.sh
│   │   │   ├── README-nextcloud-image.txt
│   │   │   ├── image.conf
│   │   │   └── 99-nextcloud-image
│   │   │
│   │   ├── odoo/                    (ERP/CRM — PostgreSQL + Odoo 18 + Nginx)
│   │   │   ├── odoo.md
│   │   │   ├── odoo-review.md
│   │   │   ├── odoo-errors.md
│   │   │   ├── odoo-post-check.md
│   │   │   ├── docker-compose.yml
│   │   │   ├── nginx/
│   │   │   │   ├── default.conf
│   │   │   │   └── default-https.conf
│   │   │   ├── odoo-bootstrap.service
│   │   │   ├── odoo-bootstrap.sh
│   │   │   ├── odoo-tune-workers.sh
│   │   │   ├── odoo-backup.sh
│   │   │   ├── README-odoo-image.txt
│   │   │   └── 99-odoo-image
│   │   │
│   │   └── n8n/                     (Workflow automation — PostgreSQL + Nginx)
│   │       ├── n8n.md
│   │       ├── n8n-review.md
│   │       ├── n8n-errors.md
│   │       └── ... (source files)
│   │
│   └── templates/                   [Reusable App Templates — Empty]
│
├── 📂 inventory/                    [Build Output Metadata]
│   ├── README.md                    (Inventory guide + format spec)
│   ├── build.env                    (Build environment config)
│   └── images/                      (Planned — image metadata storage)
│       └── (not yet created)
│
├── 📂 problem/                      [Troubleshooting Docs]
│   ├── _template.md                 (Template for new issues)
│   └── generic/                     (Generic issues — reusable across builds)
│       ├── provider-interface-rename-cloud-init.md
│       └── nextcloud-docker-install-wizard-after-bootstrap.md
│
├── 📄 Makefile                      [Automation Targets]
├── 📄 CONTRIBUTING.md               [Workflow Guide]
├── 📄 RESTRUCTURE_SUMMARY.md        [Restructure changelog]
├── 📄 .gitignore                    [Git Ignore Rules]
└── 📂 .git/
```

---

## 📌 Folder Purpose Matrix

| Folder | Purpose | Access | Frequency |
|---|---|---|---|
| **docs/** | Central documentation hub | AI agents + users | Read EVERY build |
| **scripts/templates/** | Reusable shell templates (planned) | User + automation | Copy-paste to temp → modify → run |
| **scripts/utils/** | Reusable Python utilities (planned) | Build automation | Pre-flight check + SSH runner |
| **build/apps/{app}/** | Per-app source + guide | AI agents + users | Read to understand app |
| **build/templates/** | App templates (planned) | New app creation | Copy when creating app image |
| **inventory/images/** | Built image metadata (planned) | Post-build recording | Write after capture |
| **inventory/** | Build config + inventory guide | Build automation | Read build.env |
| **problem/generic/** | Generic troubleshooting docs | AI agents | Consult when debugging |

---

## 🔄 Data Flow

### 1️⃣ Build Phase (Image Domain)

```
User requirement
     ↓
AI reads docs/README.md + build/_app-catalog.md
     ↓
AI reads build/apps/{app}/{app}.md (build guide)
     ↓
AI reads docs/AI-PIPELINE.md (framework)
     ↓
User prepares build/tmp/{app}-build.env (temp, gitignored)
     ↓
AI copy scripts/templates/*.sh.tmpl → scripts/temp/  (planned feature)
     ↓
User sed replace {PLACEHOLDERS} in temp scripts
     ↓
User run scripts on golden-image VM via SSH
     ↓
AI verify pre-capture gates ✅
     ↓
VM poweroff + capture → Glance image
     ↓
Update:
  - build/apps/{app}/{app}.md (header tag)
  - build/_app-catalog.md (status)
  - inventory/images/*.env (metadata — planned)
  - DELETE build/tmp/{app}-build.env
```

**Key:** Image build is **standalone** — ไม่ผูก environment ใดๆ

---

## 🎯 File Ownership

| Folder | Owner | Read By | Write By |
|---|---|---|---|
| agents/ | All agents | All agents | All agents |
| docs/ | Tifa | Everyone | Tifa + maintainers |
| scripts/ | Cid + Cloud | User + agents | Maintainers |
| build/apps/{app}/ | Cid + Cloud | All agents | Cid + Cloud + Tifa |
| build/templates/ | Maintainers | New app creation | Maintainers |
| inventory/images/ | Tifa | Build review | Tifa |
| problem/generic/ | Cloud + Tifa | Troubleshooting | Cloud + Tifa |

---

## 🔐 Gitignore Policy

```gitignore
# Temp files during build (delete after use)
build/tmp/                           # build-specific env
scripts/temp/                        # temp script workspace

# Secrets (NEVER commit)
.env                                 # all env files
*.private                           # private keys
credentials.txt                     # credentials
```

---

## 🌳 Dependency Hierarchy (Read in Order)

```
docs/AGENT-SPEC.md                [START HERE — Agent Flow]
    ↓
    ├─ agents/aerith.md            (if วิจัย)
    ├─ agents/cid.md               (if ออกแบบ)
    ├─ agents/cloud.md             (if build) → docs/AI-PIPELINE.md
    └─ agents/tifa.md              (if อัปเดต docs) → docs/DEPENDENCIES.md

docs/AGENTS.md                     [COMMON RULES — All agents must follow]
    ↓
    ├─ docs/references/            (mirrors, cloud-init)
    ├─ build/_app-catalog.md       (app status)
    └─ build/apps/{app}/{app}.md   (per-app guide)
```

---

## 🚀 Entry Points for Different Users

### 👤 **End User (wants to create VM from image)**
1. `docs/README.md` → Overview
2. `build/_app-catalog.md` → App status
3. `build/apps/{app}/{app}.md` → Build guide
4. Follow commands (copy-paste ready)

### 🤖 **Aerith (Research app)**
1. `docs/AGENT-SPEC.md` → Agent flow overview
2. `agents/aerith.md` → Aerith spec
3. `build/_app-catalog.md` → App status
4. Search community (Reddit, StackOverflow, GitHub)
5. Write `build/apps/{app}/{app}-review.md`

### 🏗️ **Cid (Design app image)**
1. `docs/AGENT-SPEC.md` → Agent flow overview
2. `agents/cid.md` → Cid spec
3. `build/apps/{app}/{app}-review.md` → Community research
4. `docs/references/mirrors.md` → Mirror config
5. Write `build/apps/{app}/{app}.md` + source files

### 🔧 **Cloud (Build on VM)**
1. `docs/AGENT-SPEC.md` → Agent flow overview
2. `agents/cloud.md` → Cloud spec
3. `docs/AI-PIPELINE.md` → Build pipeline framework
4. `build/apps/{app}/{app}.md` → Build guide
5. SSH to VM → build → verify → record errors

### 📝 **Tifa (Update docs)**
1. `docs/AGENT-SPEC.md` → Agent flow overview
2. `agents/tifa.md` → Tifa spec
3. `docs/DEPENDENCIES.md` → Dependency map
4. Update `_app-catalog.md`, `{app}.md`, `README.md`

### 🐛 **Troubleshooter (fixing build issues)**
1. `docs/README.md` → Overview
2. `problem/generic/` → Similar issue?
3. `docs/AI-PIPELINE.md` → Framework
4. `build/apps/{app}/{app}-errors.md` → Previous errors
5. Create `problem/generic/{new-issue}.md`

### 🏗️ **Maintainer (restructuring / adding OS)**
1. `docs/DEPENDENCIES.md` → What depends on what?
2. `docs/ARCHITECTURE.md` → How does it all fit?
3. Update all dependent files
4. Pre-commit checklist ✅

---

## 📊 Size & Scale

```text
Folder Sizes (est.):
├── docs/               ~ 200 KB   (markdown only)
├── scripts/            ~ empty    (templates + utils — planned)
├── build/apps/         ~ 400 KB   (4 apps × 100 KB ea)
├── build/templates/    ~ empty    (reusable templates — planned)
├── inventory/          ~ 10 KB    (README + build.env)
└── problem/            ~ 50 KB    (troubleshooting)

Total: ~ 660 KB (very lightweight, mostly text)
```

---

## 🔗 Quick Reference Links

| What | Location | Example |
|---|---|---|
| Agent spec | `docs/AGENT-SPEC.md` | Role + responsibilities |
| Build framework | `docs/AI-PIPELINE.md` | 4 phases + pre-capture gate |
| App status | `build/_app-catalog.md` | "WordPress: ✅ ready" |
| Build guide | `build/apps/{app}/{app}.md` | Step-by-step commands |
| Mirror config | `docs/references/mirrors.md` | Thai mirrors per OS |
| Cloud-init template | `docs/references/cloud-init-scenarios.md` | User-data examples |
| Script template | `scripts/templates/` | (Planned — not yet created) |
| Troubleshooting | `problem/generic/` | Docker pull failures, cloud-init issues |
| Dependencies | `docs/DEPENDENCIES.md` | Update A → then update B |
| Inventory guide | `inventory/README.md` | Format spec + build.env |
| Build config | `inventory/build.env` | Build environment variables |

---

**Version:** 2026-06-12  
**Purpose:** Visual architecture + folder guide  
**Audience:** Everyone (AI agents + users + maintainers)