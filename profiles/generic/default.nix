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
  networking.hostName = lib.mkForce "";
  services.qemuGuest.enable = true;
  customNixOSModules = {
    kubernetes = {
      enable = true;
    };
    caCertificates = {
      didactiklabs.enable = true;
    };
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
