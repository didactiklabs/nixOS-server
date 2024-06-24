{
  pkgs,
  nixbook,
  home-manager,
  lib,
  overrides ? {},
}: let
  defaultConfig = {
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    customHomeManagerModules = {
      gitConfig.enable = true;
      sshConfig.enable = true;
      starship.enable = true;
      vim.enable = true;
      fastfetchConfig.enable = true;
    };
    imports = [];
  };

  mergedConfig = lib.recursiveUpdate defaultConfig overrides;

  mkUser = {
    username,
    userImports ? [],
  }: {
    programs.zsh.enable = true;
    users.users."${username}" = {
      shell = pkgs.zsh;
      extraGroups = mergedConfig.extraGroups;
      isNormalUser = true;
      description = "${username}";
    };
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      backupFileExtension = "rebuild";
      users.${username} = {
        config = {
          customHomeManagerModules = mergedConfig.customHomeManagerModules;
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
            (import "${nixbook}//homeManagerModules/zshConfig.nix")
            (import "${nixbook}//homeManagerModules/gitConfig.nix")
            (import "${nixbook}//homeManagerModules/sshConfig.nix")
            (import "${nixbook}//homeManagerModules/starshipConfig.nix")
            (import "${nixbook}//homeManagerModules/vimConfig.nix")
            (import "${nixbook}//homeManagerModules/fastfetchConfig.nix")
          ]
          userImports
        ];
      };
    };
  };
in {inherit mkUser;}
