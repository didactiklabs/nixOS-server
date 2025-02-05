{
  config,
  lib,
  ...
}:
let
  cfg = config.customHomeManagerModules.gitConfig;
in
{
  config = lib.mkIf cfg.enable {
    programs.git = {
      userName = "Laurent Alhossri";
      userEmail = "laurent.alhossri@gmail.com";
    };
  };
}
