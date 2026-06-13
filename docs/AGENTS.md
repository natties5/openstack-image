# กติกา AI — Image Domain

> กติกากลางที่ทุก agent ต้องปฏิบัติตาม
> กติกาเฉพาะของแต่ละ agent อยู่ใน `agents/` folder

---

## Agent Flow

```text
User: "สร้าง X image"
  │
  ▼
1. นักสืบ (Sleuth) ─── วิจัย community → เขียน {app}-review.md
  │                          → spec: agents/image-sleuth.md
  │                          → self-upgrade: queries + scoring
  ▼
2. วิศวกร (Engineer) ── ออกแบบ stack → เขียน {app}.md + source
  │                          → spec: agents/image-engineer.md
  │                          → self-upgrade: stack-components.md
  ▼
3. ช่างทำ (Maker) ────── SSH build → verify → บันทึก errors
  │                          → spec: agents/image-maker.md
  │                          → self-upgrade: mirror matrix + cloud-init
  ▼
4. นักทำเอกสาร (Scribe) ─ อัปเดต docs → ปิด loop → ลบ temp → จบ
                               → spec: agents/image-scribe.md
                               → self-upgrade: dependency map
```

ถ้า `{app}-review.md` มีอยู่และเนื้อหายังใช้ได้ → ข้ามนักสืบ เริ่มที่วิศวกรเลย

---

## โครงสร้าง 1 App = 1 Folder

```text
build/apps/<app>/
├── <app>.md              ← ไฟล์ 1: Build guide — self-contained, ทำตามขั้นตอน
├── <app>-review.md       ← ไฟล์ 2: Community research — ผู้ใช้ต้องการอะไร, best practice
├── <app>-errors.md       ← ไฟล์ 3: AI mistakes log — คำสั่ง AI ที่ผิด, แก้ยังไง
├── docker-compose.yml    ← source files (ถ้าใช้ Docker)
├── nginx/                ← (ถ้าใช้ proxy)
├── bootstrap.sh
├── bootstrap.service
├── README-<app>-image.txt
└── 99-<app>-image
```

**กฎ 3 ไฟล์:**
1. **`<app>.md`** — Self-contained: ผู้ใช้ copy คำสั่งไปรันบน VM ได้เลย ใช้ `cat > file << 'EOF'` สร้างไฟล์ ไม่ต้องพึ่ง source folder
2. **`<app>-review.md`** — Community research: ห้ามเป็น AI test scenario ตัวเอง ต้องอ้างอิงจาก community จริง (ดู `agents/image-sleuth.md`)
3. **`<app>-errors.md`** — Log คำสั่งผิดของ AI: เก็บทุกครั้งที่ AI ให้คำสั่งแล้วพัง

---

## Header Tag สถานะ

| Tag | ความหมาย |
|---|---|
| `[พร้อม build]` | ไฟล์ 1 ครบ, source อยู่, build ได้เลย |
| `[built: standalone]` | build เสร็จแล้ว standalone |
| `[มี review]` | มี community research ครบ |
| `[รอเติมเนื้อหา]` | ยังไม่พร้อม build — ต้องสร้าง source ก่อน |
| `[build ล้มเหลว]` | build ไม่ผ่าน — ดู errors.md |

---

## ลักษณะผู้ใช้

- **Keep package cache** — ห้าม `autoremove`/`clean` ใน Set 3, เก็บ packages ลด inter bandwidth หลัง deploy
- **เปลี่ยนทันที ไม่ backup** — `sed` จบ `grep` verify, ไม่ถาม confirm, ไม่ backup ไฟล์เก่า
- **ผู้ใช้ run เอง** — บน VM golden image โดยตรง, AI บอกแค่คำสั่ง ไม่ต้อง SSH เข้า
- **อัปเดตเอกสารทันที** — เมื่อพบ pattern ใหม่ระหว่างทำงาน → อัปเดต reference files เลย

---

## Standalone Domain Policy

- Image build เป็น **standalone** ไม่ผูก environment ใดๆ
- ห้ามบันทึก temp IP, server ID, floating IP, Glance ID ลง docs กลาง
- ห้ามเก็บ password, token, private key, credentials
- Temp env อยู่ใน `build/tmp/{app}-build.env` (gitignored, ลบหลังจบ)

---

## ภาษาและสไตล์

- ✅ ใช้ภาษาไทยเป็นหลัก
- ✅ คำศัพท์เทคนิคคงภาษาอังกฤษ (docker-compose, bootstrap, Glance, etc.)
- ✅ ระบุให้ชัด: "ทำสิ่งนี้ซึ่งผลลัพธ์คือ…"
- ❌ ห้ามสุ่ม version, checksum, URL, UUID, password
- ✅ ถ้าไม่แน่ใจ: ใช้ `—` และถาม "need to verify from [source]"

---

## Web Research Tools

| เครื่องมือ | ใช้เมื่อ |
|---|---|
| `webfetch` | เว็บปกติ — ไม่มี WAF |
| `websearch` | ค้นหาข้อมูลจาก search engine |
| `browser_navigate` (Playwright MCP) | เว็บมี Cloudflare, WAF, JS challenge — `webfetch` โดน 403 |

> Playwright MCP ต้องเปิด `--user-agent`, `--viewport-size`, `--ignore-https-errors` ใน `opencode.json` ดู `docs/references/stack-components.md` → `tool: playwright-cloudflare-bypass`

---

## เอกสารที่เกี่ยวข้อง

| เอกสาร | หน้าที่ |
|---|---|
| [`docs/AGENT-SPEC.md`](AGENT-SPEC.md) | Overview — agent flow + links + cross-ownership + self-upgrade |
| [`agents/image-sleuth.md`](../agents/image-sleuth.md) | นักสืบ — วิจัย + เขียน review |
| [`agents/image-engineer.md`](../agents/image-engineer.md) | วิศวกร — ออกแบบ + เขียน guide |
| [`agents/image-maker.md`](../agents/image-maker.md) | ช่างทำ — build + verify |
| [`agents/image-scribe.md`](../agents/image-scribe.md) | นักทำเอกสาร — อัปเดต docs + ปิด loop |
| [`docs/AI-PIPELINE.md`](AI-PIPELINE.md) | Build pipeline framework (ช่างทำใช้หลัก) |
| [`docs/DEPENDENCIES.md`](DEPENDENCIES.md) | ไฟล์ไหนต้องอัปเดตพร้อมกัน (นักทำเอกสารใช้หลัก) |
| [`docs/references/mirrors.md`](references/mirrors.md) | Mirror ไทย (ช่างทำใช้) |
| [`docs/references/stack-components.md`](references/stack-components.md) | Component catalog (วิศวกรใช้หลัก) |
| [`build/_app-catalog.md`](../build/_app-catalog.md) | สถานะ app ปัจจุบัน |

---

**Version:** 2026-06-12
**Domain:** openstack-image
