# {APP_NAME} Image — Post-Check

> รันหลังสร้าง VM จาก {APP_NAME} image ครั้งแรก
> **Credentials:** `{SSH_USER}` / `{SSH_PASSWORD}` ที่ VM `{VM_IP}:{SSH_PORT}`

---

## Post-Check — 4 ข้อ

### 1. Containers running

```bash
ssh {SSH_USER}@{VM_IP} "cd /opt/{APP_NAME} && docker compose ps"
```

**ต้องได้:** {CONTAINER_COUNT} containers — {EXPECTED_CONTAINERS}

### 2. HTTP responding

```bash
ssh {SSH_USER}@{VM_IP} "curl -sI http://localhost | head -3"
```

**ต้องได้:** `HTTP/1.1 {EXPECTED_HTTP_STATUS}`

### 3. Setup wizard content

```bash
ssh {SSH_USER}@{VM_IP} "curl -s http://localhost | grep -i {APP_NAME}"
```

**ต้องได้:** มีข้อความ {APP_NAME} บนหน้า

### 4. Secrets exist

```bash
ssh {SSH_USER}@{VM_IP} "ls /opt/{APP_NAME}/.env && cat /root/{APP_NAME}-credentials.txt"
```

**ต้องได้:** `.env` มีไฟล์ + credentials มีไฟล์

---

## Success Criteria

| ข้อ | ผ่าน |
|---|---|
| 1. Containers | {EXPECTED_CONTAINERS} |
| 2. HTTP | {EXPECTED_HTTP_STATUS} |
| 3. Setup wizard | มี {APP_NAME} content |
| 4. Secrets | `.env` + `credentials.txt` มี |

**ถ้าผ่านทั้ง 4 ข้อ = Image ใช้งานได้จริง**

---

## วิธีใช้

```bash
# รันทีละข้อ ดูผล
ssh {SSH_USER}@{VM_IP} "cd /opt/{APP_NAME} && docker compose ps"
ssh {SSH_USER}@{VM_IP} "curl -sI http://localhost | head -3"
ssh {SSH_USER}@{VM_IP} "curl -s http://localhost | grep -i {APP_NAME}"
ssh {SSH_USER}@{VM_IP} "ls /opt/{APP_NAME}/.env && cat /root/{APP_NAME}-credentials.txt"
```

---

## Placeholder Mapping

| Placeholder | ตัวอย่าง (WordPress) |
|---|---|
| `{APP_NAME}` | `wordpress` |
| `{VM_IP}` | `CHANGE_ME_VM_IP` |
| `{SSH_USER}` | `root` |
| `{SSH_PASSWORD}` | `—` (from `.env`) |
| `{SSH_PORT}` | `22` |
| `{CONTAINER_COUNT}` | `3` |
| `{EXPECTED_CONTAINERS}` | `db (healthy) + wordpress + nginx` |
| `{EXPECTED_HTTP_STATUS}` | `302 Found` (redirect ไป setup) |
