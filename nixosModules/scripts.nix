{
  pkgs,
  config,
  lib,
  hostname,
  nixos_gitrepo,
  ...
}: let
  cfg = config.profileCustomization;
  novaInstall = pkgs.writeShellScriptBin "novaInstall" (builtins.readFile ../install.sh);
  novaLauncher = pkgs.writeShellScriptBin "novaLauncher" ''
    ${novaInstall}/bin/novaInstall --hostname ${hostname} --repo https://${nixos_gitrepo} --rev ${cfg.gitOps.targetRev}
  '';
in {
  options.profileCustomization.gitOps = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Branch/tag to target for the configuration rebuild-sync
      '';
    };
    targetRev = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = ''
        Branch/tag to target for the configuration rebuild-sync
      '';
    };
  };
  config = {
    environment.systemPackages = [
      novaInstall
      novaLauncher
    ];
  };
}
