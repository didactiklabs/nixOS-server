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
  ];
  url = "https://github.com/didactiklabs";
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
        user = "nixos";
        tokenFile = "/home/nixos/token1";
        inherit extraPackages url;
        workDir = "/home/nixos/runner1";
      };
      runner2 = {
        enable = true;
        name = "runner2";
        user = "nixos";
        tokenFile = "/home/nixos/token2";
        inherit extraPackages url;
        workDir = "/home/nixos/runner2";
      };
      runner3 = {
        enable = true;
        name = "runner3";
        user = "nixos";
        tokenFile = "/home/nixos/token3";
        inherit extraPackages url;
        workDir = "/home/nixos/runner3";
      };
      runner4 = {
        enable = true;
        name = "runner4";
        user = "nixos";
        tokenFile = "/home/nixos/token4";
        inherit extraPackages url;
        workDir = "/home/nixos/runner4";
      };
      runner5 = {
        enable = true;
        name = "runner5";
        user = "nixos";
        tokenFile = "/home/nixos/token5";
        inherit extraPackages url;
        workDir = "/home/nixos/runner5";
      };
    };
  };
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/ROOT";
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
