{ config, lib, pkgs, ... }:
let
  hostConsts = config.hostConsts;
#  system = nixpkgs.hostPlatform;

  merge =
  let
    f = self: newAttrSet: (lib.attrsets.recursiveUpdate self newAttrSet) // {
      __functor = f;
    };
  in attrSet: attrSet // {
    __functor = f;
  };

  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/nvidia-x11/default.nix#L35
  nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "550.78";
    sha256_64bit = "sha256-NAcENFJ+ydV1SD5/EcoHjkZ+c/be/FQ2bs+9z+Sjv3M=";
    sha256_aarch64 = "sha256-2POG5RWT2H7Rhs0YNfTGHO64Q8u5lJD9l/sQCGVb+AA=";
    openSha256 = "sha256-cF9omNvfHx6gHUj2u99k6OXrHGJRpDQDcBG3jryf41Y=";
    settingsSha256 = "sha256-lZiNZw4dJw4DI/6CI0h0AHbreLm825jlufuK9EB08iw=";
    persistencedSha256 = "sha256-qDGBAcZEN/ueHqWO2Y6UhhXJiW5625Kzo1m/oJhvbj4=";
  };

  cfg =
  merge
  # General configurations
  {
    # Timezone
    time.timeZone = hostConsts.timezone;
    #i18n.defaultLocale = hostConsts.locale;
    services.xserver.xkb.layout = hostConsts.keyboardLayout;
    #services.xserver.xkb.variant = "nativo";

    # Console
    console = {
      font = "Lat2-Terminus16";
      # keyMap = "us";
      useXkbConfig = true; # use xkb.options in tty.
    };
    programs.zsh.enable = true;
    environment.shells = [ pkgs.zsh ];
    users.defaultUserShell = pkgs.zsh;
    security.rtkit.enable = true;
  }
  # System packages
  {
    # Install NeoVim and use it globally as default editor
    programs.neovim.enable = true;
    programs.neovim.defaultEditor = true;

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    programs.gamemode.enable = true;
    programs.tuxclocker = {
      enable = true;
      useUnfree = true;
    };
    # Controller for peripherals RGB lights
    services.hardware.openrgb = {
      enable = true;
      package = pkgs.openrgb-with-all-plugins;
      motherboard = "amd";
    };
    boot.kernelParams = [
      # https://gitlab.com/CalcProgrammer1/OpenRGB#kernel-parameters
      "acpi_enforce_resources=lax"

      # https://wiki.archlinux.org/title/Sysctl#Improving_performance
      # Default: 212992
      "net.core.rmem_max=16777216"
      # Default: 212992
      "net.core.wmem_max=16777216"
      # Default: 131072
      "net.core.optmem_max=65536"
      # Default: 4096        131072  6291456
      ''net.ipv4.tcp_rmem="4096 1048576 2097152"''
      # Default: 4096        16384   4194304
      ''net.ipv4.tcp_wmem="4096 65536 16777216"''
      # Default: 4096
      "net.ipv4.udp_rmem_min=8192"
      # Default: 4096
      "net.ipv4.udp_wmem_min=8192"
      # Default: 2048
      "net.ipv4.tcp_max_syn_backlog=8192"
      # Default: 1
      "net.ipv4.tcp_slow_start_after_idle=0"
      # Default: 0
      "net.ipv4.tcp_mtu_probing=1"
    ];

    environment.systemPackages = with pkgs; [
      alacritty
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
      # NVIDIA controls and overclocking
      gwe
      # GPU-only screen recorder
      gpu-screen-recorder-gtk
      tree
      nix-tree
      # Temperature sensors poller
      lm_sensors
      # Audio effects
      easyeffects
      # Pipewire patchbay (audio routing)
      helvum
      # Game micro-compositor
      gamescope
      # Windows games compatibility layer
      lutris
      # Notifications
      dunst
      libnotify
      gnome.adwaita-icon-theme
    ];

    # Set Alacritty as default terminal
    environment.variables.TERMINAL = "alacritty";
  }
  # GUI
  {
    # Enable X11 (gave up from Wayland after 3 weeks of trying to make it work with NVIDIA)
    services.xserver.enable = true;

    # Enable the Cinnamon Desktop Environment.
    services.xserver.desktopManager.cinnamon.enable = true;
    services.xserver.displayManager.lightdm.enable = true;
    /* services.xserver.config = ''
      Section "Device"
          Identifier     "NVIDIA Card"
          Driver         "nvidia"
          VendorName     "NVIDIA Corporation"
          BoardName      "GeForce RTX 3090"
          Option         "NoLogo" "true"
          Option         "UseEDID" "false"
          Option         "ModeValidation" "NoVesaModes, NoXServerModes"
          Option         "UseDisplayDevice" "DFP-0"
      EndSection

      Section "Screen"
          Identifier     "Screen0"
          Device         "NVIDIA Card"
          Option         "UseDisplayDevice" "DFP"
          Option         "ModeValidation" "NoVesaModes, NoXServerModes"
      EndSection
    ''; */
    services.xserver.exportConfiguration = true;
    environment.cinnamon.excludePackages = with pkgs; [
      # Exclude screen reader
      orca
      # Exclude GNOME Terminal (using Alacritty terminal emulator)
      gnome.gnome-terminal
    ];

    # Enable libinput for mouse events
    services.libinput.enable = true;
    services.displayManager.defaultSession = "cinnamon";

    fonts.fontDir.enable = true;
    fonts.packages = with pkgs; [
      dejavu_fonts
    ];

    # NVIDIA
    services.xserver.videoDrivers = lib.mkForce [ "nvidia" ];
    # Coolbits 31: Enable all overclocking options
    # https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Enabling_overclocking
    services.xserver.deviceSection = ''
      BusID          "${config.hardware.nvidia.prime.nvidiaBusId}"
      VendorName     "NVIDIA Corporation"
      BoardName      "GeForce RTX 3090"
      Option         "NoLogo" "true"
      Option         "UseDisplayDevice" "DFP-5"
      Option         "AllowEmptyInitialConfiguration"
      Option         "Coolbits" "31"
    '';

    hardware = {
      nvidia = {
        open = false;
        package = nvidiaPackage;
        powerManagement.enable = true;
        modesetting.enable = true;
        nvidiaPersistenced = true;
        # nvidiaSettings = false;
      };
      # This option will expose GPUs on containers with the --device CLI option (available from 24.05)
      nvidia-container-toolkit.enable = true;
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
        extraPackages = with pkgs; [
          libva
          nvidia-vaapi-driver # LIBVA_DRIVER_NAME = "nvidia"
          #intel-media-driver  # LIBVA_DRIVER_NAME = "iHD"
          vaapiVdpau
          libvdpau-va-gl
          libva-utils
          # Vulkan
          vulkan-tools
          # DirectX 9, 10 and 11
          dxvk
        ];
      };
      # pulseaudio.support32Bit = true;
    };
    virtualisation.docker.enableNvidia = true;

    environment = {
      variables = {
        # VA-API NVIDIA
        LIBVA_DRIVER_NAME = "nvidia";
        PROTON_ENABLE_NVAPI="1";
        PROTON_ENABLE_NGX_UPDATER="1";
        DXVK_ASYNC="1";
        DXVK_ENABLE_NVAPI="1";
        NVD_BACKEND = "direct";
        GBM_BACKEND = "nvidia-drm";
        VKD3D_CONFIG="dxr11,dxr";
        __GL_GSYNC_ALLOWED = "0";
        __GL_VRR_ALLOWED = "0";
        DIRENV_LOG_FORMAT = "";
        #__NV_PRIME_RENDER_OFFLOAD = "1";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
        CINNAMON_DEBUG="1";
      } /* // {
        # https://gist.github.com/sioodmy/1932583dd8a804e0b3fe86416b923a16#tweak-your-configurationnix
        # Wayland configs
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland";
        QT_QPA_PLATFORMTHEME = "qt5ct";
        MOZ_ENABLE_WAYLAND = "1";
        XDG_SESSION_TYPE = "wayland";
        CLUTTER_BACKEND = "wayland";
        WLR_BACKENDS = "drm";
        WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
        # WLR_DRM_NO_ATOMIC = "1";
        # WLR_NO_HARDWARE_CURSORS = "1";
      } */;
    };
  }
  # Sound
  {
    sound.enable = true;
    hardware.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      audio.enable = true;
      # Add RAOP/Airplay ports to firewall
      #raopOpenFirewall = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  }
  # T Services
  {
    services = {
      # Enable CUPS to print documents.
      printing.enable = true;
      openssh = {
        enable = true;
        # Adds ~/.ssh/authorizedKeys to authorizedKeysFiles (from 24.05)
        authorizedKeysInHomedir = true;
        settings = {
          PermitRootLogin = "yes";
          PasswordAuthentication = true;
        };
      };
      dbus = {
        enable = true;
        packages = with pkgs; [ dconf ];
      };
      udev.packages = [ nvidiaPackage ];
      # TODO: Add this to a git encrypted file
      #services.cloudflared.enable
    };
  }
  # Networking
  {
    # Enable the NetworkManager service to configure network connections.
    networking.networkmanager.enable = true;
    #networking.networkmanager.wifi.backend = "iwd";
    networking.hostName = hostConsts.hostname;
    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    # networking.useDHCP = true;
    # networking.interfaces.enp6s0.useDHCP = lib.mkDefault true;
    # networking.interfaces.wlp5s0.useDHCP = lib.mkDefault true;

    # Or disable the firewall altogether.
    networking.nftables.enable = true;
    networking.firewall.enable = true;
    # Open ports in the firewall.
    networking.firewall.allowedTCPPorts = [ 22 ];
    networking.firewall.allowedUDPPorts = [];

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true;
        };
      };
    };
    services.blueman.enable = true;
  }
  # Nix
  {
    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.allowBroken = true;
    nixpkgs.flake.setNixPath = true;
    nixpkgs.flake.setFlakeRegistry = true;
    nix.package = pkgs.nixFlakes;
    nix.settings.experimental-features = [ "nix-command" "flakes" "repl-flake" ];
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
  }
  # T Users
  {
    # TODO: add HomeManager

    users.users.elpi = {
      isNormalUser = true;
      extraGroups = [
        # "wheel" for sudo access
        "wheel"
        "networkmanager"
        "bluetooth"
        "lp"
        "users"
        "kvm"
      ] ++ lib.optional config.programs.gamemode.enable "gamemode";
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
  config = removeAttrs cfg [ "__functor" ];
}

