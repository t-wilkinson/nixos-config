{ config, pkgs, inputs, ... }: 
let
  microvm = inputs.microvm.nixosModules;
  nixpkgs = inputs.nixpkgs;
  # TODO: what to use for DNS?
  DNS = [ "192.168.1.1" "1.1.1.1" "8.8.8.8" ];
  eth0 = "enp3s0";
  host-ip = "192.168.1.169";
  host-subnet = "24";
  host-gateway = "192.168.1.1";

  dev-microvm = { num }: {
    pkgs = import nixpkgs { system = "x86_64-linux"; };
    config = {
      networking.hostName = "vm-test-${num}";
      system.stateVersion = config.system.nixos.version;
      microvm = {
        hypervisor = "qemu";
        # graphics.enable = true;
        mem = 2048;
        vcpu = 2;
        interfaces = [{
          type = "tap";
          id = "vm-test-0${num}";
          mac = "02:00:00:00:00:0${num}";
        }];
        shares = [
          {
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
            tag = "ro-store";
            proto = "virtiofs";
          }
          # {
          #   tag = "dev";
          #   source = "/home/trey/dev";
          #   mountPoint = "/mnt/dev";
          #   proto = "virtiofs";
          # }
        ];
      };

      systemd.network.enable = true;

      services.openssh.enable = true;
      services.openssh.settings.PasswordAuthentication = false; 
      services.openssh.settings.PermitRootLogin = "yes"; 
      networking.firewall.allowedTCPPorts = [ 22 ];

      # services.getty.autologinUser = "user";
      users.users.user = {
        password = "password";
        group = "user";
        isNormalUser = true;
        extraGroups = [ "wheel" "video" ];
      };
      users.groups.user = { };
      security.sudo = {
        enable = true;
        wheelNeedsPassword = false;
      };

      # services.displayManager.autoLogin.user = "user";
      # hardware.opengl.enable = true;

      # services.xserver = {
      #   enable = true;
      #   desktopManager.xfce.enable = true;
      # };

      # systemd.network.networks."20-lan" = {
      #   matchConfig.Type = "ether";
      #   # networkConfig = {
      #   #   Address = ["10.0.${num}.2/24"];
      #   #   Gateway = "10.0.${num}.1";
      #   #   DNS = ["10.0.1.1"];
      #   #   IPv6AcceptRA = true;
      #   #   DHCP = "no";
      #   # };
      # };

      # microvm.qemu.extraArgs = [
      #   "-vnc" ":0"
      #   "-vga" "qxl"
      #   # needed for mounse/keyboard input via vnc
      #   "-device" "virtio-keyboard"
      #   "-usb"
      #   "-device" "usb-tablet,bus=usb-bus.0"
      # ];

      # environment.systemPackages = with pkgs; [
      #   xdg-utils # Required
      # ];
    };
  };
