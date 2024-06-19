{
  config,
  pkgs,
  lib,
  username,
  hostname,
  ...
}: {
  customNixOSModules = {
    k3s = {
      enable = true;
      podCIDR = "10.206.0.0/16";
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
      imports = [
        ./gitConfig.nix
        ./fastfetchConfig.nix
      ];
    };
  };
}
