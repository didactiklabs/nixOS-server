{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  name = "nixos-server";

  packages = [
    pkgs.qemu
    (pkgs.writeShellScriptBin "buildIso" ''
      #!/bin/bash
      set -euo pipefail
      mkdir -p output
      cp $(nix-build default.nix -A buildIso --argstr partition "''${1:-default60G}" --arg cloud "''${2:-false}")/iso/* output/
    '')
    (pkgs.writeShellScriptBin "buildQcow2" ''
      #!/bin/bash
      set -euo pipefail
      mkdir -p output
      chmod +w output -R
      cp $(${pkgs.nixos-generators}/bin/nixos-generate -f qcow -c profiles/$1/configuration.nix -I nixpkgs=$(nix eval --raw -f npins nixpkgs.outPath)) output/$1.qcow2
    '')
    (pkgs.writeShellScriptBin "runQcow2" ''
      #!/bin/bash
      set -euo pipefail
      mkdir -p output
      chmod +w output -R
      ${pkgs.nixos-generators}/bin/nixos-generate -f vm --run -c profiles/$1/configuration.nix -I nixpkgs=$(nix eval --raw -f npins nixpkgs.outPath)
    '')
    (pkgs.writeShellScriptBin "runIso" ''
      #!/bin/bash
      set -euo pipefail
      # Step 1: Build the NixOS ISO
      if ! nix-build default.nix --argstr partition "''${1:-default}" --arg cloud "''${2:-false}"; then
        echo "nix-build failed!"
        exit 1
      fi

      # Ensure the ISO path exists
      ISO_PATH=$(find result/iso -name "*.iso" | head -n 1)
      if [[ -z "$ISO_PATH" ]]; then
        echo "ISO not found after build!"
        exit 1
      fi

      # Step 2: Create a 50G raw disk image
      if ! qemu-img create -f raw disk.img 50G; then
        echo "Failed to create disk image!"
        exit 1
      fi

      # Step 3: Launch QEMU with the specified configuration
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

      # Step 4: Clean up the disk image
      echo "QEMU exited. Cleaning up."
      rm -f disk.img
    '')
  ];
}
