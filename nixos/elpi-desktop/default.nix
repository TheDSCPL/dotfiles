{ nixpkgs, ... }@args:
let
  system = "x86_64-linux";
  pkgs = import nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
      firefox.enableAdobeFlash = true;
      overlays = [
        (final: prev: {
          # Update wayland to 1.22.93
          wayland = prev.wayland.overrideAttrs (oldAttrs: let version = "1.22.93"; in {
            inherit version;
            src = builtins.fetchurl {
              url = "https://gitlab.freedesktop.org/wayland/wayland/-/releases/${version}/downloads/${oldAttrs.pname}-${version}.tar.xz";
              sha256 = "sha256-3d8545356d83330db3fcf4adbd30a138bebbc28904a0068983b64ef40182a94g";
            };
          });
          # Update gom to 0.5.1
          gom = prev.gom.overrideAttrs (oldAttrs: let version = "0.5.1"; in {
            inherit version;
            src = builtins.fetchurl {
              url = "mirror://gnome/sources/${oldAttrs.pname}/${nixpkgs.lib.versions.majorMinor version}/${oldAttrs.pname}-${version}.tar.xz";
              sha256 = "sha256-15dc4d1302f8210cf08ccba9b2696417fd946d9911bbaf5183cbe36d25d570e0";
            };
          });
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
            } );
          });
        })
      ];
    };
  };
in nixpkgs.lib.nixosSystem {
  inherit system pkgs;
  modules = [
    # Module knobs
    ({...}: {
      config.hostConsts = {
        hostname = "elpi-desktop";
        timezone = "Atlantic/Azores";
        user = {
          username = "elpi";
          name = "Elpi";
        };
      };
    })
    ./module.nix
  ];
  specialArgs = {
    inherit args;
  };
}