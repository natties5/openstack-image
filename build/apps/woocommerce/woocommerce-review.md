# WooCommerce — Community Research & User Needs

> Research จาก upstream/community สำหรับทำ WooCommerce image บน OpenStack
> สรุป: WooCommerce คือ WordPress plugin ดังนั้น image ควรเป็น WordPress-derived ecommerce image ไม่ใช่ app คนละ platform

---

## Decision

| คำถาม | คำตอบ |
|---|---|
| ควรทำ image แยกไหม | ควรทำแยก เพราะ target user คือคนต้องการร้านค้าออนไลน์ ไม่ใช่ CMS เปล่า |
| ควรใช้ stack อะไร | WordPress + WooCommerce plugin + MariaDB + Nginx + PHP-FPM |
| ควรใช้ official WooCommerce image ไหม | ไม่มี official WooCommerce container image ที่เหมาะกว่า WordPress image |
| ควร reuse WordPress image pattern ไหม | ควร reuse ให้มากที่สุด แล้วเพิ่ม WooCommerce bootstrap/cron/backup guide |

---

## User Segments

### Beginner — เปิดร้านค้าแรก

| ต้องการ | ความถี่ | เหตุผล |
|---|---|---|
| เปิด VM แล้วเข้า setup ร้านค้าได้ทันที | สูงมาก | ผู้ใช้ค้นหา WooCommerce คาดหวัง ecommerce ไม่ใช่ WordPress เปล่า |
| ไม่ต้องตั้ง DB เอง | สูงมาก | ปัญหา common ของ WordPress/WooCommerce คือ DB credentials/config |
| Upload product image/import CSV ได้ | สูง | ร้านค้าต้อง upload รูปสินค้าและ import product |
| HTTPS พร้อมแนวทางเปิดใช้งาน | สูงมาก | payment/checkout ต้องใช้ HTTPS |
| Admin credentials อยู่ใน VM เท่านั้น | สูง | standalone image ต้องไม่ bake secret ลง repo |

### SME / Store Operator

| ต้องการ | ความถี่ | เหตุผล |
|---|---|---|
| Backup DB + wp-content เป็นชุดเดียวกัน | สูงมาก | order/product/customer data อยู่ใน DB ส่วน media/plugin/theme อยู่ใน files |
| Cron/queue ทำงานแม้ traffic ต่ำ | สูง | WooCommerce ใช้ scheduled jobs, webhook, email, stock sync |
| Memory/PHP limits สูงกว่า blog ทั่วไป | สูง | product import/variation/checkout ใช้ resource มากกว่า CMS |
| Email/SMTP setup guide | สูง | order email/password reset ต้องส่งออกได้จริง |
| Upgrade warning | สูง | theme/plugin/payment extension conflict เกิดบ่อย |

### Advanced / Agency

| ต้องการ | ความถี่ | เหตุผล |
|---|---|---|
| WP-CLI | สูง | install/update/debug/cron ได้เร็ว |
| HPOS default | สูง | WooCommerce 8.2+ เปิด default สำหรับ install ใหม่และเพิ่ม performance order tables |
| Redis object cache optional | กลาง | ลด DB query ในร้านที่ traffic สูงขึ้น |
| Reverse proxy/HTTPS correctness | สูง | redirect loop/mixed content เกิดง่ายเมื่อ TLS terminate ข้างหน้า |

---

## Upstream Requirements

WooCommerce 10.8+ แนะนำ:

| Component | Requirement |
|---|---|
| WordPress | 6.9+ |
| PHP | 8.3+ |
| Database | MySQL 8.0+ หรือ MariaDB 10.6+ |
| HTTPS | Required |
| WordPress memory limit | 256 MB+ |

WordPress แนะนำ baseline ใกล้กัน: PHP 8.3+, MariaDB 10.6+/MySQL 8.0+, HTTPS, Nginx หรือ Apache

---

## Best Practices For Image

| Area | Recommendation | Priority |
|---|---|---|
| Base stack | `wordpress:php8.3-fpm` + `mariadb:lts` + `nginx` | Must |
| Install method | First boot ใช้ WP-CLI `core install` แล้ว `plugin install woocommerce --activate` | Must |
| Secrets | Generate DB/admin password ต่อ VM แล้วเขียน `/root/woocommerce-credentials.txt` | Must |
| PHP config | `memory_limit=512M`, upload/post `128M`, execution `600`, input vars `5000` | Must |
| Cron | Disable page-load WP-Cron แล้วใช้ systemd timer เรียก WP-CLI | Must |
| Action Scheduler | Cron script ต้องพยายาม run `wp action-scheduler run` ถ้ามี command | Should |
| HPOS | ใช้ default ของ WooCommerce install ใหม่ และ document compatibility risk | Should |
| HTTPS | มี Nginx HTTPS profile และ note เรื่อง payment/checkout | Should |
| Redis | Optional เท่านั้น ไม่เปิด default เพราะเพิ่ม resource/complexity | Could |
| SMTP | ไม่ preinstall plugin; document ให้ตั้งหลัง deploy | Could |

---

## Known Pitfalls

| Pitfall | ผลกระทบ | Mitigation |
|---|---|---|
| Treat WooCommerce as standalone app | ดูแลยากและผิด model upstream | ทำเป็น WordPress-derived image |
| WP-Cron พึ่ง page load | queue/payment/email job ช้าเมื่อ traffic ต่ำ | systemd timer run WP-CLI ทุก 5 นาที |
| HTTPS/proxy detect ผิด | redirect loop, mixed content, payment warning | Nginx ส่ง `HTTPS` และ `X-Forwarded-Proto` |
| HPOS plugin compatibility | extension เก่าอาจใช้ไม่ได้ | document หน้า incompatible plugins |
| Backup แค่ files หรือแค่ DB | restore แล้ว order/media หาย | backup DB + wp-content พร้อมกัน |
| Preinstall too many plugins | attack surface และ update burden สูง | preinstall เฉพาะ WooCommerce core |

---

## Sources

| Source | URL | Signal |
|---|---|---|
| WooCommerce Server Recommendations | https://woocommerce.com/document/server-requirements/ | Requirements หลักของ WooCommerce 10.8+ |
| WordPress Requirements | https://wordpress.org/about/requirements/ | Baseline PHP/DB/HTTPS |
| WooCommerce HPOS | https://developer.woocommerce.com/docs/features/high-performance-order-storage/ | HPOS default สำหรับ install ใหม่ตั้งแต่ WooCommerce 8.2 |
| Action Scheduler Performance | https://actionscheduler.org/perf/ | WP-CLI เป็นวิธีที่ดีกว่าสำหรับ queue throughput |
| WordPress Cron docs | https://developer.wordpress.org/plugins/cron/ | WP-Cron trigger จาก request/page load |
| WordPress Object Cache docs | https://developer.wordpress.org/advanced-administration/performance/cache/ | Redis/object cache เป็น optimization ไม่ใช่ baseline |
| Official WordPress Docker image | https://hub.docker.com/_/wordpress | Base image pattern |

---

## Image Conclusion

ทำ WooCommerce เป็น app folder แยกเพื่อ UX/catalog/support ที่ชัดเจน แต่ implementation เป็น WordPress variant:

```text
WordPress image = CMS baseline
WooCommerce image = WordPress + WooCommerce + ecommerce bootstrap/tuning
```
