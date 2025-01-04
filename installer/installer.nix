{
  disko,
  diskoCfg,
  ...
}:
{
  pkgs,
  lib,
  config,
  ...
}:
{
  config.system.build.scripts = rec {
    clean = pkgs.writeScriptBin "tsp-clean" ''
      set -euo pipefail
      ${pkgs.util-linux}/bin/wipefs -af ${diskoCfg.disko.devices.disk.main.device}
    '';
    format = pkgs.writeScriptBin "tsp-format" (disko.format diskoCfg);
    mount = pkgs.writeScriptBin "tsp-mount" (disko.mount diskoCfg);
    install = pkgs.writeScriptBin "tsp-install" ''
      set -euo pipefail

      mkdir -p /mnt/etc/nixos/
      ${config.system.build.nixos-install}/bin/nixos-install \
        --root /mnt \
        --no-root-password \
        --system "${config.system.build.installSystem.nixos.config.system.build.toplevel}"
      mkdir -p /mnt/tmp/nixos-server
      cp -r ${config.system.build.installSystem.sources}/installer/configuration.nix /mnt/etc/nixos/
      cp -r ${config.system.build.installSystem.sources}/. /mnt/tmp/nixos-server
      reboot
    '';
    installer = pkgs.writeScriptBin "installer" ''
      set -euo pipefail
      export PATH="$PATH:${
        lib.makeBinPath (
          with pkgs;
          [
            hwinfo
            gawk
            gnused
            busybox
            openssl
            dosfstools
            e2fsprogs
            gawk
            nixos-install-tools
            util-linux
            config.nix.package
          ]
        )
      }"
      #### DISK
      for i in $(lsblk -pln -o NAME,TYPE | grep disk | awk '{ print $1 }'); do
        if [[ "$i" == "/dev/fd0" ]]; then
          echo "$i is a floppy, skipping..."
          continue
        fi
        if grep -ql "^$i" <(mount); then
          echo "$i is in use, skipping..."
        else
          disk="$i"
          break
        fi
      done
      if [[ -z "$disk" ]]; then
        echo "ERROR: No usable disk found on this machine!"
        exit 1
      else
        echo "Found $disk, erasing..."
      fi
      ln -sf "$disk" ${diskoCfg.disko.devices.disk.main.device}

      #### Install
      ${clean}/bin/tsp-clean
      ${format}/bin/tsp-format
      ${mount}/bin/tsp-mount
      ${install}/bin/tsp-install
      touch /mnt/etc/PENDING
    '';
  };
}
