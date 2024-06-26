{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.customNixOSModules;
  kubelet = pkgs.runCommand "get-kubelet" {
    nativeBuildInputs = [ ];
    }
    ''
      mkdir -p $out/bin
      cp ${pkgs.kubernetes}/bin/kubelet $out/bin/
    '';
in {
  config = lib.mkIf cfg.kubernetes.enable {
    environment.systemPackages = [
      kubelet
    ];
  };
}