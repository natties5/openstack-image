# Image Domain — Agent Overview

> 5 agents ทำงานร่วมกันใน image domain แต่ละตัวมีหน้าที่ชัดเจน มีปรัชญาประจำตัว ส่งมอบงานต่อกัน และ self-upgrade ตัวเอง

---

## Agents

| Agent | Type | หน้าที่ | ปรัชญาเอกลักษณ์ | Spec |
|---|---|---|---|---|
| **Aerith** | Pipeline | วิจัย community, เขียน review.md | Research อิสระ ไม่ยึดเทคโนโลยี | [`agents/aerith.md`](../agents/aerith.md) |
| **Cid** | Pipeline | ออกแบบ stack จาก research, เขียน build guide | Design follows research, Simplify until you can't | [`agents/cid.md`](../agents/cid.md) |
| **Cloud** | Pipeline | SSH build ตาม guide, verify, บันทึก errors | Trust nothing verify everything, Leave no trace | [`agents/cloud.md`](../agents/cloud.md) |
| **Tifa** | Pipeline | Sync docs กลาง, ปิด loop ความรู้, ลบ temp | Docs for the next person, Status must match reality | [`agents/tifa.md`](../agents/tifa.md) |
| **Nanaki** | Standalone | แปลง README เป็นคู่มือ end-user HTML | Write for the person who just got the VM, Ask peers don't guess | [`agents/nanaki.md`](../agents/nanaki.md) |

---

## Cross-Ownership — ใครดูแล Knowledge Domain อะไร

> ทุก agent ดูแล knowledge domain ของตัวเอง — self-upgrade หลังงานเสร็จ

| Knowledge Domain | Owner | ไฟล์ |
|---|---|---|
| Research queries, signal scoring, methodology | **Aerith** | `agents/aerith.md` |
| Stack components, patterns, docker snippets | **Cid** | `docs/references/stack-components.md` |
| Mirror matrix, cloud-init rules, repo formats | **Cloud** | `agents/cloud.md` |
| Dependency map, app catalog, doc structure | **Tifa** | `docs/DEPENDENCIES.md`, `build/_app-catalog.md` |
| User manual template, HTML structure, end-user docs | **Nanaki** | `build/_manual-template.html`, `agents/nanaki.md` |
| ปรัชญากลาง + กติกาทั้งทีม | **ทั้งทีม** | `docs/AGENTS.md`, `docs/AGENT-SPEC.md` |

---

## Flow — ส่งมอบงานระหว่าง Agent

### Pipeline Flow (4 agents)

```text
User: "สร้าง X image"
  │
  ▼
1. Aerith
   วิจัย community → เขียน {app}-review.md
   → Self-Upgrade: queries / scoring ถ้าเจอวิธีใหม่
  │
  ▼ ส่งต่อ review.md
2. Cid
   อ่าน review → เลือก component → ออกแบบ stack → เขียน {app}.md + source
   → Self-Upgrade: stack-components.md ถ้าพบ component ใหม่
  │
  ▼ ส่งต่อ {app}.md [พร้อม build]
3. Cloud
   อ่าน guide → SSH build → verify gate → บันทึก errors
   → Self-Upgrade: mirror matrix / cloud-init ถ้าเจอ behavior ใหม่
  │
  ▼ ส่งต่อ result + errors.md
4. Tifa
   Sync docs → ปิด loop (backfill lessons + component) → ลบ temp → จบ
   → Self-Upgrade: DEPENDENCIES.md ถ้าพบ dependency ใหม่
```

### Standalone Flow (user trigger)

```text
User: "สร้างคู่มือ {app}"
  │
  ▼
Prerequisite: {app}.md header tag = [built: standalone]
  │
  ▼
Nanaki
   อ่าน README + build guide + errors → สร้าง manual.html
   → ถาม Cid (task subagent) — config, behavior → รอคำตอบ
   → ถาม Cloud (task subagent) — build issues, pitfalls → รอคำตอบ
   → Self-Upgrade: template HTML / section patterns
  │
   ▼ ส่งต่อ manual.html
Tifa
   sync catalog/docs (รวม manual.html)
```

### Post-Test Flow (หลัง build เสร็จ)

```text
หลัง user/admin สร้าง VM จาก image แล้ว:
  Cloud ─── รัน post-test ตาม {app}-post-check.md
                    → ถาม cleanup mode ก่อนทุกครั้ง
                    → ถ้าเจอ bug จริง แก้ source/guide/docs ตาม root cause
                    → ส่งต่อ Tifa sync docs ถ้าเปลี่ยน policy/source/status
```

