{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.customNixOSModules.networkManager;
in
{
  options.customNixOSModules.networkManager = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = '''';
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager = {
        enable = true;
        dhcp = "internal";
      };
      # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
      # The global useDHCP flag is deprecated, therefore explicitly set to false here.
      # Per-interface useDHCP will be mandatory in the future, so this generated config
      # replicates the default behaviour.
      useDHCP = false;
      dhcpcd.enable = false;
    };
    ## cf https://github.com/NixOS/nixpkgs/issues/180175#issuecomment-1658731959
    systemd.services.NetworkManager-wait-online = {
      serviceConfig = {
        ExecStart = [
          ""
          "${pkgs.networkmanager}/bin/nm-online -q"
        ];
      };
    };
  };
}
