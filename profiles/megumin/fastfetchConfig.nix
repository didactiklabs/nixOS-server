{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.customHomeManagerModules;
  logo =
    let
      image = pkgs.fetchurl {
        url = "https://i.pinimg.com/736x/7a/a3/64/7aa3640aed08fd4572f0a38c0dd56846.jpg";
        sha256 = "sha256-HGAScMH+zAUIhocWLwBXkAMMAk4v374arREmcnX0zXE=";
      };
    in
    "${image}";
in
{
  config = lib.mkIf cfg.fastfetchConfig.enable {
    home.file.".config/fastfetch/logo" = {
      source = lib.mkForce logo;
    };
  };
}
