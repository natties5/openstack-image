# Dependency Map — File Dependencies

> When you change File A, which files must you update? This document maps those dependencies.

---

## 📊 Dependency Matrix

| If You Change | Then Update | Why | Priority |
|---|---|---|---|
| `build/_guest-images.md` (guest image status) | `docs/README.md` | Update status table | HIGH |
| | `docs/AGENTS.md` (mirror matrix section) | If new OS or mirror discovered | MEDIUM |
| `build/_app-catalog.md` (app status/latest upstream/priority) | `docs/README.md` | Update status table | HIGH |
| | `docs/references/stack-components.md` | If new app category implies reusable stack pattern | MEDIUM |
| | `build/apps/{app}/{app}-review.md` | If promoting wishlist app to build candidate | MEDIUM |
| `build/apps/{app}/{app}-review.md` | `build/_app-catalog.md` | Mark as "has review" if new | MEDIUM |
| `docs/references/mirrors.md` (mirror config) | `docs/AGENTS.md` (mirror matrix section) | Update with new mirror info | HIGH |
| | `build/_guest-images.md` (if mirror changed) | Update guest image build steps | MEDIUM |
| | `docs/README.md` (if mirror structure changed) | Update mirror reference link | LOW |
| `docs/references/cloud-init-scenarios.md` (cloud-init template) | `docs/AGENTS.md` (cloud-init behavior section) | If new behavior discovered | MEDIUM |
| | `build/_guest-images.md` (if cloud-init changed) | Update cloud-init usage in guest build | MEDIUM |
| | `docs/README.md` (if structure changed) | Update cloud-init reference link | LOW |
| `problem/generic/{issue}.md` (new generic issue) | `docs/README.md` | Add to troubleshooting section | LOW |
| `build/apps/{app}/{app}-post-check.md` (post-test checklist/scope/failure routing) | `docs/AI-PIPELINE.md` | If checklist introduces generic post-test policy | MEDIUM |
| | `docs/DEPENDENCIES.md` | If new dependency chain is discovered | MEDIUM |
| `build/apps/{app}/manual.html` (user manual) | `build/_app-catalog.md` | If manual indicates new app status or new category | LOW |
| | `build/apps/{app}/{app}-errors.md` | If build issue changes manual content | LOW |
| Post-test bug fix in `build/apps/{app}/` source or guide | `build/apps/{app}/{app}-post-check.md` | Document verification and expected result | HIGH |
| | `build/apps/{app}/{app}-errors.md` | If AI command failed during post-test/build | HIGH |
| | `docs/AI-PIPELINE.md` | If fix changes generic pipeline behavior | MEDIUM |
| **Folder structure changes** | | | |
| Rename folder or create new domain | `docs/ARCHITECTURE.md` | Update folder tree | HIGH |
| | `docs/README.md` | Update quick links | HIGH |
| | `.gitignore` | If new temp file types | MEDIUM |

---

## 🔄 Reverse Dependency (What uses this file?)

| File | Used By | Purpose |
|---|---|---|
| `agents/aerith.md` | Aerith | Community research |
| `agents/cid.md` | Cid | Build guide + source design |
| `agents/cloud.md` | Cloud | SSH build + verify + errors |
| `agents/tifa.md` | Tifa | Doc updates + dependency check |
| `agents/nanaki.md` | Nanaki | User manual creation + maintenance |
| `docs/README.md` | **Entry point** — links to all other docs | Domain overview |
| `docs/AGENT-SPEC.md` | All agents | Agent flow overview + links |
| `docs/AGENTS.md` | All agents | Common rules |
| `docs/AI-PIPELINE.md` | Build automation | Pipeline framework |
| `docs/references/mirrors.md` | `docs/AGENTS.md` + `build/_guest-images.md` | Mirror selection per OS |
| `docs/references/cloud-init-scenarios.md` | `build/_guest-images.md` + app guides | Cloud-init templates |
| `build/_guest-images.md` | Build automation | Guest image pipeline |
| `build/_app-catalog.md` | `docs/README.md` + AI agents | App status overview |
| `build/_manual-template.html` | Nanaki + Cid | HTML template สำหรับคู่มือ end-user |
| `build/apps/{app}/{app}.md` | Cloud + Tifa | Per-app build guide |
| `build/apps/{app}/{app}-review.md` | Aerith + Cid | Feature selection |
| `build/apps/{app}/{app}-errors.md` | Cloud + Tifa | Error learning log |
| `build/apps/{app}/{app}-build-manifest.md` | Cloud + Nanaki + Tifa | Golden image build version history, non-secret only |
| `build/apps/{app}/{app}-post-check.md` | Cloud + Tifa | Post-test checklist, cleanup mode, failure routing |
| `build/apps/{app}/manual.html` | Nanaki + end-user | User manual (HTML) |
| `scripts/templates/*.sh.tmpl` | *(planned — not yet created)* User + `Makefile` | Build automation |
| `scripts/utils/*.py` | *(planned — not yet created)* Build automation | Pre-flight + validation |
| `scripts/README.md` | *(planned — not yet created)* User | Scripts documentation |
| `Makefile` | User | Quick automation targets |
| `CONTRIBUTING.md` | User + developer | Workflow guide |

