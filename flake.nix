{
  description = "My desktop configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs?ref=nixos-23.11";
  };

  outputs = args: {
    nixosConfigurations.elpi-desktop = import ./nixos/elpi-desktop args;
  };
}
