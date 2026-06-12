# กติกา AI — Image Domain

## Workflow: สร้าง App Image ใหม่

เมื่อได้รับคำสั่งให้สร้างหรือปรับปรุง app image ให้ทำตามลำดับนี้:

```text
1. User บอก requirement
   → AI ประมวลสิ่งที่ user ต้องการ → แนะนำวิธีที่ง่ายที่สุดที่มีโอกาสพังน้อยที่สุด

2. AI สร้าง <app>-review.md (community research)
   → ค้นหา internet (Reddit, StackOverflow, Discourse, GitHub, Hacker News):
      - มือใหม่ใช้ app นี้ยังไง? ปัญหาอะไรบ่อย?
      - มือกลาง/สูงต้องการ feature อะไร?
      - best practice จาก community
   → สรุป: แนะนำ feature A, B, C → ถาม user เลือก

3. User เลือก feature
   → AI สร้าง <app>.md (build guide) — ทำตามขั้นตอนอย่างเดียว ครบ self-contained

4. ระหว่าง build → ถ้า AI สั่งผิด
   → บันทึกใน <app>-errors.md (AI mistakes log)

5. หลัง build เสร็จ → user ทดลองใช้
   → ถ้ามี feedback จริง → อัปเดต <app>-review.md เพิ่ม

6. Capture image → อัปเดต status ใน `_app-catalog.md` (app) หรือ `_guest-images.md` (guest)
   → ปัญหา infrastructure → บันทึกใน problem/
```

## AI Build Pipeline

> **สำหรับ build บน VM จริง** — ดู `AI-PIPELINE.md` สำหรับ framework ครบ

เมื่อได้คำสั่ง "build [app] image" บน VM จริง:
1. อ่าน `AI-PIPELINE.md` → Part 1: Reusable Framework
2. อ่าน `<app>.md` → Part 2: Per-App Checklist
3. รัน build ตาม framework + specific steps
4. อัปเดต docs ตาม dependency map

## โครงสร้าง 1 App = 1 Folder

```text
build/<app>/
├── <app>.md              ← ไฟล์ 1: Build guide — self-contained, ทำตามขั้นตอน
├── <app>-review.md       ← ไฟล์ 2: Community research — ผู้ใช้ต้องการอะไร, best practice
├── <app>-errors.md       ← ไฟล์ 3: AI mistakes log — คำสั่ง AI ที่ผิด, แก้ยังไง
├── docker-compose.yml    ← source files (ถ้ามี)
├── nginx/
├── bootstrap.sh
├── bootstrap.service
├── README-<app>-image.txt
└── 99-<app>-image
```

**กฎ:**
- ไฟล์ 1 (`<app>.md`) — self-contained: ผู้ใช้ copy คำสั่งไปรันบน VM ได้เลย ใช้ `cat > file << 'EOF'` สร้างไฟล์ ไม่ต้องพึ่ง source folder
- ไฟล์ 2 (`<app>-review.md`) — community research: ห้ามเป็น AI test scenario ตัวเอง ต้องอ้างอิงจาก community จริง
- ไฟล์ 3 (`<app>-errors.md`) — log คำสั่งผิดของ AI: เก็บทุกครั้งที่ AI ให้คำสั่งแล้วพัง
- Source folder (`build/<app>/`) — ใช้ reference: agent อ่านไฟล์แยกได้, ใช้ตรวจสอบตอน build

## Header Tag สถานะ

| Tag | ความหมาย |
|---|---|
| `[พร้อม build]` | ไฟล์ 1 ครบ, source อยู่, build ได้เลย |
| `[built: {cluster}]` | build เสร็จแล้วบน cluster นั้น และต้องมี inventory/build log จริงรองรับ |
| `[มี review]` | มี community research ครบ |
| `[รอเติมเนื้อหา]` | ยังไม่พร้อม build — ต้องสร้าง source ก่อน |

## ลักษณะผู้ใช้

- **Keep package cache** — ห้าม `autoremove`/`clean` ใน Set 3, เก็บ packages ลด inter bandwidth หลัง deploy
- **เปลี่ยนทันที ไม่ backup** — `sed` จบ `grep` verify, ไม่ถาม confirm, ไม่ backup ไฟล์เก่า
- **ผู้ใช้ run เอง** — บน VM golden image โดยตรง, AI บอกแค่คำสั่ง ไม่ต้อง SSH เข้า
- **อัปเดตเอกสารทันที** — เมื่อพบ pattern ใหม่ระหว่างทำงาน → อัปเดต reference files เลย

