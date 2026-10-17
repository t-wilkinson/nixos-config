# Bringing up a machine

Every new machine starts as **void**: a blank NixOS that boots, gets on the network and lets
you in over SSH with the admin key (`adminKeys` in `hosts/homelab/inventory.nix`). The real
configuration is then deployed onto it. Images are built from `hosts/void`:

| Image | Build | Use it for |
| --- | --- | --- |
| `void-sd` | `nix build .#images.void-sd` | a Raspberry Pi (SD card or USB SSD) |
| `void-iso` | `nix build .#images.void-iso` | an x86 PC, installing from a USB stick |
| `void-disk` | `nix build .#images.void-disk` | an x86 PC, writing the target drive directly |
| `homelab` | `nix build .#images.homelab` | the Pi with its full config already in the image |

All void images: root SSH with the admin key only, mDNS (`ssh root@void.local`), NetworkManager
(`nmtui` for Wi-Fi), Tailscale (`tailscale up`), flakes and the usual install tools.

## Where to build

- **The PC** builds everything: x86 natively, aarch64 through emulation
  (`boot.binfmt.emulatedSystems`). Slow for big compiles, fine for images, which are mostly
  downloads from the binary cache.
- **The MacBook** builds aarch64-linux (Pi images, the homelab config) in the nix-darwin
  `linux-builder` VM. It doesn't build x86_64-linux unless the builder gets Rosetta, so build
  `void-iso`/`void-disk` on the PC.
- **On the Pi itself**: `nix run .#deploy -- .#homelab --remote-build` sends the derivations
  to the Pi and builds there; nothing needs to build on your machine.

If the Mac's builder isn't working yet: switch once with `customBuilder = false` in
`hosts/macos/default.nix` (uses the prebuilt VM image), check it with
`nix build --impure --expr '(with import <nixpkgs> { system = "aarch64-linux"; }; hello)'`,
then set `customBuilder = true` for the bigger VM and switch again.

## Writing an image

Find the device first (`lsblk` on Linux, `diskutil list` on macOS). Writing to the wrong
device destroys it.

```sh
# Linux
zstd -dc result/sd-image/*.img.zst | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress   # void-sd
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M conv=fsync status=progress                    # void-iso
sudo dd if=result/nixos-image-efi-raw-*.img of=/dev/sdX bs=4M conv=fsync status=progress      # void-disk

# macOS (rdiskN is faster than diskN)
diskutil unmountDisk /dev/diskN
zstd -dc result/sd-image/*.img.zst | sudo dd of=/dev/rdiskN bs=4m
```

## A new Pi (or rebuilding the homelab Pi)

1. Write `void-sd` (or `homelab`) to the card, boot the Pi on ethernet.
2. `ssh root@void.local` (or the address from your router).
3. Give it the homelab's age key, so sops can decrypt its secrets:
   `scp /path/to/age.key root@void.local:/etc/ssh/age.key && ssh root@void.local chmod 400 /etc/ssh/age.key`
   For a new host with its own key instead: `ssh root@void.local cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age`,
   add the result to `.sops.yaml`, then `sops updatekeys hosts/homelab/secrets.yaml`.
4. Deploy: `nix run .#deploy -- .#homelab --hostname void.local` (add `--remote-build` from a
   machine that can't build aarch64). From then on, `nix run .#h-deploy`.

The homelab config's root filesystem is the SD image's `NIXOS_SD` label, so a void-sd card can
take the homelab config directly.

## A new x86 machine

**From the USB installer (`void-iso`)**, booted on the target:

```sh
ssh root@void.local
# partition and mount at /mnt (by hand, or with disko), then:
nixos-generate-config --root /mnt          # hardware-configuration.nix for the new host
# add the host to the flake (hosts/<name>, nixosConfigurations.<name>), using that file
nixos-install --flake github:t-wilkinson/nixos-config#<name>
```

**By writing the drive (`void-disk`)**: put the target drive in another machine (or a USB
enclosure), write `void-disk` to it, move it back and boot. It boots void from that drive
(systemd-boot on the removable-media path, so no firmware setup is needed) and grows its
root partition to fill the drive. Then deploy:

```sh
nixos-rebuild switch --flake .#<name> --target-host root@void.local
```

The new host's config needs `fileSystems."/"` = `/dev/disk/by-label/nixos` (ext4) and the ESP
`/dev/disk/by-label/ESP` at `/boot`, matching the image, or a fresh install from the ISO.

## After the first deploy

- `tailscale up` once (the homelab Pi advertises `10.1.0.0/30`; approve the route in the admin console).
- `homelab-status` on the Pi checks services, routes, the tunnel, DNS, storage and backups.
- Beszel: create the account, copy the hub key into `homelab.services.beszel.data.hubKey`, deploy again.
