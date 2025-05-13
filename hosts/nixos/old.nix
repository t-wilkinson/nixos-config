# Unused configuration useful for reference
{ ... }:
{
  config = mkIf cfg.server.libvert.enable {
    # https://technicalsourcery.net/posts/nixos-in-libvirt/
    boot.kernelModules = [
      "kvm-intel"
      "kvm-amd"
    ];

    virtualisation.libvirtd.enable = true;
    virtualisation.libvirtd.allowedBridges = [ "${cfg.libvert.bridgeInterface}" ];

    networking.interfaces."${cfg.libvert.bridgeInterface}".useDHCP = true;
    networking.bridges = {
      "${cfg.libvert.bridgeInterface}" = {
        interfaces = [ "${cfg.libvert.ethInterface}" ];
      };
    };
  };

  programs = {
    gamemode.enable = true;
    firefox = {
      enable = true;
      preferences = {
        "widget.use-xdg-desktop-portal.file-picker" = 1;
      };
      nativeMessagingHosts.packages = [ pkgs.plasma5Packages.plasma-browser-integration ];
    };
    steam = {
      gamescopeSession.enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      enableExtraSocket = true;
      extraConfig = ''
        # enable-ssh-support
        allow-preset-passphrase;
      '';
      pinentryPackage = pkgs.pinentry-gnome3;
      defaultCacheTtl = 34560000;
      defaultCacheTtlSsh = 34560000;
      maxCacheTtl = 34560000;
      maxCacheTtlSsh = 34560000;
    };
  };

  boot.loader.grub.device = "/dev/nvme1n1p1";
  boot = {
    tmp.cleanOnBoot = true;
    supportedFilesystems = [
      "btrfs"
      "ext4"
      "fat32"
      "ntfs"
    ];
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    kernelPatches = [
      {
        name = "enable RT_FULL";
        patch = null;
        # TODO: add realtime patch: PREEMPT_RT y
        extraConfig = ''
          PREEMPT y
          PREEMPT_BUILD y
          PREEMPT_VOLUNTARY n
          PREEMPT_COUNT y
          PREEMPTION y
        '';
      }
    ];
    extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
    kernelModules = [ "acpi_call" ];
    # make 3.5mm jack work
    extraModprobeConfig = ''
      options snd_hda_intel model=headset-mode
    '';
  };

  networking.networkmanager.enable = lib.mkForce false;
  systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";
  networking = {
    hostName = hostname;
    nftables.enable = true;
    networkmanager.enable = false;
    interfaces.enp3s0 = {
      wakeOnLan.enable = true;
    };
    firewall.allowedTCPPorts = [
      22
      6229
    ];
    localCommands = ''
      ip -6 addr add 2001:610:685:1::1/64 dev eth0
    '';
  };

  # Boot
  boot = {
    # doesn't work, mac addresses are randomized because of networkmanager
    initrd.services.udev.rules = ''
      SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", \
      ATTR{address}=="52:54:00:12:01:01", KERNEL=="enp*", NAME="eth0"
      SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", \
      ATTR{address}=="8e:10:ab:93:d5:31", KERNEL=="enp*", NAME="wlan0"
    '';
  };

  networking.usePredictableInterfaceNames = true;
}
