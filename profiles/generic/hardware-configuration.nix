{lib, ...}:
with lib; {
  imports = [
    <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
  ];

  config = {
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    boot.growPartition = true;
    boot.kernelParams = ["console=ttyS0"];
    boot.loader.grub.device = "/dev/vda";
    boot.loader.timeout = 0;

    users.extraUsers.root.password = "";
  };
}
