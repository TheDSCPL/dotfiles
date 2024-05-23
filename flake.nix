{
  description = "My desktop configuration";

  inputs = {
    nixpkgs.url = "path:./flakeModules/nixpkgs-hybrid/";
  };

  outputs = { self, ... }@inputs: {
    nixosConfigurations.elpi-desktop = import ./nixos/elpi-desktop inputs;
  };
}
