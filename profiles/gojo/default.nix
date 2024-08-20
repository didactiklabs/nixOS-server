{ config, pkgs, lib, sources, ... }:
let
  overrides = {
    customHomeManagerModules = { };
    imports = [ ./fastfetchConfig.nix ];
  };
in {
  boot.initrd.availableKernelModules =
    [ "ehci_pci" "ata_piix" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm_snapshot" "dm-thin-pool" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.loader.grub.devices = [ "/dev/sda" ];
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/0480434c-adf5-4119-ae4d-8b2825aa64e3";
    fsType = "ext4";
  };
  swapDevices = [ ];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  customNixOSModules = {
    kubernetes = { enable = true; };
    caCertificates = { didactiklabs.enable = true; };
  };
  imports =
    [ (import ../../users { inherit config pkgs lib sources overrides; }) ];
}
