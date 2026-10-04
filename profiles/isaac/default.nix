{
  config,
  pkgs,
  lib,
  sources,
  ...
}:
let
  # GitHub rejects runners a few releases behind ("deprecated and cannot receive
  # messages"), faster than stable nixpkgs follows: take the whole package
  # (source + matching NuGet deps) from nixos-unstable.
  inherit
    (import sources.nixpkgs-unstable {
      inherit (pkgs.stdenv.hostPlatform) system;
    })
    github-runner
    ;
  # node24 only: the module's default (node20 + node24) pulls in the insecure nodejs_20
  nodeRuntimes = [ "node24" ];

  overrides = {
    customHomeManagerModules = { };
    imports = [ ./fastfetchConfig.nix ];
  };
  extraPackages = with pkgs; [
    xz
    google-cloud-sdk
    skopeo
    awscli2
    jq
    busybox
    npins
    colmena
    nixfmt-rfc-style
    updatecli
    git-lfs
    sudo
  ];
  url = "https://github.com/didactiklabs";
in
{
  environment = {
    etc = {
      "nixos/hardware-configuration.nix".text = ''
          {
            fileSystems."/" = {
              device = "/dev/disk/by-uuid/dummy";
              fsType = "ext4";
        options = [ "noatime" ];
            };
          }
      '';
    };
  };

  boot = {
    initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "virtio_pci"
      "virtio_scsi"
      "sd_mod"
      "sr_mod"
    ];
    initrd.kernelModules = [
      "dm_snapshot"
      "dm-thin-pool"
    ];
    loader = {
      systemd-boot.enable = false;
      grub = {
        enable = true;
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
      };
    };
  };
  services = {
    openssh.ports = [ 2077 ];
    # RPCU netbird mesh, so the RPCU runners (6-8) reach OpenStack (*.rpcu.vpn)
    # to publish hephaestus Glance images. Runner jobs can't run netbird
    # themselves (NoNewPrivileges, no /dev/net/tun). Restrict this peer's group
    # with a netbird policy: every job on isaac, runners 1-5 included, gets it.
    # One-time: put a setup key in /root/netbird-rpcu-setup-key (root only).
    netbird = {
      useRoutingFeatures = "client";
      clients.rpcu = {
        port = 51820;
        environment.NB_MANAGEMENT_URL = "https://netbird.rpcu.io";
        login = {
          enable = true;
          setupKeyFile = "/root/netbird-rpcu-setup-key";
        };
      };
    };
    github-runners = {
      runner1 = {
        enable = true;
        name = "runner1";
        user = "nixos";
        tokenFile = "/home/nixos/token1";
        inherit extraPackages url;
        package = github-runner;
        inherit nodeRuntimes;
        serviceOverrides = {
          Restart = lib.mkForce "always";
          # OOMPolicy = "continue";
        };
      };
      runner2 = {
        enable = true;
        name = "runner2";
        user = "nixos";
        tokenFile = "/home/nixos/token2";
        inherit extraPackages url;
        package = github-runner;
        inherit nodeRuntimes;
        serviceOverrides = {
          Restart = lib.mkForce "always";
          # OOMPolicy = "continue";
        };
      };
      runner3 = {
        enable = true;
        name = "runner3";
        user = "nixos";
        tokenFile = "/home/nixos/token3";
        inherit extraPackages url;
        package = github-runner;
        inherit nodeRuntimes;
        serviceOverrides = {
          Restart = lib.mkForce "always";
          # OOMPolicy = "continue";
        };
      };
      runner4 = {
        enable = true;
        name = "runner4";
        user = "nixos";
        tokenFile = "/home/nixos/token4";
        inherit extraPackages url;
        package = github-runner;
        inherit nodeRuntimes;
        serviceOverrides = {
          Restart = lib.mkForce "always";
          # OOMPolicy = "continue";
        };
      };
      runner5 = {
        enable = true;
        name = "runner5";
        user = "nixos";
        tokenFile = "/home/nixos/token5";
        inherit extraPackages url;
        package = github-runner;
        inherit nodeRuntimes;
        serviceOverrides = {
          Restart = lib.mkForce "always";
          # OOMPolicy = "continue";
        };
      };
      runner6 = {
        enable = true;
        name = "runner6";
        user = "nixos";
        tokenFile = "/home/nixos/token6";
        url = "https://github.com/RPCU";
        inherit extraPackages;
        package = github-runner;
        inherit nodeRuntimes;
        serviceOverrides = {
          Restart = lib.mkForce "always";
          # OOMPolicy = "continue";
        };
      };
      runner7 = {
        enable = true;
        name = "runner7";
        user = "nixos";
        tokenFile = "/home/nixos/token7";
        url = "https://github.com/RPCU";
        inherit extraPackages;
        package = github-runner;
        inherit nodeRuntimes;
        serviceOverrides = {
          Restart = lib.mkForce "always";
          # OOMPolicy = "continue";
        };
      };
      runner8 = {
        enable = true;
        name = "runner8";
        user = "nixos";
        tokenFile = "/home/nixos/token8";
        url = "https://github.com/RPCU";
        inherit extraPackages;
        package = github-runner;
        inherit nodeRuntimes;
        serviceOverrides = {
          Restart = lib.mkForce "always";
          # OOMPolicy = "continue";
        };
      };
    };
  };
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/ROOT";
      fsType = "ext4";
      options = [
        "noatime"
      ];
    };
    "/var" = {
      device = "/dev/disk/by-label/VAR";
      fsType = "ext4";
      options = [
        "noatime"
      ];
    };
    "/tmp" = {
      device = "/dev/disk/by-label/TMP";
      fsType = "ext4";
      options = [
        "noatime"
      ];
    };
    "/nix" = {
      device = "/dev/disk/by-label/NIX";
      fsType = "ext4";
      options = [
        "noatime"
      ];
    };
  };
  networking.useDHCP = lib.mkDefault true;
  # RPCU OpenStack endpoints: every *.rpcu.vpn name is the kgateway LB
  # (argus infrastructure/kgateway/gateway.yaml), reached over netbird-rpcu
  # (10.0.0.0/24 route via quinn). No netbird nameserver serves rpcu.vpn.
  networking.hosts."10.0.0.240" = [
    "keystone.rpcu.vpn"
    "glance.rpcu.vpn"
  ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  customNixOSModules = {
    kubernetes = {
      enable = false;
    };
    caCertificates = {
      didactiklabs.enable = true;
      bealv.enable = true;
    };
    ginx.enable = false;
  };

  imports = [
    (import ../../users/didactiklabs {
      inherit
        config
        pkgs
        lib
        sources
        overrides
        ;
    })
  ];
}
