# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:
{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # Linux Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Boot
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" "usb_storage" "dm_mod" "dm_crypt" "btrfs" "dm_mod" "dm_snapshot" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    device = "nodev"; # for UEFI, use "nodev"; otherwise, specify the device like "/dev/sda"
    efiSupport = true;
    useOSProber = true;
  };
  # /etc is mounted via an overlayfs instead of created by a custom perl script
  # EXPERIMENTAL: I tried and it breaks the build, so it's disabled for now
  #system.etc.overlay.enable = true;
  # Start systemd in initrd (required for the overlayfs above)
  #boot.initrd.systemd.enable = true;

  # Devices and mounts

  boot.initrd.luks.devices = {
#    keyholder = {
#      device = "/dev/disk/by-partlabel/Keyholder";
#      preLVM = true;
#      allowDiscards = true;
#      passphrase = "R5uYiCQzPLky2gFwig8K";
#    };
    main = {
      device = "/dev/disk/by-partlabel/lvm-root";
#      keyFile = "/path/to/mounted/keyholder/keyfile";
      allowDiscards = true;
    };
  };

  # Mount the Btrfs subvolumes
  fileSystems."/" = {
    device = "/dev/vgmint/nix-root";
    fsType = "btrfs";
    options = [ "subvol=@" ];
  };

  fileSystems."/home" = {
    device = "/dev/vgmint/nix-root";
    fsType = "btrfs";
    options = [ "subvol=@home" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/nix-efi";
    fsType = "vfat";
  };

  swapDevices = [
    {
      device = "/dev/vgmint/swap_1";
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.nvidia.prime.nvidiaBusId = "PCI:10:0:0";
}
