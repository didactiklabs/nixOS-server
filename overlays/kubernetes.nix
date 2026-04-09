# overlays/kubernetes.nix
final: prev: {
  # This attribute is a function that takes the configuration (specifically, the customNixOSModules.kubernetes.version)
  # and returns the versioned kubernetes packages.
  getKubernetesPackages =
    { config }:
    let
      cfg = config.customNixOSModules;
      sources = import ../npins;

      getNixpkgsForK8sVersion =
        k8sVersion:
        let
          pinName = "nixpkgs-k8s-${k8sVersion}";
        in
        if builtins.hasAttr pinName sources then
          (import sources.${pinName} {
            inherit (prev.stdenv.hostPlatform) system;
            config = { inherit (config.nixpkgs.config) allowUnfree allowUnfreePredicate; };
          }).kubernetes
        else
          throw "No nixpkgs pin found for Kubernetes ${k8sVersion}. Add a '${pinName}' pin to npins.";

    in
    {
      kubernetes_kubeadm = getNixpkgsForK8sVersion cfg.kubernetes.version.kubeadm;
      kubernetes_kubelet = getNixpkgsForK8sVersion cfg.kubernetes.version.kubelet;
    };
}
