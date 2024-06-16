{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.customNixOSModules;
  fluxcdVersion = "v2.3.0";
  fluxcdBundle =
    pkgs.runCommand "fluxcd-manifests" {
      name = "fluxcd-manifests";
      buildInputs = [
        pkgs.gnused
        pkgs.fluxcd
      ];
    }
    ''
      export HOME=$(mktemp -d)
      mkdir -p $out/
      ${pkgs.fluxcd}/bin/flux install -v ${fluxcdVersion} --export -n flux-system > $out/fluxcd-bundle.yaml
    '';
in {
  config = lib.mkIf cfg.k3s.enable {
    system.activationScripts.manageFluxcd = ''
      cp ${fluxcdBundle}/fluxcd-bundle.yaml /var/lib/rancher/k3s/server/manifests/ -r
    '';
  };
}
