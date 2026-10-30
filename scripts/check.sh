#!/bin/bash
# Read-only health check for the demo. Run on the server.
echo "== services =="; systemctl is-active postfix dovecot opendkim nginx php8.5-fpm
echo "== ports ==";    ss -tlnp | grep -E ':(25|80|443|587|993)\b'
echo "== memory ==";   free -h; swapon --show
echo "== dkim ==";     opendkim-testkey -d alilinux.ir -s mail -vvv
echo "== tls ==";      certbot certificates 2>/dev/null | grep -E 'Domains|Expiry'
echo "== dns ==";      for t in "A mail" "MX @" "TXT @" "TXT _dmarc"; do set -- $t; n=$2; [ "$n" = "@" ] && n=""; dig +short $1 ${n:+$n.}alilinux.ir; done