### ไฟล์ review ห้ามเป็น AI test scenario

ไฟล์ `<app>-review.md` คือ **community research** — ห้ามเขียนจากมุม AI ทดลองใช้เอง ต้อง:
- ค้นหาจาก Reddit, StackOverflow, GitHub issues, Discourse, Hacker News, official docs
- อ้างอิงสิ่งที่ผู้ใช้จริงต้องการและปัญหาที่เจอ
- แบ่งกลุ่ม: Beginner / Intermediate / Advanced
- สรุป recommendation ให้ user เลือก

**AI test scenario (ของเก่า) ให้เก็บแยกต่างหาก** — ไม่ปนกับ community research

### ไฟล์ review ห้ามมี "Next Image"

ไฟล์ `<app>-review.md` คือ completed review — ห้ามมี section ที่บอกว่า "app ต่อไปคืออะไร" เพราะ:
- ทำให้ AI งงว่า review ยังไม่เสร็จ
- ถ้าจะบอก app ต่อไป → ใส่ใน `_app-catalog.md` หรือ planning document เท่านั้น

### ทุก Step ที่สร้างไฟล์ต้องมี Comment + คำสั่งจริง

**รูปแบบ:**
```bash
# 4.1 docker-compose.yml — Docker Compose definition สำหรับ 3 services (db, wordpress, nginx)
cat > /opt/wordpress/docker-compose.yml << 'EOF'
services:
  db:
    image: mariadb:lts
    ...
EOF
```

**ข้อกำหนด:**
- **Comment บนบรรทัด** — บอกว่าไฟล์อะไร, ทำหน้าที่อะไร, มีกี่ services
- **คำสั่งสร้างไฟล์จริงด้านล่าง** — ต้องเป็น `cat > file << 'EOF' ... EOF` หรือ `vi` หรือวิธีสร้างไฟล์จริง
- **ห้ามเขียนแค่ comment** เช่น `# docker-compose.yml → /opt/wordpress/docker-compose.yml` เพราะผู้ใช้รันแค่ comment ไม่ได้สร้างไฟล์จริง

### Final Check ก่อน Snapshot ตามสถานการณ์ของ Service

**หลักการ:** checkpoints ขึ้นกับว่า service นั้นมีอะไร — มีอะไรเช็คนั้น

| Service Type | Checkpoints ที่ต้องมี |
|---|---|
| Docker-based (WordPress, n8n) | service enabled, containers stopped, images preserved, no secrets |
| Database only (MariaDB, PostgreSQL) | service enabled, no containers, images preserved |
| Simple service (Nginx only) | service enabled, no containers, config files exist |
| VM-based | service enabled, disk space OK |

**Checkpoints พื้นฐานที่ต้องมีทุก service:**
1. `systemctl is-enabled <app>-bootstrap.service` → ต้องได้ `enabled`
2. containers ต้องไม่มีรัน (`docker compose ps` → ไม่มี container แสดง)
3. secrets (`.env`, `credentials.txt`) ต้องไม่มี

**ห้าม snapshot ถ้า:**
- Service disabled
- Containers ยังรันอยู่
- Secrets ยังอยู่

---

## กฎห้ามพลาด

### VERIFY ก่อนเขียน sed ทุกครั้ง

**ห้าม copy sed pattern ข้าม OS** — pattern จริงของแต่ละ OS ต่างกัน:

