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
        url = "https://i.imgur.com/TTA9fgg.jpeg";
        sha256 = "sha256-+9/6Dei+k8e7MjsLYsQUF9njW8sRPqAxw9wCEFrzeFM=";
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
