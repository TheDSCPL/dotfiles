{ nixpkgs, ... }@args:
let
  system = "x86_64-linux";
in nixpkgs.lib.nixosSystem {
  inherit system;
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
    ./overlays.nix
    ./module.nix
  ];
  specialArgs = {
    inherit args;
  };
}