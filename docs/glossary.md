# Glossary and role in this project
| Term | Meaning | Role here |
|---|---|---|
| MTA | Mail Transfer Agent | Postfix |
| IMAP server / MDA | Delivers mailbox to the user | Dovecot |
| MUA | Mail client | Roundcube |
| SMTP | Sending protocol | ports 25 and 587 |
| IMAP | Reading protocol | port 993 |
| Submission | Authenticated client sending | port 587 |
| Maildir | One file per message | /home/ali/Maildir |
| SASL | Auth mechanism | Postfix asks Dovecot |
| MX | DNS record of mail server | mail.alilinux.ir |
| A | name -> IP | mail -> server IP |
| PTR / rDNS | IP -> name | avoids spam folder |
| SPF | Allowed sender IPs | TXT on @ |
| DKIM | Signature on messages | OpenDKIM + public key in DNS |
| DMARC | Policy when SPF/DKIM fail | p=none, reports to ali@ |
| Milter | Filter hook for Postfix | Postfix -> OpenDKIM |
| TLS | Encryption | Let's Encrypt cert |
| Certbot | Gets/renews certificates | auto renewal |
| Nginx | Web server | HTTPS for webmail |
| PHP-FPM | PHP runner | Roundcube is PHP |
| SQLite | File database | Roundcube settings |
| PAM | Linux authentication | user ali is a system user |
| NS | Domain's DNS servers | Arvan |
| Blacklist | Spam-reputation lists | IP listed on some |
| oom-kill | Kernel kills processes on low RAM | fixed with swap |
| Swap | Disk used as extra memory | 2 GB |
