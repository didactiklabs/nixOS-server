{
  config,
  pkgs,
  username,
  lib,
  home-manager,
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
        ./homeManagerModules/zshConfig.nix
        ./homeManagerModules/gitConfig.nix
        ./homeManagerModules/sshConfig.nix
        ./homeManagerModules/starshipConfig.nix
        ./homeManagerModules/vimConfig.nix
        ./homeManagerModules/fastfetchConfig.nix
      ];
    };
  };
}
