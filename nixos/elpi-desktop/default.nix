{config, lib, pkgs, inputs, ...}:
let
  hostConsts = config.hostConsts;
  dbus-hyprland-environment = pkgs.writeTextFile {
    name = "dbus-hyprland-environment";
    destination = "/bin/dbus-hyprland-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=hyprland
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };
  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;
    text = let
      schema = pkgs.gsettings-desktop-schemas;
      datadir = "${schema}/share/gesettings/schemas/${schema.name}";
    in ''
      export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
      gnome_schema=org.gnome.desktop.interface
      gesettings set $gnome_schema gtk-theme 'Adwaita'
    '';
  };
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
    #({ config, ... }: { config._module.args = { inherit pkgs inputs; }; })
    ./hardware-configuration.nix
    #./ui-sound.nix
    # ./hardened.nix
  ];
  config = let keyboardLayout = "pt"; in {
    # Linux Kernel
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # Nix configurations
    system.stateVersion = "23.11";
    nixpkgs.config.allowUnfree = true;
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

    # Console Configuration 
    console.font = "Lat2-Terminus16";
    console.useXkbConfig = true;

    # NVIDIA
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware = {
      nvidia = {
        open = true;
        powerManagement.enable = true;
        modesetting.enable = true;
        nvidiaPersistenced = true;
      };
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
        extraPackages = with pkgs; [
          vaapiVdpau
          libvdpau-va-gl
          nvidia-vaapi-driver
        ];
      };
      # pulseaudio.support32Bit = true;
    };

    # User Configuration (Create your user)
    users.users.elpi = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ]; # "wheel" for sudo access
      initialPassword = "password";
      shell = pkgs.zsh;
    };
    programs.zsh.enable = true;

    # Essential system packages
    environment.systemPackages = with pkgs; [
      socat
      neovim
      vim
      wget
      curl
      firefox
      chromium
      gnome.adwaita-icon-theme
      dbus-hyprland-environment
      configure-gtk
      cryptsetup
    ];

    # Optional Services (Uncomment and configure as needed)
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
      };
    };
    # services.xserver.enable = true; # If you want a graphical environment
    # services.printing.enable = true;
  };
}