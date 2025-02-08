{
  config,
  pkgs,
  lib,
  sources,
  ...
}:
let
  overrides = {
    customHomeManagerModules = { };
    imports = [ ./fastfetchConfig.nix ];
  };
in
{
  boot = {
    kernelParams = [
      "consoleblank=0"
      "console=ttyS0,115200n8"
    ];
    loader = {
      systemd-boot.configurationLimit = 0;
      timeout = 0;
      grub = {
        enable = true;
        devices = [ "/dev/vda" ];
      };
    };
    growPartition = true;
  };
  networking = {
    hostName = lib.mkForce "";
  };
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };
  networking = {
    useDHCP = false;
    dhcpcd.enable = false;
  };
  systemd.services = {
    qemu-guest-agent = {
      path = [ pkgs.cloud-init ];
    };
    kubelet = {
      serviceConfig.Environment = [
        ''KUBELET_KUBECONFIG_ARGS="--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf" --cloud-provider=external''
      ];
    };
  };

  services = {
    qemuGuest = {
      enable = lib.mkForce true;
    };
    cloud-init = {
      enable = true;
      network.enable = true;
    };
    resolved = {
      enable = true;
      llmnr = "false"; # allow shotdns resolution in kubevirt
      extraConfig = ''
        ResolveUnicastSingleLabel=true # allow shotdns resolution in kubevirt
      '';
    };
  };
  security = {
    polkit.enable = true;
  };
  systemd = {
    network = {
      networks = {
        "10-enp1s0" = {
          matchConfig = {
            Name = "en*";
          };
          networkConfig = {
            DHCP = "no";
          };
        };
      };
    };
  };
  customNixOSModules = {
    kubernetes = {
      enable = true;
      version = {
        kubeadm = "v1.31.4";
        kubelet = "v1.31.4";
      };
    };
    caCertificates = {
      didactiklabs.enable = true;
      bealv.enable = true;
    };
    ginx.enable = false;
  };
  imports = [
    (import ../../users/bealv {
      inherit
        config
        pkgs
        lib
        sources
        overrides
        ;
    })
    <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
  ];
}
