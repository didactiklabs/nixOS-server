{
  config,
  pkgs,
  kubelet,
  lib,
  ...
}:
let
  cfg = config.customNixOSModules;
  kubelet-bin = pkgs.runCommand "get-kubelet" { nativeBuildInputs = [ ]; } ''
    mkdir -p $out/bin
    cp ${kubelet}/bin/kubelet $out/bin/
  '';
in
{
  config = lib.mkIf cfg.kubernetes.enable { environment.systemPackages = [ kubelet-bin ]; };
}
