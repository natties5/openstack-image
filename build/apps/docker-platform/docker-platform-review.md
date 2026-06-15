# Docker Platform — Community Research & Product Variants

> Research จาก Docker Docs, Portainer Docs, Nginx Proxy Manager docs/GitHub, StackOverflow, ServerFault, Ubuntu Server docs, OpenStack/cloud-init docs
> ใช้ตัดสินใจ design สำหรับ Docker Platform image บน OpenStack

---

## Product Intent

ผู้ใช้ต้องการ image แบบ app image ไม่ใช่ host เปล่า:

```text
ลูกค้ากด Create Instance
→ VM boot ครั้งแรก
→ bootstrap ทำทุกอย่างให้เอง
→ สุ่ม secret ที่จำเป็น
→ start Web UI ทั้งหมด
→ ลูกค้า SSH เข้า VM อ่าน README/credentials
→ เข้า Web UI แล้วใช้งานได้เลย
```

นี่ใกล้ pattern WordPress/Nextcloud/Odoo ของ repo มากกว่า Docker Host แบบ minimal

---

## Product Variants / Future Image Types

| Variant | สิ่งที่ให้ | เหมาะกับ | สถานะ |
|---|---|---|---|
| Docker Host | Docker CE + Compose plugin | dev/admin ที่ต้องการ host เปล่า | บันทึกไว้เป็น future lightweight image |
| Docker Host + Portainer | Docker + Portainer Web UI | SME/dev ที่ไม่อยากใช้ CLI | เคยเป็น design แรก |
| Docker Platform | Docker + Portainer + Nginx Proxy Manager + templates | ลูกค้าทั่วไป ใช้งานง่าย | เลือกทำเป็น image นี้ |
| Docker Platform + DB Templates | เพิ่ม PostgreSQL/MariaDB/Redis examples | ลูกค้าจะ deploy หลาย app | รวมไว้ใน image นี้แบบไม่ start default |
| One-click App Image | app เฉพาะ เช่น WordPress/Odoo/Nextcloud พร้อม DB/proxy | ลูกค้าทั่วไปที่สุด | ทำแยกตาม app |
| Secure Docker Host | hardening/rootless/userns/firewall policy | ลูกค้าองค์กร/security | future image, ไม่ใช่ default |

---

## กลุ่มผู้ใช้

### ลูกค้าทั่วไป / SME

| ต้องการ | ความถี่ | Source |
|---|---|---|
| เปิด VM แล้วมีหน้าเว็บจัดการทันที | สูงมาก | Portainer/NPM community usage |
| จัด domain/SSL โดยไม่เขียน Nginx config | สูงมาก | Nginx Proxy Manager docs/GitHub |
| มี secret อยู่ใน VM ตาม README | สูง | pattern app image เดิมของ repo |
| Deploy app/database จาก template ได้ | สูง | Docker Compose community patterns |

**ปัญหาที่เจอบ่อย:**
- Docker host เปล่าใช้งานยากสำหรับลูกค้าที่ไม่ถนัด CLI
- ลูกค้าไม่รู้ว่า HTTPS ต้องจบที่ไหน จึงต้องมี Nginx Proxy Manager เป็น HTTPS/domain manager
- ถ้าไม่มี README/credentials file ลูกค้าไม่รู้ URL/port/default login
- ถ้า start database ทุกตัว default จะกิน RAM และสร้าง password ที่ลูกค้าอาจไม่ได้ใช้

### Developer / DevOps

| ต้องการ | ความถี่ | Source |
|---|---|---|
| Docker CE official repo | สูง | Docker official install docs |
| Compose plugin ไม่ใช่ `docker-compose` v1 | สูง | StackOverflow compose v2 issues |
| Buildx พร้อมใช้ | สูง | Docker package list |
| Log rotation | สูง | Docker logging docs, ServerFault docker logs questions |

**ปัญหาที่เจอบ่อย:**
- `docker compose` ไม่มีเพราะไม่ได้ติดตั้ง `docker-compose-plugin`
- Container logs โตจน disk เต็มถ้าไม่ตั้ง log rotation
- Docker published ports expose ทุก interface ถ้าไม่ bind IP หรือคุม security group

### Operator / Production

| ต้องการ | ความถี่ | Source |
|---|---|---|
| Golden image first boot สะอาด | สูง | cloud-init clean docs, OpenStack image guide |
| ไม่มี runtime volumes จาก test ติด image | สูง | image hygiene best practice |
| Admin ports แยกจาก public ports | สูง | Docker firewall docs, Ubuntu Server docs |
| NPM เป็น HTTPS gateway | สูง | Nginx Proxy Manager docs |

