{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.customNixOSModules;
  kubeadm = pkgs.runCommand "get-kubeadm" { nativeBuildInputs = [ ]; } ''
    mkdir -p $out/bin
    cp ${pkgs.kubernetes}/bin/kubeadm $out/bin/
  '';
in
{
  config = lib.mkIf cfg.kubernetes.enable { environment.systemPackages = [ kubeadm ]; };
}
