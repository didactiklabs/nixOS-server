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
    supportedFilesystems = [ "nfs" ];
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
  environment = {
    etc = {
      "kubernetes/kubelet/config.d/00-config.conf".text = ''
        kind: KubeletConfiguration
        apiVersion: kubelet.config.k8s.io/v1beta1
        allowedUnsafeSysctls:
          - net.ipv4.conf.all.src_valid_mark
      '';
    };
  };

  systemd.services = {
    qemu-guest-agent = {
      path = [ pkgs.cloud-init ];
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
        kubeadm = "v1.32.3";
        kubelet = "v1.32.3";
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
