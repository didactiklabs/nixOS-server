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
    systemd = {
      services.ginx = {
        enable = true;
        path = [
          pkgs.colmena
        ];
        environment = {
          NIX_PROFILES = "/run/current-system/sw /nix/var/nix/profiles/default /etc/profiles/per-user/root /root/.local/state/nix/profile /nix/profile /root/.nix-profile";
          NIX_PATH = "/root/.nix-defexpr/channels:nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/root/channels";
          NIXPKGS_CONFIG = "/etc/nix/nixpkgs-config.nix";
        };
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.bash}/bin/bash -c '${ginx}/bin/ginx --source https://github.com/didactiklabs/nixOs-server -b main -n 60 -- colmena apply-local --sudo'";
          Restart = "on-failure";
        };
      };
    };
  };
}
