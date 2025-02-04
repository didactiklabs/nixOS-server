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
    systemd.services.forgejo = {
      preStart =
        let
          adminCmd = "${lib.getExe config.services.forgejo.package} admin user";
          user = "root"; # Note, Forgejo doesn't allow creation of an account named "admin"
        in
        ''
          ${adminCmd} create --admin --email "root@localhost" --username ${user} --password "admin" --must-change-password || true
        '';
      serviceConfig = {
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        CapabilityBoundingSet = lib.mkForce "CAP_NET_BIND_SERVICE";
      };
    };
    services.nginx = {
      enable = true;
      virtualHosts.${forgejoSrv.DOMAIN} = {
        forceSSL = true;
        sslCertificateKey = "/var/host.key";
        sslCertificate = "/var/host.cert";
        extraConfig = ''
          client_max_body_size 512M;
        '';
        locations."/".proxyPass = "http://localhost:${toString forgejoSrv.HTTP_PORT}";
      };
    };
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
          START_SSH_SERVER = true;
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
