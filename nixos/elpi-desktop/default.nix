{ nixpkgs, ... }@flakeOutputArgs:
nixpkgs.lib.nixosSystem {
  modules = [
    ./hardware-configuration.nix
    ./configuration.nix
  ];
  specialArgs = {
    inherit flakeOutputArgs;
  };
}