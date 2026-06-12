# Guest Images — Build Pipeline

> **Version:** 2026-05-31
> **ใช้กับ:** OpenStack Lab — สร้าง guest image พื้นฐานสำหรับให้ลูกค้าสร้าง VM (9 OS)

---

## OS Comparison

| เรื่อง | AlmaLinux 10 | Debian 13 | Fedora 44 | Rocky 10 | Ubuntu 24.04 | Ubuntu 26.04 |
|---|---|---|---|---|---|---|
| Pkg manager | `dnf` | `apt` | `dnf5` | `dnf` | `apt` | `apt` |
| SSH service | `sshd` | `ssh` | `sshd` | `sshd` | `ssh` | `ssh` |
| Default user | `almalinux` | `debian` | `fedora` | — | `ubuntu` | `ubuntu` |
| Firewall | — | `ufw` | — | — | `ufw` | `ufw` |
| SELinux | Enforcing | — | Enforcing | Enforcing | — | — |
| `/var/lib/dbus/machine-id` | ไม่มี | มี → `ln -sf` | ไม่มี | ไม่มี | มี → `ln -sf` | มี → `ln -sf` |
| Locale pre-set | ไม่ | ไม่ | ใช่ | ไม่ | ไม่ | ไม่ |
| Kernel cleanup | `rpm -qa kernel-core` | `dpkg-query linux-image-*` | `rpm -qa kernel-core` | `rpm -qa kernel-core` | `dpkg-query linux-image-*` | `dpkg-query linux-image-*` |
| MOTD news | — | disable | — | — | disable | disable |

### OS เพิ่มเติม (2026-05-31)

| เรื่อง | CentOS Stream 10 | Oracle Linux 9 | openSUSE Leap 16.0 |
|---|---|---|---|
| Pkg manager | `dnf` | `dnf` | `zypper` |
| SSH service | `sshd` | `sshd` | `sshd` |
| Default user | `cloud-user` | `opc` | `root` |
| Firewall | `firewalld` | `firewalld` | `firewalld` |
| SELinux | Enforcing | Enforcing | — (AppArmor) |
| `/var/lib/dbus/machine-id` | ไม่มี | ไม่มี | มี → `ln -sf` |
| Locale pre-set | ไม่ | ไม่ | ใช่ |
| Kernel cleanup | `rpm -qa kernel-core` | `rpm -qa kernel-core` | `rpm -qa kernel-default` |
| MOTD news | — | — | — |

---

## Cloud-init Phase A — ใส่ตอนสร้าง VM

ใช้เหมือนกันทุก OS:

```yaml
#cloud-config
disable_root: false

chpasswd:
  expire: false
  users:
    - name: root
      password: "CHANGE_ME_TEMP_PASSWORD"
      type: text

runcmd:
  - passwd -u root || true
  - chage -d -1 root || true
  - mkdir -p /etc/ssh/sshd_config.d
  - printf 'PermitRootLogin yes\nPasswordAuthentication yes\nPubkeyAuthentication yes\nKbdInteractiveAuthentication no\nUsePAM yes\n' > /etc/ssh/sshd_config.d/00-image-build.conf
  - systemctl restart ssh || systemctl restart sshd || true
```

---

## Mirror Configuration — เปลี่ยนเป็น mirror ไทย

> **หลักการ:** cloud-init ใน Ubuntu cloud image จะ rewrite `/etc/apt/sources.list.d/ubuntu.sources` ทุกครั้งที่ VM เกิดใหม่ โดยดึง mirror URL จาก OpenStack metadata (`nova.clouds.archive.ubuntu.com`) → `sed` ใน golden image อย่างเดียวไม่พอ ต้องฝัง cloud-init config ให้ VM ใหม่ใช้ mirror ไทยอัตโนมัติ
>
> **Mirror policy:** Ubuntu 26.04 ใช้ `mirrors.openlandscape.cloud/ubuntu/` (first priority) — Ubuntu 24.04 ใช้ `mirror1.ku.ac.th/ubuntu/`
>
> **Source of truth:** mirror ปัจจุบันดูที่ `docs/references/mirrors.md` และคำสั่ง `sed` ทุกตัวเป็น template ต้อง `grep` pattern จริงบน `[golden-image VM]` ก่อนใช้