in
{
  # importing microvm.host causes suid problems
  # imports = [ microvm.host ];

  # microvm = {
  #   autostart = [ "microvm-0" "microvm-1" "microvm-2" ];
  #   vms = {
  #     microvm-0 = dev-microvm { num = "0"; }; # br0, the host bridge
  #     microvm-1 = dev-microvm { num = "1"; }; # br1, system subnet
  #     microvm-2 = dev-microvm { num = "2"; }; # br2, vpn
  #   };
  # };

  # br0 attaching directly to eth0 and sending traffic out through that
  # br1 creating subnet, add routes for local switching, routing, gateway, NAT for outer traffic
  # routing for system to br1 subnet
  # brvpn0 attach tun0 interface to brvpn0, forward all traffic in/out through tun0

  # networking = {
  #   useDHCP = false;
  #   useNetworkd = true;
  #   firewall.enable = true;
  #   nat = {
  #     enable = true;
  #     internalInterfaces = [ "br1" "brvpn0" ];
  #     externalInterface = "br0";
  #   };
  # };

  systemd.network = {
    enable = true;

    # netdevs = {
    #   "wlo0" = { enable = false; };
    #   "10-br0" = { netdevConfig = { Name = "br0"; Kind = "bridge"; }; };
    #   "20-br1" = { netdevConfig = { Name = "br1"; Kind = "bridge"; }; };
    #   "30-brvpn0" = { netdevConfig = { Name = "brvpn0"; Kind = "bridge"; }; };
    # };

    # networks = {
    #   "10-br0" = {
    #     matchConfig.Name = "br0";
    #     networkConfig = {
    #       Address = ["${host-ip}/${host-subnet}"]; 
    #       Gateway = host-gateway;
    #       DHCP = "no";
    #       IPForward = "yes";
    #       # IPv4Forward = "yes";
    #       IPMasquerade = "yes";
    #     };
    #     dhcpServerConfig = {
    #       PoolOffset = 10;
    #       PoolSize = 100;
    #       EmitDNS = true;
    #       EmitRouter = true;
    #       DNS = DNS;
    #     };
    #   };

    #   "20-br1" = {
    #     matchConfig.Name = "br1";
    #     networkConfig = { 
    #       Address = ["10.0.1.1/24"]; 
    #       DHCP = "no";
    #       IPForward = "yes";
    #       IPMasquerade = "yes";
    #     };
    #     dhcpServerConfig = {
    #       PoolOffset = 10;
    #       PoolSize = 100;
    #       EmitDNS = true;
    #       EmitRouter = true;
    #       DNS = DNS;
    #     };
    #   };

    #   "30-brvpn0" = {
    #     matchConfig.Name = "brvpn0";
    #     networkConfig = {
    #       DHCP = "no";
    #       IPForward = "yes";
    #       IPMasquerade = "yes";
    #     };
    #   };

    #   "40-${eth0}" = {
    #     matchConfig.Name = eth0;
    #     networkConfig.Bridge = "br0";
    #   };
    #   "50-tun0" = {
    #     matchConfig.Name = "tun0";
    #     networkConfig.Bridge = "brvpn0";
    #   };
    # };
  };

  # networking.firewall.extraCommands = ''
  #   # br0 attached to eth0 config is above

  #   # br1 subnet NAT
  #   ip route add 10.0.1.0/24 dev br0 via ${host-ip}
  #   # iptables -t nat -A POSTROUTING -o ${eth0} -s 10.0.1.0/24 -j MASQUERADE

  #   # iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -o br0 -j MASQUERADE
  #   # iptables -A FORWARD -i br1 -o br0 -j ACCEPT
  #   # iptables -A FORWARD -i br0 -o br1 -j ACCEPT

  #   # brvpn0 -> VPN tun0
  #   ip rule add iif brvpn0 lookup 100
  #   ip route add default dev tun0 table 100
  #   # iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
  #   # iptables -A FORWARD -i brvpn0 -o tun0 -j ACCEPT
  #   # iptables -A FORWARD -i tun0 -o brvpn0 -m state --state RELATED,ESTABLISHED -j ACCEPT

  #   # Catch-all rule to drop packets not matching above rules
  #   # iptables -A FORWARD -i brvpn0 -j DROP
  #   # iptables -A FORWARD -o brvpn0 -j DROP

  #   # connect vms to bridges. should I do this via nix? how do I make sure to wait for microvms to have their interface up, or do I?
  #   # ip link set dev vm-test-01 master br0
  #   # ip link set dev vm-test-02 master br1
  #   # ip link set dev vm-test-03 master brvpn0
  # '';

  # networking.firewall.extraStopCommands = ''
  #   ip route del 10.0.1.0/24 dev br0 via ${host-ip} || true
  #   ip rule del iif brvpn0 lookup 100 || true
  #   ip route del default dev tun0 table 100 || true
  # '';

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # networking.nftables.ruleset = ''
  #   table ip nat {
  #     chain postrouting {
  #       type nat hook postrouting priority 100;
  #       oifname "eno1" masquerade
  #     }
  #   }
  #   table ip filter {
  #     chain forward {
  #       type filter hook forward priority 0;
  #       iifname "br0" oifname "eno1" accept
  #       iifname "eno1" oifname "br0" ct state established,related accept
  #     }
  #   }
  # '';

  environment.systemPackages = with pkgs; [
    iproute2
    iptables
    openvpn
  ];
}
