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
  userConfig = import ../../nixosModules/userConfig.nix {
    inherit lib pkgs nixbook home-manager;
    overrides = overrides;
  };
  mkUser = userConfig.mkUser;
in {
  customNixOSModules = {
    kubernetes = {
      enable = true;
    };
  };
  imports = [
    (mkUser {username = "nixos";})
  ];
}
