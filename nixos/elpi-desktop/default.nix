{ nixpkgs, ... }@args:
let
  system = "x86_64-linux";
  # nixpkgs-unstable = args.nixpkgs-unstable;
  # unstable = import nixpkgs-unstable { inherit system; config = { allowUnfree = true; }; };
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
    #./nixpkgs-config.nix
    /* ({pkgs, lib, config, ...}:
    let
      nvidia_x11 = unstable.linuxPackages.nvidiaPackages.production;
      # nvidia-open = unstable.nvidia-open.override {
      #   inherit (pkgs) stdenv lib fetchFromGitHub kernel;
      #   inherit nvidia_x11;
      # };
    in {
      hardware.nvidia.package = nvidia_x11;
    }) */
    ./module.nix
  ];
  specialArgs = {
    inherit args system;
  };
}