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
        url = "https://pbs.twimg.com/media/FDdH_p8WYBEm_6g.png";
        sha256 = "sha256-p/iJR23YeH0WbFqdmO9MdzEurZaEMkqigt0eKSxTdPI=";
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
