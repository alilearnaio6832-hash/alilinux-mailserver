# alilinux.ir — Linux Mail Server (LPIC 1/2 Final Project)

A real, self-hosted mail server for the domain **alilinux.ir**, built by hand on Ubuntu Server
(no Mailcow / all-in-one stacks). Sends and receives real email and provides a browser webmail.

## Stack
| Component | Role |
|---|---|
| Postfix | SMTP (MTA): receive on :25, authenticated submission on :587 |
| Dovecot | IMAP (:993) + SASL authentication for Postfix, Maildir storage |
| OpenDKIM | DKIM signing of outgoing mail (milter on 127.0.0.1:12301) |
| Nginx + PHP-FPM | HTTPS web server (:443) |
| Roundcube | Webmail UI (SQLite) |
| Certbot | Let's Encrypt TLS certificate |

## Architecture
```
Browser --HTTPS:443--> Nginx -> PHP-FPM -> Roundcube --IMAPS:993 / SMTP:587--> Dovecot / Postfix
Out: Postfix -> OpenDKIM (milter) -> :25 -> remote MX (e.g. Gmail)
In : remote MTA -> :25 -> Postfix -> ~/Maildir <- Dovecot
```

## DNS records
| Type | Name | Value |
|---|---|---|
| A | mail | `<SERVER_IP>` (CDN proxy OFF) |
| MX | @ | `mail.alilinux.ir` (prio 10) |
| TXT | @ | `v=spf1 mx ip4:<SERVER_IP> ~all` |
| TXT | _dmarc | `v=DMARC1; p=none; rua=mailto:ali@alilinux.ir` |
| TXT | mail._domainkey | `v=DKIM1; h=sha256; k=rsa; p=<PUBLIC_KEY>` |
| PTR | `<SERVER_IP>` | `mail.alilinux.ir` (set at the VPS provider) |

## Repository layout
- `docs/commands.md` — every command, phase by phase
- `docs/glossary.md` — terms (MTA, MX, SPF, DKIM, DMARC, ...) and their role here
- `configs/` — sanitized configuration files
- `scripts/check.sh` — read-only health check for demos

## Challenges solved
Provider-blocked port 25 (support ticket) · Gmail 550 5.7.26 (added SPF/DKIM/DMARC) ·
Roundcube vs PHP 8.5 `array_first()` redeclare · OOM kills (2 GB swap) · Maildir permission denied.

## Known limitations
IP listed on some blocklists · DMARC `p=none` · no rspamd / automated backups yet.

> Secrets (DKIM private key, passwords) are intentionally **not** in this repo.
