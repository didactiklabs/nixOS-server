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
  services = {
    openssh.ports = [ 2077 ];
    github-runners = {
      runner1 = {
        enable = true;
        name = "runner1";
        tokenFile = "/home/nixos/token1";
        url = "https://github.com/didactiklabs";
      };
      runner2 = {
        enable = true;
        name = "runner2";
        tokenFile = "/home/nixos/token2";
        url = "https://github.com/didactiklabs";
      };
      runner3 = {
        enable = true;
        name = "runner3";
        tokenFile = "/home/nixos/token3";
        url = "https://github.com/didactiklabs";
      };
      runner4 = {
        enable = true;
        name = "runner4";
        tokenFile = "/home/nixos/token4";
        url = "https://github.com/didactiklabs";
      };
      runner5 = {
        enable = true;
        name = "runner5";
        tokenFile = "/home/nixos/token5";
        url = "https://github.com/didactiklabs";
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
  networking.useDHCP = lib.mkDefault true;
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
