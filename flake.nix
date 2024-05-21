{
  description = "My desktop configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, ... }@inputs: {
    nixosConfigurations.elpi-desktop = import ./nixos/elpi-desktop inputs;
  };
}
