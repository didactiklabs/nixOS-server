{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.customNixOSModules;
in {
  options.customNixOSModules.kubernetes = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        whether to enable kubernetes binaries globally or not
      '';
    };
  };
  imports = [
    ./kubeadm.nix
    ./kubelet.nix
    # ./cni-plugins.nix
  ];
  config = lib.mkIf cfg.kubernetes.enable {
    # kubelet systemd unit is heavily inspired by official image-builder unit
    systemd = {
      services.cloud-final = {
        path = [
          pkgs.kubernetes
          pkgs.kubectl
          pkgs.iproute2
          pkgs.iptables
          pkgs.socat
          pkgs.ethtool
          pkgs.cri-tools
          pkgs.conntrack-tools
        ];
        after = ["containerd.service"];
        wants = ["containerd.service"];
      };

      services.kubelet = {
        enable = true;
        description = "kubelet: The Kubernetes Node Agent";
        documentation = [
          "https://kubernetes.io/docs/home/"
        ];
        unitConfig = {
          After = "gen-kubelet-extra-args.service";
          Require = "gen-kubelet-extra-args.service";
          StartLimitInterval = 0;
        };
        path = [
          "/opt/cni/bin"
          pkgs.mount
          pkgs.umount
          pkgs.util-linux
          pkgs.file
          pkgs.iproute2
          pkgs.iptables
          pkgs.socat
          pkgs.ethtool
          pkgs.conntrack-tools
          pkgs.multipath-tools
          pkgs.openiscsi
          pkgs.lsscsi
        ];
        serviceConfig = {
          Restart = "always";
          RestartSec = 10;
          Environment = [
            "KUBELET_KUBECONFIG_ARGS=\"--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf\""
            "KUBELET_CONFIG_ARGS=\"--config=/var/lib/kubelet/config.yaml\""
          ];
          EnvironmentFile = [
            "-/var/lib/kubelet/kubeadm-flags.env"
            "-/etc/sysconfig/kubelet"
          ];
          ExecStart = [
            "${pkgs.kubernetes}/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS"
          ];
        };
        wantedBy = ["multi-user.target"];
     };

      # we need cacert to be a real file to be mounted in kube's pods using hostPath volumes
      tmpfiles.rules = [
        "d /etc/sysconfig 0755 root root -"
        "d /etc/kubernetes 0755 root root -"
        "d /etc/kubernetes/manifests 0755 root root -"
        "d /run/kubeadm 0755 root root -"
        "d /run/cluster-api 0755 root root -"
      ];
    };
  };
}
