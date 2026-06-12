# Image Domain — Agent Overview

> 4 agents ทำงานร่วมกันใน image domain แต่ละตัวมีหน้าที่ชัดเจน มีปรัชญาประจำตัว ส่งมอบงานต่อกัน และ self-upgrade ตัวเอง

---

## Agents

| Agent | ไทย | หน้าที่ | ปรัชญาเอกลักษณ์ | Spec |
|---|---|---|---|---|
| **Sleuth** | นักสืบ | วิจัย community, เขียน review.md | Research อิสระ ไม่ยึดเทคโนโลยี | [`agents/image-sleuth.md`](../agents/image-sleuth.md) |
| **Engineer** | วิศวกร | ออกแบบ stack จาก research, เขียน build guide | Design follows research, Simplify until you can't | [`agents/image-engineer.md`](../agents/image-engineer.md) |
| **Maker** | ช่างทำ | SSH build ตาม guide, verify, บันทึก errors | Trust nothing verify everything, Leave no trace | [`agents/image-maker.md`](../agents/image-maker.md) |
| **Scribe** | นักทำเอกสาร | Sync docs กลาง, ปิด loop ความรู้, ลบ temp | Docs for the next person, Status must match reality | [`agents/image-scribe.md`](../agents/image-scribe.md) |

---

## Cross-Ownership — ใครดูแล Knowledge Domain อะไร

> ทุก agent ดูแล knowledge domain ของตัวเอง — self-upgrade หลังงานเสร็จ

| Knowledge Domain | Owner | ไฟล์ |
|---|---|---|
| Research queries, signal scoring, methodology | **Sleuth** | `agents/image-sleuth.md` |
| Stack components, patterns, docker snippets | **Engineer** | `docs/references/stack-components.md` |
| Mirror matrix, cloud-init rules, repo formats | **Maker** | `agents/image-maker.md` |
| Dependency map, app catalog, doc structure | **Scribe** | `docs/DEPENDENCIES.md`, `build/_app-catalog.md` |
| ปรัชญากลาง + กติกาทั้งทีม | **ทั้งทีม** | `docs/AGENTS.md`, `docs/AGENT-SPEC.md` |

---

## Flow — ส่งมอบงานระหว่าง Agent

```text
User: "สร้าง X image"
  │
  ▼
1. นักสืบ (Sleuth)
   วิจัย community → เขียน {app}-review.md
   → Self-Upgrade: queries / scoring ถ้าเจอวิธีใหม่
  │
  ▼ ส่งต่อ review.md
2. วิศวกร (Engineer)
   อ่าน review → เลือก component → ออกแบบ stack → เขียน {app}.md + source
   → Self-Upgrade: stack-components.md ถ้าพบ component ใหม่
  │
  ▼ ส่งต่อ {app}.md [พร้อม build]
3. ช่างทำ (Maker)
   อ่าน guide → SSH build → verify gate → บันทึก errors
   → Self-Upgrade: mirror matrix / cloud-init ถ้าเจอ behavior ใหม่
  │
  ▼ ส่งต่อ result + errors.md
4. นักทำเอกสาร (Scribe)
   Sync docs → ปิด loop (backfill lessons + component) → ลบ temp → จบ
   → Self-Upgrade: DEPENDENCIES.md ถ้าพบ dependency ใหม่
```

### ถ้า Build พัง — Handoff Rules

```text
ช่างทำ build พัง
  │
  ├── ปัญหา mirror/repo/DNS ────→ นักสืบ (หา solution จาก community)
  ├── ปัญหา architecture/config ──→ วิศวกร (แก้ guide หรือ stack)
  ├── ปัญหาคำสั่งผิด (typo) ───→ ช่างทำ แก้เอง (ดู errors.md ของ app อื่น)
  └── พังหนัก / ลอง 3 ครั้ง ──→ นักทำเอกสาร → แจ้ง user
```

---

## หลักการ Self-Upgrade

> ทุก agent เรียนรู้และอัปเดต knowledge domain ของตัวเองอัตโนมัติหลังงานเสร็จ

| Agent | อัปเดตอะไร | ดู section |
|---|---|---|
| Sleuth | Research queries, signal scoring | `agents/image-sleuth.md` → Self-Upgrade |
| Engineer | Stack components, patterns | `agents/image-engineer.md` → Self-Upgrade |
| Maker | Mirror matrix, cloud-init rules | `agents/image-maker.md` → Self-Upgrade |
| Scribe | Dependency map | `agents/image-scribe.md` → Self-Upgrade |

**กฎ:**
- Self-Upgrade เกิดอัตโนมัติหลังงานเสร็จ — ไม่ต้องถาม user
- แต่ละ agent อัปเดตเฉพาะ knowledge domain ของตัวเอง — ดู Cross-Ownership Table
- ทุก entry ต้องมาจากของจริง (build/research จริง) — ไม่เพิ่มจากทฤษฎี

---

## ถ้ามี review.md อยู่แล้ว — ข้ามนักสืบได้

```text
ถ้า {app}-review.md มีอยู่และเนื้อหายังใช้ได้:
  → ข้ามนักสืบ เริ่มที่วิศวกรเลย
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
| `docs/AI-PIPELINE.md` | ช่างทำ — build pipeline framework |
| `docs/DEPENDENCIES.md` | นักทำเอกสาร — ไฟล์ไหนต้องอัปเดตพร้อมกัน |
| `docs/references/mirrors.md` | ช่างทำ + วิศวกร — mirror ไทย |
| `docs/references/stack-components.md` | วิศวกร — component catalog |
| `docs/references/cloud-init-scenarios.md` | ช่างทำ — cloud-init behavior |
| `build/_app-catalog.md` | ทุก agent — สถานะ app |
| `build/_guest-images.md` | วิศวกร + ช่างทำ — guest image status |

---

**Version:** 2026-06-12
**Domain:** openstack-image
