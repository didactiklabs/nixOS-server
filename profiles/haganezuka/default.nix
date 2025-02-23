{
  config,
  pkgs,
  lib,
  sources,
  ...
}:
let
  overrides = {
    customHomeManagerModules = { };
    imports = [ ./fastfetchConfig.nix ];
  };
in
{
  services = {
    haproxy = {
      enable = true;
      config = ''
        global
          log /dev/log local0
          log /dev/log local1 notice
          chroot /var/lib/haproxy
          stats socket /run/haproxy/admin.sock mode 660 level admin
          stats timeout 30s
          user haproxy
          group haproxy
          daemon
          tune.ssl.default-dh-param 2048
        defaults
          log global
          option redispatch
          option httplog
          option dontlognull
          timeout connect 5s
          timeout client 50s
          timeout server 50s
        frontend kubernetes-api
          bind *:6443
          default_backend kubernetes-masters
        backend kubernetes-masters
          balance roundrobin
          option httpchk GET /healthz
          default-server inter 10s fall 3 rise 2
          server master1 10.250.0.8:6443 check
          server master2 10.250.0.9:6443 check
          server master3 10.250.0.10:6443 check
      '';
    };
    qemuGuest = {
      enable = lib.mkForce true;
    };
    resolved = {
      enable = true;
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
        device = "/dev/disko";
      };
    };
  };
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/ROOT";
      fsType = "ext4";
    };
    "/tmp" = {
      device = "/dev/disk/by-label/TMP";
      fsType = "ext4";
    };
    "/var" = {
      device = "/dev/disk/by-label/VAR";
      fsType = "ext4";
    };
    "/nix" = {
      device = "/dev/disk/by-label/NIX";
      fsType = "ext4";
    };
  };
  systemd = {
    network = {
      enable = true;
      networks = {
        "10-ens18" = {
          matchConfig = {
            Name = "en*";
          };
          linkConfig.RequiredForOnline = "routable";
          networkConfig = {
            DHCP = "yes";
          };
          dhcpV4Config = {
            UseDNS = true;
            UseDomains = true;
            UseHostname = true;
          };
        };
      };
    };
  };
  networking = {
    useDHCP = false;
    dhcpcd.enable = false;
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  customNixOSModules = {
    forgejo = {
      enable = false;
      domain = "git.bealv.lan";
    };
    caCertificates = {
      didactiklabs.enable = true;
      bealv.enable = true;
    };
    ginx.enable = true;
  };
  imports = [
    (import ../../users/bealv {
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
