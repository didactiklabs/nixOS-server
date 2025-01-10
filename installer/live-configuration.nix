{
  pkgs,
  modulesPath,
  disko,
  config,
  partition,
  cloud,
  lib,
  ...
}:
let
  diskoCfg = import ./partitions/${partition}.nix { disk = "/dev/disko"; };
  nixosConfig = import ./pre-configuration.nix {
    inherit
      pkgs
      modulesPath
      disko
      diskoCfg
      cloud
      config
      ;
  };
  isoType = if cloud then "-cloud" else "";
in
{
  isoImage.isoName = lib.mkForce "${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}-${partition}${isoType}.iso";
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    (import ./installer.nix { inherit disko diskoCfg; })
  ];
  system.build.installSystem.nixos = nixosConfig.system.build.installSystem.nixos;
  services.getty.autologinUser = "nixos";
  console.keyMap = "fr";
  networking = {
    hostName = "";
    useDHCP = true;
  };
  environment.systemPackages =
    [
      pkgs.hwinfo
      pkgs.busybox
    ]
    ++ (with config.system.build.scripts; [
      clean
      format
      mount
      install
      installer
    ]);
  nix = {
    package = pkgs.lix;
    settings = {
      trusted-users = [
        "root"
        "@wheel"
      ];
      substituters = [ "https://s3.didactiklabs.io/nix-cache" ];
      trusted-public-keys = [ "didactiklabs-nixcache:PxLKN0+ZkP07M8g8/B6xbP6A4MYpqQg6LH7V3muiy/0=" ];
    };
    extraOptions = ''
      # Ensure we can still build when missing-server is not accessible
      fallback = true
    '';
  };
  programs.bash.loginShellInit = ''
    clear
    sudo ${config.system.build.scripts.installer}/bin/installer
  '';
}
