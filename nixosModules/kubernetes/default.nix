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
  kubeadm-bin = pkgs.runCommand "get-kubeadm" { nativeBuildInputs = [ ]; } ''
    mkdir -p $out/bin
    cp ${kubeadm}/bin/kubeadm $out/bin/
  '';
  kubelet-bin = pkgs.runCommand "get-kubelet" { nativeBuildInputs = [ ]; } ''
    mkdir -p $out/bin
    cp ${kubelet}/bin/kubelet $out/bin/
  '';
  kubeadm-upgrade = pkgs.writeShellScriptBin "kubeadm-upgrade" ''
    set -euo pipefail
    if [ -f "/etc/kubernetes/admin.conf" ] && [ "$(${pkgs.kubectl}/bin/kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes | grep control-plane)" ]; then
      KUBE_APISERVER_VERSION=$(${pkgs.kubectl}/bin/kubectl --kubeconfig=/etc/kubernetes/admin.conf version -o json | ${pkgs.jq}/bin/jq -r '.serverVersion.gitVersion')
      if [ "$KUBE_APISERVER_VERSION" != "${cfg.kubernetes.version.kubeadm}" ]; then
        ${kubeadm-bin}/bin/kubeadm upgrade apply ${cfg.kubernetes.version.kubeadm} -y -v=9
        echo upgrade control-plane done.
        exit 0
      fi
    elif [ -f "/etc/kubernetes/kubelet.conf" ] && [ "$(${pkgs.kubectl}/bin/kubectl --kubeconfig=/etc/kubernetes/kubelet.conf cluster-info | grep running)" ]; then
      KUBE_APISERVER_VERSION=$(${pkgs.kubectl}/bin/kubectl --kubeconfig=/etc/kubernetes/kubelet.conf version -o json | ${pkgs.jq}/bin/jq -r '.serverVersion.gitVersion')
      if [ "$KUBE_APISERVER_VERSION" != "${cfg.kubernetes.version.kubeadm}" ]; then
        ${kubeadm-bin}/bin/kubeadm upgrade node -v=9
        echo upgrade worker done.
        exit 0
      fi
    fi
    echo no upgrade required.
  '';
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
        type = lib.types.str;
        default = "vx.x.x";
        description = ''
          kubeadm version
        '';
      };
      kubelet = lib.mkOption {
        type = lib.types.str;
        default = "vx.x.x";
        description = ''
          kubelet version
        '';
      };
    };
  };
  config = lib.mkIf cfg.kubernetes.enable {
    boot.kernel.sysctl = {
      # values from kubernetes official image-builder
      "net.ipv4.tcp_syncookies" = false;
      "vm.swappiness" = 60;
      "net.bridge.bridge-nf-call-iptables" = 1;
      "net.bridge.bridge-nf-call-ip6tables" = 1;
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv4.tcp_congestion_control" = "bbr";
      "kernel.panic" = 10;
      "fs.inotify.max_user_instances" = 8192;
      "fs.inotify.max_user_watches" = 524288;
    };
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
    environment = {
      systemPackages = [
        kubeadm-bin
        kubelet-bin
      ];
    };
    # kubelet systemd unit is heavily inspired by official image-builder unit
    systemd = {
      services.kubeadm-upgrade = {
        enable = true;
        path = [
          "${kubeadm-bin}"
          pkgs.jq
        ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.bash}/bin/bash -c '${kubeadm-upgrade}/bin/kubeadm-upgrade'";
          Restart = "on-failure";
        };
      };
      timers.kubeadm-upgrade-timer = {
        enable = true;
        description = "Timer to run myService every 5 minutes";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnUnitActiveSec = "5min";
          Persistent = true;
          Unit = "kubeadm-upgrade.service";
        };
      };
      services.kubelet = {
        enable = true;
        description = "kubelet: The Kubernetes Node Agent";
        documentation = [ "https://kubernetes.io/docs/home/" ];
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
            "${kubelet-bin}/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS"
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
    virtualisation.containerd = {
      enable = true;
      settings = {
        version = 2;
        plugins = {
          "io.containerd.grpc.v1.cri" = {
            cni.bin_dir = "/opt/cni/bin";
          };
          "io.containerd.grpc.v1.cri" = {
            device_ownership_from_security_context = true;
          };
          "io.containerd.grpc.v1.cri".containerd.runtimes.runc = {
            runtime_type = "io.containerd.runc.v2";
          };
          "io.containerd.grpc.v1.cri".containerd.runtimes.runc.options = {
            SystemdCgroup = true;
          };
        };
      };
    };
  };
}
