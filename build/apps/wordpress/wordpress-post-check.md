# WordPress Image — Post-Check Checklist

> Checklist กลางสำหรับตรวจ VM ที่สร้างจาก WordPress image ครั้งแรก
> ห้ามใส่ password, temp IP, หรือ runtime credentials ในไฟล์นี้

---

## Scope

ใช้เช็คว่า image ที่ capture แล้ว boot เป็น VM ใหม่ได้จริงหรือไม่

| รายการ | สถานะ | หมายเหตุ |
|---|---|---|
| Build guide พร้อม | ✅ done | `build/apps/wordpress/wordpress.md` |
| Build VM ทำจริง | ✅ done | ดู cluster inventory ที่เกี่ยวข้อง |
| Cleanup ก่อน capture | ✅ done | ต้องไม่มี runtime secret ก่อน snapshot |
| Capture เป็น Glance image | ✅ done | ยืนยันจาก VM test ที่ boot จาก image; Glance ID — |
| Boot VM จาก image | ✅ done | VM test boot แล้วและ SSH ได้ |
| Post-test VM จาก image | ✅ pass | ตรวจเมื่อ 2026-06-08 |

---

## Runtime Data Policy

ไฟล์ต่อไปนี้เป็น runtime/temp data เท่านั้น:

| Path | เกิดเมื่อไหร่ | Policy |
|---|---|---|
| `/opt/wordpress/.env` | bootstrap ตอน boot VM | ต้องลบก่อน capture, หลัง boot VM ใหม่ต้องถูกสร้างใหม่ |
| `/root/wordpress-credentials.txt` | bootstrap ตอน boot VM | ต้องลบก่อน capture, ห้าม dump content ลง repo |
| `/var/log/wordpress-bootstrap.log` | bootstrap ตอน test/build | ลบก่อน capture ได้ |

---

## Post-Check — รันบน VM ที่สร้างจาก image

[wordpress-test-vm]

### 1. Bootstrap service

```bash
systemctl is-enabled wordpress-bootstrap.service
systemctl status wordpress-bootstrap.service --no-pager
```

**ต้องได้:** service `enabled` และไม่ failed

### 2. Containers running

```bash
cd /opt/wordpress
docker compose ps
```

**ต้องได้:** 3 containers — `db` healthy, `wordpress` running, `nginx` running

### 3. HTTP responding

```bash
curl -sI http://localhost | head -3
```

**ต้องได้:** HTTP response จาก WordPress setup page เช่น `302 Found` หรือ `200 OK`

### 4. Setup wizard content

```bash
curl -sL http://localhost | grep -i wordpress
```

**ต้องได้:** มีข้อความ WordPress บนหน้า setup หลัง follow redirect

### 5. Runtime files created after boot

```bash
ls -l /opt/wordpress/.env /root/wordpress-credentials.txt
```

**ต้องได้:** มีทั้ง 2 ไฟล์หลัง boot VM ใหม่

**ห้าม:** เปิดหรือ dump content ของ credentials ลงเอกสาร

---

## Success Criteria

| ข้อ | เกณฑ์ผ่าน | สถานะ |
|---|---|---|
| 1. Bootstrap service | enabled และไม่ failed | ✅ pass |
| 2. Containers | db healthy + wordpress running + nginx running | ✅ pass |
| 3. HTTP | root `302` ไป install page, install page `200` | ✅ pass |
| 4. Setup wizard | มี WordPress content หลัง follow redirect | ✅ pass |
| 5. Runtime files | `.env` + `credentials.txt` ถูกสร้างหลัง boot | ✅ pass |

ถ้าผ่านครบทั้ง 5 ข้อ = image boot ใช้งานจริงผ่าน post-test

---

## วิธีใช้ซ้ำ

1. สร้าง VM ใหม่จาก Glance image
2. SSH เข้า `[wordpress-test-vm]`
3. รันคำสั่งในหัวข้อ Post-Check ทีละข้อ
4. อัปเดตตาราง `Success Criteria` เป็น `✅ pass` หรือ `❌ fail`
5. ถ้า fail ให้บันทึก incident ใน `problem/generic/` และ cluster `problem/` ที่เกี่ยวข้อง โดยไม่ใส่ secret
