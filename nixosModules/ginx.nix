{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.customNixOSModules.ginx;
  sources = import ../npins;
  ginx = import "${sources.nixbook}//customPkgs/ginx.nix" { inherit pkgs; };
  osupdate = pkgs.writeShellScriptBin "osupdate" ''
    set -euo pipefail
    echo last applied revisions: $(${pkgs.jq}/bin/jq .rev /etc/nixos/version)
    echo applying revision: "$(${pkgs.git}/bin/git ls-remote https://github.com/didactiklabs/nixOs-server HEAD | awk '{print $1}')"...

    echo Running ginx...
    ${ginx}/bin/ginx --source https://github.com/didactiklabs/nixOs-server -b main --now -- ${pkgs.colmena}/bin/colmena apply-local --sudo
  '';
in
{
  options.customNixOSModules.ginx = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Ginx is a cli tool that watch a remote repository and run an arbitrary command on changes/updates.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [
        pkgs.colmena
        osupdate
        ginx
      ];
    };

    systemd = {
      services = {
        ginx = {
          enable = true;
          path = [
            pkgs.colmena
          ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.bash}/bin/bash -c '${ginx}/bin/ginx --source https://github.com/didactiklabs/nixOs-server -b main -n 60 --exit-on-fail -- colmena apply-local'";
            Restart = "always";
          };
        };
        timers = {
          ginx-timer = {
            enable = true;
            description = "Timer to run myService every 5 minutes";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnUnitActiveSec = "5min";
              Persistent = true;
              Unit = "ginx.service";
            };
          };
        };
      };
    };
  };
}
