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
        url = "https://i.imgur.com/k1P3IZr.png";
        sha256 = "sha256-xMswxjnAnKsWfp9rjSMFeE9GWTQfNbfscPtaHCCCHRU=";
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
