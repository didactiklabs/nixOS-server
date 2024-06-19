{
  config,
  pkgs,
  lib,
  username,
  hostname,
  ...
}: {
  profileCustomization = {
    gitOps = {
      enable = false;
      targetRev = "main";
    };
  };
  customNixOSModules = {
    kubernetes = {
      enable = true;
    };
  };
  home-manager = {
    users."${username}" = {
      customHomeManagerModules = {
        gitConfig.enable = true;
        sshConfig.enable = true;
        starship.enable = true;
        vim.enable = true;
        fastfetchConfig.enable = true;
      };
    };
  };
}
