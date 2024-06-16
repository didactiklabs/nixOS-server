{
  config,
  pkgs,
  username,
  hostname ? "nixos",
  lib,
  nixos_gitrepo ? "https://github.com/didactiklabs/nixOS-server.git",
  ...
}: let
  nixOS_version = "24.05";
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-${nixOS_version}.tar.gz";
  userProfile =
    if builtins.pathExists ./profiles/${username}-${hostname}
    then import ./profiles/${username}-${hostname} {inherit lib config pkgs username hostname;}
    else import ./profiles/dummy.nix;
in {
  imports = [
    ./hardware-configuration.nix
    ./tools.nix
    ./nixosModules/k3s
    (import ./nixosModules/scripts.nix {inherit pkgs username hostname nixos_gitrepo;})
    (import ./nixosModules/networkManager.nix {inherit lib config pkgs username;})
    (import "${home-manager}/nixos")

    ({
      config,
      pkgs,
      ...
    }:
      import
      ./home-manager.nix {inherit lib config pkgs username home-manager nixOS_version;})
    userProfile
  ];
  boot.kernel.sysctl = {
    # ANSSI R9
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.pid_max" = 65536;
    "kernel.perf_cpu_time_max_percent" = 1;
    "kernel.perf_event_max_sample_rate" = 1;
    "kernel.perf_event_paranoid" = 2;
    "kernel.unprivileged_bpf_disabled" = 1;
    "kernel.panic_on_oops" = 1;
    # ANSSI R12
    "net.core.bpf_jit_harden" = 2;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.shared_media" = 0;
    "net.ipv4.conf.default.shared_media" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.all.arp_filter" = 1;
    "net.ipv4.conf.all.arp_ignore" = 2;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.tcp_rfc1337" = 1;
    # ANSSI R14
    "fs.suid_dumpable" = 0;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    # Disable IPV6
    "net.ipv6.conf.all.disable_ipv6" = 1;
  };
  # Bootloader.
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
  ];
  boot.loader.grub.enable = true;
  boot.loader.grub.devices = ["/dev/sda"];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  networking.hostName = "${hostname}"; # Define your hostname.
  #networking.nameservers = ["2a01:4f8:c2c:123f::1"];
  # Enable networking
  networking.networkmanager.enable = true;
  # Set your time zone.
  time.timeZone = "Europe/Paris";
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
    LC_ALL = "C.UTF-8";
  };
  # Configure console keymap
  console.keyMap = "fr";
  # Define a user account. Don't forget to set a password with `passwd`.
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = ["wheel"];
  };
  # Allow unfree packages
  nixpkgs.config.allowUnfreePredicate = pkg: true;
  nixpkgs.config.allowUnfree = true;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  # SSH Agent
  programs.gnupg.agent.enableSSHSupport = false;
  programs.ssh.startAgent = true;
  # New versions of OpenSSH seem to default to disallowing all `ssh-add -s`
  # calls when no whitelist is provided, so this becomes necessary.
  # programs.ssh.agentPKCS11Whitelist = "${pkgs.opensc}/lib/opensc-pkcs11.so";
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = [
  ];
  environment.variables = {
    EDITOR = "vim";
  };
  services.resolved.enable = true;
  # Disable the OpenSSH daemon.
  services.openssh = {
    enable = true;
  };
  networking.firewall.enable = false;
  system.stateVersion = "${nixOS_version}";
}
