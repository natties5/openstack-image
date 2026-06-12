# Image Inventory

> Metadata ของ image ที่ build แล้ว ใช้ร่วมกันทุก cluster

---

## โครงสร้าง

```text
inventory/
├── README.md           ← ไฟล์นี้
├── build.env           ← Build environment template
└── images/             ← Image metadata (non-secret only)
    ├── .gitkeep
    ├── guest-images.env  ← Guest image metadata
    └── app-images.env    ← App image metadata
```

## หลักการ

- **Domain-level** — เก็บ image ที่ใช้ทุก cluster เหมือนกัน (base OS, cloud-init)
- **Standalone build** — build image ที่ไหนก็ได้ แต่ record ใต้ `inventory/` ต้องเป็น generic และใช้ซ้ำได้ทุก cluster
- **Cluster-specific** — ถ้า deploy/import เข้า cluster จริง ค่อยเก็บข้อมูลเฉพาะ cluster ใน `clusters/{name}/inventory/`
- ไม่เก็บ image binary ใน repo (เดี๋ยว repo บวม) — เก็บแค่ metadata หรือลิงก์
- Temp env สำหรับ build ให้อยู่ใต้ `build/tmp/` ได้เฉพาะระหว่างทำงาน ต้อง gitignored และลบทิ้งหลัง build
- ห้ามเก็บ password, token, private key, temp VM IP, server ID, Floating IP, Glance ID เฉพาะรอบ build หรือ credential จริงใน repo

## วิธีเพิ่ม image ใหม่

1. Build image ตาม `build/apps/{app}/{app}.md` หรือ `build/_guest-images.md`
2. อัปเดต metadata หรือลิงก์ non-secret ใน `inventory/images/`
3. ถ้ามีข้อมูลเฉพาะ cluster เช่น Glance ID, VM IP, SSH credential → ไม่บันทึกใน `inventory/`; อัปเดต cluster docs เฉพาะเมื่อ deploy/import เข้า cluster นั้นจริง

## Image ปัจจุบัน

| Image | OS | Size | ใช้กับ | หมายเหตุ |
|---|---|---|---|---|
| — | — | — | — | ยังไม่มี image metadata |

## Nextcloud rebuild target

| เรื่อง | ค่า |
|---|---|
| Status | ⚠️ รอ rebuild/capture ใหม่ |
| OS | Ubuntu 26.04 |
| Install flow | Auto-install, admin user `admin`, password สุ่มต่อ VM |
| Data layout | Bind mount `/var/lib/nextcloud/{app,db,redis}` |
| First boot | ไม่พึ่ง internet, ใช้ Docker images ที่ pre-pull ใน golden image |
| HTTPS | วาง cert เองที่ `/opt/nextcloud/certs/` แล้วเปิด profile `https` |

ยังไม่มี Glance ID หรือ image metadata จริง ห้ามเติมจนกว่าจะ capture/import เสร็จ