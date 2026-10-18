# hosts/homelab/wifi.nix
# Keeping the Pi's uplink (a USB Wi-Fi dongle, homelab.nodes.pi.wanInterface) alive.
#
# Symptom: Wi-Fi drops and stays down until a reboot, even with Wi-Fi power saving off.
# "Until a reboot" points below NetworkManager: the dongle or its driver wedges (USB
# autosuspend, a firmware hang, or a brown-out when the USB backup disk spins up on the same
# bus), so reconnecting from NM alone doesn't help. Mitigations here:
#   - no USB autosuspend (the dongle is never put to sleep)
#   - no MAC randomisation during scans (some drivers/routers handle it badly)
#   - wifi-watchdog: checks the uplink every minute and escalates
#       3 failed checks  -> reconnect the interface through NetworkManager
#       5                -> reset the dongle on the USB bus (deauthorize / reauthorize)
#       8                -> restart NetworkManager
#       every 20 (~20 min) -> reboot, unless the Pi booted less than an hour ago
#       (and another USB reset at 10, 30, 50, ...)
#     Each failure logs link state, recent kernel messages and the Pi's throttling flags, so
#     `journalctl -u wifi-watchdog -b -1` after a reboot shows what the dongle was doing.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hl = config.homelab;
  iface = hl.nodes.${hl.thisNode}.wanInterface;
  ntfyHeader = config.sops.templates."ntfy-auth-header".path or null;
  notify = hl.services.ntfy.runsHere && ntfyHeader != null;

  watchdog = pkgs.writeShellApplication {
    name = "wifi-watchdog";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      iproute2
      iputils
      iw
      networkmanager
      systemd
      util-linux
      curl
      libraspberrypi # vcgencmd
    ];
    text = ''
      IF=${lib.escapeShellArg iface}
      STATE=/run/wifi-watchdog
      mkdir -p "$STATE"
      fails=$(cat "$STATE/fails" 2> /dev/null || echo 0)

      # Remember the dongle's USB device (e.g. 1-1.4) while it's visible: after a wedge the
      # network interface can disappear, and the reset needs to know what to reset.
      if [ -e "/sys/class/net/$IF/device" ]; then
        dev=$(readlink -f "/sys/class/net/$IF/device")   # .../1-1.4/1-1.4:1.0 (USB interface)
        usb=$(basename "$(dirname "$dev")")              # 1-1.4 (USB device)
        [ -e "/sys/bus/usb/devices/$usb/authorized" ] && echo "$usb" > "$STATE/usb"
      fi

      uplink_ok() {
        local gw
        gw=$(ip -4 route show default dev "$IF" 2> /dev/null | awk '{ print $3; exit }')
        { [ -n "$gw" ] && ping -c 2 -W 2 -I "$IF" "$gw" > /dev/null 2>&1; } \
          || ping -c 2 -W 3 -I "$IF" 1.1.1.1 > /dev/null 2>&1
      }

      notify() {
        ${lib.optionalString notify ''
          curl -sS --max-time 10 -H @${ntfyHeader} -H "Title: Pi Wi-Fi" -H "Tags: signal_strength" \
            --data-binary "$1" http://${hl.services.ntfy.localEndpoint}/homelab > /dev/null || true
        ''}
        :
      }

      if uplink_ok; then
        touch "$STATE/ever-up"
        if [ "$fails" -ge 3 ]; then
          msg="Wi-Fi recovered after $fails failed checks (last action: $(cat "$STATE/action" 2> /dev/null || echo none))"
          echo "$msg"
          notify "$msg"
        fi
        echo 0 > "$STATE/fails"
        rm -f "$STATE/action"
        exit 0
      fi

      fails=$((fails + 1))
      echo "$fails" > "$STATE/fails"
      echo "uplink check failed ($fails in a row)"
      ip -br link show "$IF" 2>&1 || echo "$IF: interface missing"
      ip -4 -br addr show "$IF" 2>&1 || true
      iw dev "$IF" link 2>&1 || true
      nmcli -t -f DEVICE,STATE,CONNECTION device 2>&1 || true
      vcgencmd get_throttled 2>&1 || true   # 0x0 = fine; bit 0/16 = under-voltage now/since boot
      journalctl -k -n 15 --no-pager -o short-monotonic 2>&1 | grep -iE "usb|wl|80211|firmware|voltage" || true

      act() {
        echo "$1" > "$STATE/action"
        echo "action: $1"
      }
      usb_reset() {
        local usb
        usb=$(cat "$STATE/usb" 2> /dev/null || true)
        if [ -n "$usb" ] && [ -e "/sys/bus/usb/devices/$usb/authorized" ]; then
          act "USB reset of $usb"
          echo 0 > "/sys/bus/usb/devices/$usb/authorized"
          sleep 3
          echo 1 > "/sys/bus/usb/devices/$usb/authorized"
        else
          act "USB reset skipped (device unknown)"
        fi
      }
      case "$fails" in
        3)
          act "reconnect $IF"
          nmcli device reconnect "$IF" || nmcli device connect "$IF" || true
          ;;
        5) usb_reset ;;
        8)
          act "restart NetworkManager"
          systemctl restart NetworkManager
          ;;
        *)
          if [ $((fails % 20)) -eq 0 ]; then
            up=$(awk '{ print int($1) }' /proc/uptime)
            if [ ! -e "$STATE/ever-up" ]; then
              # Never connected since boot: a missing dongle or a wrong password, not a wedge.
              # Rebooting wouldn't help, and would loop.
              act "reboot skipped (uplink never came up this boot)"
            elif [ "$up" -gt 3600 ]; then
              act "reboot"
              notify "Wi-Fi down for $fails minutes; rebooting"
              systemctl reboot
            else
              act "reboot skipped (booted ''${up}s ago)"
            fi
          elif [ $((fails % 10)) -eq 0 ]; then
            usb_reset
          fi
          ;;
      esac
    '';
  };
in
{
  # The dongle (and the backup disk) are never autosuspended
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];

  # Regulatory domain: without it the kernel uses the restrictive "world" domain, which can
  # leave 5 GHz channels unusable (the network shows in scans but association fails)
  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="US"
  '';

  networking.networkmanager.wifi = {
    powersave = false;
    scanRandMacAddress = false;
  };

  systemd.services.wifi-watchdog = {
    description = "Check the Wi-Fi uplink and recover it";
    after = [ "NetworkManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe watchdog;
    };
  };
  systemd.timers.wifi-watchdog = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1min";
      AccuracySec = "10s";
    };
  };

  environment.systemPackages = [
    watchdog
    pkgs.iw
    pkgs.usbutils # lsusb -t: which driver the dongle uses
    pkgs.libraspberrypi # vcgencmd get_throttled
  ];
}
