{
  config,
  pkgs,
  username,
  lib,
  home-manager,
  nixbook,
  nixOS_version,
  ...
}: let
in {
  programs.zsh.enable = true;
  users.users."${username}" = {
    shell = pkgs.zsh;
  };
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "rebuild";
    users.${username} = {
      pkgs,
      config,
      ...
    }: {
      config = {
        home = {
          stateVersion = "${nixOS_version}";
          username = "${username}";
          homeDirectory = "/home/${username}";
          sessionVariables = {
            NIXPKGS_ALLOW_UNFREE = 1;
          };
        };
        programs.home-manager.enable = true;
      };
      # Let Home Manager install and manage itself.
      imports = [
        (import "${nixbook}//homeManagerModules/zshConfig.nix")
        (import "${nixbook}//homeManagerModules/gitConfig.nix")
        (import "${nixbook}//homeManagerModules/sshConfig.nix")
        (import "${nixbook}//homeManagerModules/starshipConfig.nix")
        (import "${nixbook}//homeManagerModules/vimConfig.nix")
        (import "${nixbook}//homeManagerModules/fastfetchConfig.nix")
      ];
    };
  };
}
