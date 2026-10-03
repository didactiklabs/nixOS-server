let
  sources = import ./npins;
in
{
  pkgs,
  lib,
  ...
}:
{
  imports = [ "${sources.nixbook}/devenvModules/devenv.nix" ];

  packages = with pkgs; [
    qemu
    docker
    npins
  ];

  env.PATH = lib.mkForce "$PWD/scripts:$PATH";

  scripts = {
    build-iso.exec = ''
      mkdir -p output
      cp $(nix-build default.nix -A buildIso --argstr partition "''${1:-default70G}" --argstr cloud "''${2:-false}")/iso/* output/
    '';
    build-qcow2.exec = ''
      set -euo pipefail
      # build-qcow2 <profile> [k8s-version]  (version: e.g. 1.36.3, overrides the profile's)
      mkdir -p output
      chmod +w output -R
      name="$1''${2:+-$2}"
      cp "$(nix-build default.nix -A buildQcow2 --argstr profile "$1" --argstr k8sVersion "''${2:-}")/nixos.qcow2" "output/$name.qcow2"
      echo "output/$name.qcow2"
    '';
    build-oci-qcow2.exec = ''
      mkdir -p output
      chmod +w output -R
      $(nix-build default.nix -A ociQcow2 --argstr profile $1) > output/$1-qcow2-oci.tar
    '';
    show-k8s-pins.description = "Display already available Kubernetes nixpkgs pins via npins";
    show-k8s-pins.exec = ''
      ${pkgs.npins}/bin/npins show | grep 'nixpkgs-k8s-'
    '';
    add-k8s-pin.description = "Pin a nixpkgs revision for a specific Kubernetes version via npins";
    add-k8s-pin.exec = ''
      if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: add-k8s-pin <K8S_VERSION> <NIXPKGS_REV>"
        echo "Example: add-k8s-pin 1.35.2 24f4544180242cd80bb2492ce6907243bc716e08"
        exit 1
      fi

      # pin names have no "v" prefix (overlays/kubernetes.nix looks up nixpkgs-k8s-<version>)
      K8S_VERSION="''${1#v}"
      NIXPKGS_REV="$2"
      PIN_NAME="nixpkgs-k8s-$K8S_VERSION"

      echo "Adding pin for $PIN_NAME with revision $NIXPKGS_REV..."
      ${pkgs.npins}/bin/npins add github NixOS nixpkgs \
        --name "$PIN_NAME" \
        --branch "master" --frozen \
        --at "$NIXPKGS_REV"
      echo "Nixpkgs pin for Kubernetes $K8S_VERSION added and frozen in npins."
      echo "Remember to add corresponding 'kubeadm-$K8S_VERSION' and 'kubelet-$K8S_VERSION' entries if you haven't already."
    '';
    run-iso.exec = ''
      set -euo pipefail
      if ! nix-build default.nix --argstr partition "''${1:-default70G}" --argstr cloud "''${2:-false}"; then
        echo "nix-build failed!"
        exit 1
      fi

      ISO_PATH=$(find result/iso -name "*.iso" | head -n 1)
      if [[ -z "$ISO_PATH" ]]; then
        echo "ISO not found after build!"
        exit 1
      fi

      if ! qemu-img create -f raw disk.img 80G; then
        echo "Failed to create disk image!"
        exit 1
      fi

      qemu-system-x86_64 \
        -enable-kvm \
        -m 4096 \
        -cpu host \
        -cdrom "$ISO_PATH" \
        -boot once=d \
        -drive file=disk.img,format=raw \
        -nic user,model=virtio,hostfwd=tcp::2222-:22 || {
        echo "QEMU launch failed!"
        rm -f disk.img
        exit 1
      }

      echo "QEMU exited. Cleaning up."
      rm -f disk.img
    '';
  };

  enterShell = ''
    echo ""
    echo "🔧 nixOS-server development environment loaded"
    echo ""
    echo "Available tools:"
    ${lib.concatStringsSep "\n    " (
      map (pkg: "echo \"  • ${pkg.name or pkg.pname or "unknown"} - ${pkg.meta.description or ""}\"") (
        with pkgs;
        [
          qemu
          docker
          npins
        ]
      )
    )}
    echo ""
    echo "Available build scripts:"
    echo ""
    echo "  build-iso       - Build bootable NixOS installation ISO image"
    echo "                    Output: ./output/"
    echo "                    Example: build-iso default70G false"
    echo ""
    echo "  build-qcow2     - Build compressed QCOW2 disk image for VM/cloud use"
    echo "                    Output: ./output/<profile>.qcow2"
    PROFILES=$(ls -1 profiles/ 2>/dev/null | tr '\n' ',' | sed 's/,$//')
    echo "                    Available profiles: $PROFILES"
    echo "                    Usage: build-qcow2 <profile> [k8s-version] -> output/<profile>[-<version>].qcow2"
    echo "                    Example: build-qcow2 kaassopeia 1.36.3"
    echo ""
    echo "  build-oci-qcow2 - Build OCI container image with embedded QCOW2"
    echo "                    Output: ./output/<profile>-qcow2-oci.tar"
    echo "                    Available profiles: $PROFILES"
    echo "                    Example: build-oci-qcow2 kaas"
    echo ""
    echo "  run-iso         - Build ISO and boot it in QEMU (4GB RAM, KVM)"
    echo "                    Example: run-iso default70G false"
    echo ""
    echo "  show-k8s-pins   - Display already available Kubernetes nixpkgs pins"
    echo "                    Example: show-k8s-pins"
    echo ""
    echo "  add-k8s-pin     - Pin a nixpkgs revision for a specific Kubernetes version"
    echo "                    Usage: add-k8s-pin <K8S_VERSION> <NIXPKGS_REV>"
    echo "                    Example: add-k8s-pin 1.35.2 24f4544180242cd80bb2492ce6907243bc716e08"
    echo ""
  '';
}