---

## 🎯 Update Workflow

### Scenario 1: สร้าง App Image ใหม่

```text
1. Create build/apps/{newapp}/ folder
   ↓
2. Write build/apps/{newapp}/{newapp}.md (build guide)
   ↓
3. Write build/apps/{newapp}/{newapp}-review.md (community research)
   ↓
4. Write build/apps/{newapp}/{newapp}-errors.md (placeholder)
   ↓
5. Update build/_app-catalog.md (add row with app + status)
   ↓
6. Update docs/README.md (update status table + quick links)
```

**Affected files:** 6 files  
**Dependency chain:** Step 1 → 2 → 3 → 5 → 6

---

### Scenario 2: Build App Image เสร็จ

```text
1. Update build/apps/{app}/{app}.md (header tag: [พร้อม build] → [built: standalone])
   ↓
2. Create/Update build/apps/{app}/{app}-build-manifest.md (latest build versions, NO IP/ID/secret)
   ↓
3. Update build/_app-catalog.md (status: "พร้อม build" → "built แล้ว", Manifest link)
   ↓
4. Update docs/README.md (if status table needs update)
   ↓
5. Create/Update build/apps/{app}/{app}-post-check.md (if new checks found)
   ↓
6. Update build/apps/{app}/{app}-errors.md (if errors occurred during build)
   ↓
7. Delete temp env file: build/tmp/{app}-build.env
```

**Affected files:** 5-7 files  
**Dependency chain:** Step 1 → 2 → 3 → 4, 5, 6 (parallel) → 7

---

### Scenario 2.5: Post-Test App Image หลังสร้าง VM ใหม่

```text
1. Read build/apps/{app}/{app}-post-check.md
   ↓
2. Ask user cleanup mode: no-cleanup หรือ cleanup-test-targets
   ↓
3. Run post-test checklist on VM from image
   ↓
4. Ask user/admin before optional final reboot gate; if approved, run reboot persistence test last
   ↓
5. If post-test passes: update post-check with new expected exceptions/checks if discovered
   ↓
6. If post-test finds app/source bug: fix source files + {app}.md/deploy guide
   ↓
7. Update {app}-errors.md if AI command failed or wrong instruction caused failure
   ↓
8. Update docs/AI-PIPELINE.md if the lesson is generic across apps
   ↓
9. Update build/_app-catalog.md/docs/README.md only if image status changes
```

**Affected files:** 1-6 files
**Dependency chain:** Step 1 → 2 → 3 → 4/5/6 → 7/8 as needed

---

### Scenario 3: พบ Mirror Issue ใหม่ + Fix

```text
1. Update docs/references/mirrors.md (new mirror info + verify)
   ↓
2. Update docs/AGENTS.md → mirror matrix section
   ↓
3. Update build/_guest-images.md (if guest image steps need mirror change)
   ↓
4. (Optional) Create problem/generic/mirror-{issue}.md (if reusable pattern)
   ↓
5. Update docs/README.md (if mirror section structure changed)
```

**Affected files:** 4-5 files  
**Dependency chain:** Step 1 → 2 → 3, 4 (parallel) → 5

---

## 🚨 Common Mistakes to Avoid

