{
  config,
  unstable,
  ...
}:
let
  cfg = config.homelab.services.immich;
in
{
  services.immich = {
    package = unstable.immich;
    enable = true;
    port = cfg.port;
    host = "0.0.0.0";
    mediaLocation = "/mnt/storage/immich";
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
    ports = [ "3003:3003" ];
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

  systemd.services.immich-server.serviceConfig = {
    ReadWritePaths = [ config.homelab.drives.pubdrive ];
  };

  systemd.services.immich-microservices.serviceConfig = {
    ReadWritePaths = [ config.homelab.drives.pubdrive ];
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
