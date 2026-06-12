# Cloud-init User Data — ลูกค้าสร้าง VM

> user-data ที่ลูกค้าใส่ตอนสร้าง VM จาก guest image ที่ build แล้ว

---

## กรณีที่ 1 — Password

```yaml
#cloud-config
disable_root: false

chpasswd:
  expire: true
  users:
    - name: root
      password: "CHANGE_ME_TEMP_PASSWORD"
      type: text

runcmd:
  - passwd -u root || true
  - chage -d 0 root || true
  - mkdir -p /etc/ssh/sshd_config.d
  - find /etc/ssh/sshd_config.d -maxdepth 1 -type f -name '*.conf' -delete
  - printf 'PermitRootLogin yes\nPasswordAuthentication yes\nPubkeyAuthentication yes\nKbdInteractiveAuthentication no\nUsePAM yes\n' > /etc/ssh/sshd_config.d/00-image-build.conf
  - systemctl restart ssh || systemctl restart sshd || true
```

Login: `ssh root@<IP>` → ใช้ password ชั่วคราวที่ตั้งไว้ → ระบบบังคับเปลี่ยน password ใหม่

---

## กรณีที่ 2 — Keypair

```yaml
#cloud-config
disable_root: false

chpasswd:
  expire: true
  users:
    - name: root
      password: "CHANGE_ME_TEMP_PASSWORD"
      type: text

ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAA...     # ← ใส่ public key จริง

runcmd:
  - passwd -u root || true
  - chage -d 0 root || true
  - mkdir -p /etc/ssh/sshd_config.d
  - find /etc/ssh/sshd_config.d -maxdepth 1 -type f -name '*.conf' -delete
  - printf 'PermitRootLogin yes\nPasswordAuthentication no\nPubkeyAuthentication yes\nKbdInteractiveAuthentication no\nUsePAM yes\n' > /etc/ssh/sshd_config.d/00-image-build.conf
  - systemctl restart ssh || systemctl restart sshd || true
```

Login: `ssh -i <private_key> root@<IP>` → ใช้ key auth และ password ชั่วคราวสำหรับบังคับเปลี่ยน password

---

## ความต่าง

| | Password | Keypair |
|---|---|---|
| `PasswordAuthentication` | `yes` | `no` |
| `PubkeyAuthentication` | `yes` | `yes` |
| `ssh_authorized_keys` | ไม่มี | มี |
| login ด้วย | password | key เท่านั้น |
| บังคับเปลี่ยน password | ✅ | ✅ |
