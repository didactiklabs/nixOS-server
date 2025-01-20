{
  cloud ? false,
  partition ? "default60G",
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
in
{
  imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix> ];
  buildIso =
    (isoInstall.extendModules {
      modules = [
        "${pkgs.path}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        {
          isoImage.squashfsCompression = null;
        }
      ];
    }).config.system.build.isoImage;
}
