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
in
{
  imports = [
    ./tools.nix
    (import "${sources.nixbook}//nixosModules/caCertificates.nix")
    ./nixosModules/k3s
    ./nixosModules/ginx.nix
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
    # values from kubernetes official image-builder
    "net.ipv4.tcp_syncookies" = false;
    "vm.swappiness" = 60;
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.bridge.bridge-nf-call-ip6tables" = 1;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.tcp_congestion_control" = "bbr";
    "vm.overcommit_memory" = lib.mkDefault "1";
    "kernel.panic" = 10;
    "fs.inotify.max_user_instances" = 8192;
    "fs.inotify.max_user_watches" = 524288;
  };
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
    networkmanager.enable = true;
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
  };
  # SSH Agent
  programs = {
    ssh.startAgent = true;
    gnupg.agent.enableSSHSupport = false;
  };
  environment.systemPackages = [
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
  environment.variables = {
    EDITOR = "vim";
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
  virtualisation.containerd = {
    enable = true;
    settings = {
      version = 2;
      plugins = {
        "io.containerd.grpc.v1.cri" = {
          cni.bin_dir = "/opt/cni/bin";
        };
        "io.containerd.grpc.v1.cri" = {
          device_ownership_from_security_context = true;
        };
        "io.containerd.grpc.v1.cri".containerd.runtimes.runc = {
          runtime_type = "io.containerd.runc.v2";
        };
        "io.containerd.grpc.v1.cri".containerd.runtimes.runc.options = {
          SystemdCgroup = true;
        };
      };
    };
  };
}
