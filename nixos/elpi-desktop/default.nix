{ nixpkgs, ... }@inputs: nixpkgs.lib.nixosSystem {
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
    ./overlays/gnome-mutter-triple-buffering
    ./module
  ];
  specialArgs = {
    flakeInputs = inputs;
  };
}