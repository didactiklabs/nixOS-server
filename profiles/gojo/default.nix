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
  customNixOSModules = {
    k3s = {
      enable = false;
      podCIDR = "10.206.0.0/16";
    };
  };
  imports = [
    (import ../../users {inherit config pkgs lib nixbook home-manager overrides;})
  ];
}