### ขั้นตอน (ทำใน golden image VM ก่อน capture)

**1. เปลี่ยน mirror ทันที (สำหรับ session ปัจจุบัน)**

[golden-image VM]

```bash
# เช็คก่อนเปลี่ยน
grep -n 'URIs' /etc/apt/sources.list.d/ubuntu.sources

# เปลี่ยน primary + security → mirror ไทย
# Ubuntu 24.04: mirror1.ku.ac.th
# Ubuntu 26.04: mirrors.openlandscape.cloud (first priority)
MIRROR="mirror1.ku.ac.th"   # เปลี่ยนเป็น mirrors.openlandscape.cloud สำหรับ 26.04
sudo sed -i \
  -e "s|http://nova.clouds.archive.ubuntu.com/ubuntu/|http://${MIRROR}/ubuntu/|g" \
  -e "s|http://security.ubuntu.com/ubuntu|http://${MIRROR}/ubuntu/|g" \
  /etc/apt/sources.list.d/ubuntu.sources

# verify
grep -n 'URIs' /etc/apt/sources.list.d/ubuntu.sources
sudo apt update
```

**2. ฝัง cloud-init config (ให้ VM ใหม่ใช้ mirror ไทยตลอดไป)**

[golden-image VM]

```bash
# Ubuntu 24.04: mirror1.ku.ac.th
# Ubuntu 26.04: mirrors.openlandscape.cloud (first priority)
MIRROR="mirror1.ku.ac.th"   # เปลี่ยนเป็น mirrors.openlandscape.cloud สำหรับ 26.04
sudo tee /etc/cloud/cloud.cfg.d/99-thai-mirror.cfg > /dev/null << EOF
apt:
  primary:
    - arches: [default]
      uri: http://${MIRROR}/ubuntu/
  security:
    - arches: [default]
      uri: http://${MIRROR}/ubuntu/
EOF

cat /etc/cloud/cloud.cfg.d/99-thai-mirror.cfg   # verify
```

### Verify หลัง capture

สร้าง VM ใหม่จาก image → `apt update` → output ต้องเป็น mirror ที่ตั้งไว้ (24.04: `mirror1.ku.ac.th`, 26.04: `mirrors.openlandscape.cloud`) ทั้ง primary **และ** security — ต้อง**ไม่มี** `nova.clouds.archive.ubuntu.com` หรือ `security.ubuntu.com`

### OS อื่น

| OS | Mirror URL | cloud-init config ไฟล์ |
|---|---|---|
| Ubuntu 26.04 | `http://mirrors.openlandscape.cloud/ubuntu/` | ✅ `99-thai-mirror.cfg` (sed `.sources` + cloud-init) |
| Ubuntu 24.04 | `http://mirror1.ku.ac.th/ubuntu/` | ✅ `99-thai-mirror.cfg` (sed `.sources` + cloud-init) |
| Debian 13 | `http://mirror1.ku.ac.th/debian/` (primary) + `/debian-security/` (security) | `mirror+file://` → overwrite `/etc/apt/mirrors/` + `99-thai-mirror.cfg` |
| AlmaLinux 10 | `http://mirror1.ku.ac.th/almalinux/` | ไม่ต้อง cloud-init — `sed` ใน `/etc/yum.repos.d/*.repo` |
| Rocky 10 | `http://mirror1.ku.ac.th/rocky-linux/` | ไม่ต้อง cloud-init — `sed` ใน `/etc/yum.repos.d/*.repo` |
| CentOS Stream 10 | `http://mirror1.ku.ac.th/centos-stream/` (ต้อง verify) | ไม่ต้อง cloud-init — `sed` ใน `/etc/yum.repos.d/centos*.repo` |
| Oracle Linux 9 | `http://mirror1.ku.ac.th/oracle-linux/` (ต้อง verify) | ไม่ต้อง cloud-init — `sed` ใน `/etc/yum.repos.d/oraclelinux*.repo` |
| openSUSE Leap 16.0 | `http://mirror1.ku.ac.th/opensuse/` (ต้อง verify) | ไม่ต้อง cloud-init — `zypper mr` + `zypper ar` |
| Fedora 44 | ไม่มี mirror ไทย — ใช้ metalink (default) | — |

