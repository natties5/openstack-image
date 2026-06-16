# Grafana+Prometheus — AI Mistakes Log

> บันทึกคำสั่งที่ AI ให้แล้วพังระหว่าง build image นี้

## 2026-06-15 Build VM

| Date | Phase | Failed command | Error | Root cause | Fix |
|---|---|---|---|---|---|
| 2026-06-15 | Local SSH helper | `python -m pip install --user paramiko` | `Microsoft Visual C++ 14.0 or greater is required` while building `cffi` for Python 3.15 | Local Python 3.15 alpha had no compatible wheel for dependency chain | Used temporary Node `ssh2` helper instead; no credential written to repo |
| 2026-06-15 | Validate configs | `docker run --rm -v /opt/monitoring/prometheus:/etc/prometheus:ro prom/prometheus:latest promtool check config /etc/prometheus/prometheus.yml` | `prometheus: error: unexpected promtool` | `prom/prometheus:latest` image entrypoint is `prometheus`, so `promtool` was passed as an argument | Use `docker run --rm --entrypoint promtool ... check config ...` |
| 2026-06-15 | Pull images | `docker compose -f /opt/monitoring/docker-compose.yml pull` | Docker Hub/CloudFront `TLS handshake timeout` | Transient network pull timeout | Retry pulls per service; images pulled successfully |
| 2026-06-15 | Bootstrap | `/usr/local/sbin/grafana-prometheus-bootstrap.sh` | `env: $'bash\r': No such file or directory` | Scripts uploaded from Windows had CRLF line endings | Run `sed -i 's/\r$//'` on executable scripts after copy; added to guide |
| 2026-06-15 | Smoke test | `curl -fsS http://127.0.0.1:9093/-/healthy` | Alertmanager restart loop; logs showed `open /etc/alertmanager/alertmanager.yml: permission denied` | Guide set config file permission to `600`, but Alertmanager container does not read it as root | Change permission to `644`; Alertmanager became healthy |
| 2026-06-15 | Post-test coverage | Console login / MOTD path was not tested | User saw `run-parts: failed to exec /etc/update-motd.d/99-grafana-prometheus-image: No such file or directory` on console login | Post-check missed `/etc/update-motd.d` execution and CRLF/shebang validation; file can exist but fail if shebang has CRLF | Added MOTD/run-parts/shebang checks to post-check; verify with `run-parts /etc/update-motd.d` and `head -1 ... | od -An -tx1` |

---

## Template

| Date | Phase | Failed command | Error | Root cause | Fix |
|---|---|---|---|---|---|
| — | — | — | — | — | — |
