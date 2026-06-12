# Dependency Map — File Dependencies

> When you change File A, which files must you update? This document maps those dependencies.

---

## 📊 Dependency Matrix

| If You Change | Then Update | Why | Priority |
|---|---|---|---|
| `build/_guest-images.md` (guest image status) | `docs/README.md` | Update status table | HIGH |
| | `docs/AGENTS.md` (mirror matrix section) | If new OS or mirror discovered | MEDIUM |
| `build/_app-catalog.md` (app status) | `docs/README.md` | Update status table | HIGH |
| `build/apps/{app}/{app}.md` (build guide) | `build/_app-catalog.md` | Update header tag (e.g., `[พร้อม build]`) | HIGH |
| | `docs/examples/build-{app}.md` | If new build example needed | MEDIUM |
| `build/apps/{app}/{app}-review.md` | `build/_app-catalog.md` | Mark as "has review" if new | MEDIUM |
| `docs/references/mirrors.md` (mirror config) | `docs/AGENTS.md` (mirror matrix section) | Update with new mirror info | HIGH |
| | `build/_guest-images.md` (if mirror changed) | Update guest image build steps | MEDIUM |
| | `docs/README.md` (if mirror structure changed) | Update mirror reference link | LOW |
| `docs/references/cloud-init-scenarios.md` (cloud-init template) | `docs/AGENTS.md` (cloud-init behavior section) | If new behavior discovered | MEDIUM |
| | `build/_guest-images.md` (if cloud-init changed) | Update cloud-init usage in guest build | MEDIUM |
| | `docs/README.md` (if structure changed) | Update cloud-init reference link | LOW |
| `problem/generic/{issue}.md` (new generic issue) | `docs/README.md` | Add to troubleshooting section | LOW |
| | (none auto-required) | Update when deploying to cluster | - |
| **Cluster-specific files** | | | |
| `clusters/{name}/inventory/vm.md` | `clusters/{name}/README.md` | Update VM count, status table | HIGH |
| | (build docs NOT affected) | Keep image build standalone | - |
| `clusters/{name}/problem/{issue}.md` | `clusters/{name}/README.md` | Reference incident log | MEDIUM |
| **Folder structure changes** | | | |
| Rename folder or create new domain | `docs/ARCHITECTURE.md` | Update folder tree | HIGH |
| | `docs/README.md` | Update quick links | HIGH |
| | `.gitignore` | If new temp file types | MEDIUM |

---

## 🔄 Reverse Dependency (What uses this file?)

| File | Used By | Purpose |
|---|---|---|
| `docs/README.md` | **Entry point** — links to all other docs | Domain overview |
| `docs/AGENT-SPEC.md` | AI agents | Role + responsibilities |
| `docs/AGENTS.md` | AI agents | Image-specific rules |
| `docs/AI-PIPELINE.md` | Build automation | Pipeline framework |
| `docs/references/mirrors.md` | `docs/AGENTS.md` + `build/_guest-images.md` | Mirror selection per OS |
| `docs/references/cloud-init-scenarios.md` | `build/_guest-images.md` + app guides | Cloud-init templates |
| `build/_guest-images.md` | Build automation | Guest image pipeline |
| `build/_app-catalog.md` | `docs/README.md` + AI agents | App status overview |
| `build/apps/{app}/{app}.md` | User + AI agents | Per-app build guide |
| `build/apps/{app}/{app}-review.md` | User + AI agents | Feature selection |
| `build/apps/{app}/{app}-errors.md` | AI agents | Error learning log |
| `scripts/templates/*.sh.tmpl` | User + `Makefile` | Build automation |
| `scripts/utils/*.py` | Build automation | Pre-flight + validation |
| `Makefile` | User | Quick automation targets |
| `CONTRIBUTING.md` | User + developer | Workflow guide |

---

## 🎯 Update Workflow

### Scenario 1: สร้าง App Image ใหม่

```
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
   ↓
7. (Optional) Create docs/examples/build-{newapp}.md (if needed)
```

**Affected files:** 7 files  
**Dependency chain:** Step 1 → 2 → 3 → 5 → 6