### Rocky 10 — เปลี่ยน mirror

```bash
# เช็คก่อนเปลี่ยน
grep -n 'mirrorlist\|baseurl' /etc/yum.repos.d/rocky*.repo

# disable mirrorlist + set baseurl → mirror1.ku.ac.th
# (openlandscape.cloud ไม่มี Rocky 10 — directory เปล่า)
sudo sed -i \
  -e 's/^mirrorlist=/#mirrorlist=/' \
  -e 's|^#baseurl=http://dl.rockylinux.org/\$contentdir|baseurl=http://mirror1.ku.ac.th/rocky-linux|' \
  /etc/yum.repos.d/rocky*.repo

# verify
grep -n 'baseurl\|^mirrorlist' /etc/yum.repos.d/rocky*.repo
sudo dnf makecache
```

### AlmaLinux 10 — เปลี่ยน mirror

> **บทเรียน:** AlmaLinux 10 repo format ต่างจาก Rocky — มี space หลัง `#`, ใช้ `repo.almalinux.org` (ไม่ใช่ `dl.almalinux.org`), ไม่มี `$contentdir`

```bash
# เช็คก่อนเปลี่ยน
grep -n 'mirrorlist\|baseurl' /etc/yum.repos.d/almalinux*.repo

# Step 1 — comment mirrorlist (pattern จริง: mirrors.almalinux.org)
sudo sed -i 's|^mirrorlist=https://mirrors.almalinux.org|#mirrorlist=https://mirrors.almalinux.org|' \
  /etc/yum.repos.d/almalinux*.repo

# Step 2 — uncomment + redirect baseurl (repo.almalinux.org → mirror1.ku.ac.th)
sudo sed -i 's|^# baseurl=https://repo.almalinux.org/almalinux/|baseurl=http://mirror1.ku.ac.th/almalinux/|' \
  /etc/yum.repos.d/almalinux*.repo

# verify
grep -n 'baseurl\|^mirrorlist' /etc/yum.repos.d/almalinux*.repo
sudo dnf makecache
```

### Debian 13 — เปลี่ยน mirror (`mirror+file://`)

> **สำคัญ:** Debian 13 cloud image ใช้ `mirror+file://` — เปลี่ยนโดย overwrite `/etc/apt/mirrors/*.list` (ไม่ใช่ sed `.sources` แบบ Ubuntu)
> `openlandscape.cloud` **ไม่มี** debian-security → ต้องใช้ `mirror1.ku.ac.th` ซึ่งมีทั้ง primary + security

```bash
# Primary mirror (trixie, trixie-updates, trixie-backports)
echo 'http://mirror1.ku.ac.th/debian' | sudo tee /etc/apt/mirrors/debian.list

# Security mirror (trixie-security)
echo 'http://mirror1.ku.ac.th/debian-security' | sudo tee /etc/apt/mirrors/debian-security.list

# Disable PDiffs (mirror ไทยไม่มี pdiff)
echo 'Acquire::PDiffs "false";' | sudo tee /etc/apt/apt.conf.d/99-no-pdiffs

# Cloud-init config (กัน VM ใหม่ rewrite sources)
sudo tee /etc/cloud/cloud.cfg.d/99-thai-mirror.cfg > /dev/null << 'EOF'
apt:
  primary:
    - arches: [default]
      uri: http://mirror1.ku.ac.th/debian/
  security:
    - arches: [default]
      uri: http://mirror1.ku.ac.th/debian-security/
EOF

# Verify
cat /etc/apt/mirrors/debian.list /etc/apt/mirrors/debian-security.list
sudo apt update
```

