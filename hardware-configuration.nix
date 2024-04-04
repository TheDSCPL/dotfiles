{ config, lib, ... }:

{
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "dm_mod" "dm_crypt" "btrfs" "dm_mod" "dm_snapshot" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

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

  # Close the keyholder after decrypting the main partition
#  boot.initrd.postDeviceCommands = ''
#    umount /dev/mapper/keyholder || true  # Ignore error if not mounted
#    cryptsetup luksClose keyholder
#  '';

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    device = "nodev"; # for UEFI, use "nodev"; otherwise, specify the device like "/dev/sda"
    efiSupport = true;
    useOSProber = true;
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
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

#  boot.loader.systemd-boot.enable = true;
#  boot.loader.efi.canTouchEfiVariables = true;

#  boot.initrd.luks.devices = {
#    keyholder = {
#      device = "/dev/disk/by-partlabel/Keyholder";
#      preLVM = true;
#    };
#    main = {
#      device = "/dev/disk/by-partlabel/lvm-root";
#      keyFile = "/keyholder/keyfile";
#    };
#  };
}
