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
    "/var/lib/containerd" = {
      device = "/dev/disk/by-label/VARLIBCONTAINERD";
      fsType = "ext4";
    };
    "/var/lib/longhorn" = {
      device = "/dev/disk/by-label/VARLIBLONGHORN";
      fsType = "ext4";
    };
    "/nix" = {
      device = "/dev/disk/by-label/NIX";
      fsType = "ext4";
    };
  };
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  customNixOSModules = {
    kubernetes = {
      enable = true;
      version = {
        kubeadm = "v1.31.4";
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
    (import ../../users {
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