> **ทดสอบหลัง capture:** Debian `mirror+file://` + cloud-init `apt_configure` — behavior ยังไม่ยืนยัน ต้องสร้าง VM ใหม่จาก image → `apt update` verify

### CentOS Stream 10 — เปลี่ยน mirror

> **⚠️ สำคัญ:** CentOS Stream 10 ใช้ `metalink=` (ไม่ใช่ `mirrorlist=` เหมือน Alma/Rocky) — **ห้ามใช้ sed approach แบบ Alma/Rocky** เพราะ grep ไม่เจอ + repos แยกกัน 2 ไฟล์
> Approach: verify mirror path → disable repo เดิมทั้ง 2 ไฟล์ → สร้าง `centos-th.repo` ใหม่
> `mirror1.ku.ac.th/centos-stream/10-stream/` มี BaseOS, AppStream, CRB — **ไม่มี extras-common (404)**
> Default user: `cloud-user`

```bash
# Step A — verify (CentOS Stream ใช้ metalink=)
grep 'metalink\|^enabled' /etc/yum.repos.d/centos*.repo
curl -sI http://mirror1.ku.ac.th/centos-stream/10-stream/BaseOS/x86_64/os/ | head -1
# ต้องได้ HTTP/1.1 200 OK — ถ้า 404 → path ผิด

# Step B — disable repo เดิมทั้ง 2 ไฟล์
sudo mv /etc/yum.repos.d/centos.repo /etc/yum.repos.d/centos.repo.bak
sudo mv /etc/yum.repos.d/centos-addons.repo /etc/yum.repos.d/centos-addons.repo.bak

# Step C — สร้าง repo ไทยใหม่
sudo tee /etc/yum.repos.d/centos-th.repo > /dev/null << 'EOF'
[baseos]
name=CentOS Stream 10 - BaseOS
baseurl=http://mirror1.ku.ac.th/centos-stream/10-stream/BaseOS/$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial-SHA256
enabled=1

[appstream]
name=CentOS Stream 10 - AppStream
baseurl=http://mirror1.ku.ac.th/centos-stream/10-stream/AppStream/$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial-SHA256
enabled=1

[crb]
name=CentOS Stream 10 - CRB
baseurl=http://mirror1.ku.ac.th/centos-stream/10-stream/CRB/$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial-SHA256
enabled=0
EOF

# Step D — verify
sudo dnf makecache
```

### Oracle Linux 9 — เปลี่ยน mirror

> pipeline เดียวกับ AlmaLinux/Rocky — RPM-based, `dnf`, SELinux Enforcing
> default user: `opc`
> Mirror URL ต้อง verify (`mirror1.ku.ac.th` อาจไม่มี oracle-linux — fallback `yum.oracle.com`)

```bash
# เช็คก่อนเปลี่ยน
grep -n 'mirrorlist\|baseurl' /etc/yum.repos.d/oraclelinux*.repo

# disable mirrorlist + set baseurl → mirror ไทย
sudo sed -i \
  -e 's/^mirrorlist=/#mirrorlist=/' \
  -e 's|^#baseurl=https://yum.oracle.com|baseurl=http://mirror1.ku.ac.th/oracle-linux|' \
  /etc/yum.repos.d/oraclelinux*.repo

# verify
grep -n 'baseurl\|^mirrorlist' /etc/yum.repos.d/oraclelinux*.repo
sudo dnf makecache
```

### openSUSE Leap 16.0 — เปลี่ยน mirror (zypper)

