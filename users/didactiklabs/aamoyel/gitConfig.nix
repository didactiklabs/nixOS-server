{ config, lib, ... }:
let
  cfg = config.customHomeManagerModules.gitConfig;
in
{
  config = lib.mkIf cfg.enable {
    programs.git = {
      userName = "Alan Amoyel";
      userEmail = "alanamoyel06@gmail.com";
    };
  };
}
