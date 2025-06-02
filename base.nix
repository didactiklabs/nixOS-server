{
  config,
  hostname,
  lib,
  ...
}:
let
  sources = import ./npins;
  pkgs = import sources.nixpkgs {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = true;
    };
  };

  hostProfile = import ./profiles/${hostname} {
    inherit
      lib
      config
      pkgs
      hostname
      sources
      ;
  };
  ginx = import "${sources.nixbook}//customPkgs/ginx.nix" { inherit pkgs; };
  osupdate = pkgs.writeShellScriptBin "osupdate" ''
    set -euo pipefail
    echo last applied revisions: $(${pkgs.jq}/bin/jq .rev /etc/nixos/version)
    echo applying revision: "$(${pkgs.git}/bin/git ls-remote https://github.com/didactiklabs/nixOs-server HEAD | awk '{print $1}')"...

    echo Running ginx...
    ${ginx}/bin/ginx --source https://github.com/didactiklabs/nixOs-server -b main --now -- ${pkgs.colmena}/bin/colmena apply-local --sudo
  '';
in
{
  environment = {
    systemPackages = [
      osupdate
      pkgs.kitty
      pkgs.killall
      pkgs.git
      pkgs.kubectl
      pkgs.cilium-cli
      pkgs.coreutils
      pkgs.procps
      pkgs.gawk
      pkgs.file
      pkgs.gnugrep
      pkgs.unixtools.top
      pkgs.unixtools.ping
      pkgs.unixtools.arp
      pkgs.gnused
      pkgs.mount
      pkgs.umount
      pkgs.multipath-tools
      pkgs.openiscsi
      pkgs.lsscsi
      pkgs.curl
      pkgs.iproute2
      pkgs.iptables
      pkgs.socat
      pkgs.ethtool
      pkgs.cri-tools
      pkgs.conntrack-tools
      # debug tools
      pkgs.unixtools.netstat
      pkgs.netcat-gnu
      pkgs.dig
      pkgs.tcpdump
    ];
    variables = {
      EDITOR = "vim";
      NIXPKGS_ALLOW_UNFREE = 1;
    };
  };
  nixpkgs.config.allowUnfree = true;
  imports = [
    ./tools.nix
    (import "${sources.nixbook}//nixosModules/caCertificates.nix")
    ./nixosModules/ginx.nix
    ./nixosModules/sysctl.nix
    ./nixosModules/getRevision.nix
    ./nixosModules/forgejo.nix
    (import ./nixosModules/kubernetes {
      inherit
        pkgs
        config
        lib
        ;
    })
    (import ./nixosModules/networkManager.nix { inherit lib config pkgs; })
    (import "${sources.home-manager}/nixos")
    hostProfile
  ];
  # Bootloader.
  hardware = {
    enableAllFirmware = true;
  };
  boot = {
    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
    ];
    loader.grub.enable = lib.mkDefault true;
    kernelPackages = pkgs.linuxPackages_latest;
    tmp.cleanOnBoot = true;
  };
  networking = {
    hostName = "${hostname}"; # Define your hostname.
    firewall.enable = false;
  };
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
  nix = {
    package = pkgs.lix;
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
      dates = [ "03:45" ];
    };
    settings = {
      nix-path = [
        "nixpkgs=${sources.nixpkgs}"
        "home-manager=${sources.home-manager}"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
      substituters = [ "https://s3.didactiklabs.io/nix-cache" ];
      trusted-public-keys = [ "didactiklabs-nixcache:PxLKN0+ZkP07M8g8/B6xbP6A4MYpqQg6LH7V3muiy/0=" ];
    };
    extraOptions = ''
      # Ensure we can still build when missing-server is not accessible
      fallback = true
      min-free = ${toString (10240 * 1024 * 1024)}
      max-free = ${toString (10240 * 1024 * 1024)}
    '';
  };
  # SSH Agent
  programs = {
    ssh.startAgent = true;
    gnupg.agent.enableSSHSupport = false;
  };
  services = {
    resolved.enable = true;
    # Disable the OpenSSH daemon.
    openssh = {
      enable = true;
    };
  };
  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "24.05";
  # Containerd
}
