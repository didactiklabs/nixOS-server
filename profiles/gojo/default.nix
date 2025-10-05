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
    initrd = {
      availableKernelModules = [
        "ehci_pci"
        "ata_piix"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [
        "dm_snapshot"
        "dm-thin-pool"
      ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    loader.grub.devices = [ "/dev/sda" ];
  };
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/0480434c-adf5-4119-ae4d-8b2825aa64e3";
    fsType = "ext4";
  };
  swapDevices = [ ];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  customNixOSModules = {
    networkManager.enable = true;
    kubernetes = {
      enable = true;
      version = {
        kubeadm = "v1.34.1";
        kubelet = "v1.34.0";
      };
    };
    caCertificates = {
      didactiklabs.enable = true;
    };
    ginx.enable = true;
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