**ปัญหาที่เจอบ่อย:**
- Docker และ UFW interaction ซับซ้อน เพราะ Docker NAT อาจ bypass UFW rules
- Portainer mount `/var/run/docker.sock` จึงมีสิทธิ์คุม host ทั้งหมด
- Nginx Proxy Manager upstream มี default login จึงต้องบอกให้เปลี่ยนทันที

---

## Component Decisions

### Docker CE
- ใช้ official Docker apt repository
- ติดตั้ง `docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`
- ไม่ใช้ `snap`, ไม่ใช้ Ubuntu `docker.io`

### Portainer CE
- ใช้ `portainer/portainer-ce:lts`
- เปิด HTTPS ที่ `9443`
- bootstrap สร้าง admin ผ่าน official API `/api/users/admin/init`
- สุ่ม password และเขียนใน `/root/docker-platform-credentials.txt`

### Nginx Proxy Manager
- ใช้ `jc21/nginx-proxy-manager:latest` ตาม upstream quick setup
- เปิด `80`, `443`, `81`
- ใช้เป็นตัวจัด domain, reverse proxy, Let's Encrypt ผ่าน Web UI
- ค่าเริ่มต้น upstream คือ `admin@example.com` / `changeme`; bootstrap ใช้ API login แล้วเปลี่ยนเป็น password สุ่มแบบ best-effort
- ถ้า NPM API เปลี่ยน password ไม่สำเร็จ credentials file จะระบุ fallback และบังคับเปลี่ยนทันทีหลัง first login
- ไม่เปิด NPM ผ่าน HTTPS admin default เพราะ NPM ใช้ `81` สำหรับ admin UI และจัด HTTPS ให้ proxy hosts ผ่าน `443`

### Database Templates
- ใส่ PostgreSQL, MariaDB, Redis เป็น examples/templates
- ไม่ start default เพราะจะกิน RAM/disk และสร้าง secret ที่ลูกค้าอาจไม่ได้ใช้
- bind DB examples กับ `127.0.0.1` เพื่อลด accidental public exposure

### Logging
- ใช้ `json-file` พร้อม `max-size=10m`, `max-file=3`
- official docs ระบุ `log-opts` ใน `daemon.json` ต้องเป็น string

---

## สิ่งที่ควรมีใน Image (Recommended)

| Feature | Priority | Reason |
|---|---|---|
| Docker CE official repo | Must | update/security path ชัดเจน |
| Compose plugin + Buildx | Must | workflow ปัจจุบันของ Docker |
| Docker log rotation | Must | กัน disk เต็มจาก container logs |
| Portainer CE | Must | Web UI จัด container/stack |
| Nginx Proxy Manager | Must | Web UI จัด domain/HTTPS |
| Credentials file | Must | ลูกค้าเปิด VM แล้วรู้ secret/URL ทันที |
| README + MOTD | Must | บอก next steps ชัดเจน |
| DB/app examples | Should | ลูกค้าต่อยอดได้ง่าย แต่ไม่กิน resource default |
| Pre-pull images | Should | ลด first boot latency |

---

## สิ่งที่ตัดสินใจไม่ใส่ (Conscious Omissions)

| Feature | Reason |
|---|---|
| Start PostgreSQL/MariaDB/Redis default | ลูกค้าอาจไม่ได้ใช้, กิน RAM, ต้องสร้าง secret หลายชุด |
| Docker rootless default | setup ซับซ้อน, Portainer/rootless มี limitation |
| Auto-add user เข้า `docker` group | Docker group = root-level privilege |
| Traefik | powerful แต่ซับซ้อนกว่า NPM สำหรับลูกค้าทั่วไป |
| Caddy only | auto HTTPS ดีแต่ไม่มี UI จัด domain สำหรับ beginner |
| Portainer Edge port `8000` | standalone image ส่วนใหญ่ไม่ใช้ Edge Agents |
| Portainer HTTP `9000` | current Portainer default ใช้ HTTPS `9443` |
| Auto-create customer domains | image ไม่รู้ domain/DNS ของลูกค้าล่วงหน้า |

---

## Final Design Decision

```text
ลูกค้าสร้าง VM จาก Image
→ systemd เรียก docker-platform-bootstrap.sh
→ สุ่ม Portainer admin password และ Nginx Proxy Manager password
→ สร้าง /opt/docker-platform/.env
→ start Portainer + Nginx Proxy Manager
→ initialize Portainer admin และเปลี่ยน NPM password ผ่าน API
→ เขียน /root/docker-platform-credentials.txt
→ ลูกค้า SSH เข้า VM อ่าน README/credentials
→ เข้า Portainer/NPM แล้วใช้งานได้เลย
```

Security group ที่แนะนำ:
- Public: `80`, `443`
- Admin only: `22`, `81`, `9443`
