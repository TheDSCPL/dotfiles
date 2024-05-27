{nixpkgs, pkgs, lib, ...}: {
  # Make the nixpkgs channel be the system configuration flake's nixpkgs
  # input (benefit from the overlays, same configs and locked versions)
  /* nix = {
    registry = {
      self.flake = self;
      nixpkgs.flake = inputs.nixpkgs;
      n.flake = inputs.nixpkgs;
    };
    #registry.nixpkgs.flake = nixpkgs;
    nixPath = [ "nixpkgs=${nixpkgs}" ];
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  }; */

  nixpkgs = {
    config = {
      allowUnfree = true;
      # firefox.enableAdobeFlash = true;
    };

    overlays = [
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
      })
      (final: prev: {
        # Update gom to 0.5.1
        gom = prev.gom.overrideAttrs (oldAttrs: let version = "0.5.1"; in {
          inherit version;
          src = builtins.fetchurl {
            url = "https://download.gnome.org/sources/${oldAttrs.pname}/${lib.versions.majorMinor version}/${oldAttrs.pname}-${version}.tar.xz";
            sha256 = "sha256-FdxNEwL4IQzwjMupsmlkF/2UbZkRu69Rg8vjbSXVcOA=";
          };
        });
      })
      (final: prev: {
        # Disable networkmanager-vpnc due to compillation error (and I don't use it anyway)
        networkmanager-vpnc = prev.networkmanager-vpnc.overrideAttrs (oldAttrs: {
          buildCommand = "echo 'Disabled this package due to compillation error (nm_version.h not found on package version 1.2.8)' > $out";
        });
      })
      (final: prev: {
        # Update libshumate to 1.2.2
        libshumate = prev.libshumate.overrideAttrs (oldAttrs: let version = "1.2.2"; in {
          inherit version;
          src = builtins.fetchurl {
            url = "https://download.gnome.org/sources/${oldAttrs.pname}/${lib.versions.majorMinor version}/${oldAttrs.pname}-${version}.tar.xz";
            sha256 = "sha256-b1h1effy1gs40/RyfrGo0v6snL3AGOU/9fdyqGCPpEs=";
          };
          # Remove patch for version 1.2.1 because it's merged in 1.2.2
          patches = [];
          # Disable broken tests
          # doCheck = false;
        });
      })
      (final: prev: {
        # Update umockdev to 0.18.3
        umockdev = prev.umockdev.overrideAttrs (oldAttrs: let version = "0.18.3"; in {
          inherit version;
          src = builtins.fetchurl {
            url = "https://github.com/martinpitt/umockdev/releases/download/${version}/umockdev-${version}.tar.xz";
            sha256 = "sha256-q6lcMjA3yELxYXkxJgIxuFV9EZqiiRy8qLgR/MVZKUo=";
          };
          patches = (oldAttrs.patches or []) ++ [
            ./umockdev-remove-unknown-Wno-incompatible-function-pointer-type.patch
          ];
        });
      }) #libsecret-disable-broken-test-collection-test.patch
      (final: prev: {
        # Disable broken tests
        libwacom = prev.libwacom.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or []) ++ [
            ./libwacom-disable-files-in-git-and-pytest-tests.patch
          ];
        });
      })
      (final: prev: {
        # Disable broken tests
        libsecret = prev.libsecret.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or []) ++ [
            ./libsecret-disable-broken-test-collection-test.patch
          ];
        });
      })
      (final: prev: {
        # Disable X11 in dunst
        dunst = prev.dunst.override {
          withX11 = false;
          withWayland = true;
        };
      })
      (final: prev: {
        # Disable X11 in gtk3 (not anymore; gdk was needed by multiple packages)
        gtk3 = prev.gtk3.override {
          waylandSupport = true;
          x11Support = true;
        };
      })
      (final: prev: {
        # Disable X11 in gtk4 and disable broken media-gstreamer compilation
        gtk4 = (prev.gtk4.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags or [] ++ [ "-Dmedia-gstreamer=disabled" ];
        })).override {
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
      (final: prev: {
        glib = prev.glib.overrideAttrs (oldAttrs: {
          # Fix known build error
          # https://stackoverflow.com/a/21835025/6302540
          postPatch = ''
            ${oldAttrs.postPatch or ""}
            # Replace all strings with pattern "^static inline" with "static __inline" in all .c and .h files
            find . -type f '(' -name '*.c' -o -name '*.h' ')' -exec sed -i 's/^static inline/static __inline/g' {} +
          '';
        });
      })
      (final: prev: {
        cairo = prev.cairo.override {
          x11Support = true;
          xcbSupport = false;
          gobjectSupport = true;
        };
      })
      # GNOME 46: triple-buffering-v4-46
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
      })
    ];
  };
}