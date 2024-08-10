{ config, pkgs, inputs, ... }: 
let
  microvm = inputs.microvm.nixosModules;
  nixpkgs = inputs.nixpkgs;
  dev-microvm = { num }: {
    pkgs = import nixpkgs { system = "x86_64-linux"; };
    config = {
      networking.hostName = "qemu-vnc";
      system.stateVersion = config.system.nixos.version;
      microvm = {
        hypervisor = "qemu";
        # graphics.enable = true;
        mem = 2048;
        vcpu = 2;
        interfaces = [{
          type = "tap";
          id = "vm-test-${num}";
          mac = "02:00:00:00:00:0${num}";
        }];
        shares = [
        {
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
          tag = "ro-store";
          proto = "virtiofs";
        }
        {
          tag = "dev";
          source = "/home/trey/dev";
          mountPoint = "/mnt/dev";
          proto = "virtiofs";
        }
        ];
      };

      systemd.network.enable = true;

      systemd.network.networks."20-lan" = {
        matchConfig.Type = "ether";
        # networkConfig = {
        #   Address = ["10.0.${num}.2/24"];
        #   Gateway = "10.0.${num}.1";
        #   DNS = ["10.0.1.1"];
        #   IPv6AcceptRA = true;
        #   DHCP = "no";
        # };
      };

      # microvm.qemu.extraArgs = [
      #   "-vnc" ":0"
      #   "-vga" "qxl"
      #   # needed for mounse/keyboard input via vnc
      #   "-device" "virtio-keyboard"
      #   "-usb"
      #   "-device" "usb-tablet,bus=usb-bus.0"
      # ];
      
      # services.openssh.enable = true;
      # services.openssh.settings.PasswordAuthentication = false; # Secure root login
      # services.openssh.settings.PermitRootLogin = "yes"; # Secure root login
      # networking.firewall.allowedTCPPorts = [ 22 ]; # Allow SSH

      # services.getty.autologinUser = "user";
      # users.users.user = {
      #   password = "";
      #   group = "user";
      #   isNormalUser = true;
      #   extraGroups = [ "wheel" "video" ];
      # };
      # users.groups.user = { };
      # security.sudo = {
      #   enable = true;
      #   wheelNeedsPassword = false;
      # };

      # services.displayManager.autoLogin.user = "user";
      # hardware.opengl.enable = true;

      # services.xserver = {
      #   enable = true;
      #   desktopManager.xfce.enable = true;
      # };

      environment.systemPackages = with pkgs; [
        # xdg-utils # Required
      ];
    };
  };
in
{
  imports = [ microvm.host ];

  microvm = {
    autostart = [ ];
    vms = {
      microvm-0 = dev-microvm { num = "0"; }; # br0, the host bridge
      microvm-1 = dev-microvm { num = "1"; }; # br1, vpn new york
      microvm-2 = dev-microvm { num = "2"; }; # br2, vpn albania
    };
  };

  networking.useNetworkd = true;

  systemd.network = 
  let
    # TODO: what to use for DNS?
    DNS = [ "192.168.1.1" ];
  in
  {
    # br0
    netdevs."br0" = {
      netdevConfig.Name = "br0";
      netdevConfig.Kind = "bridge";
    };
    networks."br0" = {
      matchConfig.Name = "br0";
      networkConfig.Address = ["10.0.0.0/24"]; 
      networkConfig.IPv4Forward = true;
      networkConfig.DHCPServer = {
        PoolOffset = 10;
        PoolSize = 100;
        EmitDNS = true;
        EmitRouter = true;
        DNS = DNS;
        EmitNTP = false;
        EmitTimezone = false;
      };
    };

    # br1
    netdevs."br1" = {
      netdevConfig.Name = "br1";
      netdevConfig.Kind = "bridge";
    };
    networks."br1" = {
      matchConfig.Name = "br1";
      networkConfig.Address = ["10.0.1.0/24"]; 
      networkConfig.IPv4Forward = true;
      networkConfig.DHCPServer = {
        PoolOffset = 10;
        PoolSize = 100;
        EmitDNS = true;
        EmitRouter = true;
        DNS = DNS;
        EmitNTP = false;
        EmitTimezone = false;
      };
    };

    # br2
    netdevs."br2" = {
      netdevConfig.Name = "br2";
      netdevConfig.Kind = "bridge";
    };
    networks."br2" = {
      matchConfig.Name = "br2";
      networkConfig.Address = ["10.0.2.0/24"]; 
      networkConfig.IPv4Forward = true;
      networkConfig.DHCPServer = {
        PoolOffset = 10;
        PoolSize = 100;
        EmitDNS = true;
        EmitRouter = true;
        DNS = DNS;
        EmitNTP = false;
        EmitTimezone = false;
      };
    };
  };

  networking.firewall.extraCommands = ''
    # TODO: what about vms on subnet want to communicate with each other, is something like the following necessary?
    # ip route add -s 10.0.1.0/24 via 0.0.0.0
    # ip route add -s 10.0.2.0/24 via 0.0.0.0

    # br1 -> VPN tun1
    ip rule add iif br1 lookup 100
    ip route add default dev tun1 table 100

    # br2 -> VPN tun2
    ip rule add iif br2 lookup 101
    ip route add default dev tun2 table 101

    # NAT on br0 subnet, tun1, tun2
    iptables -t nat -A POSTROUTING -o enp3s0 -s 10.0.0.0/24 -j MASQUERADE
    iptables -t nat -A POSTROUTING -o tun1 -j MASQUERADE
    iptables -t nat -A POSTROUTING -o tun2 -j MASQUERADE
  '';

  # boot.kernel.sysctl."net.ipv4.ip_forward" = 1;


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
}
