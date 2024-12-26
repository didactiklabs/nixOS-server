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
        url = "https://static1.personality-database.com/profile_images/85929ec953584389b7f31b816984d8a6.png";
        sha256 = "sha256-LX4Sp6fDSpr6gTwS4ClZrdfIJav9s1f92h290vP/8Kc=";
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
