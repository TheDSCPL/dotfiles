{
  description = "My desktop configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-23.11";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.elpi-desktop = nixpkgs.lib.nixosSystem {
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
        ./nixos/elpi-desktop
      ];
      specialArgs = {
        inherit inputs;
      };
    };
  };
}
