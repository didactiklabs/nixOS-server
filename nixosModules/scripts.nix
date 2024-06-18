{
  pkgs,
  username,
  hostname,
  nixos_gitrepo,
  ...
}: let
  novaInstall = pkgs.writeShellScriptBin "novaInstall" (builtins.readFile ../install.sh);
  novaLauncher =
    pkgs.writeShellScriptBin "novaLauncher"
    ''
      date >> /var/log/nova.log
      echo "-----" >> /var/log/nova.log
      echo "-----" >> /var/log/nova.log
      novaInstall --username ${username} --hostname ${hostname} --repo https://${nixos_gitrepo} --branch main >> /var/log/nova.log
    '';
in {
  environment.systemPackages = [
    novaInstall
    novaLauncher
  ];
  systemd.services.novalauncher = {
    description = "NovaLauncher script to maintain the server up to date with git.";
    partOf = ["default.target"];
    requires = ["default.target"];
    after = ["default.target"];
    wantedBy = ["default.target"];
    serviceConfig = {
      User = "root";
      Group = "root";
      Type = "oneshot";
      ExecStart = "${novaLauncher}/bin/novaLauncher";
    };
  };
  systemd.timers."novalauncher" = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "1m";
      Unit = "novalauncher.service";
    };
  };
}
