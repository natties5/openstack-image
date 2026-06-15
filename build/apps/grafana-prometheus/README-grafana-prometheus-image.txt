Grafana+Prometheus Monitoring Image
====================================

This VM is a self-service monitoring appliance for VM, website, API, TCP port,
and ping checks that this VM can reach over the network.

First steps:
  1. Open TCP 80 to access Grafana.
  2. SSH into the VM.
  3. Read generated login info:
       sudo monitoring-info
  4. Open Grafana:
       http://<VM-IP>/

Common commands:
  sudo monitoring-info
  sudo monitoring-status
  sudo monitoring-list-targets
  sudo monitoring-add-http https://example.com website
  sudo monitoring-add-node 10.0.0.12:9100 web-01
  sudo monitoring-add-tcp 10.0.0.20:5432 postgres-01
  sudo monitoring-add-ping 10.0.0.30 router-01
  sudo monitoring-reset-grafana-password

Network notes:
  - HTTP/HTTPS/TCP/ping checks work when this VM can reach the target.
  - Linux CPU/RAM/Disk metrics require node_exporter on the target VM and TCP 9100 open from this VM.
  - Prometheus and Alertmanager are bound to 127.0.0.1 on this VM.

If this VM was created from a snapshot of another already-used VM, the old
Grafana password and monitoring state may be copied too. Run:
  sudo monitoring-reset-grafana-password
if you want a new Grafana admin password.
