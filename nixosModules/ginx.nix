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
  # Run by ginx in its checkout of the repo when a new revision lands. After
  # the per-host delay, the evaluation + switch runs in a transient unit (own
  # cgroup): throttled before it can push etcd/kubelet out of memory, low
  # CPU/IO priority (MemoryMax is a backstop well above a normal evaluation),
  # and a switch that restarts ginx.service can no longer kill itself.
  applyScript = pkgs.writeShellScript "ginx-apply" ''
    set -euo pipefail
    sleep ${toString cfg.applyDelay}
    exec ${config.systemd.package}/bin/systemd-run --wait --collect --pipe --quiet \
      --unit=ginx-apply --working-directory="$PWD" \
      --setenv=PATH="$PATH" --setenv=HOME=/root \
      -p MemoryHigh=2G -p MemoryMax=4G -p CPUWeight=20 -p IOWeight=20 \
      -- colmena apply-local
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
    applyDelay = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 0;
      description = ''
        Seconds to wait after a new revision is detected before evaluating and
        applying it. Give hosts of the same cluster different values so they
        never evaluate/switch at the same time (an evaluation needs a few GB of
        RAM; three control planes doing it at once starved etcd on 2026-10-02).
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
        # Builds/substitutions of a deploy run in nix-daemon: same treatment.
        nix-daemon.serviceConfig = {
          MemoryHigh = "2G";
          MemoryMax = "4G";
          CPUWeight = 20;
          IOWeight = 20;
        };
        ginx = {
          enable = true;
          path = [
            pkgs.colmena
          ];
          wantedBy = [ "multi-user.target" ];
          # A switch must never restart the service it runs from. Applies now
          # run in their own unit (applyScript), so this only matters for the
          # deploy that changes this unit: changes here take effect at the next
          # ginx restart (or reboot).
          restartIfChanged = false;
          serviceConfig = {
            ExecStart = "${ginx}/bin/ginx --source https://github.com/didactiklabs/nixOs-server -b main -n 60 --exit-on-fail -- ${applyScript}";
            Restart = "always";
          };
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
}
