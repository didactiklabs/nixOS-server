{
  cloud ? false,
}:
let
  sources = import ./npins;
  pkgs = import sources.nixpkgs { };
  disko = import sources.disko { inherit (pkgs) lib; };

  laptop = import "${pkgs.path}/nixos/lib/eval-config.nix" {
    system = "x86_64-linux";
    modules = [
      ./installer/configuration.nix
    ];
    specialArgs = { inherit disko cloud; };
  };
in
{
  laptopInstallerIso =
    (laptop.extendModules {
      modules = [
        "${pkgs.path}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        {
          isoImage.squashfsCompression = null;
        }
      ];
    }).config.system.build.isoImage;
}
