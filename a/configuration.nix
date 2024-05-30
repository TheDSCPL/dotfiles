{ config, lib, pkgs, ... }:

let
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
  imports = [
    # ./boot.nix
    ./hardware-configuration.nix # Optional: Separate file for hardware settings
    ./hardened.nix
  ];

  system.stateVersion = "23.11";
  nixpkgs.config.allowUnfree = true;
  hardware.enableRedistributableFirmware = true;
  nix.package = pkgs.nixFlakes;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking (Assuming NetworkManager)
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;
  networking.hostName = "elpi-desktop";

  # Timezone 
  time.timeZone = "UTC";

  # Console Configuration 
  console.font = "Lat2-Terminus16";
  console.keyMap = "us";

  # NVIDIA
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware = {
    nvidia = {
      # open = true;
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
    #pulseaudio.support32Bit = true;
  };

  # Pipewire
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Wayland and Hyprland
  programs.hyprland = {
    enable = true;
    enableNvidiaPatches = true;
    xwayland.enable = true;
  };
  services.xserver = {
    enable = false;
    displayManager.sddm.enable = true;
  };
  services.dbus.enable = true;
  services.dbus.packages = with pkgs; [dconf];
  services.udev.packages = with pkgs; [gnome.gnome-settings-daemon];
  programs = {
    ccache.enable = true;
    hyprland = {
      package = inputs.hyprland.packages.${pkgs.system}.default.override {
        nvidiaPatches = true;
        wlroots =
          inputs.hyprland.packages.${pkgs.system}.wlroots-hyprland.overrideAttrs
          (old: {
            patches =
              (old.patches or [])
              ++ [
                (pkgs.fetchpatch {
                  url = "https://aur.archlinux.org/cgit/aur.git/plain/0001-nvidia-format-workaround.patch?h=hyprland-nvidia-screenshare-git";
                  sha256 = "A9f1p5EW++mGCaNq8w7ZJfeWmvTfUm4iO+1KDcnqYX8=";
                })
              ];
          });
      };
    };
  };

  
  environment.sessionVariables = {
    # If the cursor becomes invisible
    #WLR_NO_HARDWARE_CURSORS = "1";
    # Hint electron apps to use Wayland
    NIXOS_OZONE_WL = "1";
  };
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # User Configuration (Create your user)
  users.users.elpi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # "wheel" for sudo access
    initialPassword = "password";
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  # Essential Tools (A few very basic ones to start)
  environment.systemPackages = with pkgs; [
    socat
    neovim
    vim
    wget
    curl
    firefox
    chromium

    # Wayland nav bar (maybe change to eww?)
    (waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      })
    )
    # Notifications
    dunst
    libnotify
    # Wayland dektop background
    swww
    #Terminal emulator
    alacritty
    # App launcher
    rofi-wayland
    # Network applet
    networkmanagerapplet
  ];

  # Wayland configs
  # https://gist.github.com/sioodmy/1932583dd8a804e0b3fe86416b923a16#tweak-your-configurationnix
  environment = {
    variables = {
      NIXOS_OZONE_WL = "1";
      GBM_BACKEND = "nvidia-drm";
      __GL_GSYNC_ALLOWED = "0";
      __GL_VRR_ALLOWED = "0";
      DISABLE_QT5_COMPAT = "0";
      ANKI_WAYLAND = "1";
      DIRENV_LOG_FORMAT = "";
      WLR_DRM_NO_ATOMIC = "1";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_QPA_PLATFORMTHEME = "qt5ct";
      MOZ_ENABLE_WAYLAND = "1";
      WLR_BACKEND = "vulkan";
      WLR_NO_HARDWARE_CURSORS = "1";
      XDG_SESSION_TYPE = "wayland";
      CLUTTER_BACKEND = "wayland";
      WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
    };
    loginShellInit = ''
      dbus-update-activation-environment --systemd DISPLAY
      eval $(ssh-agent)
      eval $(gnome-keyring-daemon --start)
      export GPG_TTY=$TTY
    '';
  };
  environment.systemPackages = with pkgs; environment.systemPackages ++ [
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

}