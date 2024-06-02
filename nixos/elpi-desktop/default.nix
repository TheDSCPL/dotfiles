{ nixpkgs, ... }@flakeOutputArgs:
nixpkgs.lib.nixosSystem {
  modules = [
    # Module knobs
    ({...}: {
      config.hostConsts = {
        hostname       = "elpi-desktop";
        timezone       = "Atlantic/Azores";
        #locale         = "pt_PT.UTF-8";
        locale         = "en_US.utf8";
        keyboardLayout = "pt";
        user = {
          name     = "Elpi";
          username = "elpi";
        };
      };
    })
    ./hardware-configuration.nix
    ./configuration.nix
  ];
  specialArgs = {
    inherit flakeOutputArgs;
  };
}