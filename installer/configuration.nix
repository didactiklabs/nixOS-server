{
  pkgs,
  modulesPath,
  disko,
  config,
  cloud,
  ...
}:
let
  sources = import ../npins;
  diskoCfg = import ./disko.nix { disk = "/dev/disko"; };
  ginx = import "${sources.nixbook}//customPkgs/ginx.nix" { inherit pkgs; };
  installerSources = pkgs.callPackage ./sources.nix { };
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    (import ./installer.nix { inherit disko diskoCfg; })
  ];
  system.build.installSystem.sources = installerSources;
  system.build.installSystem.nixos = import "${pkgs.path}/nixos/lib/eval-config.nix" {
    system = "x86_64-linux";
    modules = [
      "${modulesPath}/profiles/minimal.nix"
      "${modulesPath}/profiles/qemu-guest.nix"
      "${modulesPath}/profiles/all-hardware.nix"
      {
        users.users.nixos = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
          ];
        };
        security.sudo.wheelNeedsPassword = false;
        programs.bash.loginShellInit = ''
          ${
            if cloud then
              ''
                while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
                  echo 'Waiting for cloud-init...';
                  sleep 1;
                done
              ''
            else
              ""
          }
                  echo Starting final configuration...
                  sleep 2
                  cd /tmp/nixos-server
                  colmena apply-local --sudo
                  sudo reboot
        '';
        nixpkgs.config.allowUnfree = true;
        environment.systemPackages = with pkgs; [
          wpa_supplicant
          wirelesstools
          networkmanager
          dhcpcd
          colmena
        ];
        services = {
          getty.autologinUser = "nixos";
          qemuGuest.enable = if cloud then true else false;
          cloud-init =
            if cloud then
              {
                enable = true;
              }
            else
              { };
        };
        networking = {
          hostName = if cloud then "" else "ippo";
          useDHCP = true;
        };
        boot.loader = {
          systemd-boot.enable = false;
          grub = {
            enable = true;
          };
        };
        hardware = {
          firmware = [
            pkgs.linux-firmware
          ];
          enableRedistributableFirmware = true;
        };
        nix = {
          package = pkgs.lix;
          settings = {
            trusted-users = [
              "root"
              "@wheel"
            ];
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            substituters = [ "https://s3.didactiklabs.io/nix-cache" ];
            trusted-public-keys = [ "didactiklabs-nixcache:PxLKN0+ZkP07M8g8/B6xbP6A4MYpqQg6LH7V3muiy/0=" ];
          };
          extraOptions = ''
            # Ensure we can still build when missing-server is not accessible
            fallback = true
          '';
        };
      }
      (disko.config diskoCfg)
    ];
  };
  services.getty.autologinUser = "nixos";
  console.keyMap = "fr";
  networking = {
    hostName = "megumin";
    useDHCP = true;
  };
  environment.systemPackages =
    [
      ginx
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
