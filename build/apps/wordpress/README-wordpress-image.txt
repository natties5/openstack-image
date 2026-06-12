=== WordPress Docker Image — Ubuntu 26.04 ===

Access:  http://<VM-IP>
Setup:   Open in browser → follow 5-minute WordPress install wizard

Credentials:
  DB credentials: /root/wordpress-credentials.txt
  WordPress admin: YOU create during setup wizard

Directory:
  /opt/wordpress/                     Main directory
    docker-compose.yml                Service definitions
    nginx/default.conf                Nginx config (editable)
    nginx/default-https.conf          HTTPS template
    php/wordpress.ini                 PHP settings (editable)
    certs/                            Place TLS certs here

Common Commands:
  cd /opt/wordpress
  docker compose ps                   Check status
  docker compose logs -f              View logs
  docker compose restart              Restart ALL services (wordpress + nginx + db)
  docker compose restart wordpress    Restart after editing php/wordpress.ini
  docker compose restart nginx        Restart after editing nginx/default.conf

Restart ทั้ง stack ทำยังไง:
  docker compose restart               # restart ทั้งหมด
  docker compose restart nginx        # restart แค่ nginx
  docker compose restart wordpress    # restart แค่ wordpress

หลังแก้ php หรือ nginx → restart ตัวที่แก้ + อีกตัวด้วยเสมอ:
  แก้ wordpress.ini  →  docker compose restart wordpress nginx
  แก้ nginx config   →  docker compose restart nginx wordpress

Enable HTTPS:
  1. Point DNS → VM floating IP
  2. Place certs: /opt/wordpress/certs/fullchain.pem + privkey.pem
  3. chmod 644 fullchain.pem && chmod 600 privkey.pem
  4. Set domain:  echo "DOMAIN=yourdomain.com" >> /opt/wordpress/.env
  5. Stop HTTP:   docker compose stop nginx
  6. Start HTTPS: docker compose --profile https up -d
  7. WordPress auto-detects HTTPS via $_SERVER['HTTPS'] — no DB change needed

Backup:
  DB:   docker compose exec db mysqldump -u root -p"$(grep MYSQL_ROOT_PASSWORD .env | cut -d= -f2)" wordpress > db-backup.sql
  Files: tar czf wp-backup.tar.gz -C /opt/wordpress .env php/ nginx/
