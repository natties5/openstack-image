# Grafana+Prometheus — Community Research & User Needs [มี review]

> Research จาก community และ upstream docs สำหรับ image แบบ VM / Website / Service Monitoring Appliance
> โจทย์ user: ลูกค้าเปิด VM แล้วใช้งาน Grafana monitoring ได้ทันที โดยไม่ต้องรู้ underlying provider/network platform

---

## Research Scope

| หัวข้อ | รายละเอียด |
|---|---|
| App | Grafana + Prometheus monitoring appliance |
| Primary use case | Monitor VM, website, API, TCP service, และ endpoint ที่ monitoring VM เข้าถึงได้ |
| Scale | ตั้งแต่ VM ไม่กี่เครื่องจนถึงหลายสิบ/หลายร้อย target; image ต้องเริ่มง่ายและขยายต่อได้ |
| Deployment expectation | เปิด VM แล้วเข้า Grafana เห็น dashboard/self-monitoring ได้ทันที |
| Customer model | ลูกค้าเพิ่ม target ด้วย IP/URL/port; ไม่ต้องรู้ provider หรือ tenant |

---

## Sources

| Source | เข้าด้วย | Signal ที่ได้ |
|---|---|---|
| Prometheus official docs: configuration, node_exporter, blackbox exporter pattern, security model, storage | webfetch | Source of truth เรื่อง scrape config, exporters, security, TSDB |
| Grafana official docs: Docker image, provisioning datasource/dashboard/alerting | webfetch | Source of truth เรื่อง provisioning และ Docker behavior |
| Reddit via Playwright MCP (`old.reddit.com`) | browser/MCP | User expectation for VM monitoring, Zabbix vs Prometheus tradeoff |
| Grafana Community Forum via Playwright MCP | browser/MCP | Provisioning pitfalls: datasource UID, dashboard import, alerting setup |
| Hacker News discussions | websearch | Scale/operability tradeoffs, Prometheus+Grafana+Alertmanager consensus |
| GitHub issues via websearch/webfetch | websearch/webfetch | Prometheus storage/node_exporter/Grafana provisioning pitfalls |

หมายเหตุ: `www.reddit.com` รุ่นใหม่เจอ JS challenge แต่ `old.reddit.com` อ่านได้ผ่าน Playwright MCP. GitHub MCP ใน session นี้ไม่ connected จึงใช้ websearch/webfetch อ่าน GitHub issues แทน.

---

## Positioning

Image นี้ควรสื่อสารกับลูกค้าว่าเป็น:

```text
VM / Website / Service Monitoring Appliance
```

หลักการใช้งาน:

| Concept | อธิบายให้ลูกค้า |
|---|---|
| Monitor scope | Monitor ได้ทุก target ที่ VM นี้เข้าถึงผ่าน network ได้ |
| Same network | VM ภายใน network เดียวกันมัก monitor ได้ง่ายที่สุด |
| Cross network | Monitor ข้าม network ได้ถ้ามี route, public IP, VPN, firewall rule, หรือ security rule ที่อนุญาต |
| Target identity | ลูกค้าใส่ IP, hostname, URL, และ port เท่านั้น |
| Platform abstraction | ไม่พูดเรื่อง provider, tenant, credential, หรือ control plane ใน UX ลูกค้า |

---

## กลุ่มผู้ใช้

### Beginner — เปิด VM แล้วใช้งานทันที

| ต้องการ | Priority | Source |
|---|---|---|
| เข้า Grafana แล้วมี Prometheus datasource พร้อมใช้ | 🔴 Must | Grafana provisioning docs + Grafana Community |
| มี dashboard CPU/RAM/Disk/Network/uptime ตั้งแต่ boot | 🔴 Must | Reddit/HN monitoring discussions |
| monitor VM ตัว monitoring appliance เองทันที | 🔴 Must | Prometheus node_exporter docs |
| เพิ่ม website/API target ด้วย URL ง่ายๆ | 🔴 Must | Prometheus blackbox exporter docs |
| เพิ่ม target VM โดยแก้ไฟล์หรือใช้ helper script | 🟠 Should | Prometheus file-based service discovery docs |
| alert พื้นฐาน เช่น node down, disk full, high CPU/memory, HTTP down | 🟠 Should | HN + Alertmanager docs |

### Intermediate — monitor หลาย VM / หลาย service

