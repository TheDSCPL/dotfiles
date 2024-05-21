{ nixpkgs, ... }@inputs:
let gnome-mutter-triple-buffering =
  { pkgs, ... }: {
    nixpkgs.overlays = [
      # GNOME 46: triple-buffering-v4-46
      (final: prev: {
        gnome = prev.gnome.overrideScope (gnomeFinal: gnomePrev: {
          mutter = gnomePrev.mutter.overrideAttrs ( old: {
            src = pkgs.fetchgit {
              # https://gitlab.gnome.org/vanvugt/mutter/-/commits/triple-buffering-v4-46
              url = "https://gitlab.gnome.org/vanvugt/mutter.git";
              #rev = "663f19bc02c1b4e3d1a67b4ad72d644f9b9d6970";
              rev = "triple-buffering-v4-46";
              sha256 = "sha256-I1s4yz5JEWJY65g+dgprchwZuPGP9djgYXrMMxDQGrs=";         
            };
          } );
        });
      })
    ];
  };
in nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
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
    gnome-mutter-triple-buffering
    ./module.nix
  ];
  specialArgs = {
    flakeInputs = inputs;
  };
}