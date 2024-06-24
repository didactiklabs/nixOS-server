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
    kubernetes = {
      enable = true;
    };
  };
  imports = [
    (import ../../users {inherit config pkgs lib nixbook home-manager overrides;})
  ];
}
