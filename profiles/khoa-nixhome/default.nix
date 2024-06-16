{
  config,
  pkgs,
  lib,
  username,
  hostname,
  ...
}: {
  home-manager = {
    users."${username}" = {
      customHomeManagerModules = {
        gitConfig.enable = true;
        sshConfig.enable = true;
        starship.enable = true;
        vim.enable = true;
        fastfetchConfig.enable = true;
      };
      imports = [
        ./gitConfig.nix
      ];
    };
  };
}
