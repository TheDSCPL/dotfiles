# Editted version of:
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/hardened.nix
# Also has appended some configurations from a blog post. Link in a prefixing comment.
# Author: TheDSCPL

# A profile with most (vanilla) hardening options enabled by default,
# potentially at the cost of stability, features and performance.
#
# This profile enables options that are known to affect system
# stability. If you experience any stability issues when using the
# profile, try disabling it. If you report an issue and use this
# profile, always mention that you do.

{ config, lib, pkgs, ... }:

with lib;

{
  # boot.kernelPackages = mkDefault pkgs.linuxPackages_latest_hardened;
  ## Not using the hardened kernel to avoid runtime issues for now
  boot.kernelPackages = mkDefault pkgs.linuxPackages_latest;

  nix.settings.allowed-users = mkDefault [ "@wheel" "@builders" ];

  environment.memoryAllocator.provider = mkDefault "scudo";
  environment.variables.SCUDO_OPTIONS = mkDefault "ZeroContents=1";

  security.lockKernelModules = mkDefault true;

  ## Disabling this to allow NixOS kernel to update without rebooting
  #security.protectKernelImage = mkDefault true;
  security.protectKernelImage = mkDefault false;

  ## Disabling this to avoid the performance penalty
  #security.allowSimultaneousMultithreading = mkDefault false;
  security.allowSimultaneousMultithreading = mkDefault true;

  ## Meltdown is already prevented by hardware fixes in new processors,
  ## and, according to the docs, PTI is enabled on processors that
  ## don't have those hardware patches
  #security.forcePageTableIsolation = mkDefault true;
  security.forcePageTableIsolation = mkDefault false;

  # This is required by podman to run containers in rootless mode.
  security.unprivilegedUsernsClone = mkDefault config.virtualisation.containers.enable;

  security.virtualisation.flushL1DataCache = mkDefault "always";

  ## TODO: Disabled until I have time to look into the available
  ##       profiles and configurations.
  #security.apparmor.enable = mkDefault true;
  #security.apparmor.killUnconfinedConfinables = mkDefault true;

  boot.kernelParams = [
    # Don't merge slabs
    "slab_nomerge"

    # Overwrite free'd pages
    "page_poison=1"

    # Enable page allocator randomization
    "page_alloc.shuffle=1"

    # Disable debugfs
    ## Keep debugfs on. The security implication is not relevant to me.
    ## https://patchwork.kernel.org/project/linux-security-module/patch/152346403637.4030.15247096217928429102.stgit@warthog.procyon.org.uk/#21721329
    #"debugfs=off"
  ];

  boot.blacklistedKernelModules = [
    # Obscure network protocols
    "ax25"
    "netrom"
    "rose"

    # Old or rare or insufficiently audited filesystems
    "adfs"
    "affs"
    "bfs"
    "befs"
    "cramfs"
    "efs"
    "erofs"
    "exofs"
    "freevxfs"
    "f2fs"
    "hfs"
    "hpfs"
    "jfs"
    "minix"
    "nilfs2"
    "ntfs"
    "omfs"
    "qnx4"
    "qnx6"
    "sysv"
    "ufs"
  ];

  # Hide kptrs even for processes with CAP_SYSLOG
  boot.kernel.sysctl."kernel.kptr_restrict" = mkOverride 500 2;

  # Disable bpf() JIT (to eliminate spray attacks)
  boot.kernel.sysctl."net.core.bpf_jit_enable" = mkDefault false;

  # Disable ftrace debugging
  boot.kernel.sysctl."kernel.ftrace_enabled" = mkDefault false;

  # Enable strict reverse path filtering (that is, do not attempt to route
  # packets that "obviously" do not belong to the iface's network; dropped
  # packets are logged as martians).
  boot.kernel.sysctl."net.ipv4.conf.all.log_martians" = mkDefault true;
  boot.kernel.sysctl."net.ipv4.conf.all.rp_filter" = mkDefault "1";
  boot.kernel.sysctl."net.ipv4.conf.default.log_martians" = mkDefault true;
  boot.kernel.sysctl."net.ipv4.conf.default.rp_filter" = mkDefault "1";

  # Ignore broadcast ICMP (mitigate SMURF)
  boot.kernel.sysctl."net.ipv4.icmp_echo_ignore_broadcasts" = mkDefault true;

  # Ignore incoming ICMP redirects (note: default is needed to ensure that the
  # setting is applied to interfaces added after the sysctls are set)
  boot.kernel.sysctl."net.ipv4.conf.all.accept_redirects" = mkDefault false;
  boot.kernel.sysctl."net.ipv4.conf.all.secure_redirects" = mkDefault false;
  boot.kernel.sysctl."net.ipv4.conf.default.accept_redirects" = mkDefault false;
  boot.kernel.sysctl."net.ipv4.conf.default.secure_redirects" = mkDefault false;
  boot.kernel.sysctl."net.ipv6.conf.all.accept_redirects" = mkDefault false;
  boot.kernel.sysctl."net.ipv6.conf.default.accept_redirects" = mkDefault false;

  # Ignore outgoing ICMP redirects (this is ipv4 only)
  boot.kernel.sysctl."net.ipv4.conf.all.send_redirects" = mkDefault false;
  boot.kernel.sysctl."net.ipv4.conf.default.send_redirects" = mkDefault false;

  ########################################################################
  ## From: https://dataswamp.org/~solene/2022-01-13-nixos-hardened.html ##
  ########################################################################

  # enable firewall and block all ports
  networking.nftables.enable = true;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [];
  networking.firewall.allowedUDPPorts = [];

  # disable coredump that could be exploited later
  # and also slow down the system when something crash
  systemd.coredump.enable = false;

  # required to run chromium
  security.chromiumSuidSandbox.enable = true;

  # enable firejail
  programs.firejail.enable = true;

  # create system-wide executables firefox and chromium
  # that will wrap the real binaries so everything
  # work out of the box.
  programs.firejail.wrappedBinaries = {
      firefox = {
          executable = "${pkgs.lib.getBin pkgs.firefox}/bin/firefox";
          profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
      };
      chromium = {
          executable = "${pkgs.lib.getBin pkgs.chromium}/bin/chromium";
          profile = "${pkgs.firejail}/etc/firejail/chromium.profile";
      };
  };

  # enable antivirus clamav and
  # keep the signatures' database updated
  services.clamav.daemon.enable = true;
  services.clamav.updater.enable = true;
}
