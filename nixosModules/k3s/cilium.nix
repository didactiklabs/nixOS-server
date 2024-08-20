{ config, pkgs, lib, ... }:
let
  cfg = config.customNixOSModules;
  sources = import ../../npins;
  ciliumSrc = sources.cilium;
  ciliumBundle = pkgs.runCommand "cilium-manifests" {
    name = "cilium-manifests";
    buildInputs = [ pkgs.gnused pkgs.kubernetes-helm ];
    src = "${ciliumSrc}";
  } ''
    export HOME=$(mktemp -d)
    mkdir -p $out/
    ${pkgs.kubernetes-helm}/bin/helm template ${ciliumSrc}/install/kubernetes/cilium --namespace kube-system  \
      --set ipv4.enabled=true --set ipv6.enabled=false \
      --set rollOutCiliumPods=true \
      --set kubeProxyReplacement=true \
      --set annotateK8sNode=true \
      --set operator.enabled=true --set operator.rollOutPods=true --set operator.replicas=1  \
      --set "ipam.operator.clusterPoolIPv4PodCIDRList[0]=${cfg.k3s.podCIDR}"
      > $out/cilium-bundle.yaml
  '';
in {
  config = lib.mkIf cfg.k3s.enable {
    system.activationScripts.manageCilium = ''
      mkdir -p /var/lib/rancher/k3s/server/manifests
      cp ${ciliumBundle}/cilium-bundle.yaml /var/lib/rancher/k3s/server/manifests/ -r
    '';
  };
}