> **สำคัญ:** openSUSE ใช้ `zypper` (ไม่ใช่ dnf/apt) — workflow ต่างจาก OS อื่น
> Default user: `root`
> Mirror URL ต้อง verify — `mirror1.ku.ac.th/opensuse` อาจไม่มี Leap 16.0

```bash
# Step 1 — เช็ค repo ปัจจุบัน
zypper lr -u

# Step 2 — disable repo เก่าทั้งหมด + ตั้ง repo ใหม่ด้วย mirror ไทย
sudo zypper mr -da
sudo zypper ar -f http://mirror1.ku.ac.th/opensuse/distribution/leap/16.0/repo/oss/ main-oss
sudo zypper ar -f http://mirror1.ku.ac.th/opensuse/distribution/leap/16.0/repo/non-oss/ main-non-oss
sudo zypper ar -f http://mirror1.ku.ac.th/opensuse/update/leap/16.0/oss/ update-oss
sudo zypper ar -f http://mirror1.ku.ac.th/opensuse/update/leap/16.0/non-oss/ update-non-oss

# Step 3 — verify
zypper lr -u
sudo zypper --non-interactive refresh
```

> **หมายเหตุ:** cloud-init ไม่ rewrite zypper repo config — `zypper mr` ครั้งเดียวพอ ไม่ต้อง `99-thai-mirror.cfg`

### RPM-based OS — หลักการ

cloud-init ไม่ rewrite repo config แบบ Ubuntu → `sed` ใน golden image ครั้งเดียวพอ ไม่ต้อง `99-thai-mirror.cfg`

---

## Set 1 — หลังสร้าง VM เสร็จ (upgrade)

**RPM-based (Alma, Rocky, Fedora, CentOS Stream, Oracle):**
```bash
cloud-init status --wait
dnf clean all && dnf -y makecache
dnf -y upgrade --refresh                             # Alma/Rocky/CentOS/Oracle
# dnf5 -y upgrade --refresh                          # Fedora 44
```

**openSUSE Leap (zypper):**
```bash
cloud-init status --wait
zypper --non-interactive update
```

**DEB-based (Debian, Ubuntu):**
```bash
cloud-init status --wait
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
```

> หลังเสร็จ → **reboot จาก host**: `openstack server reboot <SERVER_ID>`

---

## Set 2 — หลัง reboot เสร็จ (configure)

