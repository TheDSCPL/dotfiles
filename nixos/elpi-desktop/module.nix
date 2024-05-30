{config, lib, pkgs, ...}@inputs:
let
  hostConsts = config.hostConsts;
in
{
  options = {
    hostConsts = {
      hostname = lib.mkOption {
        type = lib.types.uniq lib.types.str;
        example = "elpi-desktop";
      };
      user.username = lib.mkOption {
        type = lib.types.str;
        example = "elpi";
      };
      user.name = lib.mkOption {
        type = lib.types.str;
        example = "Elpi";
      };
      timezone = lib.mkOption {
        type = lib.types.str;
        example = "Atlantic/Azores";
        default = "Atlantic/Azores";
      };
    };
  };
  imports = [
    #({ config, ... }: { config._module.args = { inherit pkgs flakeInputs; }; })
    ./hardware-configuration.nix
    ./ui-sound.nix
    # ./hardened.nix
  ];
  config =
  let keyboardLayout = "pt"; in {
    # Linux Kernel
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # Nix configurations
    system.stateVersion = "23.11";
    hardware.enableRedistributableFirmware = true;
    nix.package = pkgs.nixFlakes;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Networking (Assuming NetworkManager)
    networking.networkmanager.enable = true;
    networking.useDHCP = lib.mkDefault true;
    networking.hostName = hostConsts.hostname;

    # Timezone 
    time.timeZone = hostConsts.timezone;

    # Keyboard Configuration
    services.xserver.xkb.layout = keyboardLayout;

    # /etc is mounted via an overlayfs instead of created by a custom perl script
    # EXPERIMENTAL: I tried and it breaks the build, so it's disabled for now
    #system.etc.overlay.enable = true;
    # Start systemd in initrd (required for the overlayfs above)
    # boot.initrd.systemd.enable = true;

    # Console Configuration 
    console.font = "Lat2-Terminus16";
    console.useXkbConfig = true;

    # User Configuration (Create your user)
    users.users.elpi = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ]; # "wheel" for sudo access
      initialPassword = "password";
      shell = pkgs.zsh;
    };
    programs.zsh.enable = true;
    environment.shells = [ pkgs.zsh ];
    users.defaultUserShell = pkgs.zsh;

    # Essential system packages
    environment.systemPackages = with pkgs; [
      socat
      neovim
      vim
      wget
      curl
      firefox-devedition-bin
      # chromium
      cryptsetup
      wayland
    ];

    # Optional Services (Uncomment and configure as needed)
    services.openssh = {
      enable = true;
      # Adds ~/.ssh/authorizedKeys to authorizedKeysFiles (from 24.05)
      # authorizedKeysInHomedir = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
      };
    };
    # services.xserver.enable = true; # If you want a graphical environment
    # services.printing.enable = true;
  };
}