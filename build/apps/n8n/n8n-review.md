# n8n — Community Research & User Needs

> Research จาก community (r/n8n, n8n Discourse, GitHub issues, Hacker News)
> ใช้ตัดสินใจ feature ที่ต้องมีใน image — ยังไม่ complete (n8n.md ยังเป็นโครงเปล่า)

---

## กลุ่มผู้ใช้

### Beginner — automate งานง่าย

| ต้องการ | ความถี่ | Source |
|---|---|---|
| — | — | — |

### Intermediate — workflow ซับซ้อน

| ต้องการ | ความถี่ | Source |
|---|---|---|
| — | — | — |

### Advanced — production deployment

| ต้องการ | ความถี่ | Source |
|---|---|---|
| — | — | — |

---

## Best Practices จาก Community

(TBD — research เมื่อพร้อม build)

---

## สิ่งที่ควรมีใน Image (Recommended)

| Feature | Priority | Reason |
|---|---|---|
| PostgreSQL | 🔴 Must | n8n docs recommend |
| N8N_ENCRYPTION_KEY auto-generate | 🔴 Must | Required for credentials encryption |
| HTTPS via nginx reverse proxy | 🟠 Should | n8n webhooks need HTTPS |
| WEBHOOK_URL auto-detect IP | 🟡 Could | Webhooks work without manual config |

---

## สิ่งที่ตัดสินใจไม่ใส่

| Feature | Reason |
|---|---|
| — | — |
