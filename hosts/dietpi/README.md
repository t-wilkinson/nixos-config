# DietPI

DietPI configuration

## Services

**Backups**
Backup data to drive and nixos

**DNS & DHCP** Pi-hole and dnsmasq

**Dynamic DNS** ddclient

**Routing** nftables

Forward internet to my domain (treywilkinson.com) to my pi.

**VPN** WireGuard

**SSH** Dropbear

## Hardware

Raspberry Pi 4
Gigabit ethernet

## Networking

- Forward port 6239 to 23 from router

### Dynamic DNS

- Setup Dynamic DNS via changeip.com from treywilkinson.dynamic-dns.net
- Configure domain to work with dynamic-dns

## Configuring

```bash
# allow VPN clients to use pihole for DNS requests
pihole -a -i local

# adding dietpi wg0 interface
ip link add wg0 type wireguard
ip addr add 10.0.0.1/24 dev wg0
wg set wg0 private-key ./privatekey
ip link set wg0 up
```
