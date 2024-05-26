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
      cairo = prev.cairo.override {
        x11Support = false;
        xcbSupport = false;
        gobjectSupport = true;
      };
    })
    (final: prev: {
      gtk2 = prev.gtk2.overrideAttrs (oldAttrs: {
        preConfigure = ''
          ${oldAttrs.preConfigure or ""}
          export CAIRO_BACKEND_LIBS="cairo-gobject cairo-svg cairo-pdf"
        '';
      });
    })
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