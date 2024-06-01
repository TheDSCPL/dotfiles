{
  description = "My desktop configuration";

  inputs = {
    #nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    #nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
  };

  outputs = { ... }@args: {
    nixosConfigurations.elpi-desktop = import ./nixos/elpi-desktop args;
  };
}
