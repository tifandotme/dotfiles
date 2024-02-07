# `man resolved.conf` for details

# Some examples of DNS servers which may be used for DNS= and FallbackDNS=:
# Cloudflare: 1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com
# Google:     8.8.8.8#dns.google 8.8.4.4#dns.google 2001:4860:4860::8888#dns.google 2001:4860:4860::8844#dns.google
# Quad9:      9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net

dns() {
  if [ -z "$1" ] || [ "$1" != "on" ] && [ "$1" != "off" ]; then
    echo "Usage: dns on|off"
    return 1
  fi

  local action=$1

  if [ "$action" = "on" ]; then
    sudo tee /etc/systemd/resolved.conf <<EOF >/dev/null
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com
FallbackDNS=9.9.9.9#quad9.net 149.112.112.112#quad9.net 2620:fe::fe#quad9.net 2620:fe::9#quad9.net
Domains=~.
DNSSEC=yes
DNSOverTLS=yes
EOF
  elif [ "$action" = "off" ]; then
    sudo tee /etc/systemd/resolved.conf <<EOF >/dev/null
[Resolve]
#DNS=
#FallbackDNS=
#Domains=
#DNSSEC=
#DNSOverTLS=
EOF
  fi

  sudo systemctl restart systemd-resolved
  sudo systemctl restart NetworkManager

  echo "/etc/systemd/resolved.conf has been updated"
  echo ""

  resolvectl
}
