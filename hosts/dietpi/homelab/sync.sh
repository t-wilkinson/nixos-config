#!/usr/bin/env bash
rsync -avR -e ssh {caddy,ntfy,docker-compose.yml} pi:/homelab
rsync -avR -e ssh dnsmasq.d-homelab.conf pi:/etc/dnsmasq.d/homelab.conf

# /etc/wireguard/
