# Guest Images — AI Mistakes Log

> บันทึกข้อผิดพลาดระหว่าง build base image — ให้ AI ไม่พลาดซ้ำ

---

## 2026-06-04 — Property over-recommendation (Ubuntu 26.04)

**ปัญหา:** แนะนำ `--property hw_disk_bus=virtio` + `--property hw_scsi_model=virtio-scsi` ทั้งที่ไม่จำเป็น
**ของจริง:** `hw_disk_bus=virtio` เป็น Nova default อยู่แล้ว ไม่ต้องใส่; `hw_scsi_model=virtio-scsi` ใช้กับ SCSI bus เท่านั้น — virtio ignore property นี้
**ที่ถูก:** ใส่แค่ `--property hw_qemu_guest_agent=yes` ตัวเดียวก็พอ
**บทเรียน:** ก่อนแนะนำ property → นึกก่อนว่า Nova default คืออะไร, property นั้นใช้กับ bus อะไร

## 2026-06-04 — Mirror policy not checked (Ubuntu 26.04)

**ปัญหา:** แนะนำ `mirror1.ku.ac.th` เป็น mirror แรกทั้งที่ user มี policy `openlandscape.cloud` first priority
**ของจริง:** `openlandscape.cloud` มี `resolute/` ครบ — ควรใช้เป็น default
**ที่ถูก:** ต้องเช็ค policy ใน `mirrors.md` และ AGENTS.md ก่อนทุกครั้ง — `openlandscape.cloud` ก่อน `mirror1.ku.ac.th` หลัง
**บทเรียน:** mirror policy มีใน AGENTS.md แล้ว → ต้องอ่านก่อน

## 2026-06-04 — SHA256SUMS format (Ubuntu 26.04 + Fedora 44)

**ปัญหา:** ใช้ `sha256sum -c` กับ multi-arch checksum file → WARNING "17 lines are improperly formatted"
**ควรเป็น:** ต้องบอกผู้ใช้ให้ใช้ `--ignore-missing`: `sha256sum -c SHA256SUMS --ignore-missing` เพราะไฟล์ checksum ตัวเดียวมีทุกรูปแบบ (qcow2, vmdk, ova, tar.gz, squashfs) และทุก arch
**บทเรียน:** Fedora + Ubuntu cloud image checksum files เป็น multi-arch — ต้อง `--ignore-missing`

## 2026-06-04 — dnf5 vs yum confusion (Fedora 44)

**ปัญหา:** Fedora 44 ใช้ `dnf5` แต่ `yum` ยังเป็น symlink ใช้งานได้ — ไม่ได้อธิบายให้ชัดเจน
**ของจริง:** ทั้ง `yum update` และ `dnf5 -y upgrade` ใช้ได้ — `yum` symlink ไป `dnf5` ใน Fedora 41+
**ที่ถูก:** ใน pipeline ระบุ `dnf5 -y upgrade --refresh` ชัดเจน แต่ไม่ต้อง panic ถ้าผู้ใช้พิมพ์ `yum`
**บทเรียน:** Fedora 41+ `yum` = symlink → `dnf5` — ใช้ได้ทั้งคู่ แต่ในเอกสารให้ใช้ `dnf5` ชัดเจน
