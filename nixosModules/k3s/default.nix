{ config, lib, ... }:
let
  cfg = config.customNixOSModules;
in
{
  options.customNixOSModules.k3s = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        whether to enable k3s globally or not
      '';
    };
    podCIDR = lib.mkOption {
      type = lib.types.str;
      default = "10.69.0.0/16";
      description = ''
        whether to enable k3s globally or not
      '';
    };
  };
  imports = [
    ./cilium.nix
    ./fluxcd.nix
  ];
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/docs/USAGE.md
  config = lib.mkIf cfg.k3s.enable {
    networking.firewall.allowedTCPPorts = [
      6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
      # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
      # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
    ];
    networking.firewall.allowedUDPPorts = [
      # 8472 # k3s, flannel: required if using multi-node for inter-node networking
    ];
    services.k3s = {
      enable = true;
      role = "server";
      extraFlags = toString [
        "--write-kubeconfig-mode '0644'"
        "--disable-cloud-controller"
        "--disable-helm-controller"
        "--disable-network-policy"
        "--disable servicelb"
        "--disable traefik"
        "--disable local-storage"
        "--disable metrics-server"
        "--disable runtimes"
        "--flannel-backend=none"
        # "--kubelet-arg=v=4" # Optionally add additional args to k3s
      ];
    };
  };
}