| ต้องการ | Priority | Source |
|---|---|---|
| เพิ่ม VM target จำนวนมากด้วย target file หรือ helper script | 🔴 Must | Prometheus file_sd pattern + Reddit VM monitoring use case |
| Blackbox probe HTTP/HTTPS/TCP/ICMP เพื่อดู availability | 🔴 Must | Prometheus blackbox exporter docs + HN discussion |
| labels ที่อ่านออก เช่น customer, role, environment, instance | 🟠 Should | Prometheus labels/service discovery docs |
| คู่มือเปิด firewall/security rule สำหรับ `9100`, `80/443`, target ports | 🟠 Should | Prometheus security model + community pitfalls |
| Dashboard แยก Node metrics, Endpoint health, Alerts | 🟠 Should | Grafana provisioning docs |

### Advanced — scale ใหญ่หรือหลายทีม

| ต้องการ | Priority | Source |
|---|---|---|
| HA/long-term metrics ผ่าน duplicate Prometheus, Thanos, Mimir, Cortex, VictoriaMetrics, หรือ remote_write | 🟠 Should | HN scale discussions + Prometheus ecosystem |
| Grafana org/folder/datasource permission design | 🟡 Could | Grafana provisioning/admin docs |
| Dashboard/folder naming convention ต่อ customer/team | 🟡 Could | Grafana Community |
| Retention tuning ตาม disk size และจำนวน targets | 🟡 Could | Prometheus storage docs |

---

## Competitive Landscape

| Option | จุดแข็ง | จุดอ่อน | เหมาะกับ image นี้ไหม |
|---|---|---|---|
| Prometheus + Grafana + Alertmanager | Community ใหญ่, exporter ecosystem ครบ, dashboard ยืดหยุ่น | ต้องเตรียม config/dashboard ให้ดี ไม่งั้น beginner งง | ✅ เหมาะที่สุด |
| Zabbix | All-in-one, VM/server monitoring ใช้ง่ายกว่าในบางทีม | UI/agent model หนักกว่า, less cloud-native | 🟡 คู่แข่งสำคัญ แต่ไม่ใช่โจทย์นี้ |
| Netdata | เปิดแล้วเห็น metrics ง่ายมาก | ระยะยาว/หลาย VM/alert routing ไม่ยืดหยุ่นเท่า Prometheus stack | 🟡 เหมาะ beginner แต่ไม่ใช่ standard stack |
| Grafana Cloud | ลดภาระ operate stack | ไม่ standalone, ผูกบริการภายนอก | ❌ ไม่ตรง standalone image |
| VictoriaMetrics | performance/scale ดี, PromQL compatible ส่วนใหญ่ | เปลี่ยน core component จาก Prometheus | 🟡 upgrade path สำหรับ scale ใหญ่ ไม่ใช่ default |
| Thanos/Mimir/Cortex | HA/long-term/multi-tenant | เพิ่ม complexity มาก | ❌ ไม่ควรใส่ base image |

---

## Component Decision

| Component | Default | Priority | เหตุผล |
|---|---:|---|---|
| Grafana OSS | ✅ | 🔴 Must | UI หลัก, provision datasource/dashboard ได้ |
| Prometheus | ✅ | 🔴 Must | Metrics TSDB + scrape engine |
| Alertmanager | ✅ | 🔴 Must | Routing, silence, repeat, notification baseline |
| node_exporter | ✅ | 🔴 Must | Monitor monitoring VM เองทันที และเป็น pattern สำหรับ target VMs |
| blackbox_exporter | ✅ | 🔴 Must | Monitor website/API/TCP/ICMP โดยไม่ต้องลง agent |
| file_sd target directory | ✅ | 🔴 Must | เพิ่ม VM/endpoint targets ง่ายและไม่ต้องแก้ config หลัก |
| Nginx reverse proxy | ✅ | 🟠 Should | เปิด Grafana ผ่าน port 80/443 และซ่อน internal ports |
| prebuilt dashboards | ✅ | 🔴 Must | เปิด VM แล้วเห็นข้อมูลทันที |
| helper scripts | ✅ | 🟠 Should | ลด friction เช่น `add-node`, `add-http`, `add-tcp` |
| cAdvisor | ❌ default, ✅ optional | 🟡 Could | เฉพาะลูกค้าที่ใช้ Docker ใน VM; ต้องระวัง host mounts |

ไม่ใส่ใน image นี้:

| Component | เหตุผล |
|---|---|
| Log aggregation | เพิ่ม disk/retention/sensitive-data complexity; user ตัดสินใจแล้วไม่ใส่ |
| Distributed tracing | ไม่ใช่โจทย์ VM/service monitoring |
| Agent orchestration layer | เพิ่ม abstraction/agent complexity เกิน baseline |
| Provider discovery | ลูกค้าไม่ต้องรู้ provider concept; ใช้ IP/URL/port แทน |
| Provider control-plane exporter | ไม่ใช่ customer-facing VM monitoring และต้องใช้ credential เฉพาะ provider |

