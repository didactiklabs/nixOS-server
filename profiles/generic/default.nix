{
  config,
  pkgs,
  lib,
  nixbook,
  home-manager,
  ...
}: let
  overrides = {
    customHomeManagerModules = {
    };
    imports = [
      ./fastfetchConfig.nix
    ];
  };
in {
  networking.hostName = lib.mkForce "";
  customNixOSModules = {
    kubernetes = {
      enable = true;
    };
    caCertificates = {
      didactiklabs.enable = true;
    };
  };
  imports = [
    (import ../../users {inherit config pkgs lib nixbook home-manager overrides;})
  ];
}
