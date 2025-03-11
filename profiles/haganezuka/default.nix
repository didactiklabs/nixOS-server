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
        defaults
          log global
          option httplog
          option dontlognull
          timeout connect 5000
          timeout client 50000
          timeout server 50000
        frontend kubernetes-api
          bind *:6443
          mode tcp
          option tcplog
          default_backend kubernetes-masters
        backend kubernetes-masters
          balance roundrobin
          option tcplog
          option tcp-check
          default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
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
