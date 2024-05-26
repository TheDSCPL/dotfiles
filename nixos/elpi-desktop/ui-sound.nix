{pkgs, flakeInputs, ...}@inputs: {
  config = {
    # Pipewire
    sound.enable = true;
    security.rtkit.enable = true;
    hardware.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    programs.xwayland.enable = true;
    services.xserver = {
      enable = false;
      displayManager.gdm.enable = true;
      displayManager.gdm.wayland = true;
      desktopManager.gnome.enable = true;
    };
    services.displayManager.defaultSession = "gnome";

    services.dbus.enable = true;
    services.dbus.packages = with pkgs; [dconf];
    services.udev.packages = with pkgs; [gnome.gnome-settings-daemon];
    programs = {
      ccache.enable = true;
    };

    environment.systemPackages = with pkgs; [
      # Notifications
      dunst
      libnotify
      #Terminal emulator
      # alacritty
      # Network applet
      # networkmanagerapplet
      gnome.adwaita-icon-theme
    ];

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
          libva
          nvidia-vaapi-driver # LIBVA_DRIVER_NAME = "nvidia"
          intel-media-driver  # LIBVA_DRIVER_NAME = "iHD"
          # vaapiVdpau
          # libvdpau-va-gl
          # Vulkan
          vulkan-tools
          # DirectX 9, 10 and 11
          dxvk
        ];
      };
      # pulseaudio.support32Bit = true;
    };

    environment = {
      noXlibs = false;
      variables = {
        # VA-API NVIDIA
        LIBVA_DRIVER_NAME = "nvidia";
        PROTON_ENABLE_NVAPI="1";
        DXVK_ENABLE_NVAPI="1";
        NVD_BACKEND = "direct";
      } // {
        # https://gist.github.com/sioodmy/1932583dd8a804e0b3fe86416b923a16#tweak-your-configurationnix
        # Wayland configs
        NIXOS_OZONE_WL = "1";
        GBM_BACKEND = "nvidia-drm";
        __GL_GSYNC_ALLOWED = "0";
        __GL_VRR_ALLOWED = "0";
        DIRENV_LOG_FORMAT = "";
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
        QT_QPA_PLATFORM = "wayland";
        QT_QPA_PLATFORMTHEME = "qt5ct";
        MOZ_ENABLE_WAYLAND = "1";
        XDG_SESSION_TYPE = "wayland";
        CLUTTER_BACKEND = "wayland";
        WLR_BACKENDS = "drm";
        WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
        # WLR_DRM_NO_ATOMIC = "1";
        # WLR_NO_HARDWARE_CURSORS = "1";
      };
      /* loginShellInit = ''
        dbus-update-activation-environment --systemd DISPLAY
        eval $(ssh-agent)
        eval $(gnome-keyring-daemon --start)
        export GPG_TTY=$TTY
      ''; */
    };
  };
}