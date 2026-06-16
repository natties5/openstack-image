=========================================================================
Grafana + Prometheus — ผังไฟล์ (อะไรอยู่ที่ไหน)
=========================================================================

[Directory หลัก]
  /opt/monitoring/
      โฟลเดอร์หลักของระบบ monitoring — ทุกอย่างอยู่ที่นี่

[Config — แก้ไขได้]
  /opt/monitoring/docker-compose.yml
      ตั้งค่า Docker containers ทั้งหมด เช่น port, volume, restart policy

  /opt/monitoring/nginx/default.conf
      ตั้งค่า Nginx reverse proxy — ใช้ตอนเพิ่ม TLS/HTTPS หรือเปลี่ยน route

  /opt/monitoring/prometheus/prometheus.yml
      ตั้งค่า Prometheus — scrape interval, retention, global setting

  /opt/monitoring/prometheus/rules/alerts.yml
      ตั้งค่าเงื่อนไข alert — threshold ต่างๆ เช่น CPU สูงเกิน 90%

  /opt/monitoring/alertmanager/alertmanager.yml
      ตั้งค่าการส่ง alert — email, LINE, Slack, webhook

  /opt/monitoring/blackbox/blackbox.yml
      ตั้งค่า blackbox exporter — วิธี probe HTTP, TCP, ICMP

  /opt/monitoring/grafana/provisioning/
      ตั้งค่า Grafana อัตโนมัติ — datasource และ dashboard provider

[Target files — helper command จัดการให้ ปกติไม่ต้องแก้]
  /opt/monitoring/prometheus/targets/nodes.yml
      รายชื่อเครื่องที่ monitor ผ่าน node_exporter

  /opt/monitoring/prometheus/targets/http.yml
      รายชื่อ URL ที่ monitor ผ่าน HTTP/HTTPS

  /opt/monitoring/prometheus/targets/tcp.yml
      รายชื่อ TCP port ที่ monitor

  /opt/monitoring/prometheus/targets/ping.yml
      รายชื่อ IP ที่ monitor ผ่าน ping

  /opt/monitoring/prometheus/targets/cadvisor.yml
      รายชื่อ container metrics (optional — ต้องเปิด profile เพิ่ม)

[Dashboard]
  /opt/monitoring/grafana/dashboards/
      วางไฟล์ dashboard JSON ได้ที่นี่ — Grafana จะโหลดให้อัตโนมัติ

[Runtime — ระบบสร้างและจัดการให้ ห้ามแก้ไข]

  /opt/monitoring/.env
      เก็บ password และ secret ต่างๆ

  /root/README-grafana-prometheus-image.txt
      ไฟล์ที่คุณกำลังอ่านอยู่นี้

  /var/lib/grafana-prometheus-firstboot.done
      marker — บอกว่าระบบ boot ครั้งแรกแล้ว

[ข้อมูล — Docker volumes อย่าลบ]

  grafana_data
      เก็บ Grafana settings, dashboards, users

  prometheus_data
      เก็บ metrics ย้อนหลังทั้งหมด

  alertmanager_data
      เก็บ alert state และ silences

[ดู Log]

  docker logs grafana
  docker logs prometheus
  docker logs alertmanager
  docker logs node-exporter
  docker logs blackbox-exporter
  docker logs monitoring-nginx

[Scripts — คำสั่งต่างๆ]

  /usr/local/sbin/monitoring-*
      helper commands ทั้งหมด (monitoring-info, monitoring-add-* ฯลฯ)

  /usr/local/sbin/grafana-prometheus-bootstrap.sh
      script ที่รันตอนเปิดเครื่องครั้งแรก

  /etc/systemd/system/grafana-prometheus-bootstrap.service
      systemd service — ควบคุมการเปิด/ปิดระบบ

  /etc/update-motd.d/99-grafana-prometheus-image
      MOTD — ข้อความที่เห็นตอน login

=========================================================================
