# กติกา AI — Image Domain

> กติกากลางที่ทุก agent ต้องปฏิบัติตาม
> กติกาเฉพาะของแต่ละ agent อยู่ใน `agents/` folder

---

## Agent Flow

### Pipeline Agents (4 ตัว)

```text
User: "สร้าง X image"
  │
  ▼
1. Aerith ─── วิจัย community → เขียน {app}-review.md
  │                          → spec: agents/aerith.md
  │                          → self-upgrade: queries + scoring
  ▼
2. Cid ── ออกแบบ stack → เขียน {app}.md + source
  │                          → spec: agents/cid.md
  │                          → self-upgrade: stack-components.md
  ▼
3. Cloud ────── SSH build → verify → บันทึก errors
  │                          → spec: agents/cloud.md
  │                          → self-upgrade: mirror matrix + cloud-init
  ▼
4. Tifa ─ อัปเดต docs → ปิด loop → ลบ temp → จบ
                                → spec: agents/tifa.md
                                → self-upgrade: dependency map
```

ถ้า `{app}-review.md` มีอยู่และเนื้อหายังใช้ได้ → ข้าม Aerith เริ่มที่ Cid เลย

### Standalone Agents

#### Nanaki

```text
User: "สร้างคู่มือ {app}"
  │
  ▼
Prerequisite: {app}.md header tag = [built: standalone]
  │
  ▼
Nanaki:
  1. อ่าน README + source + build guide + errors
  2. ถาม Cid (task subagent) — config, behavior → รอคำตอบ
  3. ถาม Cloud (task subagent) — build issues, pitfalls → รอคำตอบ
  4. สร้าง manual.html
  │
  ▼
ส่งต่อ → Tifa sync docs (รวม manual.html ใน catalog)
```

**Trigger:** User สั่ง "สร้างคู่มือ {app}"
**Spec:** `agents/nanaki.md`
**Self-upgrade:** template HTML + section patterns

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
├── 99-<app>-image
└── manual.html           ← คู่มือ end-user (Nanaki สร้าง — user trigger)
```

**กฎ 3 ไฟล์:**
1. **`<app>.md`** — Self-contained: ผู้ใช้ copy คำสั่งไปรันบน VM ได้เลย ใช้ `cat > file << 'EOF'` สร้างไฟล์ ไม่ต้องพึ่ง source folder
2. **`<app>-review.md`** — Community research: ห้ามเป็น AI test scenario ตัวเอง ต้องอ้างอิงจาก community จริง (ดู `agents/aerith.md`)
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

## Build Manifest Policy

หลัง build สำเร็จให้เก็บประวัติ version แบบ non-secret ที่ `build/apps/{app}/{app}-build-manifest.md` โดยใช้ template กลาง `build/_build-manifest-template.md`

- Manifest คือประวัติ golden image build ล่าสุด + changelog สั้นๆ ไม่ใช่ runtime inventory
- เก็บเฉพาะ App, status, build date `YYYY-MM-DD`, Base OS เช่น `Ubuntu 26.04`, Docker stack package versions แบบ minimal, runtime tool versions, container image tag + digest, build notes
- ห้ามเก็บ image name, Glance ID, server ID, floating IP, VM IP, hostname, OpenStack project/user/auth context, password, token, private key, runtime credential
- ถ้า build ล้มเหลว ไม่ต้องสร้าง manifest ใหม่ ให้บันทึกใน `{app}-errors.md` อย่างเดียว
- Post-test VM จาก image ไม่แก้ manifest เพราะ manifest เป็นข้อมูล golden-image build เท่านั้น

---

## Post-Test Policy

Post-test คือการตรวจ VM ใหม่ที่สร้างจาก image หลัง capture/deploy แล้ว ไม่ใช่ pre-capture gate ของ golden-image VM

- ก่อน post-test ต้องถาม cleanup mode ทุกครั้ง: `no-cleanup` หรือ `cleanup-test-targets`
- `no-cleanup` คือทิ้ง containers, volumes, `.env`, README, marker, logs, test targets และ password state ไว้ให้ user/admin ตรวจต่อ
- `cleanup-test-targets` คือ cleanup เฉพาะ target ทดสอบที่ checklist เพิ่ม แล้ว reload app
- Reboot test เป็น optional final gate ต้องถาม user/admin ก่อนทุกครั้ง และต้องทำเป็นขั้นตอนสุดท้ายเท่านั้น
- ถ้า post-test เจอ bug จริง ให้แก้ source/guide/docs ตาม root cause ในรอบเดียวกัน ไม่ใช่สรุปอย่างเดียว
- ถ้า bug เป็น pattern กลาง ให้ update `docs/AI-PIPELINE.md`, `docs/DEPENDENCIES.md`, และ agent spec ที่เกี่ยวข้อง
- ทุก app post-check ที่พร้อมใช้งานจริงควรมี overview checklist table, pipeline scope, failure routing, cleanup/no-cleanup policy, expected exceptions
- ห้ามบันทึก runtime password, floating IP, server ID, image ID หรือ credentials ลง repo

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

> Playwright MCP ต้องเปิด `--user-agent`, `--viewport-size`, `--ignore-https-errors` ใน config ของ tool ดู `docs/references/stack-components.md` → `tool: playwright-cloudflare-bypass`

---

## เอกสารที่เกี่ยวข้อง

| เอกสาร | หน้าที่ |
|---|---|
| [`docs/AGENT-SPEC.md`](AGENT-SPEC.md) | Overview — agent flow + links + cross-ownership + self-upgrade |
| [`agents/aerith.md`](../agents/aerith.md) | Aerith — วิจัย + เขียน review |
| [`agents/cid.md`](../agents/cid.md) | Cid — ออกแบบ + เขียน guide |
| [`agents/cloud.md`](../agents/cloud.md) | Cloud — build + verify |
| [`agents/tifa.md`](../agents/tifa.md) | Tifa — อัปเดต docs + ปิด loop |
| [`agents/nanaki.md`](../agents/nanaki.md) | Nanaki — สร้างคู่มือ end-user HTML (standalone — user trigger) |
| [`docs/AI-PIPELINE.md`](AI-PIPELINE.md) | Build pipeline framework (Cloud ใช้หลัก) |
| [`docs/DEPENDENCIES.md`](DEPENDENCIES.md) | ไฟล์ไหนต้องอัปเดตพร้อมกัน (Tifa ใช้หลัก) |
| [`docs/references/mirrors.md`](references/mirrors.md) | Mirror ไทย (Cloud ใช้) |
| [`docs/references/stack-components.md`](references/stack-components.md) | Component catalog (Cid ใช้หลัก) |
| [`build/_app-catalog.md`](../build/_app-catalog.md) | สถานะ app ปัจจุบัน |

---

**Version:** 2026-06-16
**Domain:** openstack-image
