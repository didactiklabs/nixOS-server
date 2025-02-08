{
  cloud ? "ippo",
  partition ? "default70G",
  profile ? "kaasix",
  ...
}:
let
  sources = import ./npins;
  pkgs = import sources.nixpkgs { };
  disko = import sources.disko { inherit (pkgs) lib; };

  isoInstall = import "${pkgs.path}/nixos/lib/eval-config.nix" {
    system = "x86_64-linux";
    modules = [
      ./installer/live-configuration.nix
    ];
    specialArgs = { inherit disko partition cloud; };
  };
  nixosSystem = import (sources.nixpkgs + "/nixos") {
    configuration = ./profiles/${profile}/configuration.nix;
  };
  buildQcow2 = import <nixpkgs/nixos/lib/make-disk-image.nix> {
    inherit lib pkgs;
    inherit (nixosSystem) config;
    diskSize = "auto";
    format = "qcow2-compressed";
    configFile = ./profiles/${profile}/configuration.nix;
    partitionTableType = "hybrid";
    additionalSpace = "100G";
  };
  inherit (pkgs) lib;
in
{
  imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix> ];
  inherit lib nixosSystem buildQcow2;
  buildIso =
    (isoInstall.extendModules {
      modules = [
        "${pkgs.path}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        {
          isoImage.squashfsCompression = null;
        }
      ];
    }).config.system.build.isoImage;
  ociQcow2 = pkgs.dockerTools.buildLayeredImage {
    name = "${profile}-${nixosSystem.config.customNixOSModules.kubernetes.version.kubeadm}";
    includeStorePaths = false;
    fakeRootCommands = ''
      mkdir -p ./disk
      cp -L ${buildQcow2}/nixos.qcow2 ./disk/${profile}.qcow2
    '';
  };
}
