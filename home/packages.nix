{ inputs, pkgs, config, ... }:

{
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    inputs.todo.packages."${system}".todo
    maim 
    # cli tools
    exa ffmpeg unzip xclip fetch
    libnotify gnupg update-nix-fetchgit yt-dlp ytmdl
    ripgrep rsync imagemagick
    scrot bottom newsboat unrar
    tealdeer killall onefetch
    du-dust 
    # gui apps
    obs-studio mpv sxiv tdesktop
    transmission-gtk pavucontrol pcmanfm
    # unfree apps (sorry daddy stallman)
    minecraft steam
    # dev tools
    python3 git jdk dconf gcc rustc rustfmt cargo
  ];
}