```bash
# ── Kernel cleanup (เหลือ 2 ตัวล่าสุด) ─────────────────────
# RPM (Alma/Rocky/CentOS/Oracle):
mapfile -t KERNELS < <(rpm -qa kernel-core | sort -V)
COUNT=${#KERNELS[@]}
if (( COUNT >= 3 )); then
  TO_REMOVE=("${KERNELS[@]:0:$((COUNT-2))}")
  dnf remove -y "${TO_REMOVE[@]}"                    # Alma/Rocky/CentOS/Oracle
  # dnf5 remove -y "${TO_REMOVE[@]}"                 # Fedora
fi

# openSUSE (ใช้ kernel-default ไม่ใช่ kernel-core):
# mapfile -t KERNELS < <(rpm -qa kernel-default | sort -V)
# COUNT=${#KERNELS[@]}
# if (( COUNT >= 3 )); then
#   TO_REMOVE=("${KERNELS[@]:0:$((COUNT-2))}")
#   zypper remove -y "${TO_REMOVE[@]}"
# fi

# DEB:
mapfile -t KERNELS < <(dpkg-query -W -f='${Package}\n' 'linux-image-[0-9]*' | sort -V)
COUNT=${#KERNELS[@]}
if (( COUNT >= 3 )); then
  TO_REMOVE=("${KERNELS[@]:0:$((COUNT-2))}")
  DEBIAN_FRONTEND=noninteractive apt-get purge -y "${TO_REMOVE[@]}"
  apt-get autoremove -y
fi

# ── Locale + Timezone ──────────────────────────────────────
localectl set-locale LANG=en_US.UTF-8                 # ทุก OS (Fedora ข้ามได้)
locale-gen en_US.UTF-8                                # เฉพาะ Debian/Ubuntu
timedatectl set-timezone Asia/Bangkok

# ── Cloud-init OpenStack config ────────────────────────────
mkdir -p /etc/cloud/cloud.cfg.d
cat > /etc/cloud/cloud.cfg.d/99-openstack-imagebuild.cfg << 'EOF'
disable_root: false
preserve_hostname: false
manage_etc_hosts: true
datasource_list: [ConfigDrive, OpenStack, None]
EOF

# ── Disable auto-updates ───────────────────────────────────
systemctl disable --now dnf-automatic.timer 2>/dev/null || true     # RPM
systemctl disable --now apt-daily.timer apt-daily-upgrade.timer \
  apt-daily.service apt-daily-upgrade.service \
  unattended-upgrades.service 2>/dev/null || true                    # DEB

# ── Growpart verify ────────────────────────────────────────
which growpart || echo "WARNING: growpart not found"

# ── Disable firewall ───────────────────────────────────────
systemctl disable --now firewalld.service 2>/dev/null || true       # RPM (ยกเว้น Fedora)
systemctl disable --now ufw.service 2>/dev/null || true             # DEB

# ── SELinux relabel (RPM เท่านั้น) ─────────────────────────
restorecon -Rv /etc/ssh/ /etc/cloud/

# ── SSH Policy ─────────────────────────────────────────────
find /etc/ssh/sshd_config.d -maxdepth 1 -type f -name '*.conf' -delete
printf 'PermitRootLogin yes\nPasswordAuthentication yes\nPubkeyAuthentication yes\nKbdInteractiveAuthentication no\nUsePAM yes\n' \
  > /etc/ssh/sshd_config.d/00-image-build.conf
sshd -t && systemctl restart sshd                       # Alma/Rocky/Fedora
# sshd -t && systemctl restart ssh                      # Debian/Ubuntu

# ── Per-instance script (copy authorized_keys → root) ────
mkdir -p /var/lib/cloud/scripts/per-instance
cat > /var/lib/cloud/scripts/per-instance/10-root-authorized-keys.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
install -d -m 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
for f in /home/*/.ssh/authorized_keys; do
  [ -f "$f" ] || continue
  cat "$f" >> /root/.ssh/authorized_keys
  break
done
sort -u /root/.ssh/authorized_keys -o /root/.ssh/authorized_keys || true
EOF
chmod +x /var/lib/cloud/scripts/per-instance/10-root-authorized-keys.sh

# ── Enable services ────────────────────────────────────────
systemctl enable --now qemu-guest-agent 2>/dev/null || true
systemctl enable sshd                                  # Alma/Rocky/Fedora
# systemctl enable ssh                                 # Debian/Ubuntu

# ── Disable MOTD news (Debian/Ubuntu เท่านั้น) ────────────
echo 'ENABLED=0' > /etc/default/motd-news 2>/dev/null || true

# ── Validate ───────────────────────────────────────────────
echo "=== SSH Policy ===" && sshd -T | grep -Ei 'permitrootlogin|passwordauthentication|pubkeyauthentication'
echo "=== Timezone ===" && timedatectl | grep "Time zone"
echo "=== Locale ===" && localectl | grep "System Locale"
echo "=== Kernel count ===" && rpm -qa kernel-core | sort -V  # or: dpkg-query -W -f='${Package}\n' 'linux-image-[0-9]*' | sort -V
echo "=== Per-instance script ===" && ls -la /var/lib/cloud/scripts/per-instance/
echo "=== 00-image-build.conf ===" && cat /etc/ssh/sshd_config.d/00-image-build.conf
echo "=== datasource config ===" && cat /etc/cloud/cloud.cfg.d/99-openstack-imagebuild.cfg
echo "=== Cloud-init status ===" && cloud-init status
```

---

## Set 3 — Clean ก่อน capture

