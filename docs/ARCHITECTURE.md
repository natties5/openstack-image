# Project Architecture — Folder Structure & Purpose

---

## 📁 Full Folder Tree

```text
openstack-image/
│
├── 📂 docs/                          [Documentation Centralized]
│   ├── README.md                    (Domain overview + quick start)
│   ├── AGENT-SPEC.md                (Agent role + responsibilities)
│   ├── AGENTS.md                    (Image-specific rules)
│   ├── AI-PIPELINE.md               (Build pipeline framework)
│   ├── DEPENDENCIES.md              (File dependency map)
│   ├── ARCHITECTURE.md              (This file - visual structure)
│   ├── examples/                    (Step-by-step build examples)
│   │   ├── build-wordpress.md
│   │   ├── build-nextcloud.md
│   │   └── build-odoo.md
│   └── references/                  (Reusable references)
│       ├── mirrors.md               (Thai mirror matrix per OS)
│       └── cloud-init-scenarios.md  (Cloud-init user-data templates)
│
├── 📂 scripts/                       [Automation & Tools]
│   ├── README.md                    (How to use scripts)
│   ├── templates/                   (Shell script templates for build)
│   │   ├── step2_install_base.sh.tmpl
│   │   ├── step3_install_docker.sh.tmpl
│   │   ├── step4_5_deploy_files.sh.tmpl
│   │   ├── step6_enable_service.sh.tmpl
│   │   ├── step7_test_bootstrap.sh.tmpl
│   │   ├── step8_cleanup.sh.tmpl
│   │   ├── step9_final_check.sh.tmpl
│   │   └── README.md                (Template usage guide)
│   └── utils/                       (Reusable utilities)
│       ├── ssh-runner.py            (Paramiko SSH helper for Windows)
│       ├── env-validator.py         (Pre-flight environment check)
│       ├── image-capturer.py        (OpenStack image capture wrapper)
│       └── README.md                (Utils API + examples)
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
│   └── templates/                   [Reusable App Templates]
│       ├── .env.example             (Template env vars)
│       ├── bootstrap.service.tmpl   (systemd service template)
│       ├── docker-compose.yml.tmpl  (Docker Compose base template)
│       ├── cloud-init.tmpl          (Cloud-init user-data template)
│       └── nginx-default.conf.tmpl  (Nginx config template)
│
├── 📂 inventory/                    [Build Output Metadata]
│   ├── images/                      (Image metadata storage)
│   │   ├── guest-images.env         (Guest image list + Glance IDs)
│   │   └── app-images.env           (App image list + Glance IDs)
│   └── README.md                    (Inventory guide + format spec)
│
├── 📂 problem/                      [Troubleshooting Docs]
│   ├── generic/                     (Generic issues - reusable across builds)
│   │   ├── docker-pull-failed-proxy.md (Docker pull failure with proxy)
│   │   ├── provider-interface-rename-cloud-init.md
│   │   ├── nextcloud-docker-install-wizard-after-bootstrap.md
│   │   └── ...
│   └── _template.md                 (Template for new issues)
│
├── 📂 clusters/                     [Cluster-Specific (Future)]
│   └── README.md                    (Placeholder for cluster docs)
│
├── 📄 Makefile                      [Automation Targets]
│   ├── make build-app APP=<name> ENV=<path>
│   ├── make validate-env ENV=<path>
│   ├── make list-apps
│   ├── make cleanup-temp
│   └── make docs
│
├── 📄 CONTRIBUTING.md               [Workflow Guide]
│   ├── How to create new app image
│   ├── How to update existing guide
│   ├── How to troubleshoot
│   └── Pre-commit checklist
│
├── 📄 .gitignore                    [Git Ignore Rules]
│   ├── image/tmp/
│   ├── build/temp/
│   ├── scripts/temp/
│   ├── .env
│   ├── *.private
│   └── credentials.txt
│
└── 📂 .git/
```

---

## 📌 Folder Purpose Matrix

