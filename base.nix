{
  config,
  hostname,
  lib,
  ...
}:
let
  sources = import ./npins;
  ginx = import "${sources.nixbook}//customPkgs/ginx.nix" { inherit pkgs; };
  pkgs = import sources.nixpkgs { };

  hostProfile = import ./profiles/${hostname} {
    inherit
      lib
      config
      pkgs
      hostname
      sources
      ;
  };
  jsonFile = builtins.toJSON {
    url =
      if builtins.pathExists ./.git then
        builtins.readFile (
          pkgs.runCommand "getRemoteUrl" { buildInputs = [ pkgs.git ]; } ''
            grep -oP '(?<=url = ).*' ${./.git/config} | tr -d '\n' > $out;
          ''
        )
      else
        {
          url = "unknown";
        };
    branch =
      if builtins.pathExists ./.git then
        builtins.readFile (
          pkgs.runCommand "getBranch" { buildInputs = [ pkgs.git ]; } ''
            cat ${./.git/HEAD} | awk '{print $2}' | tr -d '\n' > $out;
          ''
        )
      else
        { branch = "unknown"; };
    rev =
      if builtins.pathExists ./.git then
        let
          gitRepo = builtins.fetchGit ./.; # Fetch the Git repository
        in
        gitRepo.rev # Access the 'rev' attribute directly
      else
        {
          rev = "unknown"; # Default value when there's no .git directory
        }
        .rev;
    lastModifiedDate =
      if builtins.pathExists ./.git then
        let
          gitRepo = builtins.fetchGit ./.; # Fetch the Git repository
        in
        gitRepo.lastModifiedDate
      else
        {
          lastModifiedDate = "unknown";
        }
        .lastModifiedDate;
  };
in
{
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];
  environment = {
    etc = {
      "nixos/version".source = pkgs.writeText "projectGit.json" jsonFile;
    };
    systemPackages = [
      ginx
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
    };
  };

  imports = [
    ./tools.nix
    (import "${sources.nixbook}//nixosModules/caCertificates.nix")
    ./nixosModules/ginx.nix
    ./nixosModules/sysctl.nix
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
      dates = "weekly";
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