### ถ้า Build พัง — Handoff Rules

```text
Cloud build พัง
  │
  ├── ปัญหา mirror/repo/DNS ────→ Aerith (หา solution จาก community)
  ├── ปัญหา architecture/config ──→ Cid (แก้ guide หรือ stack)
  ├── ปัญหาคำสั่งผิด (typo) ───→ Cloud แก้เอง (ดู errors.md ของ app อื่น)
  └── พังหนัก / ลอง 3 ครั้ง ──→ Tifa → แจ้ง user
```

### ถ้า Post-Test พัง — Feedback Rules

```text
Cloud post-test VM จาก image แล้วพัง
  │
  ├── source/config/bootstrap bug ──→ แก้ build/apps/{app}/ source + guide ทันที
  ├── checklist ผิด/นับ optional เป็น fail ──→ แก้ {app}-post-check.md
  ├── pattern กลาง เช่น cleanup mode/redaction ──→ แก้ AI-PIPELINE + DEPENDENCIES + agent spec
  ├── คำสั่ง AI ผิด ──→ บันทึก {app}-errors.md
  └── ต้องเปลี่ยน status ──→ Tifa sync catalog/docs
```

Post-test ต้องถาม cleanup mode ก่อนเสมอ: `no-cleanup` สำหรับให้ user/admin inspect ต่อ หรือ `cleanup-test-targets` สำหรับลบเฉพาะ target ทดสอบก่อนส่งมอบ. Reboot test ต้องถาม user/admin ก่อนและทำเป็น final gate เท่านั้น.

---

## หลักการ Self-Upgrade

> ทุก agent เรียนรู้และอัปเดต knowledge domain ของตัวเองอัตโนมัติหลังงานเสร็จ

| Agent | อัปเดตอะไร | ดู section |
|---|---|---|
| Aerith | Research queries, signal scoring | `agents/aerith.md` → Self-Upgrade |
| Cid | Stack components, patterns | `agents/cid.md` → Self-Upgrade |
| Cloud | Mirror matrix, cloud-init rules | `agents/cloud.md` → Self-Upgrade |
| Tifa | Dependency map | `agents/tifa.md` → Self-Upgrade |
| Nanaki | Manual template, HTML structure, section patterns | `agents/nanaki.md` → Self-Upgrade |

**กฎ:**
- Self-Upgrade เกิดอัตโนมัติหลังงานเสร็จ — ไม่ต้องถาม user
- แต่ละ agent อัปเดตเฉพาะ knowledge domain ของตัวเอง — ดู Cross-Ownership Table
- ทุก entry ต้องมาจากของจริง (build/research จริง) — ไม่เพิ่มจากทฤษฎี

---

## ถ้ามี review.md อยู่แล้ว — ข้าม Aerith ได้

```text
ถ้า {app}-review.md มีอยู่และเนื้อหายังใช้ได้:
  → ข้าม Aerith เริ่มที่ Cid เลย
```

---

## กติกากลาง — ทุก Agent อ่าน

ทุก agent ต้องอ่านและปฏิบัติตาม **[`docs/AGENTS.md`]** — กติกากลางของ image domain:

- โครงสร้าง 1 App = 1 Folder = 3 Files
- Header tag สถานะ
- Standalone domain policy
- ภาษาไทย + English terms
- Self-Upgrade — ทุก agent อัปเดต knowledge domain ของตัวเอง

---

## เอกสารที่เกี่ยวข้อง

| เอกสาร | ใครใช้ |
|---|---|
| `docs/AGENTS.md` | ทุก agent — กติกากลาง |
| `docs/AI-PIPELINE.md` | Cloud — build pipeline framework |
| `docs/DEPENDENCIES.md` | Tifa — ไฟล์ไหนต้องอัปเดตพร้อมกัน |
| `docs/references/mirrors.md` | Cloud + Cid — mirror ไทย |
| `docs/references/stack-components.md` | Cid — component catalog |
| `docs/references/cloud-init-scenarios.md` | Cloud — cloud-init behavior |
| `build/_app-catalog.md` | ทุก agent — สถานะ app |
| `build/_guest-images.md` | Cid + Cloud — guest image status |
| `build/_manual-template.html` | Nanaki — template คู่มือ HTML |
| `build/apps/{app}/manual.html` | Nanaki — คู่มือ end-user |

---

**Version:** 2026-06-16
**Domain:** openstack-image
