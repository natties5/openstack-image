# Grafana+Prometheus Image — Post-Check

> รันหลัง deploy VM หรือหลังสร้าง VM จาก image ครั้งแรก
> ขอบเขต: verify service และ self-service UX เท่านั้น ไม่รวม OpenStack capture/Glance

---

## Post-Check — 10 ข้อ

### 1. Bootstrap service completed

```bash
systemctl is-enabled grafana-prometheus-bootstrap.service
systemctl is-active grafana-prometheus-bootstrap.service
systemctl status grafana-prometheus-bootstrap.service --no-pager
```

ต้องได้:
- `enabled`
- `active` หรือ `inactive` แบบ oneshot ที่ completed สำเร็จ
- ไม่มี error ใน status ล่าสุด

### 2. Runtime files exist

```bash
test -f /opt/monitoring/.env && echo env-ok
test -f /root/README-grafana-prometheus-image.txt && echo info-ok
test -f /var/lib/grafana-prometheus-firstboot.done && echo marker-ok
```

ต้องได้:
- `env-ok`
- `info-ok`
- `marker-ok`

### 3. Containers running

```bash
docker compose -f /opt/monitoring/docker-compose.yml --env-file /opt/monitoring/.env ps
```

ต้องเห็น containers หลัก:
- `grafana`
- `prometheus`
- `alertmanager`
- `node-exporter`
- `blackbox-exporter`
- `monitoring-nginx`

### 4. HTTP endpoints healthy

```bash
curl -fsS http://127.0.0.1/ >/dev/null && echo grafana-ok
curl -fsS http://127.0.0.1:9090/-/healthy && echo prometheus-ok
curl -fsS http://127.0.0.1:9093/-/healthy && echo alertmanager-ok
```

ต้องได้:
- `grafana-ok`
- `Prometheus Server is Healthy.`
- `OK`

### 5. Public service exposure is limited

```bash
ss -lntp | grep -E ':80|:9090|:9093' || true
```

ต้องได้:
- TCP `80` bind public สำหรับ Nginx
- TCP `9090` bind `127.0.0.1` เท่านั้น
- TCP `9093` bind `127.0.0.1` เท่านั้น

### 6. Self-service info works

```bash
sudo monitoring-info | head -30
```

ต้องเห็น:
- Grafana URL
- Username `admin`
- generated password
- quick commands

### 7. Status command works

```bash
sudo monitoring-status
```

ต้องเห็น:
- container table
- Grafana via Nginx: OK
- Prometheus: OK
- Alertmanager: OK
- target summary
- disk summary

### 8. Target helpers work

```bash
sudo monitoring-add-http http://127.0.0.1/ local-grafana-test
sudo monitoring-add-tcp 127.0.0.1:80 local-nginx-test
sudo monitoring-add-ping 127.0.0.1 local-ping-test
sudo monitoring-list-targets
```

ต้องได้:
- Prometheus reload สำเร็จ
- targets ใหม่แสดงใน list
- ไม่มี YAML syntax error จาก reload

### 9. Reset Grafana password works without deleting state

```bash
before_targets=$(grep -R "local-grafana-test\|local-nginx-test\|local-ping-test" /opt/monitoring/prometheus/targets | wc -l)
sudo monitoring-reset-grafana-password
after_targets=$(grep -R "local-grafana-test\|local-nginx-test\|local-ping-test" /opt/monitoring/prometheus/targets | wc -l)
test "$before_targets" = "$after_targets" && echo targets-preserved
sudo monitoring-info | grep -E 'Username: admin|Password:'
```

ต้องได้:
- `targets-preserved`
- password ใหม่ใน `monitoring-info`
- dashboards/targets ไม่หาย

### 10. Prometheus sees targets

```bash
curl -fsS http://127.0.0.1:9090/api/v1/targets | jq -r '.data.activeTargets[] | [.labels.job, .labels.instance, .health] | @tsv'
```

ต้องเห็น:
- `prometheus` target `up`
- `node` target `up`
- `blackbox_http` self-check target อย่างน้อยหนึ่งรายการ
- target ที่เพิ่มในข้อ 8 เริ่มแสดงหลังรอ scrape interval

---

## Success Criteria

| ข้อ | ผ่านเมื่อ |
|---|---|
| Bootstrap | service enabled และ completed |
| Runtime files | `.env`, README, marker มีครบ |
| Containers | 6 containers หลัก running |
| HTTP | Grafana/Prometheus/Alertmanager healthy |
| Exposure | public เฉพาะ port 80; 9090/9093 localhost |
| Self-service | `monitoring-info`, `monitoring-status`, add target, reset password ใช้ได้ |
| Persistence | reset password ไม่ลบ targets/dashboards/metrics |
| Prometheus targets | targets active และ health ถูกต้อง |

ผ่านทุกข้อ = deploy ใช้งานได้จริง

---

## Cleanup หลัง post-test ถ้าต้องการลบ target ทดสอบ

Post-check เพิ่ม target ทดสอบเข้าไฟล์จริง ถ้าต้องการลบก่อนส่งลูกค้า:

```bash
sed -i '/local-grafana-test/,+3d' /opt/monitoring/prometheus/targets/http.yml
sed -i '/local-nginx-test/,+3d' /opt/monitoring/prometheus/targets/tcp.yml
sed -i '/local-ping-test/,+3d' /opt/monitoring/prometheus/targets/ping.yml
sudo monitoring-reload
```

ถ้าเป็น post-test บน VM ที่จะส่งให้ลูกค้าจริง ให้ลบ target ทดสอบก่อนส่งมอบ.
