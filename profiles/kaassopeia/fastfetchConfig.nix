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
        url = "https://i.imgur.com/1MZnT8y.jpeg";
        sha256 = "sha256-+gr8JP0lzqwRoL0Jqt5onGIBp+G0E+XHtjfQSPHvNdw=";
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
