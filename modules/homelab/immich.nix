# modules/homelab/immich.nix
{
  config,
  lib,
  unstable,
  ...
}:
let
  cfg = config.homelab.services.immich;
  shares = config.homelab.storage.shares;
in
# Runs natively on its host (the PC; host = "pc" in hosts/inventory.nix), with machine
# learning in a CUDA container. The old Pi container version is ./immich-container.nix.
lib.mkIf cfg.runsHere {
  services.immich = {
    package = unstable.immich;
    enable = true;
    port = cfg.port;
    host = "0.0.0.0";
    mediaLocation = shares.immich.path; # thumbnails, encoded video, backups/ (database dumps)
    # accelerationDevices = [
    #   "/dev/dri/renderD129"
    #   "/dev/nvidia0"
    #   "/dev/nvidiactl"
    #   "/dev/nvidia-uvm"
    # ];
    machine-learning = {
      enable = false;

      # environment = {
      #   IMMICH_ACCELERATION_PROVIDER = "cuda";
      #   CUDA_VISIBLE_DEVICES = "0";

      #   LD_LIBRARY_PATH = lib.makeLibraryPath [
      #     pkgs.cudaPackages.cudatoolkit
      #     pkgs.cudaPackages.cudnn
      #     pkgs.linuxPackages.nvidia_x11
      #     "/run/opengl-driver/lib"
      #   ];
      #   # # prime offload environment variables
      #   # __NV_PRIME_RENDER_OFFLOAD = "1";
      #   # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      #   # __VK_LAYER_NV_optimus = "NVIDIA_only";
      # };
    };
  };

  virtualisation.oci-containers.containers.immich-machine-learning = {
    image = "ghcr.io/immich-app/immich-machine-learning:release-cuda";
    # Docker-published ports bypass the NixOS firewall, so bind to loopback only.
    # Immich's machine-learning URL must then be http://127.0.0.1:3003 (not "localhost", which may resolve to ::1).
    ports = [ "127.0.0.1:3003:3003" ];
    volumes = [
      "immich-model-cache:/cache"
    ];
    environment = {
      CUDA_VISIBLE_DEVICES = "0";
      IMMICH_HOST = "0.0.0.0";
      IMMICH_PORT = "3003";
    };
    extraOptions = [
      "--device=/dev/nvidiactl"
      "--device=/dev/nvidia-uvm"
      "--device=/dev/nvidia0"
      "--ipc=host"
    ];
  };

  # pubdrive is an external library (the photos stay where they are). The microservices
  # worker runs inside immich-server now; there is no immich-microservices unit.
  systemd.services.immich-server.serviceConfig = {
    ReadWritePaths = [ shares.pubdrive.path ];
  };

  users.users.immich.extraGroups = [
    "serverdata"
    "video"
    "render"
  ];

  systemd.services."docker-immich-machine-learning" = {
    wantedBy = [ "immich-server.service" ];
  };

  # systemd.services.immich-machine-learning.serviceConfig = {
  #   # PrivateDevice = lib.mkForce false;
  #   # DevicePolicy = "closed";
  #   DeviceAllow = [
  #     "/dev/dri/renderD129 rw"
  #     "/dev/nvidia0 rw"
  #     "/dev/nvidiactl rw"
  #     "/dev/nvidia-uvm rw"
  #     "/dev/nvidia-uvm-tools rw"
  #     "/dev/nvidia-modeset rw"
  #   ];
  # };

  # systemd.services.immich-server.serviceConfig = {
  #   DeviceAllow = [
  #     "/dev/nvidiactl rw"
  #     "/dev/nvidia0 rw"
  #     "/dev/nvidia-modeset rw"
  #     "/dev/nvidia-uvm rw"
  #   ];
  # };
}