---

## Recommended Image Behavior

### Boot-ready baseline

เมื่อ boot VM จาก image:

1. Grafana เปิดที่ `http://<vm-ip>/` ผ่าน Nginx
2. Prometheus scrape ตัวเอง, Alertmanager, node_exporter, blackbox_exporter
3. Grafana มี Prometheus datasource provisioned ด้วย UID คงที่ เช่น `prometheus`
4. Dashboard พื้นฐานถูก provision แล้ว:
   - Monitoring VM Overview
   - Linux Node Overview
   - Prometheus Targets / Self-monitoring
   - Blackbox Endpoint Health
   - Alert Overview
5. มี target directory เช่น `/opt/monitoring/targets/` สำหรับเพิ่ม VM/endpoint
6. มี README ใน VM บอก quick commands เพิ่ม target และ reload Prometheus

### Self-service password policy

| Scenario | Behavior |
|---|---|
| VM แรกจาก official image | first boot generate random Grafana admin password ใหม่ |
| Reboot VM เดิม | password ไม่เปลี่ยน |
| ลูกค้าลืม password | SSH เข้า VM ด้วย sudo แล้วรัน `monitoring-reset-grafana-password` |
| ลูกค้า snapshot VM ที่ใช้งานแล้วแล้วขึ้น VM ใหม่ | password/state เดิมติดไปตาม snapshot; ถ้าต้องการเปลี่ยนให้รัน reset script |

Password policy ต้อง self-service และไม่ต้องมี admin snapshot workflow ใน customer-facing image นี้.

Reset script ต้องเปลี่ยน password ผ่าน Grafana CLI/API หรือวิธีที่แก้ Grafana DB จริง ไม่ใช่แก้ `.env` อย่างเดียว เพราะ `GF_SECURITY_ADMIN_PASSWORD` ใช้ตอน init database ครั้งแรกเท่านั้น.

### Target management

| Mode | ตัวอย่าง | ใช้เมื่อ |
|---|---|---|
| Linux VM metrics | `add-node 10.0.0.12:9100 web-01` | target VM ลง node_exporter แล้ว |
| Website/API uptime | `add-http https://example.com website-prod` | monitor HTTP status, latency, TLS cert |
| TCP port | `add-tcp 10.0.0.20:5432 postgres-01` | monitor service port เปิด/ปิด |
| ICMP/ping | `add-ping 10.0.0.30 router-01` | monitor reachability ขั้นพื้นฐาน |
| Manual file | แก้ `/opt/monitoring/targets/*.yml` | admin ต้องการ control labels เอง |

### Network model

| Scenario | ทำได้ไหม | เงื่อนไข |
|---|---|---|
| VM อยู่ network เดียวกับ monitoring VM | ✅ ได้ | เปิด exporter/port และ firewall allow |
| VM อยู่อีก network | ✅ ได้ถ้ามี route | ต้องมี routing/VPN/shared network/public IP |
| Website public | ✅ ได้ | monitoring VM ออก internet หรือ reach URL ได้ |
| Private service port | ✅ ได้ถ้า network ถึง | เปิด firewall จาก monitoring VM ไป port นั้น |
| Target ที่ network ไม่ถึง | ❌ ไม่ได้ | ต้องเพิ่ม route/VPN/public endpoint ก่อน |

---

## Deployment Pitfalls

### Security

| Pitfall | Impact | Recommendation |
|---|---|---|
| Expose Prometheus public | เห็น metrics/config และอาจถูก query/DoS | ไม่ bind public; เข้าเฉพาะ internal network หรือผ่าน reverse proxy ที่มี auth |
| Expose Alertmanager public | ใครก็สร้าง silence/ดู alert data ได้ | ไม่ expose public |
| Expose exporters public โดยไม่จำเป็น | leak host/container details | เปิดเฉพาะจาก monitoring VM ไป target เท่านั้น |
| Expose blackbox exporter public | SSRF surface เพราะรับ target ผ่าน `/probe?target=` | ให้ Prometheus เรียกผ่าน internal Docker network เท่านั้น |
| Default password ถาวร | เสี่ยง takeover | first boot ต้อง generate random password ต่อ VM |
| Reset password โดยแก้ `.env` อย่างเดียว | password ไม่เปลี่ยนถ้า Grafana DB init แล้ว | ใช้ Grafana CLI/API reset admin password จริง |

### Prometheus storage