```bash
# Step 1: Package cleanup — ข้าม (เก็บ packages/cache ลด inter bandwidth หลัง deploy)
# dnf autoremove -y                                                # Alma/Rocky
# dnf5 autoremove -y                                               # Fedora
# DEBIAN_FRONTEND=noninteractive apt-get autoremove --purge -y      # Debian/Ubuntu

# Step 2: Cloud-init clean
cloud-init clean --logs --seed
rm -rf /var/lib/cloud/instances/* /var/lib/cloud/instance /var/lib/cloud/sem/*

# Step 3: Remove netplan (if any)
rm -f /etc/netplan/50-cloud-init.yaml

# Step 4: Truncate machine-id
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id 2>/dev/null || true     # RPM
# rm -f /var/lib/dbus/machine-id                       # DEB
# ln -sf /etc/machine-id /var/lib/dbus/machine-id      # DEB

# Step 5: Remove SSH host keys
rm -f /etc/ssh/ssh_host_*

# Step 6: Clean sshd_config.d (keep 00-image-build.conf)
find /etc/ssh/sshd_config.d -maxdepth 1 -type f -name '*.conf' \
  ! -name '00-image-build.conf' -delete

# Step 7: Remove build-time authorized keys
rm -f /root/.ssh/authorized_keys
rm -f /home/*/.ssh/authorized_keys

# Step 8: Clean history / tmp / logs
rm -f /root/.bash_history
rm -f /home/*/.bash_history
history -c
rm -rf /tmp/* /var/tmp/*
find /var/log -type f -name '*.log' -exec truncate -s 0 {} +
truncate -s 0 /var/log/wtmp /var/log/btmp /var/log/lastlog

# Step 9: Remove repo backup (if any)
rm -rf /var/backups/image-build/repos

# Step 10: fstrim + sync
fstrim -av
sync
```

> หลังเสร็จ → **shutdown จาก host**: `openstack server stop <SERVER_ID>` → รอ SHUTOFF → capture image

---

## Capture Image

```bash
openstack server image create --name "<OS>-guest-YYYYMMDD" <SERVER_ID>
```

---

## Build Verification

| OS | Download | Repo | Config | สถานะ |
|---|---|---|---|---|
| AlmaLinux 10 | ✅ | ✅ | ✅ | ✅ เสร็จ |
| Debian 13 | ✅ | ✅ | ✅ | ✅ เสร็จ |
| Fedora 44 | ✅ | ✅ | ✅ | ✅ เสร็จ |
| Rocky 10 | ✅ | ✅ | ✅ | ✅ เสร็จ |
| Ubuntu 24.04 | ✅ | ✅ | ✅ | ✅ เสร็จ |
| Ubuntu 26.04 | ✅ | ✅ | ✅ | ✅ เสร็จ |
| CentOS Stream 10 | ✅ | ✅ | ✅ | ✅ เสร็จ |
| Oracle Linux 9 | ❌ | ❌ | ❌ | ❌ รอ verify mirror |
| openSUSE Leap 16.0 | ❌ | ❌ | ❌ | ❌ รอ verify mirror |

---

## Per-OS Notes

### AlmaLinux 10
- `dnf` (ไม่ใช่ `dnf5`)
- SELinux Enforcing — ต้อง `restorecon`
- `/var/lib/dbus/machine-id` ไม่มี — ข้าม error ได้

### Rocky 10
- `dnf` (ไม่ใช่ `dnf5`)
- SELinux Enforcing — ต้อง `restorecon`
- `/var/lib/dbus/machine-id` ไม่มี — ข้าม error ได้

### Fedora 44
- `dnf5` (`yum` เป็น symlink ไป `dnf5` — ใช้ได้ทั้งคู่ แต่ใน pipeline ใช้ `dnf5`)
- SELinux Enforcing — ต้อง `restorecon`
- `/var/lib/dbus/machine-id` ไม่มี — ข้าม error ได้
- Locale ตั้งมาแล้วใน base image — ข้าม `localectl set-locale`
- Mirror: ไม่มี mirror ไทย — ใช้ metalink (default) ไม่ต้อง config mirror
- Latest build: 44-1.7 (Apr 2026)
- Kernel: `6.19.x / 7.0.x (fc44)`
- qemu-guest-agent: pre-installed + enabled จาก base image