---

### Scenario 2: Build App Image เสร็จ

```
1. Update build/apps/{app}/{app}.md (header tag: [พร้อม build] → [built: ...])
   ↓
2. Update build/_app-catalog.md (status: "พร้อม build" → "built แล้ว")
   ↓
3. Update docs/README.md (if status table needs update)
   ↓
4. Create/Update build/apps/{app}/{app}-post-check.md (if new checks found)
   ↓
5. Update build/apps/{app}/{app}-errors.md (if errors occurred during build)
   ↓
6. Delete temp env file: image/tmp/{app}-build.env
   ↓
7. Update inventory/images/*.env (generic build metadata, NO IP/ID/secret)
```

**Affected files:** 5-7 files  
**Dependency chain:** Step 1 → 2 → 3, 4, 5 (parallel) → 7

---

### Scenario 3: พบ Mirror Issue ใหม่ + Fix

```
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

### Scenario 4: Build บน Cluster จริง

```
1. Pre-flight: Read clusters/{name}/inventory/vm.md + cluster/.env
   ↓
2. Run build per build/apps/{app}/{app}.md
   ↓
3. Update clusters/{name}/inventory/vm.md (add image name + Glance ID + VM info)
   ↓
4. Update clusters/{name}/README.md (add service to service table)
   ↓
5. (Optional) Create clusters/{name}/problem/{date}-{issue}.md (if issues found)
   ↓
6. Update build/_app-catalog.md (add cluster: {name})
   ↓
7. Update build/apps/{app}/{app}.md (header tag: [built: {cluster}])
   ↓
8. NOTE: image/build/* docs stay STANDALONE (no IP/ID/secret)
```

**Affected files:** 5-7 files  
**Dependency chain:** 1 → 2 → 3 → 4 → 6 → 7  
**Important:** Cluster files are separate from build docs (keep standalone policy)

---

## 🚨 Common Mistakes to Avoid

| Mistake | Impact | Fix |
|---|---|---|
| ✅ Update `build/_app-catalog.md` but forget `docs/README.md` | Status table out of sync | Always update both |
| ✅ Change mirror but forget to update `docs/AGENTS.md` | Mirror matrix outdated | Update dependency immediately |
| ✅ Create new guest image but forget to update `docs/README.md` | Broken quick links | Update overview doc |
| ✅ Commit `image/tmp/*.env` to git | Secret leakage | Add to `.gitignore` + regenerate secrets |
| ✅ Update `build/apps/{app}/` but forget to update `build/_app-catalog.md` | Status out of sync | Check catalog after every build |
| ✅ Write build guide without testing = broken steps | User can't follow | Always test before publishing |

---

## 📌 Checklist Before Commit

```bash
# Before you git commit, ask yourself:

1. Did I update docs/README.md if I changed _catalog or _guest-images?     [ ] ✅
2. Did I update docs/AGENTS.md if I changed mirror or cloud-init?          [ ] ✅
3. Did I update build/_app-catalog.md if I created/updated app?            [ ] ✅
4. Did I check for .gitignore violations (image/tmp/, build/temp/)?        [ ] ✅
5. Did I delete temp env files (image/tmp/{app}-build.env)?                [ ] ✅
6. Did I verify all internal links work? (no broken paths)                  [ ] ✅
7. Did I test the guide before committing?                                 [ ] ✅
8. Did I record any new issues in problem/generic/?                        [ ] ✅

If any [ ] is empty → fix before commit!
```

---

## 🔗 File Location Reference

```text
Key files to check dependencies:

- docs/README.md                    ← Central overview (many dependencies point here)
- build/_app-catalog.md             ← App status (dependency point #2)
- build/_guest-images.md            ← Guest image pipeline (dependency point #3)
- docs/references/mirrors.md        ← Mirror config (dependency point for OS builds)
- docs/references/cloud-init-scenarios.md ← Cloud-init (dependency point for cloud-init changes)
```

---

**Version:** 2026-06-12  
**Purpose:** Help AI + users track which files must be updated together  
**Use:** Before every commit, consult this document
