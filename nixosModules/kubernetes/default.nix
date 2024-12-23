{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.customNixOSModules;
  sources = import ../../npins;

  kubernetesComponent =
    component: source:
    pkgs.kubernetes.overrideAttrs (oldAttrs: {
      src = source;
      components = [ component ];
    });

  # Define kubelet and kubeadm using the common function with different versions and hashes
  kubeadmSource = sources."kubeadm-${cfg.kubernetes.version.kubeadm}";
  kubeletSource = sources."kubelet-${cfg.kubernetes.version.kubelet}";
  kubelet = kubernetesComponent "cmd/kubelet" kubeletSource;
  kubeadm = kubernetesComponent "cmd/kubeadm" kubeadmSource;
in
{
  options.customNixOSModules.kubernetes = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        whether to enable kubernetes binaries globally or not
      '';
    };
    version = {
      kubeadm = lib.mkOption {
        type = lib.types.string;
        default = "vx.x.x";
        description = ''
          kubeadm version
        '';
      };
      kubelet = lib.mkOption {
        type = lib.types.string;
        default = "vx.x.x";
        description = ''
          kubelet version
        '';
      };
    };
  };
  imports = [
    (import ./kubeadm.nix {
      inherit
        pkgs
        kubeadm
        config
        lib
        ;
    })
    (import ./kubelet.nix {
      inherit
        pkgs
        kubelet
        config
        lib
        ;
    })
  ];
  config = lib.mkIf cfg.kubernetes.enable {
    system = {
      activationScripts = {
        # we need to prepare a cni dir where kubernetes CNI pods can drop their own binaries
        prepareCniDir.text = ''
          mkdir -p /opt/cni/bin
          for cnibin in ${pkgs.cni-plugins}/bin/*; do
            ln -sf ''${cnibin} /opt/cni/bin/$(basename ''${cnibin})
          done
        '';
        # CSI expects "some" binaries to be included in "real" FHS path
        copyCSIbins.text = ''
          mkdir -p /usr/bin
          cp ${pkgs.kubectl}/bin/kubectl /usr/bin/kubectl
          cp ${pkgs.util-linux}/bin/blkid /usr/bin/blkid
          cp ${pkgs.util-linux}/bin/blockdev /usr/bin/blockdev
          cp ${pkgs.coreutils}/bin/cat /usr/bin/cat
          cp ${pkgs.cryptsetup}/bin/cryptsetup /usr/bin/cryptsetup
          cp ${pkgs.coreutils}/bin/dd /usr/bin/dd
          cp ${pkgs.coreutils}/bin/df /usr/bin/df
          cp ${pkgs.procps}/bin/free /usr/bin/free
          cp ${pkgs.e2fsprogs}/bin/fsck.ext3 /usr/bin/fsck.ext3
          cp ${pkgs.e2fsprogs}/bin/fsck.ext4 /usr/bin/fsck.ext4
          cp ${pkgs.openiscsi}/bin/iscsiadm /usr/bin/iscsiadm
          cp ${pkgs.util-linux}/bin/losetup /usr/bin/losetup
          cp ${pkgs.coreutils}/bin/ls /usr/bin/ls
          cp ${pkgs.lsscsi}/bin/lsscsi /usr/bin/lsscsi
          cp ${pkgs.coreutils}/bin/mkdir /usr/bin/mkdir
          cp ${pkgs.e2fsprogs}/bin/mkfs.ext3 /usr/bin/mkfs.ext3
          cp ${pkgs.e2fsprogs}/bin/mkfs.ext4 /usr/bin/mkfs.ext4
          cp ${pkgs.mount}/bin/mount /usr/bin/mount
          cp ${pkgs.multipath-tools}/bin/multipath /usr/bin/multipath
          cp ${pkgs.multipath-tools}/bin/multipathd /usr/bin/multipathd
          cp ${pkgs.procps}/bin/pgrep /usr/bin/pgrep
          cp ${pkgs.e2fsprogs}/bin/resize2fs /usr/bin/resize2fs
          cp ${pkgs.umount}/bin/umount /usr/bin/umount
          cp ${pkgs.kmod}/bin/lsmod /usr/bin/lsmod
        '';
      };
    };

    # kubelet systemd unit is heavily inspired by official image-builder unit
    systemd = {
      services.kubelet = {
        enable = true;
        description = "kubelet: The Kubernetes Node Agent";
        documentation = [ "https://kubernetes.io/docs/home/" ];
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
            ''KUBELET_KUBECONFIG_ARGS="--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"''
            ''KUBELET_CONFIG_ARGS="--config=/var/lib/kubelet/config.yaml"''
          ];
          EnvironmentFile = [
            "-/var/lib/kubelet/kubeadm-flags.env"
            "-/etc/sysconfig/kubelet"
          ];
          ExecStart = [
            "${kubelet}/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS"
          ];
        };
        wantedBy = [ "multi-user.target" ];
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
