{ lib, unstable, ... }:
{

  services.immich = {
    package = unstable.immich;
    enable = true;
    port = 2283;
    host = "0.0.0.0";
    mediaLocation = "/mnt/storage/immich";
    accelerationDevices = [ "/dev/dri/renderD129" ];
    machine-learning = {
      enable = true;
      environment = {
        # Tell ONNX Runtime / PyTorch to target CUDA
        IMMICH_ACCELERATION_PROVIDER = "cuda";
        # prime offload environment variables
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
        CUDA_VISIBLE_DEVICES = "0";
      };
    };
  };
  users.users.immich.extraGroups = [ "serverdata" ];

  systemd.services.immich-machine-learning.serviceConfig = {
    DeviceAllow = [
      "/dev/nvidiactl rw"
      "/dev/nvidia0 rw"
      "/dev/nvidia-modeset rw"
      "/dev/nvidia-uvm rw"
      "/dev/nvidia-uvm-tools rw"
    ];
  };

  systemd.services.immich-server.serviceConfig = {
    DeviceAllow = [
      "/dev/nvidiactl rw"
      "/dev/nvidia0 rw"
      "/dev/nvidia-modeset rw"
      "/dev/nvidia-uvm rw"
    ];
  };
}
