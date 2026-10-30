# Commands, phase by phase (run as root on the server)

## 3. Server preparation
```bash
ssh root@<SERVER_IP>
apt update && apt upgrade -y
hostnamectl set-hostname mail.alilinux.ir
nano /etc/hosts        # last line: 127.0.1.1 mail.alilinux.ir mail
hostname -f
```

## 4. Port 25 and PTR
Port 25 opened via provider support ticket. PTR set in provider panel.
```bash
nc -zv -w5 gmail-smtp-in.l.google.com 25
dig +short -x <SERVER_IP>
```

## 5. DNS check
```bash
dig +short A mail.alilinux.ir @8.8.8.8
dig +short MX alilinux.ir @8.8.8.8
dig +short TXT alilinux.ir @8.8.8.8
dig +short TXT _dmarc.alilinux.ir @8.8.8.8
```

## 6. Postfix
```bash
apt install -y postfix mailutils      # Internet Site, mail name = alilinux.ir
# then apply configs/postfix/main.cf.snippet with `postconf -e 'key = value'`
systemctl restart postfix
```

## 7. Dovecot + submission (587) + mail user
```bash
apt install -y dovecot-imapd
cp configs/dovecot/99-alilinux.conf /etc/dovecot/conf.d/
# submission: add configs/postfix/master.cf.submission to /etc/postfix/master.cf
useradd -m -s /usr/sbin/nologin ali && passwd ali
mkdir -p /home/ali/Maildir/{cur,new,tmp}
chown -R ali:ali /home/ali/Maildir && chmod -R 700 /home/ali/Maildir
systemctl restart dovecot postfix
doveconf -n | head -30
ss -tlnp | grep -E ':(587|993)\b'
```

## 8. TLS certificate
```bash
apt install -y certbot
certbot certonly --standalone -d mail.alilinux.ir
cat > /etc/letsencrypt/renewal-hooks/deploy/reload-mail.sh <<'X'
#!/bin/sh
systemctl reload postfix dovecot
X
chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-mail.sh
```

## 9. First test (failed: Gmail 550 5.7.26, no SPF/DKIM)
```bash
echo "Test body" | mail -s "Test 1" -a "From: ali@alilinux.ir" <you>@gmail.com
tail -f /var/log/mail.log
```

## 10. OpenDKIM
```bash
apt install -y opendkim opendkim-tools
mkdir -p /etc/opendkim/keys/alilinux.ir
opendkim-genkey -b 2048 -d alilinux.ir -D /etc/opendkim/keys/alilinux.ir -s mail
chown -R opendkim:opendkim /etc/opendkim
chmod 600 /etc/opendkim/keys/alilinux.ir/mail.private
cp /etc/opendkim.conf /etc/opendkim.conf.bak
cp configs/opendkim/opendkim.conf /etc/opendkim.conf
# milter lines are in configs/postfix/main.cf.snippet
systemctl restart opendkim postfix
cat /etc/opendkim/keys/alilinux.ir/mail.txt     # public key -> DNS TXT mail._domainkey
opendkim-testkey -d alilinux.ir -s mail -vvv    # expect: key OK
```

## 11. Webmail
```bash
apt install -y nginx php-fpm roundcube-core roundcube-sqlite3
rm /etc/nginx/sites-enabled/default
cp configs/nginx/roundcube /etc/nginx/sites-available/roundcube
ln -s /etc/nginx/sites-available/roundcube /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
cat configs/roundcube/config.inc.php.snippet | tail -n +2 >> /etc/roundcube/config.inc.php
php -l /etc/roundcube/config.inc.php
```

## 12. Troubleshooting
```bash
# Roundcube HTTP 500 (array_first redeclared on PHP 8.5) - temporary workaround
F=/usr/share/roundcube/program/lib/Roundcube/bootstrap.php
cp $F $F.bak
sed -i 's/^function array_first(/function rc_unused_array_first(/; s/^function array_last(/function rc_unused_array_last(/' $F
php -l $F && systemctl restart php*-fpm

# OOM kills -> 2 GB swap
fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
systemctl reset-failed; systemctl restart nginx postfix dovecot

# INBOX Permission denied
mkdir -p /home/ali/Maildir/{cur,new,tmp}
chown -R ali:ali /home/ali/Maildir && chmod -R 700 /home/ali/Maildir
systemctl restart dovecot
```

## 13. Final test
```bash
tail -f /var/log/mail.log
grep "status=sent" /var/log/mail.log | tail -3
```
Send from webmail; in Gmail desktop "Show original" -> SPF/DKIM/DMARC = PASS.

## Remaining
```bash
certbot reconfigure --cert-name mail.alilinux.ir --webroot -w /var/www/html
certbot renew --dry-run
ufw allow 22,25,80,443,587,993/tcp && ufw enable
```
