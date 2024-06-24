{
  config,
  pkgs,
  lib,
  nixbook,
  home-manager,
  overrides,
  ...
}: let
  cfg = config.customHomeManagerModules;
  userConfig = import ../nixosModules/userConfig.nix {
    inherit lib pkgs nixbook home-manager;
    overrides = overrides;
  };
  mkUser = userConfig.mkUser;
in {
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
