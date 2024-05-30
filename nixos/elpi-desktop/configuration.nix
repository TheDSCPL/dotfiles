{ config, lib, pkgs, ... }:
let
  hostConsts = config.hostConsts;
#  system = nixpkgs.hostPlatform;

  config =
  # General configurations
  {
    # Timezone
    time.timeZone = hostConsts.timezone;
    i18n.defaultLocale = hostConsts.locale;
    services.xserver.xkb.layout = hostConsts.keyboardLayout;

    # Console
    console = {
      font = "Lat2-Terminus16";
      # keyMap = "us";
      useXkbConfig = true; # use xkb.options in tty.
    };
    programs.zsh.enable = true;
    environment.shells = [ pkgs.zsh ];
    users.defaultUserShell = pkgs.zsh;
  } //
  # System packages
  {
    # Install NeoVim and use it globally as default editor
    programs.neovim.enable = true;
    programs.neovim.defaultEditor = true;

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    environment.systemPackages = with pkgs; [
      htop
      vim
      git
      wget
      curl
      # firefox-devedition-bin
      # chromium
      cryptsetup
      unzip
      zip
      tree
    ];
  } //
  # T GUI
  {
    # TODO: add the rest of the GUI config

    # Enable X11 (gave up from Wayland after 3 weeks of trying to make it work with NVIDIA)
    services.xserver.enable = true;
    # Enable the GNOME Desktop Environment.
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;
    # Enable libinput for mouse events
    services.libinput.enable = true;
    services.xserver.displayManager.defaultSession = "gnome";
    # From 24.05
    #services.displayManager.defaultSession = "gnome";
  } //
  # Sound
  {
    sound.enable = true;
    hardware.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  } //
  # Services
  {
    # Enable CUPS to print documents.
    # services.printing.enable = true;
    services = {
      openssh = {
        enable = true;
        # Adds ~/.ssh/authorizedKeys to authorizedKeysFiles (from 24.05)
        # authorizedKeysInHomedir = true;
        settings = {
          # PermitRootLogin = "yes";
          PasswordAuthentication = true;
        };
      };
      dbus = {
        enable = true;
        packages = with pkgs; [ dconf ];
      };
      udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
    };
  } //
  # Networking
  {
    # Enable the NetworkManager service to configure network connections.
    networking.networkmanager.enable = true;
    networking.networkmanager.wifi.backend = "iwd";
    # Enable wireless support via wpa_supplicant.
    #networking.wireless.enable = true;
    networking.hostName = hostConsts.hostname;
    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    networking.useDHCP = true;
    # networking.interfaces.enp6s0.useDHCP = lib.mkDefault true;
    # networking.interfaces.wlp5s0.useDHCP = lib.mkDefault true;

    # Or disable the firewall altogether.
    networking.nftables.enable = true;
    networking.firewall.enable = true;
    # Open ports in the firewall.
    networking.firewall.allowedTCPPorts = [];
    networking.firewall.allowedUDPPorts = [];

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  } //
  # T Nix
  {
    # TODO: set nixpkgs channel to this flake's configured nixpkgs input

    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.allowBroken = true;
    nix.package = pkgs.nixFlakes;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    # This option defines the first version of NixOS you have installed on this particular machine,
    # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
    #
    # Most users should NEVER change this value after the initial install, for any reason,
    # even if you've upgraded your system to a new NixOS release.
    #
    # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
    # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
    # to actually do that.
    #
    # This value being lower than the current NixOS release does NOT mean your system is
    # out of date, out of support, or vulnerable.
    #
    # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
    # and migrated your data accordingly.
    #
    # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
    system.stateVersion = "23.11"; # Did you read the comment?
  } //
  # T Users
  {
    # TODO: add HomeManager

    users.users.elpi = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ]; # "wheel" for sudo access
      initialPassword = "password";
      shell = pkgs.zsh;
    };
  };
in
{
  options = {
    hostConsts = {
      hostname = lib.mkOption {
        type = lib.types.uniq lib.types.str;
        example = "elpi-desktop";
      };
      timezone = lib.mkOption {
        type = lib.types.str;
        example = "Atlantic/Azores";
      };
      locale = lib.mkOption {
        type = lib.types.str;
        example = "pt_PT.UTF-8";
      };
      user.username = lib.mkOption {
        type = lib.types.str;
        example = "elpi";
      };
      user.name = lib.mkOption {
        type = lib.types.str;
        example = "Elpi";
      };
      keyboardLayout = lib.mkOption {
        type = lib.types.str;
        example = "pt";
      };
    };
  };
  inherit config;
}

