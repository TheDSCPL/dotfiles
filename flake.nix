{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.elpi-desktop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({...}: {
          config.hostConsts = {
            hostname = "elpi-desktop";
            user = {
              username = "elpi";
              name = "Elpi";
            };
            timezone = "Atlantic/Azores";
          };
        })
        ./nixos/elpi-desktop
      ];
      specialArgs = {
        inherit inputs;
      };
    };
  };
}
