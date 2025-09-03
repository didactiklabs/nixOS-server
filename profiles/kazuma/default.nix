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
  systemd.services = {
    qemu-guest-agent = {
      enable = lib.mkForce true;
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
  services = {
    resolved = {
      enable = true;
    };
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  customNixOSModules = {
    kubernetes = {
      enable = true;
      version = {
        kubeadm = "v1.33.4";
        kubelet = "v1.31.4";
      };
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
