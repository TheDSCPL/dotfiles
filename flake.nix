{
  description = "My desktop configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs?ref=nixos-23.11";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, ... }@args:
  let
    nixpkgs-hyb = nixpkgs // {
      overlays = (nixpkgs.overlays or []) ++ [
        /* (final: prev: {
          grilo-plugins = prev.grilo-plugins // {
            broken = true;
            replacement = nixpkgs-stable.grilo-plugins;
          };
        }) */
        (
          final: prev: {
            gom = prev.gom.overrideAttrs (oldAttrs: let version = "0.5.1"; in {
              inherit version;
              src = builtins.fetchurl {
                url = "mirror://gnome/sources/${oldAttrs.pname}/${self.lib.versions.majorMinor version}/${oldAttrs.pname}-${version}.tar.xz";
                sha256 = "sha256-15dc4d1302f8210cf08ccba9b2696417fd946d9911bbaf5183cbe36d25d570e0";
              };
            });
          }
        )
      ];
    };
  in {
    nixosConfigurations.elpi-desktop = import ./nixos/elpi-desktop (
      builtins.removeAttrs (args // { nixpkgs = nixpkgs-hyb; }) [ "nixpkgs-stable" ]
    );
  };
}
