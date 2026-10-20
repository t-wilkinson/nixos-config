# modules/homelab/status-lib.sh
# Check functions for `homelab-status`. status.nix prepends the node's settings (LAN_IP) and
# appends the checks generated from the inventory, then calls `finish`.

quiet=0
color=1
for arg in "$@"; do
  case "$arg" in
    -q | --quiet) quiet=1 ;;
    --no-color) color=0 ;;
    -h | --help)
      echo "usage: homelab-status [--quiet] [--no-color]"
      echo "  Checks this node's services, routes, tunnel, DNS, storage and backups."
      echo "  --quiet     print only warnings and failures"
      echo "  exit code   0 = no failures (warnings allowed), 1 = something failed"
      exit 0
      ;;
    *)
      echo "homelab-status: unknown option $arg (try --help)" >&2
      exit 2
      ;;
  esac
done
[ -t 1 ] || color=0

# Some checks read root-only state (the borg repo, systemd units of other users)
if [ "$(id -u)" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

if [ "$color" = 1 ]; then
  G=$'\e[32m' Y=$'\e[33m' R=$'\e[31m' B=$'\e[1m' N=$'\e[0m'
else
  G='' Y='' R='' B='' N=''
fi

passed=0
warned=0
failed=0

ok() {
  passed=$((passed + 1))
  [ "$quiet" = 1 ] || printf '  %s✓%s %-26s %s\n' "$G" "$N" "$1" "$2"
}
warn() {
  warned=$((warned + 1))
  printf '  %s!%s %-26s %s\n' "$Y" "$N" "$1" "$2"
}
fail() {
  failed=$((failed + 1))
  printf '  %s✗%s %-26s %s\n' "$R" "$N" "$1" "$2"
}
section() {
  [ "$quiet" = 1 ] || printf '%s%s%s\n' "$B" "$1" "$N"
}

# Is another node up? Cached, so a sleeping PC costs one ping, not one per check.
declare -A host_state=()
host_up() {
  local ip=$1
  if [ -z "${host_state[$ip]:-}" ]; then
    if ping -c 1 -W 2 "$ip" > /dev/null 2>&1; then
      host_state[$ip]=up
    else
      host_state[$ip]=down
    fi
  fi
  [ "${host_state[$ip]}" = up ]
}

http_code() {
  curl -sk -o /dev/null -w '%{http_code}' --max-time 10 "$@" 2> /dev/null || true
}
good_code() {
  case "$1" in
    2?? | 3?? | 401 | 403) return 0 ;;
    *) return 1 ;;
  esac
}

# check_unit LABEL UNIT
check_unit() {
  local state
  state=$(systemctl is-active "$2" 2> /dev/null || true)
  if [ "$state" = active ]; then
    ok "$1" "$2"
  else
    fail "$1" "$2 is ${state:-unknown}"
  fi
}

# check_lan LABEL NAME HOST_IP  (HOST_IP empty when the service runs on this node)
# Connects to Caddy on this node's LAN address, so the request counts as LAN traffic.
check_lan() {
  local code
  code=$(http_code --resolve "$2:443:$LAN_IP" "https://$2/")
  if good_code "$code"; then
    ok "$1" "$2 ($code)"
  elif [ -n "$3" ] && ! host_up "$3"; then
    warn "$1" "$2: $3 is asleep or offline"
  else
    fail "$1" "$2 returned $code"
  fi
}

# check_public LABEL NAME HOST_IP  (real DNS, so the request goes through Cloudflare and the tunnel)
check_public() {
  local code
  code=$(http_code "https://$2/")
  if good_code "$code"; then
    ok "$1" "$2 ($code)"
  elif [ -n "$3" ] && ! host_up "$3"; then
    warn "$1" "$2: $3 is asleep or offline"
  elif [ "$code" = 530 ] || [ "$code" = 502 ]; then
    fail "$1" "$2 returned $code (tunnel or origin unreachable)"
  else
    fail "$1" "$2 returned $code"
  fi
}

# check_not_public NAME  (a private service's public name must not be in public DNS)
check_not_public() {
  local ans
  if ! ans=$(dig +short +time=3 +tries=1 A "$1" @1.1.1.1 2> /dev/null); then
    warn "Not in public DNS" "could not query 1.1.1.1 for $1"
  elif [ -z "$ans" ]; then
    ok "Not in public DNS" "$1"
  else
    fail "Not in public DNS" "$1 resolves to $(echo "$ans" | tr '\n' ' ')"
  fi
}

