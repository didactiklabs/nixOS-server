# overlays/kubernetes.nix
final: prev: {
  # This attribute is a function that takes the configuration (specifically, the customNixOSModules.kubernetes.version)
  # and returns the versioned kubernetes packages.
  getKubernetesPackages =
    { config }:
    let
      cfg = config.customNixOSModules;
      sources = import ../npins; # Assuming npins is at the project root

      getNixpkgsForK8sVersion =
        k8sVersion: component:
        let
          pinName = "nixpkgs-k8s-${k8sVersion}";
        in
        if builtins.hasAttr pinName sources then
          (import sources.${pinName} {
            inherit (prev.stdenv.hostPlatform) system;
            config = { inherit (config.nixpkgs.config) allowUnfree allowUnfreePredicate; };
          }).kubernetes
        else
          prev.kubernetes.overrideAttrs (oldAttrs: {
            version = k8sVersion;
            src = sources."${component}-${k8sVersion}";
            components = [ "cmd/${component}" ];
          });

    in
    {
      kubernetes_kubeadm = getNixpkgsForK8sVersion cfg.kubernetes.version.kubeadm "kubeadm";
      kubernetes_kubelet = getNixpkgsForK8sVersion cfg.kubernetes.version.kubelet "kubelet";
    };
}
