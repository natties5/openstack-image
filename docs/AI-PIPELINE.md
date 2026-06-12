# AI Pipeline — App Image Build

> **Version:** 2026-06-06
> **ใช้กับ:** ทุก app image build (WordPress, Nextcloud, Odoo, n8n, etc.)
> **Pattern:** Pre-flight → SSH → Build → Verify → Post-build

---

## หลักการ

| สิ่ง | ใช้ซ้ำได้ | ต้องคิดใหม่ |
|---|---|---|
| Pre-flight checks | ✅ | ❌ |
| SSH helper (paramiko) | ✅ | ❌ |
| Verification pattern | ✅ | ❌ |
| Post-build doc updates | ✅ | ❌ |
| Build steps (per app) | ❌ | ✅ ตาม app |
| Docker images | ❌ | ✅ ตาม app |
| Bootstrap logic | ❌ | ✅ ตาม app |

---

## Part 1: Reusable Framework

### Trigger

```
เมื่อ user บอก "build [app] image" หรือ "สร้าง [app] image"
```

### Phase 0: Pre-flight — อ่าน docs ก่อน ห้ามถาม user

> **กฎ:** ทุกเรื่องที่หาคำตอบได้จาก docs → อ่านก่อน

**AI ต้องอ่านก่อน:**

| เรื่อง | หาได้จาก | ถ้ายังไม่พร้อม |
|---|---|---|
| Guest image พร้อมหรือยัง | `_guest-images.md` → OS นั้น ✅ เสร็จ? | สร้าง guest image ก่อน |
| VM IP, user, OS | `<app>-build.env` (temp, gitignored) หรือ output ที่ user ส่งมา | ให้ user ยืนยันก่อนเข้า VM |
| SSH/OpenStack credentials | `<app>-build.env` (temp, gitignored) | เติมเป็น temp env แล้วลบทิ้งหลังจบ |
| Build guide พร้อมหรือยัง | `<app>.md` → header tag `[พร้อม build]`? | สร้าง guide ก่อน |

**Env ownership:** image build เป็น standalone workflow ใช้ temp env ใต้ `build/tmp/<app>-build.env` ได้เท่านั้นระหว่างทำงาน ไฟล์นี้ต้อง gitignored และลบทิ้งหลัง build ห้าม commit IP, ID, password, token หรือ private key

**Temp env contract:** ใช้เป็นไฟล์ชั่วคราวเฉพาะรอบ build ห้าม commit และต้องลบหลังจบงาน

```text
IMAGE_BUILD_HOST=—
IMAGE_BUILD_USER=—
IMAGE_BUILD_PASSWORD=—
IMAGE_BUILD_SSH_PORT=22
IMAGE_BUILD_SERVER_ID=—
IMAGE_BUILD_IMAGE_NAME=ubuntu-26.04-{APP_NAME}-YYYYMMDD
```

ถ้าต้องใช้ OpenStack CLI ในรอบ build ให้ใส่ `OS_*` ใน temp env เดียวกัน และห้ามบันทึกค่า auth, server ID, image ID หรือ floating IP ลง docs กลาง

**บน VM เมื่อ SSH เข้าแล้ว — verify 4 ข้อ:**

```bash
lsb_release -a | grep Release          # OS version
grep URIs /etc/apt/sources.list.d/ubuntu.sources  # Mirror ไทย
curl -sI https://download.docker.com | head -1    # DNS OK
df -h /                                   # Disk > 5G
```

### Phase 1: Build

**Step 1:** Install base packages
**Step 2:** Install Docker + Compose
**Step 3:** Create directories
**Step 4:** Deploy static files
**Step 5:** Enable systemd service
**Step 6:** Test bootstrap + pre-pull images
**Step 7:** Cleanup (remove secrets, stop containers)
**Step 8:** Final check + poweroff

> ดูรายละเอียดแต่ละ step ใน `<app>.md` ของแต่ละ app

### Pre-Capture Gate — ต้องผ่านก่อน poweroff/capture

[golden-image VM]

```bash
# 1. bootstrap service ต้อง enabled
systemctl is-enabled {APP_NAME}-bootstrap.service

# 2. containers ต้องหยุดหมดแล้ว
docker compose -f /opt/{APP_NAME}/docker-compose.yml ps

# 3. Docker images ต้องยังอยู่ (ห้าม image prune -a)
docker images | grep -E "{APP_NAME}|postgres|mariadb|mysql|nginx|redis"

# 4. runtime secret/config ต้องไม่มีใน golden image
test ! -e /opt/{APP_NAME}/.env && echo ".env: absent"
test ! -e /root/{APP_NAME}-credentials.txt && echo "credentials: absent"

# 5. bootstrap log จาก test build ลบได้ก่อน capture
test ! -e /var/log/{APP_NAME}-bootstrap.log && echo "bootstrap log: absent"

# 6. volumes จาก test bootstrap ต้องไม่มี
if docker volume ls --format '{{.Name}}' | grep -qi {APP_NAME}; then
  echo "ERROR: runtime volumes remain"
  exit 1
fi
echo "volumes: absent"
```

**ห้าม capture ถ้า:** service disabled, containers ยังรัน, images หาย, `.env`/credentials/log จาก test bootstrap ยังอยู่, หรือ Docker volumes ยังมี runtime data จากการทดสอบ

**หลักการ:** VM ใหม่จาก image ต้องเป็น fresh first boot และสร้าง `.env`/credentials ชุดใหม่เอง ห้ามเก็บ runtime data จาก golden-image VM เข้า image

### Phase 2: Post-build

**ทุก build ต้องอัปเดต:**