# check_lan_dns NAME  (Blocky answers homelab names with this node's address)
check_lan_dns() {
  local ans
  ans=$(dig +short +time=3 +tries=1 A "$1" @"$LAN_IP" 2> /dev/null | tail -n 1 || true)
  if [ "$ans" = "$LAN_IP" ]; then
    ok "Homelab DNS" "$1 -> $ans"
  else
    fail "Homelab DNS" "$1 -> ${ans:-no answer}"
  fi
}

# check_tunnel  (cloudflared's /ready endpoint on its local metrics port, 20241 by default)
check_tunnel() {
  local port body n
  for port in 20241 20242 20243 20244 20245; do
    body=$(curl -s --max-time 5 "http://localhost:$port/ready" 2> /dev/null) || continue
    n=$(jq -r '.readyConnections // 0' <<< "$body" 2> /dev/null || true)
    [[ "$n" =~ ^[0-9]+$ ]] || n=0
    if [ "$n" -gt 0 ]; then
      ok "Cloudflare tunnel" "$n edge connections"
    else
      fail "Cloudflare tunnel" "cloudflared is running but not connected"
    fi
    return
  done
  fail "Cloudflare tunnel" "no cloudflared /ready endpoint on localhost:20241-20245"
}

# check_tailscale
check_tailscale() {
  local st
  st=$(tailscale status --json 2> /dev/null | jq -r '.BackendState' 2> /dev/null || true)
  if [ "$st" = Running ]; then
    ok "Tailscale" "running"
  else
    fail "Tailscale" "state: ${st:-unknown}"
  fi
}

# check_nfs LABEL PATH SERVER_IP  (listing triggers the automount; bounded so a hung mount can't stall the check)
check_nfs() {
  if timeout -k 2 8 ls -A "$2/" > /dev/null 2>&1; then
    ok "$1" "$2"
  elif ! host_up "$3"; then
    warn "$1" "$2: $3 is asleep or offline"
  else
    fail "$1" "$2 not responding"
  fi
}

# check_backup REPO MOUNT PASSFILE  (newest borg archive younger than 26 h; MOUNT "-" when the
# repo is a plain directory rather than on its own drive)
check_backup() {
  local json last ts age
  if [ "$2" != - ] && ! mountpoint -q "$2"; then
    fail "Backups" "$2 is not mounted"
    return
  fi
  if ! json=$(BORG_PASSCOMMAND="cat $3" timeout 60 borg list --json --last 1 --lock-wait 10 "$1" 2> /dev/null); then
    fail "Backups" "cannot read $1"
    return
  fi
  last=$(jq -r '.archives[0].time // empty' <<< "$json" 2> /dev/null || true)
  if [ -z "$last" ] || ! ts=$(date -d "$last" +%s 2> /dev/null); then
    fail "Backups" "no archives in $1"
    return
  fi
  age=$((($(date +%s) - ts) / 3600))
  if [ "$age" -lt 26 ]; then
    ok "Backups" "newest archive ${age}h old"
  else
    fail "Backups" "newest archive ${age}h old"
  fi
}

# check_disk PATH
check_disk() {
  local pct
  if [ "$1" != / ] && ! mountpoint -q "$1"; then
    warn "Disk $1" "not mounted"
    return
  fi
  pct=$(df --output=pcent "$1" 2> /dev/null | tail -n 1 | tr -dc '0-9' || true)
  if [ -z "$pct" ]; then
    fail "Disk $1" "unavailable"
  elif [ "$pct" -lt 85 ]; then
    ok "Disk $1" "$pct% used"
  elif [ "$pct" -lt 95 ]; then
    warn "Disk $1" "$pct% used"
  else
    fail "Disk $1" "$pct% used"
  fi
}

# check_node NAME IP
check_node() {
  if host_up "$2"; then
    ok "Node $1" "$2 reachable"
  else
    warn "Node $1" "$2 is asleep or offline"
  fi
}

finish() {
  local total=$((passed + warned + failed))
  if [ "$quiet" = 0 ] || [ "$warned" -gt 0 ] || [ "$failed" -gt 0 ]; then
    printf '\n%s checks: %s passed, %s warnings, %s failed\n' "$total" "$passed" "$warned" "$failed"
  fi
  [ "$failed" -eq 0 ]
}
