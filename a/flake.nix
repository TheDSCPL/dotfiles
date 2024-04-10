{
  description = "A very basic flake";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland/";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixpkgs.overlays = [inputs.nixpkgs-wayland.overlay];
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";
    hostName = "elpi-desktop";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    lib = nixpkgs.lib;
  in {
    nixosConfigurations.${hostName} = lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          # Pass the home-manager configuration here, within the NixOS module context.
          home-manager.users.elpi = {
            home.stateVersion = "23.11";
            # Example configuration for Home Manager
            programs.zsh.enable = true;
            home.sessionVariables = {
              EDITOR = "vim";
            };
          };
        }
      ];
    };
  };
}