| ไฟล์ | อัปเดตอะไร |
|---|---|
| `inventory/README.md` หรือ app post-check | generic build result, image name pattern, status แบบไม่มี IP/ID/secret |
| `_app-catalog.md` | สถานะ build |
| `<app>.md` header tag | `[พร้อม build]` → `[built: standalone]` |
| `build/tmp/<app>-build.env` | ลบทิ้งหลังจบงาน |

### Phase 3: เจอปัญหา

**บันทึกตามขอบเขต:**

| ที่ | เก็บอะไร | ใช้ template |
|---|---|---|
| `problem/generic/` | วิธีแก้ generic (ใช้ `{placeholder}`) | `_template.md` |

---

## Part 2: Per-App Checklist

### WordPress — พร้อม build

| รายการ | ค่า |
|---|---|
| Build guide | `build/apps/wordpress/wordpress.md` |
| Header tag | `[พร้อม build]` |
| Base OS | Ubuntu 26.04 |
| Docker images | `mariadb:lts`, `wordpress:php8.3-fpm`, `nginx:1.27` |
| Build VM | standalone build | ดู inventory หลัง build |
| Build log | `problem/generic/` หรือ app errors log หลัง build |

### Nextcloud — ⚠️ รอ rebuild

| รายการ | ค่า |
|---|---|
| Build guide | `build/apps/nextcloud/nextcloud.md` |
| Header tag | `[รอ rebuild]` |
| Base OS | Ubuntu 26.04 |
| Docker images | `nextcloud:30.0-apache`, `postgres:16.9`, `redis:7.4-alpine`, `nginx:1.27-alpine` |
| Special notes | Auto-install, bind mount `/var/lib/nextcloud`, first boot no pull, HTTPS cert วางเอง |

### Odoo — ✅ พร้อม build

| รายการ | ค่า |
|---|---|
| Build guide | `build/apps/odoo/odoo.md` |
| Header tag | `[พร้อม build]` |
| Base OS | Ubuntu 26.04 |
| Docker images | `odoo:18.0`, `postgres:16`, `nginx:1.27` |
| Minimum flavor | 2 vCPU / 2GB RAM / 20GB disk |
| Special notes | Auto-create DB `odoo_prod`, random admin password, `list_db=False`, adaptive workers, HTTPS cert วางเอง |

### n8n — ⏳ Future

| รายการ | ค่า |
|---|---|
| Build guide | `build/apps/n8n/n8n.md` (ถ้ามี) |
| Header tag | `[รอเติมเนื้อหา]` หรือ `[พร้อม build]` |
| Base OS | Ubuntu 26.04 หรือ Debian 13 |
| Docker images | `n8nio/n8n`, `postgres:15` |

---

## Part 3: SSH Helper Template

ใช้ Python paramiko สำหรับ SSH บน Windows

```python
#!/usr/bin/env python3
"""SSH helper - Reusable template for all app builds"""
import paramiko
import sys
import io

# UTF-8 fix for Thai/Unicode output on Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

def ssh_exec(host, user, password, commands, port=22, timeout=600):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print(f"Connecting to {user}@{host}:{port}...")
    client.connect(host, port=port, username=user, password=password, timeout=30)
    print("Connected!\n")
    
    results = []
    for cmd in commands:
        print(f">>> {cmd[:100]}{'...' if len(cmd)>100 else ''}")
        stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
        out = stdout.read().decode('utf-8', errors='replace')
        err = stderr.read().decode('utf-8', errors='replace')
        exit_code = stdout.channel.recv_exit_status()
        if out:
            print(out.rstrip())
        if err:
            print(f"STDERR: {err.rstrip()}")
        print(f"Exit code: {exit_code}\n")
        results.append({'cmd': cmd, 'stdout': out, 'stderr': err, 'exit_code': exit_code})
    
    client.close()
    return results

if __name__ == "__main__":
    # === เปลี่ยนค่าตาม app ===
    HOST = "CHANGE_ME"
    USER = "root"
    PASSWORD = "CHANGE_ME"
    PORT = 22
    # ==================================
    
    commands = [
        # ใส่ commands ตาม app ที่จะ build
        # ตัวอย่าง: pre-flight
        "lsb_release -a | grep Release",
        "df -h /",
    ]
    
    ssh_exec(HOST, USER, PASSWORD, commands, PORT)
```

**วางไฟล์:** `build/tmp/ssh_helper.py` (gitignored)

**กฎ:** SSH helper และค่าจริงของ `HOST`/`PASSWORD` ต้องอยู่ใน path private/gitignored เท่านั้น ห้าม commit password, temp IP ของ test VM, หรือ output ที่มี secret

---

## วิธีใช้สำหรับ Nextcloud (ครั้งต่อไป)

1. **อ่าน** `AI-PIPELINE.md` → ดู Part 1 framework
2. **อ่าน** `build/apps/nextcloud/nextcloud.md` → ดู specific steps
3. **เตรียม** `build/tmp/nextcloud-build.env` → SSH/OpenStack/temp build values สำหรับรอบนี้เท่านั้น
4. **รัน** SSH/helper จาก temp env → ห้าม commit HOST, USER, PASSWORD, IP หรือ ID
5. **Build** ตาม nextcloud.md steps
6. **อัปเดต** docs ใต้ `build/` และ `docs/` ตาม Phase 2 แล้วลบ temp env

---

## Update Log

| วันที่ | เพิ่ม/แก้ | โดย |
|---|---|---|
| 2026-06-06 | สร้างใหม่จาก WordPress build | AI (minimax-m2.7) |
| 2026-06-08 | ปรับ workflow เป็น standalone image build + `build/tmp/<app>-build.env` | AI |
