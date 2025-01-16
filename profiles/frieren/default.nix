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
  environment = {
    etc = {
      "kubernetes/kubelet/config.d/00-config.yaml".text = ''
        kind: KubeletConfiguration
        apiVersion: kubelet.config.k8s.io/v1beta1
        maxPods: 200
      '';
    };
  };
  boot = {
    initrd.availableKernelModules = [
      "ehci_pci"
      "ata_piix"
      "megaraid_sas"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];
    initrd.kernelModules = [
      "dm_snapshot"
      "dm-thin-pool"
    ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    loader.grub.devices = [ "/dev/sdc" ];
  };
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/a072429e-a0ab-4c57-961f-0abc176d56b1";
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
        kubeadm = "v1.32.1";
        kubelet = "v1.32.1";
      };
    };
    caCertificates = {
      didactiklabs.enable = true;
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
