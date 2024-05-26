{nixpkgs, pkgs, ...}: {
  nixpkgs.config = {
    allowUnfree = true;
    # firefox.enableAdobeFlash = true;
  };
  nixpkgs.overlays = [
    (final: prev: {
      # Update wayland to 1.22.93
      wayland = (prev.wayland.overrideAttrs (oldAttrs: let version = "1.22.93"; in {
        inherit version;
        src = builtins.fetchurl {
          url = "https://gitlab.freedesktop.org/wayland/wayland/-/releases/${version}/downloads/${oldAttrs.pname}-${version}.tar.xz";
          sha256 = "sha256-siqTGEz0oetTBFPVYLxoaqa2lUWrafuoatpEeUEDOAg=";
        };
        patches = [];
      })).override {
        withDocumentation = false;
      };
      /* # Update gom to 0.5.1
      gom = prev.gom.overrideAttrs (oldAttrs: let version = "0.5.1"; in {
        inherit version;
        src = builtins.fetchurl {
          url = "mirror://gnome/sources/${oldAttrs.pname}/${nixpkgs.lib.versions.majorMinor version}/${oldAttrs.pname}-${version}.tar.xz";
          sha256 = "sha256-FdxNEwL4IQzwjMupsmlkF/2UbZkRu69Rg8vjbSXVcOA=";
        };
      }); */
    })
    (final: prev: {
      NetworkManager-vpnc = final.stdenv.mkDerivation {
        pname = "NetworkManager-vpnc";
        src = null;
        buildCommand = "echo 'Disabled this package due to compillation error (nm_version.h not found on package version 1.2.8)' > $out";
        passthru = {
          updateScript = {
            name = "gnome-update-script";
            command = [ "true" ];
            supportedFeatures = [
              "commit"
            ];
          };
          networkManagerPlugin = "VPN/nm-vpnc-service.name";
        };
      };
    })
    (final: prev: {
      dunst = prev.dunst.override {
        withX11 = false;
        withWayland = true;
      };
    })
    (final: prev: {
      gtk3 = prev.gtk3.override {
        waylandSupport = true;
        x11Support = false;
      };
    })
    #libepoxy
    (final: prev: {
      libepoxy = prev.libepoxy.overrideAttrs (oldAttrs: {
        mesonFlags = builtins.map (flag: if (flag == "-Degl=no") then "-Degl=yes" else flag) (oldAttrs.mesonFlags or []);
        buildInputs = oldAttrs.buildInputs ++ [ pkgs.libGL ];
      });
    })
    /* (final: prev: {
      cairo = prev.cairo.override {
        x11Support = false;
        xcbSupport = false;
        gobjectSupport = true;
      };
    }) */
    /* # GNOME 46: triple-buffering-v4-46
    (final: prev: {
      gnome = prev.gnome.overrideScope (gnomeFinal: gnomePrev: {
        mutter = gnomePrev.mutter.overrideAttrs ( old: {
          src = pkgs.fetchgit {
            # https://gitlab.gnome.org/vanvugt/mutter/-/commits/triple-buffering-v4-46
            url = "https://gitlab.gnome.org/vanvugt/mutter.git";
            #rev = "663f19bc02c1b4e3d1a67b4ad72d644f9b9d6970";
            rev = "refs/heads/triple-buffering-v4-46";
            sha256 = "sha256-I1s4yz5JEWJY65g+dgprchwZuPGP9djgYXrMMxDQGrs=";         
          };
        });
      });
    }) */
  ];
}