# hosts/homelab/wifi.nix
# Keeping the Pi's Wi-Fi uplink (homelab.nodes.pi.wanInterface) alive: the built-in Wi-Fi
# (wlan0, brcmfmac) or a USB adapter.
#
# History (2026-10): the USB dongle dropped and stayed down until a reboot; the built-in Wi-Fi
# then failed every connection attempt at 802.11 authentication. That turned out to be a weak
# link: the gateway reached the Pi at only -73 dBm on 5 GHz, and the Pi's own weaker
# transmissions mostly didn't make it back. WPA3, the password and the driver were ruled out.
# The real fix is signal (an extender or a better antenna); the settings here make the Pi
# keep trying, recover by itself, and log the signal so a weak link is obvious next time.
#
# Mitigations here:
#   - no USB autosuspend (a USB adapter is never put to sleep)
#   - no MAC randomisation during scans (some drivers/routers handle it badly)
#   - wifi-watchdog: checks the uplink every minute and escalates
#       3 failed checks  -> reconnect the interface through NetworkManager
#       5                -> reset the radio: a USB adapter is reset on the bus, the built-in
#                           Wi-Fi has its driver reloaded
#       8                -> restart NetworkManager
#       every 20 (~20 min) -> reboot, unless the Pi booted less than an hour ago
#       (and another radio reset at 10, 30, 50, ...)
#     Each failure logs link state, the signal of the network it should be on, recent kernel
#     messages and the Pi's throttling flags, so `journalctl -u wifi-watchdog -b -1` after a
#     reboot shows what the radio was doing.
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
      kmod # modprobe: reload the built-in Wi-Fi's driver
      gnugrep
      curl
      libraspberrypi # vcgencmd
    ];
    text = ''
      IF=${lib.escapeShellArg iface}
      STATE=/run/wifi-watchdog
      mkdir -p "$STATE"
      fails=$(cat "$STATE/fails" 2> /dev/null || echo 0)

      # Remember the radio while it's visible: after a wedge the network interface can
      # disappear, and the reset needs to know what to reset. A USB adapter is remembered by
      # its USB device (e.g. 1-1.4); any adapter by its driver's kernel module (e.g. brcmfmac).
      if [ -e "/sys/class/net/$IF/device" ]; then
        dev=$(readlink -f "/sys/class/net/$IF/device")   # .../1-1.4/1-1.4:1.0 (USB interface)
        usb=$(basename "$(dirname "$dev")")              # 1-1.4 (USB device)
        if [ -e "/sys/bus/usb/devices/$usb/authorized" ]; then
          echo "$usb" > "$STATE/usb"
        else
          rm -f "$STATE/usb"
        fi
        if [ -e "$dev/driver/module" ]; then
          basename "$(readlink -f "$dev/driver/module")" > "$STATE/module"
        fi
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
      # Signal of the network the uplink should be on (from the last scan). Around -70 dBm or
      # weaker, the Pi's replies often don't reach the router: a weak link, not a software fault.
      ssid=$(nmcli -g 802-11-wireless.ssid connection show wifi-uplink 2> /dev/null || true)
      if [ -n "$ssid" ]; then
        iw dev "$IF" scan dump 2> /dev/null \
          | awk -v ssid="$ssid" '/^BSS /{ bss=substr($2, 1, 17) } /signal:/{ sig=$2" "$3 } /freq:/{ f=$2 }
              $1 == "SSID:" && substr($0, index($0, $2)) == ssid { print "seen " ssid " " bss " " f " MHz " sig }' \
          || true
      fi
      nmcli -t -f DEVICE,STATE,CONNECTION device 2>&1 || true
      vcgencmd get_throttled 2>&1 || true   # 0x0 = fine; bit 0/16 = under-voltage now/since boot
      journalctl -k -n 15 --no-pager -o short-monotonic 2>&1 | grep -iE "usb|wl|80211|firmware|voltage" || true

      act() {
        echo "$1" > "$STATE/action"
        echo "action: $1"
      }
      radio_reset() {
        local usb mod holder
        usb=$(cat "$STATE/usb" 2> /dev/null || true)
        mod=$(cat "$STATE/module" 2> /dev/null || true)
        if [ -n "$usb" ] && [ -e "/sys/bus/usb/devices/$usb/authorized" ]; then
          act "USB reset of $usb"
          echo 0 > "/sys/bus/usb/devices/$usb/authorized"
          sleep 3
          echo 1 > "/sys/bus/usb/devices/$usb/authorized"
        elif [ -n "$mod" ]; then
          # Built-in Wi-Fi: unload and reload its driver. Modules that use it (brcmfmac's
          # vendor modules, e.g. brcmfmac_cyw) have to go first.
          act "reload driver $mod"
          for holder in /sys/module/"$mod"/holders/*; do
            [ -e "$holder" ] && modprobe -r "$(basename "$holder")"
          done
          modprobe -r "$mod" || true
          sleep 3
          modprobe "$mod" || true
        else
          act "radio reset skipped (device unknown)"
        fi
      }
      case "$fails" in
        3)
          act "reconnect $IF"
          nmcli device reconnect "$IF" || nmcli device connect "$IF" || true
          ;;
        5) radio_reset ;;
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
            radio_reset
          fi
          ;;
      esac
    '';
  };
in
{
  # A USB Wi-Fi adapter (and the backup disk) are never autosuspended
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];

  # Regulatory domain: without it the kernel uses the restrictive "world" domain, which can
  # leave 5 GHz channels unusable (the network shows in scans but association fails)
  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="US"

    # The Pi's built-in Wi-Fi (brcmfmac, wlan0): with wpa_supplicant 2.11+ (26.05 has 2.12) the chip's offloaded
    # authentication never completes ("Authentication with <bssid> timed out", assoc reject
    # status 16) on both bands. Turning off the firmware SAE (0x80000) and auth/4-way-handshake
    # offload (0x2000) features hands authentication back to wpa_supplicant.
    options brcmfmac feature_disable=0x82000
  '';

  networking.networkmanager.wifi = {
    powersave = false;
    scanRandMacAddress = false;
    # Backend: wpa_supplicant (the default). iwd was tried; it always picks WPA3 when the network
    # offers it, and WPA3 never completed on this chip (only tried on the weak link, so not a
    # verdict). wpa_supplicant with pmf = 1 in the wifi-uplink profile (networking.nix) stays on
    # WPA2, which is verified working.
  };

  # nm-online waits for the Wi-Fi to connect. When it can't (no signal, wrong network), the unit
  # fails, switch-to-configuration reports the failure, and deploy-rs rolls the whole deploy
  # back - including whatever was meant to fix the Wi-Fi. Nothing here needs to wait for it.
  systemd.services.NetworkManager-wait-online.enable = false;

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
