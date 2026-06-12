# Provider Interface Renamed Back After Reboot

## Symptom

ต้องการเปลี่ยนชื่อขา provider NIC เป็น `{provider-interface}` ผ่าน netplan แล้ว `netplan apply` หรือ reboot แล้วชื่อยังกลับไปเป็น `{old-interface}` หรือมี log ว่า rename สำเร็จแล้วแต่ถูกเปลี่ยนกลับอีกครั้ง

ตัวอย่างอาการ:

```text
{old-interface}: renamed from ethX
{provider-interface}: renamed from {old-interface}
{old-interface}: renamed from {provider-interface}
```

หรือ `ip -br a` หลัง reboot ยังเห็น `{old-interface}` แทน `{provider-interface}`

## Why It Broke

`set-name` ใน netplan ไม่ได้ rename interface แบบถาวรด้วยตัวเอง แต่ netplan generate rule ให้ udev/systemd-networkd ใช้ตอน boot

ถ้ามี config ต้นทางของ cloud-init/curtin ยังระบุชื่อเก่าอยู่ เช่น:

```yaml
set-name: {old-interface}
```

cloud-init หรือ rule ที่ generate จาก config เก่าอาจ rename interface กลับเป็นชื่อเดิมหลังจาก netplan rename เป็นชื่อใหม่แล้ว

ไฟล์ที่มักเกี่ยวข้อง:

```text
/etc/netplan/50-cloud-init.yaml
/etc/cloud/cloud.cfg.d/50-curtin-networking.cfg
/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
/run/systemd/network/*.link
```

## Confirm

เช็กว่า interface runtime เป็นชื่ออะไร:

```bash
ip -br a
ip a
```

เช็กว่า netplan generate `.link` rule ให้ชื่อใหม่แล้วหรือยัง:

```bash
ls -l /run/systemd/network/*{provider-interface}*
udevadm test-builtin net_setup_link /sys/class/net/{old-interface} 2>&1 | grep -iE '{provider-interface}|name|link'
```

เช็ก log rename ตอน boot:

```bash
journalctl -b | grep -iE '{provider-interface}|{old-interface}|rename'
```

ถ้าเห็น sequence แบบนี้ แปลว่า rename เป็นชื่อใหม่สำเร็จแล้ว แต่มีบางอย่าง rename กลับ:

```text
{provider-interface}: renamed from {old-interface}
{old-interface}: renamed from {provider-interface}
```

ค้นหา config ที่ยังอ้างชื่อเก่าหรือ MAC ของ provider NIC:

```bash
grep -R "{old-interface}\|{provider-interface}\|{provider-mac}" /etc /run /usr/lib/systemd/network /lib/udev/rules.d /etc/udev/rules.d 2>/dev/null
```

## Fix

แก้ netplan ให้ provider NIC ใช้ชื่อเป้าหมายและ match ด้วย MAC:

```yaml
network:
  version: 2
  ethernets:
    {provider-interface}:
      match:
        macaddress: "{provider-mac}"
      set-name: "{provider-interface}"
      mtu: 1500
      dhcp4: false
      dhcp6: false
```

ถ้า `/etc/cloud/cloud.cfg.d/50-curtin-networking.cfg` ยังมีชื่อเก่า ให้ backup แล้วแก้ทุก reference ให้ตรงกับชื่อใหม่:

```bash
cp /etc/cloud/cloud.cfg.d/50-curtin-networking.cfg /etc/cloud/cloud.cfg.d/50-curtin-networking.cfg.bak
sed -i 's/{old-interface}/{provider-interface}/g' /etc/cloud/cloud.cfg.d/50-curtin-networking.cfg
```

ปิด cloud-init network config เพื่อไม่ให้ generate netplan ทับอีกหลัง prepare เครื่องเสร็จ:

```bash
printf 'network: {config: disabled}\n' >/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
```

Apply และ reboot:

```bash
netplan generate
netplan apply
reboot
```

## Verification

หลัง reboot ต้องเห็น provider NIC เป็นชื่อเป้าหมาย:

```bash
ip -br a | grep '{provider-interface}'
```

เช็กว่าไม่มีชื่อเก่าค้างใน cloud-init/netplan:

```bash
grep -R "{old-interface}" /etc/cloud/cloud.cfg.d /etc/netplan 2>/dev/null
```

เช็กว่า cloud-init network ถูกปิดแล้ว:

```bash
cat /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
```

ผลที่ต้องการ:

```text
network: {config: disabled}
```

## Notes

`/etc/cloud/cloud.cfg.d/50-curtin-networking.cfg` เป็น config ต้นทางที่ curtin/cloud-init สร้างตอน deploy เครื่อง ไม่ใช่ไฟล์ network runtime โดยตรง แต่ถ้า cloud-init network ยังเปิดอยู่หรือถูกสั่ง regenerate อาจใช้ไฟล์นี้สร้าง `/etc/netplan/50-cloud-init.yaml` ใหม่ได้

ถ้าปิด cloud-init network แล้ว ระบบจะใช้ netplan ปัจจุบันเป็นหลัก แต่ควรแก้ `50-curtin-networking.cfg` ให้ตรงด้วยเพื่อลดความสับสนเวลา troubleshooting ในอนาคต

warning `gateway4 has been deprecated` จาก `netplan apply` เป็น warning เรื่อง syntax เก่า ไม่ใช่สาเหตุที่ rename NIC ล้มเหลว
