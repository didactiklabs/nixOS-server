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
    k3s = {
      enable = false;
      podCIDR = "10.206.0.0/16";
    };
  };
  imports = [
    (mkUser {
      username = "khoa";
      userImports = [
        ./khoa
      ];
    })
    (mkUser {username = "aamoyel";})
    (mkUser {username = "nixos";})
  ];
}
