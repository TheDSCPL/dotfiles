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
        (final: prev: {
          grilo-plugins = prev.grilo-plugins // {
            broken = true;
            replacement = nixpkgs-stable.grilo-plugins;
          };
        })
      ];
    };
  in {
    nixosConfigurations.elpi-desktop = import ./nixos/elpi-desktop (
      args // { nixpkgs = nixpkgs-hyb; }
    );
  };
}
