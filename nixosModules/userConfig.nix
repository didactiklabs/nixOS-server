{
  pkgs,
  sources,
  lib,
  overrides ? { },
}:
let
  defaultConfig = {
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    customHomeManagerModules = {
      gitConfig.enable = true;
      sshConfig.enable = true;
      fastfetchConfig.enable = true;
    };
    imports = [ ];
  };

  mergedConfig = lib.recursiveUpdate defaultConfig overrides;

  mkUser =
    {
      username,
      userImports ? [ ],
      authorizedKeys ? [ ],
    }:
    {
      programs.zsh.enable = true;
      users.users."${username}" = {
        shell = pkgs.zsh;
        extraGroups = mergedConfig.extraGroups;
        isNormalUser = true;
        description = "${username}";
        openssh.authorizedKeys.keys = authorizedKeys;
      };
      home-manager = {
        useUserPackages = true;
        useGlobalPkgs = true;
        backupFileExtension = "rebuild";
        users.${username} = {
          config = {
            customHomeManagerModules = mergedConfig.customHomeManagerModules;
            programs.zsh.initExtra = ''
              fastfetch
            '';
            home = {
              stateVersion = "24.05";
              username = "${username}";
              homeDirectory = "/home/${username}";
              sessionVariables = {
                NIXPKGS_ALLOW_UNFREE = 1;
              };
            };
            programs.home-manager.enable = true;
          };
          imports = lib.concatLists [
            mergedConfig.imports
            [
              (import "${sources.nixbook}//homeManagerModules/zshConfig.nix")
              (import "${sources.nixbook}//homeManagerModules/gitConfig.nix")
              (import "${sources.nixbook}//homeManagerModules/sshConfig.nix")
              (import "${sources.nixbook}//homeManagerModules/fastfetchConfig.nix")
            ]
            userImports
          ];
        };
      };
    };
in
{
  inherit mkUser;
}
