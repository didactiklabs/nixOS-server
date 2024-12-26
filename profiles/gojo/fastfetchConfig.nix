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
        url = "https://avatars.pfptown.com/145/gojo-pfp-1778.png";
        sha256 = "sha256-JZW6MivwAiDVZBFldSreytmSkrsyJXggfBb2+ygfqkg=";
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