| Folder | Purpose | Access | Frequency |
|---|---|---|---|
| **docs/** | Central documentation hub | AI agents + users | Read EVERY build |
| **scripts/templates/** | Reusable shell templates | User + automation | Copy-paste to temp → modify → run |
| **scripts/utils/** | Reusable Python utilities | Build automation | Pre-flight check + SSH runner |
| **build/apps/{app}/** | Per-app source + guide | AI agents + users | Read to understand app |
| **build/templates/** | App templates (reusable) | New app creation | Copy when creating app image |
| **inventory/images/** | Built image metadata | Post-build recording | Write after capture |
| **problem/generic/** | Generic troubleshooting docs | AI agents | Consult when debugging |
| **clusters/** | Cluster-specific docs (future) | Cluster deployment phase | NOT image build phase |

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
User prepares image/tmp/{app}-build.env (temp, gitignored)
     ↓
AI copy scripts/templates/*.sh.tmpl → scripts/temp/
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
  - inventory/images/*.env (metadata)
  - DELETE image/tmp/{app}-build.env
```

### 2️⃣ Cluster Deployment Phase (Cluster Domain)

```
[Image from Phase 1 is STANDALONE]
     ↓
Cluster ops reads clusters/{name}/.env + inventory/vm.md
     ↓
Import image → Glance (generic image)
     ↓
Create VM from image
     ↓
cloud-init runs bootstrap.service (auto-generate secrets)
     ↓
App up + running ✅
     ↓
Update: clusters/{name}/inventory/vm.md (IP, VM ID, etc.)
```

**Key:** Image build is **STANDALONE** — no cluster-specific data  
Cluster data goes to **clusters/** folder, NOT image build docs

---

## 🎯 File Ownership

| Folder | Owner | Read By | Write By |
|---|---|---|---|
| docs/ | AI agents | Everyone | AI agents + maintainers |
| scripts/ | Build automation | User + AI | Maintainers |
| build/apps/{app}/ | AI agents | AI + user | AI agents |
| build/templates/ | Maintainers | New app creation | Maintainers |
| inventory/images/ | Build automation | Cluster deployment | Build automation |
| problem/generic/ | AI agents | Troubleshooting | AI agents |
| clusters/ | Cluster ops | Cluster deployment | Cluster ops |

---

## 🔐 Gitignore Policy

```gitignore
# Temp files during build (delete after use)
image/tmp/                          # build-specific env
build/temp/                         # build workspace
scripts/temp/                       # temp script workspace

# Secrets (NEVER commit)
.env                                # all env files
*.private                           # private keys
credentials.txt                     # credentials
```

---

## 🌳 Dependency Hierarchy (Read in Order)

```
docs/README.md                      [START HERE]
    ↓
    ├─ docs/AGENT-SPEC.md          (if AI agent)
    ├─ docs/AGENTS.md              (if AI agent)
    ├─ docs/AI-PIPELINE.md         (before building)
    ├─ build/_app-catalog.md       (check app status)
    ├─ build/apps/{app}/{app}.md   (per-app guide)
    └─ docs/references/            (mirrors, cloud-init)

docs/DEPENDENCIES.md                [IF UPDATING DOCS]
    ↓
    Check: which files must I update together?

scripts/README.md                   [FOR BUILD AUTOMATION]
    ↓
    scripts/templates/*.sh.tmpl
    ↓
    scripts/utils/*.py

problem/generic/_template.md        [WHEN TROUBLESHOOTING]
    ↓
    Create problem/generic/{issue}.md
```

---

## 🚀 Entry Points for Different Users

### 👤 **End User (wants to create VM from image)**
1. `docs/README.md` → Overview
2. `build/_app-catalog.md` → App status
3. `build/apps/{app}/{app}.md` → Build guide
4. Follow commands (copy-paste ready)

### 🤖 **AI Agent (building image)**
1. `docs/README.md` → Overview
2. `docs/AGENT-SPEC.md` → Your role
3. `docs/AGENTS.md` → Rules
4. `docs/AI-PIPELINE.md` → Framework
5. `build/_app-catalog.md` → Status
6. `build/apps/{app}/{app}.md` → Per-app guide

### 🔧 **Cluster Ops (deploying image to cluster)**
1. `docs/README.md` → Overview
2. `inventory/images/*.env` → Image list
3. `clusters/{name}/inventory/vm.md` → VM info
4. Import image → Create VM → Done

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
├── scripts/            ~ 50 KB    (templates + utils)
├── build/apps/         ~ 400 KB   (4 apps × 100 KB ea)
├── build/templates/    ~ 20 KB    (reusable templates)
├── inventory/          ~ 10 KB    (metadata)
└── problem/            ~ 50 KB    (troubleshooting)

Total: ~ 700 KB (very lightweight, mostly text)
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
| Script template | `scripts/templates/step*.sh.tmpl` | Copy-paste ready |
| Troubleshooting | `problem/generic/` | Docker pull failures, etc. |
| Dependencies | `docs/DEPENDENCIES.md` | Update A → then update B |

---

**Version:** 2026-06-12  
**Purpose:** Visual architecture + folder guide  
**Audience:** Everyone (AI agents + users + maintainers)
