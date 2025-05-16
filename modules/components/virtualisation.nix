{
  username,
  NixVirt,
  microvm,
  pkgs,
  ...
}:
{
  # home-manager.users.${username} = {
  #   home.packages = with pkgs; [
  #     virt-manager
  #     virt-viewer
  #     libguestfs

  #     # lxc
  #     # lxd-lts
  #     # distrobuilder
  #     # incus
  #     qemu
  #     OVMF

  #     spice
  #     spice-gtk
  #     spice-protocol
  #     win-virtio
  #     win-spice
  #   ];
  # };

  imports = [
    # NixVirt.nixosModules.default
    # microvm.nixosModules.host
    # ./dev-microvm.nix
  ];

  environment.systemPackages = with pkgs; [
    colima # lima with contains (docker, containerd, kubernetes, incus)
    lima # linux (virtual)machines
    kubernetes
    minikube
    docker
    docker-compose
    kubectl
  ];

  # boot.kernelModules = [ "kvm-intel" ];
  virtualisation = {
    # docker.enable = true;
    # spiceUSBRedirection.enable = true;
    # lxd.enable = false;
    # incus.enable = false; # make sure to run `incus admin init`
    # podman = {
    #   enable = false;
    #   # dockerCompat = true;
    #   defaultNetwork.settings.dns_enabled = true;
    # };
    # libvirtd = {
    #   enable = false;
    #   # onBoot = "ignore";
    #   # onShutdown = "shutdown";
    #   qemu = {
    #     package = pkgs.qemu_kvm;
    #     runAsRoot = true;
    #     swtpm.enable = true;
    #     ovmf.enable = true;
    #     ovmf.packages = [ pkgs.OVMFFull.fd ];
    #   };
    # };
  };

  # virtualisation.libvirt = {
  #   enable = true;
  #   swtpm.enable = true;
  #   connections."qemu:///system" = {
  #     pools = [
  #       {
  #         definition = NixVirt.lib.pool.writeXML {
  #           name = "images"; # libvirt seems to be using the directory for the pool name, instead of this, but the lib expects this to be defined
  #           uuid = "650c5bbb-eebd-4cea-8a2f-36e1a75a8683"; # Add a UUID here
  #           type = "dir";
  #           target = { path = "/home/trey/dev/t-wilkinson/vms/images"; };
  #         };
  #         active = true;
  #         volumes = [
  #           {
  #             name = "debian.qcow";
  #             definition = NixVirt.lib.volume.writeXML {
  #               name = "debian.qcow";
  #               capacity = { count = 12; unit = "GB"; };
  #             };
  #           }
  #           # {
  #           #   name = "whonix/Whonix-Gateway-Xfce-17.2.0.7.Intel_AMD64.qcow2";
  #           #   definition = NixVirt.lib.volume.writeXML {
  #           #     name = "whonix/Whonix-Gateway-Xfce-17.2.0.7.Intel_AMD64.qcow2";
  #           #     capacity = { count = 12; unit = "GB"; };
  #           #   };
  #           # }
  #           # {
  #           #   name = "whonix/Whonix-Workstation-Xfce-17.2.0.7.Intel_AMD64.qcow2";
  #           #   definition = NixVirt.lib.volume.writeXML {
  #           #     name = "whonix/Whonix-Workstation-Xfce-17.2.0.7.Intel_AMD64.qcow2";
  #           #     capacity = { count = 12; unit = "GB"; };
  #           #   };
  #           # }
  #         ];
  #       }
  #     ];
  #     networks = [
  #     {
  #       definition = NixVirt.lib.network.writeXML (NixVirt.lib.network.templates.bridge {
  #           uuid = "70b08691-28dc-4b47-90a1-45bbeac9ab5a";
  #           subnet_byte = 71;
  #           });
  #       active = true;
  #     }
  #     ];
  #     domains = [
  #       # {
  #       #   definition = NixVirt.lib.domain.writeXML (NixVirt.lib.domain.templates.linux
  #       #   {
  #       #     name = "Whonix-Workstation";
  #       #     uuid = "d36db468-8c52-491a-9e83-da77d79d635f";
  #       #     memory = { count = 4; unit = "GiB"; };
  #       #     storage_vol = { pool = "images"; volume = "whonix/Whonix-Workstation-Xfce-17.2.0.7.Intel_AMD64.qcow2"; };
  #       #   });
  #       #   active = true;
  #       # }
  #       # {
  #       #   definition = NixVirt.lib.domain.writeXML (NixVirt.lib.domain.templates.linux
  #       #   {
  #       #     name = "Whonix-Gateway";
  #       #     uuid = "6570e4a2-d7bb-4520-9e12-b24cc685766d";
  #       #     memory = { count = 4; unit = "GiB"; };
  #       #     storage_vol = { pool = "images"; volume = "whonix/Whonix-Gateway-Xfce-17.2.0.7.Intel_AMD64.qcow2"; };
  #       #   });
  #       #   active = true;
  #       # }
  #       {
  #         definition = NixVirt.lib.domain.writeXML (NixVirt.lib.domain.templates.linux
  #         {
  #           name = "test-vm";
  #           uuid = "cc7439ed-36af-4696-a6f2-1f0c4474d87e";
  #           memory = { count = 4; unit = "GiB"; };
  #           storage_vol = { pool = "images"; volume = "debian.qcow"; };
  #         });
  #         active = false;
  #       }
  #     ];
  #   };
  # };

  # networking.firewall.trustedInterfaces = [ "virbr0" ];
  # networking.bridges.virbr0.interfaces = [];

  # users.users.${username}.extraGroups =
  #   [ "docker" "podman" "libvirtd" "lxd" "incus" "kvm" ];
}
