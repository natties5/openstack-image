# Image Domain — Agent Overview

> 4 agents ทำงานร่วมกันใน image domain แต่ละตัวมีหน้าที่ชัดเจน ส่งมอบงานต่อกัน

---

## Agents

| Agent | ไทย | หน้าที่ | Spec |
|---|---|---|---|
| **Sleuth** | นักสืบ | วิจัย community, เขียน review.md | [`agents/image-sleuth.md`](../agents/image-sleuth.md) |
| **Engineer** | วิศวกร | ออกแบบ app, เขียน build guide + source | [`agents/image-engineer.md`](../agents/image-engineer.md) |
| **Maker** | ช่างทำ | SSH build, verify, บันทึก errors | [`agents/image-maker.md`](../agents/image-maker.md) |
| **Scribe** | นักทำเอกสาร | อัปเดต docs, ลบ temp, เช็ค dependency | [`agents/image-scribe.md`](../agents/image-scribe.md) |

---

## Flow — ส่งมอบงานระหว่าง Agent

```text
User: "สร้าง X image"
  │
  ▼
1. นักสืบ (Sleuth)
   วิจัย community → เขียน {app}-review.md
  │
  ▼ ส่งต่อ review.md
2. วิศวกร (Engineer)
   อ่าน review → ออกแบบ stack → เขียน {app}.md + source files
  │
  ▼ ส่งต่อ {app}.md [พร้อม build]
3. ช่างทำ (Maker)
   อ่าน guide → SSH build → verify 6 ข้อ → บันทึก errors
  │
  ▼ ส่งต่อ result + errors.md
4. นักทำเอกสาร (Scribe)
   อัปเดต _app-catalog.md + header tag + ลบ temp → จบ
```

### ถ้า Build พัง — Handoff Rules

```text
ช่างทำ build พัง
  │
  ├── ปัญหา mirror/repo/DNS ────→ นักสืบ (หา solution จาก community)
  ├── ปัญหา architecture/config ──→ วิศวกร (แก้ guide / docker-compose)
  ├── ปัญหาคำสั่งผิด (typo) ───→ ช่างทำ แก้เอง (ดู errors.md ของ app อื่น)
  └── พังหนัก / ลอง 3 ครั้ง ──→ นักทำเอกสาร → แจ้ง user
```

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

กติกาเฉพาะของแต่ละ agent อยู่ใน spec ของแต่ละตัว

---

## เอกสารที่เกี่ยวข้อง

| เอกสาร | ใครใช้ |
|---|---|
| `docs/AGENTS.md` | ทุก agent — กติกากลาง |
| `docs/AI-PIPELINE.md` | ช่างทำ — build pipeline framework |
| `docs/DEPENDENCIES.md` | นักทำเอกสาร — ไฟล์ไหนต้องอัปเดตพร้อมกัน |
| `docs/references/mirrors.md` | ช่างทำ + วิศวกร — mirror ไทย |
| `docs/references/cloud-init-scenarios.md` | ช่างทำ — cloud-init behavior |
| `build/_app-catalog.md` | ทุก agent — สถานะ app |
| `build/_guest-images.md` | วิศวกร + ช่างทำ — guest image status |

---

**Version:** 2026-06-12
**Domain:** openstack-image