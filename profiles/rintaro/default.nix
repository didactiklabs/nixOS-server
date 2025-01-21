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
    kernelParams = [
      "consoleblank=0"
      "console=ttyS0,115200n8"
    ];
    loader = {
      systemd-boot.configurationLimit = 0;
      timeout = 0;
      grub = {
        enable = true;
      };
    };
  };
  networking = {
    hostName = lib.mkForce "";
  };
  networking.useDHCP = lib.mkDefault true;
  services.cloud-init.enable = true;
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
    ginx.enable = false;
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
    <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
  ];
}