### Debian 13
- `apt`, SSH ชื่อ `ssh` (ไม่ใช่ `sshd`)
- ใช้ AppArmor (ไม่ต้อง `restorecon`)
- `/var/lib/dbus/machine-id` มี — ต้อง `ln -sf` ไม่ใช่แค่ลบ
- ต้อง `locale-gen en_US.UTF-8` ก่อน `localectl set-locale`

### Ubuntu 24.04
- `apt`, SSH ชื่อ `ssh` (ไม่ใช่ `sshd`)
- ใช้ AppArmor (ไม่ต้อง `restorecon`)
- `/var/lib/dbus/machine-id` มี — ต้อง `ln -sf` ไม่ใช่แค่ลบ
- ต้อง `locale-gen en_US.UTF-8` ก่อน `localectl set-locale`
- disable MOTD news: `echo 'ENABLED=0' > /etc/default/motd-news`
- Mirror: `mirror1.ku.ac.th/ubuntu/`

### Ubuntu 26.04
- Codename: `resolute`
- Pipeline เหมือน Ubuntu 24.04 ทุกอย่าง — `.sources` (deb822), cloud-init rewrite, `99-thai-mirror.cfg`
- `apt`, SSH ชื่อ `ssh` (ไม่ใช่ `sshd`)
- ใช้ AppArmor (ไม่ต้อง `restorecon`)
- `/var/lib/dbus/machine-id` มี — ต้อง `ln -sf` ไม่ใช่แค่ลบ
- ต้อง `locale-gen en_US.UTF-8` ก่อน `localectl set-locale`
- disable MOTD news: `echo 'ENABLED=0' > /etc/default/motd-news`
- Mirror: `mirrors.openlandscape.cloud/ubuntu/` (first priority)
- Kernel: `linux-image-7.0.0-xx-generic` (24.04 เป็น 6.x)

### CentOS Stream 10
- `dnf` (ไม่ใช่ `dnf5`)
- SELinux Enforcing — ต้อง `restorecon`
- `/var/lib/dbus/machine-id` ไม่มี — ข้าม error ได้
- pipeline เดียวกับ AlmaLinux/Rocky — เปลี่ยนแค่ repo path
- default user: `cloud-user`

### Oracle Linux 9
- `dnf` (ไม่ใช่ `dnf5`)
- SELinux Enforcing — ต้อง `restorecon`
- `/var/lib/dbus/machine-id` ไม่มี — ข้าม error ได้
- pipeline เดียวกับ AlmaLinux/Rocky — เปลี่ยนแค่ repo path
- default user: `opc`
- kernel: UEK (Unbreakable Enterprise Kernel) หรือ RHCK → `rpm -qa kernel-uek*` หรือ `kernel-core`

### openSUSE Leap 16.0
- `zypper` (ไม่ใช่ dnf/apt) — ใช้คำสั่งต่างจาก OS อื่น
- SSH ชื่อ `sshd` — `systemctl enable sshd`
- ใช้ AppArmor (ไม่ต้อง `restorecon`)
- `/var/lib/dbus/machine-id` มี — ต้อง `ln -sf`
- Kernel cleanup ใช้ `rpm -qa kernel-default` (ไม่ใช่ `kernel-core`)
- cloud-init ไม่แตะ repo config — `zypper mr` ครั้งเดียวพอ
- Locale ตั้งมาแล้วใน JeOS base image — ข้าม `localectl set-locale`

> **ConfigDrive** ต้องอยู่ตัวแรกใน datasource_list — HTTP metadata (`169.254.169.254`) timeout ใน environment
