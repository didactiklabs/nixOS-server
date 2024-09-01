{ pkgs, ... }:
{
  config = {
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    networking.useDHCP = false;
    networking.networkmanager.enable = true;
    networking.networkmanager.dhcp = "internal";
    networking.dhcpcd.enable = false;
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