| Pitfall | Impact | Recommendation |
|---|---|---|
| ใช้ NFS/SMB/EFS-like storage กับ TSDB | corruption/latency/compaction issue | ใช้ local disk สำหรับ Prometheus TSDB |
| ไม่จำกัด retention | disk เต็มจน stack ล่ม | ตั้ง `--storage.tsdb.retention.time` และ/หรือ `--storage.tsdb.retention.size` |
| ตั้ง retention size ชิด disk เกินไป | WAL/compaction ไม่มี buffer | ใช้ประมาณ 80-85% ของ disk ที่กันไว้ |

### Grafana provisioning

| Pitfall | Impact | Recommendation |
|---|---|---|
| Datasource UID ไม่คงที่ | dashboard import/provision แล้ว panel หา datasource ไม่เจอ | กำหนด UID `prometheus` คงที่ |
| ใช้ env var ใน dashboard JSON | Grafana ไม่ expand ตามที่คาด | ใช้ env var ใน provisioning YAML เท่านั้น |
| allow UI update แล้วไฟล์ provisioning overwrite | user แก้ dashboard แล้วหาย | README ต้องบอกว่า provisioned dashboards เป็น baseline |

### Node exporter / cAdvisor

| Pitfall | Impact | Recommendation |
|---|---|---|
| node_exporter ใน container โดยไม่ mount host root | ได้ metric ของ container ไม่ใช่ host | ใช้ `--path.rootfs=/host` และ bind mount host root read-only |
| filesystem collector เจอ mount ค้าง | scrape timeout | exclude mount points/fs types ที่ไม่จำเป็น |
| cAdvisor expose public | leak container/env/resource metadata | ถ้าเปิด optional profile ห้าม publish port public |

---

## Feature Recommendations

| Feature | Priority | Decision |
|---|---|---|
| Grafana provisioned Prometheus datasource UID `prometheus` | 🔴 Must | ใส่ default |
| Prebuilt dashboard set | 🔴 Must | ใส่ default |
| Prometheus target files under `/opt/monitoring/targets/` | 🔴 Must | ใส่ default |
| Alertmanager installed and wired | 🔴 Must | ใส่ default, notification receiver เป็น placeholder |
| Blackbox HTTP/TCP/ICMP templates | 🔴 Must | ใส่ default |
| Nginx reverse proxy | 🟠 Should | ใส่ default เพื่อ user เข้า port 80 ได้ |
| Helper scripts `add-node`, `add-http`, `add-tcp` | 🟠 Should | ใส่ default |
| Helper script `monitoring-reset-grafana-password` | 🔴 Must | self-service กรณีลืม password โดยไม่ลบ data |
| HTTPS automation | 🟡 Could | optional หลัง user มี domain |
| cAdvisor Docker metrics | 🟡 Could | optional profile เท่านั้น |

---

## Lessons Learned

1. Image นี้ต้องเป็น customer-facing monitoring appliance ไม่ใช่ provider-specific monitoring tool
2. ลูกค้าควรคิดแค่ target IP/URL/port ที่ monitoring VM reach ได้
3. “เปิด VM แล้วใช้งานได้ทันที” ต้องมี self-monitoring ก่อน แม้ยังไม่มี target ลูกค้า
4. `file_sd_configs` คือ default ที่ปลอดภัยและเข้าใจง่ายที่สุดสำหรับ VM/endpoint targets
5. `blackbox_exporter` มี value สูงมาก เพราะ monitor availability ได้โดยไม่ลง agent
6. Prometheus/Grafana provisioning ต้อง lock datasource UID ตั้งแต่แรก ไม่อย่างนั้น dashboard จะ brittle
7. Grafana password ต้อง random แค่ first boot ต่อ VM และ reset ผ่าน script เมื่อผู้ใช้ลืม
8. Scale ใหญ่ควร document path ไป Thanos/Mimir/VictoriaMetrics/remote_write แต่ไม่ควรใส่ใน base image

---

## ส่งต่อให้วิศวกร

ออกแบบ `build/apps/grafana-prometheus/grafana-prometheus.md` และ source files โดยยึด stack นี้:

```text
Grafana OSS + Prometheus + Alertmanager + node_exporter + blackbox_exporter + Nginx
Optional profile: cAdvisor
```

Build guide ต้อง self-contained, เปิด VM แล้วเห็น dashboard ได้ทันที, เพิ่ม target ด้วย IP/URL/port ได้ง่าย, มี `monitoring-reset-grafana-password`, ไม่มี snapshot-prep script, และต้องไม่มี credential, token, IP ชั่วคราว, server ID, image ID หรือ password ถาวรใน repo.
