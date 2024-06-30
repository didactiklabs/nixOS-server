{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.customNixOSModules;
in {
  options.customNixOSModules.caCertificates = {
    didactiklabs.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        whether to enable caCertificates globally or not.
      '';
    };
  };
  config = {
    security.pki.certificateFiles =
      [
        "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ]
      ++ lib.optional cfg.caCertificates.didactiklabs.enable ../../assets/certs/didactiklabs-ca.crt;
  };
}