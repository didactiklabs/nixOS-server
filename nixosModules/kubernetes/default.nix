{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.customNixOSModules;
in {
  options.customNixOSModules.kubernetes = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        whether to enable kubernetes binaries globally or not
      '';
    };
  };
  imports = [
    ./kubeadm.nix
    # ./cni-plugins.nix
  ];
}
