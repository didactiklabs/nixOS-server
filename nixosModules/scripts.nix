{
  pkgs,
  config,
  lib,
  username,
  hostname,
  nixos_gitrepo,
  ...
}: let
  cfg = config.profileCustomization;
  novaInstall = pkgs.writeShellScriptBin "novaInstall" (builtins.readFile ../install.sh);
  novaLauncher = pkgs.writeShellScriptBin "novaLauncher" ''
    ${novaInstall}/bin/novaInstall --username ${username} --hostname ${hostname} --repo https://${nixos_gitrepo} --rev ${cfg.gitOps.targetRev}
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
    systemd.services.novalauncher = lib.mkIf cfg.gitOps.enable {
      description = "NovaLauncher script to maintain the server up to date with git.";
      partOf = ["default.target"];
      requires = ["default.target"];
      after = ["default.target"];
      wantedBy = ["default.target"];
      serviceConfig = {
        User = "root";
        Group = "root";
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -lc ${novaLauncher}/bin/novaLauncher";
      };
    };
    systemd.timers."novalauncher" = lib.mkIf cfg.gitOps.enable {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "1m";
        Unit = "novalauncher.service";
      };
    };
  };
}
