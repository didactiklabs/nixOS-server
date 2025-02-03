{
  config,
  lib,
  ...
}:
let
  cfg = config.customNixOSModules.forgejo;
  forgejoSrv = config.services.forgejo.settings.server;
in
{
  options.customNixOSModules.forgejo = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = '''';
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = '''';
    };
  };
  config = lib.mkIf cfg.enable {
    services.forgejo = {
      enable = true;
      database.type = "postgres";
      # Enable support for Git Large File Storage
      lfs.enable = true;
      settings = {
        server = {
          DOMAIN = "${cfg.domain}";
          # You need to specify this to remove the port from URLs in the web UI.
          ROOT_URL = "https://${forgejoSrv.DOMAIN}/";
          HTTP_PORT = 3000;
        };
        openid = {
          ENABLE_OPENID_SIGNIN = true;
          ENABLE_OPENID_SIGNUP = true;
        };
        # You can temporarily allow registration to create an admin user.
        service.DISABLE_REGISTRATION = true;
        # Add support for actions, based on act: https://github.com/nektos/act
        actions = {
          ENABLED = true;
          DEFAULT_ACTIONS_URL = "github";
        };
      };
    };
  };
}
