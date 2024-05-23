{
  description = "A nixpkgs unstable clone with some broken packages replaced by their nixpkgs-23.11 versions";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs?ref=nixos-23.11";
  };

  outputs = { self, nixpkgs-u, nixpkgs-23-11 }:
  let
    a = {};
  in nixpkgs-u // {
    overlays = (nixpkgs-u.overlays or []) ++ [
      (final: prev: {
        grilo-plugins = prev.grilo-plugins // {
          broken = true;
          replacement = nixpkgs-23-11.grilo-plugins;
        };
      })
    ];
  } ;
}