| Mistake | Impact | Fix |
|---|---|---|
| ✅ Update `build/_app-catalog.md` but forget `docs/README.md` | Status table out of sync | Always update both |
| ✅ Add new catalog category but forget `stack-components.md` | Cid has no reusable pattern | Add category pattern if based on real research/build |
| ✅ Change mirror but forget to update `docs/AGENTS.md` | Mirror matrix outdated | Update dependency immediately |
| ✅ Create new guest image but forget to update `docs/README.md` | Broken quick links | Update overview doc |
| ✅ Commit `build/tmp/*.env` to git | Secret leakage | Add to `.gitignore` + regenerate secrets |
| ✅ Update `build/apps/{app}/` but forget to update `build/_app-catalog.md` | Status out of sync | Check catalog after every build |
| ✅ Write build guide without testing = broken steps | User can't follow | Always test before publishing |

---

## 📌 Checklist Before Commit

```bash
# Before you git commit, ask yourself:

1. Did I update docs/README.md if I changed _catalog or _guest-images?     [ ] ✅
2. Did I update docs/AGENTS.md if I changed mirror or cloud-init?          [ ] ✅
3. Did I update build/_app-catalog.md if I created/updated app?            [ ] ✅
4. Did I check for .gitignore violations (build/tmp/, build/templates/)?   [ ] ✅
5. Did I delete temp env files (build/tmp/{app}-build.env)?                [ ] ✅
6. Did I verify all internal links work? (no broken paths)                  [ ] ✅
7. Did I test the guide before committing?                                 [ ] ✅
8. Did I record any new issues in problem/generic/?                        [ ] ✅

If any [ ] is empty → fix before commit!
```

---

## 📁 Paths vs Current Reality

> อ้างอิงโครงสร้างจริงของ repo — ถ้า path ยังไม่มีให้สร้างก่อนใช้

| Path | สถานะ | หมายเหตุ |
|---|---|---|
| `build/apps/{app}/` | ✅ มี | docker-platform, grafana-prometheus, n8n, nextcloud, odoo, woocommerce, wordpress |
| `build/_app-catalog.md` | ✅ มี | |
| `build/_guest-images.md` | ✅ มี | |
| `build/templates/` | ⚠️ มีแต่ว่างเปล่า | ยังไม่มี template ไฟล์ |
| `build/tmp/` | ❌ ยังไม่มี | ต้องสร้างเวลา build (gitignored) |
| `docs/examples/` | ⚠️ มีแต่ว่างเปล่า | ยังไม่มี build example ไฟล์ |
| `docs/references/` | ✅ มี | |
| `inventory/images/` | ❌ ยังไม่มี | ต้องสร้าง subdirectory `images/` ก่อนใช้ |
| `problem/generic/` | ✅ มี | nextcloud-docker-install-wizard-after-bootstrap.md, provider-interface-rename-cloud-init.md |
| `scripts/templates/` | ⚠️ มีแต่ว่างเปล่า | *(planned)* จะใส่ `*.sh.tmpl` build templates |
| `scripts/utils/` | ⚠️ มีแต่ว่างเปล่า | *(planned)* จะใส่ `*.py` pre-flight + validation |
| `scripts/README.md` | ❌ ยังไม่มี | *(planned)* scripts documentation |

---

## 🔗 File Location Reference

```text
Key files to check dependencies:

- agents/aerith.md                  ← Aerith (community research → review.md)
- agents/cid.md                     ← Cid (design → build guide + source)
- agents/cloud.md                   ← Cloud (build → verify → errors)
- agents/tifa.md                    ← Tifa (update docs → delete temp)
- agents/nanaki.md                  ← Nanaki (standalone — user trigger)
- docs/AGENT-SPEC.md                 ← Agent flow overview
- docs/AGENTS.md                      ← Common rules (all agents)
- build/_app-catalog.md               ← App status (dependency point #2)
- build/_guest-images.md              ← Guest image pipeline (dependency point #3)
- docs/references/mirrors.md           ← Mirror config (dependency point for OS builds)
- docs/references/cloud-init-scenarios.md ← Cloud-init (dependency point for cloud-init changes)
```

---

**Version:** 2026-06-16
**Purpose:** Help AI + users track which files must be updated together  
**Use:** Before every commit, consult this document
