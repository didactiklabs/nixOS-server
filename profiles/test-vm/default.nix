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
  services.qemuGuest.enable = true;
  virtualisation.forwardPorts = [
    {
      from = "host";
      host.port = 2000;
      guest.port = 22;
    }
  ];
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
