{
  config,
  pkgs,
  kubeadm,
  lib,
  ...
}:
let
  cfg = config.customNixOSModules;
  kubeadm-bin = pkgs.runCommand "get-kubeadm" { nativeBuildInputs = [ ]; } ''
    mkdir -p $out/bin
    cp ${kubeadm}/bin/kubeadm $out/bin/
  '';
in
{
  config = lib.mkIf cfg.kubernetes.enable { environment.systemPackages = [ kubeadm-bin ]; };
}