| OS | Repo format | ตัวอย่างของจริง |
|---|---|---|
| Rocky 10 | `mirrorlist=` + `#baseurl=http://dl.rockylinux.org/$contentdir/...` (ไม่มี space หลัง #) |
| AlmaLinux 10 | `mirrorlist=` + `# baseurl=https://repo.almalinux.org/almalinux/...` (มี space หลัง #, ไม่มี $contentdir) |
| Ubuntu 24.04 | `.sources` (deb822) — `URIs:` + URL |
| Ubuntu 26.04 | `.sources` (deb822) — `URIs:` + URL |
| Debian 13 | `mirror+file://` — `/etc/apt/mirrors/*.list` |
| CentOS Stream 10 | `metalink=` (ไม่ใช่ `mirrorlist=`) — approach: disable repo เดิมทั้งไฟล์ + สร้าง `centos-th.repo` ใหม่ |

**ก่อนเขียน sed → grep ของจริงบน VM ก่อนเสมอ** — ส่ง output มาให้ AI ดู → AI เขียน sed จาก pattern จริง
— **ถ้า grep ไม่เจอ pattern ที่คุ้น** (เช่น เจอ `metalink=` ไม่ใช่ `mirrorlist=`) → เปลี่ยน approach ทันที ห้ามเดา

### Verify mirror subpath ก่อนใช้

กำหนด `baseurl` ใน repo config แล้ว → `curl -sI <baseurl>/ | head -1` ต้องได้ `200 OK`
ถ้า 404 → mirror ไม่มี repo นั้น → ต้องปิด repo หรือใช้ inter แทน

### Mirror availability

- `openlandscape.cloud` — ไม่มี Rocky 10 (directory เปล่า), ไม่มี debian-security (404)
- `mirror1.ku.ac.th` — ครบทุก OS รวมทั้ง debian-security, Rocky 10
- Fedora — ไม่มี mirror ในไทยเลย ต้อง SG/TW/JP/KR หรือ metalink
- CentOS Stream 10 — `mirror1.ku.ac.th/centos-stream/10-stream/` มี BaseOS, AppStream, CRB — **ไม่มี extras-common (404)** → ต้องปิด
- Oracle Linux / openSUSE — `mirror1.ku.ac.th` ยังไม่ verify → ต้อง curl test path ก่อน

### Cloud-init behavior

- **Ubuntu 24.04 / 26.04** — `apt_configure` rewrite `.sources` ทุก boot → ต้อง `99-thai-mirror.cfg`
- **Debian 13** — `mirror+file://` + `apt_configure` behavior TBD → ใส่ `99-thai-mirror.cfg` กันเหนียว
- **RPM-based** (Rocky, Alma, Fedora) — cloud-init ไม่แตะ repo config → `sed` ครั้งเดียวพอ

### Mirror method matrix

| OS | Method | cloud-init config | Mirror URL |
|---|---|---|---|
| Ubuntu 26.04 | sed `.sources` direct URI | ✅ `99-thai-mirror.cfg` | `mirrors.openlandscape.cloud/ubuntu` |
| Ubuntu 24.04 | sed `.sources` direct URI | ✅ `99-thai-mirror.cfg` | `mirror1.ku.ac.th/ubuntu` |
| Rocky 10 | sed `rocky*.repo` (mirrorlist→comment, baseurl) | ❌ ไม่ต้อง | `mirror1.ku.ac.th/rocky-linux` |
| AlmaLinux 10 | sed `almalinux*.repo` (mirrorlist→comment, baseurl) | ❌ ไม่ต้อง | `mirror1.ku.ac.th/almalinux` |
| Debian 13 | overwrite `/etc/apt/mirrors/` files | ✅ กันเหนียว | `mirror1.ku.ac.th/debian` + `/debian-security` |
| CentOS Stream 10 | disable repo เดิม + สร้าง `centos-th.repo` ใหม่ | ❌ ไม่ต้อง | `mirror1.ku.ac.th/centos-stream/10-stream/` — ไม่มี extras-common |
| Oracle Linux 9 | (TBD — grep เอาจริง) | ❌ ไม่ต้อง | `mirror1.ku.ac.th/oracle-linux/` (ต้อง verify) |
| openSUSE Leap 16.0 | `zypper mr` + `zypper ar` | ❌ ไม่ต้อง | `mirror1.ku.ac.th/opensuse/` (ต้อง verify) |
| Fedora 44 | TBD | ❌ ไม่ต้อง | metalink (default) — ไม่มี mirror ไทย |

`image/references/mirrors.md` คือ source of truth เรื่อง mirror ปัจจุบัน ถ้าไฟล์ build ใดขัดกันให้แก้ตามไฟล์นั้นก่อน

## Dependency Map — แก้ไฟล์ A ต้องอัปเดตไฟล์ B

**กฎ:** เมื่อ AI สั่งให้สร้าง แก้ไข หรือเจอปัญหาใหม่ → เช็คตารางนี้ทุกครั้งว่ามีไฟล์ไหนต้องอัปเดตตาม

| ถ้าแก้/สร้าง | ต้องอัปเดต |
|---|---|
| สร้าง app ใหม่ (`build/<app>/`) | `_app-catalog.md`, `image/README.md` |
| build app image เสร็จ | `_app-catalog.md` (เปลี่ยนสถานะ), `<app>.md` (header tag) |
| build guest image เสร็จ | `_guest-images.md` (เปลี่ยนสถานะ) |
| แก้ mirror (`references/mirrors.md`) | AGENTS.md (mirror matrix section), `_guest-images.md` |
| พบ cloud-init behavior ใหม่ | `references/cloud-init-scenarios.md`, AGENTS.md (cloud-init section), `_guest-images.md` |
| build app image บน cluster จริง | `clusters/{name}/inventory/vm.md`, `clusters/{name}/README.md`, `_app-catalog.md`, `<app>.md` |
| สร้าง app image เสร็จ (capture แล้ว) | `clusters/{name}/inventory/vm.md` (image name, Glance ID), `clusters/{name}/README.md` (service table) |
| เจอปัญหาใหม่ระหว่าง build | `image/problem/` (generic, {placeholder}) + `clusters/{name}/problem/` (incident log, IP จริง, timestamp) |
| เจอปัญหาใหม่ (generic) | `problem/` — ใช้ `_template.md` |
| เปลี่ยนโครงสร้าง folder | `image/README.md` |
| เพิ่ม/แก้ reference | `image/README.md` (tree / index)

---

## Cluster Build Execution

เมื่อ build app image บน VM จริงของ cluster (ไม่ใช่แค่เขียน guide) — ต้องอัปเดตทั้ง domain และ cluster:

### ไฟล์ cluster ที่ต้องมีก่อนเริ่ม build

| ไฟล์ | เนื้อหา |
|---|---|
| `clusters/{name}/.env` | SSH user, password/key, VM IP (gitignored) |
| `clusters/{name}/.env.example` | template เปล่า — commit ได้ |
| `clusters/{name}/inventory/vm.md` | ตาราง VM ใน cluster |
| `clusters/{name}/README.md` | ภาพรวม cluster + service map |

### ก่อนเริ่ม build — Pre-flight Verification

> **กฎ:** ก่อน SSH เข้า VM build app image — ต้อง verify ข้อมูลจาก docs ที่มีอยู่แล้วก่อน ห้ามถาม user ถ้าหาคำตอบได้เอง

**AI ต้องอ่านก่อนถาม:**

| เรื่อง | หาได้จาก | ถ้ายังไม่มี → สร้างก่อน |
|---|---|---|
| Guest image พร้อมหรือยัง | `_guest-images.md` → OS นั้น ✅ เสร็จ? | สร้าง guest image ก่อน |
| VM IP, user, OS | `clusters/{name}/inventory/vm.md` | สร้าง inventory ก่อน |
| SSH credentials | `clusters/{name}/.env` | ถาม user |
| Build guide พร้อมหรือยัง | `<app>.md` → header tag `[พร้อม build]`? | สร้าง guide ก่อน |

**เมื่อ SSH เข้า VM แล้ว — verify 4 ข้อบน VM:**

| เช็ค | คำสั่ง | ต้องได้ |
|---|---|---|
| OS version | `lsb_release -a \| grep Release` | Ubuntu 26.04 หรือ codename ที่ตรงกับ guide |
| Mirror ไทย | `grep URIs /etc/apt/sources.list.d/ubuntu.sources` (Ubuntu) | `mirror1.ku.ac.th` หรือ `mirrors.openlandscape.cloud` |
| DNS ใช้ได้ | `curl -sI https://download.docker.com \| head -1` | `HTTP/2 200` |
| Disk space | `df -h /` | `Avail > 5G` |

**ห้ามถาม user เรื่องที่หาได้จาก docs** — เช่น "guest image สร้างเสร็จหรือยัง", "mirror ไทยใช้ไหม" — ถ้ามี docs → อ่านก่อน

### หลัง build เสร็จ — ไฟล์ที่ต้องอัปเดต

| อะไร | เก็บที่ไหน | หมายเหตุ |
|---|---|---|
| VM IP, image name, Glance ID | `clusters/{name}/inventory/vm.md` | เพิ่ม row ในตาราง VM |
| service ใหม่ใน cluster | `clusters/{name}/README.md` | เพิ่มใน service table |
| สถานะ build | `_app-catalog.md` | เปลี่ยนจาก "พร้อม build" → "built แล้ว" |
| header tag | `<app>.md` | `[พร้อม build]` → `[built: {cluster}]` |

### เจอปัญหาระหว่าง build — บันทึก 2 ที่เสมอ

1. **`image/problem/`** — วิธีแก้ generic ใช้ `{placeholder}`, ไม่มี IP จริง
   - ใช้ template จาก `image/problem/_template.md`
2. **`clusters/{name}/problem/`** — incident log: เกิดอะไรกับ cluster นี้, IP จริง, timestamp, แก้ยังไง

**ตัวอย่าง:** Docker ล้มเหลวตอน pull image
- `image/problem/docker-pull-failed-proxy.md` → generic solution
- `clusters/{name}/problem/2026-06-06-docker-pull-failed.md` → IP จริง, คำสั่งที่รัน, error message
