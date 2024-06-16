{
  pkgs,
  username,
  hostname,
  nixos_gitrepo,
  ...
}: let
  novaInstall = pkgs.writeShellScriptBin "novaInstall" (builtins.readFile ../install.sh);
  novaLauncher =
    pkgs.writeShellScriptBin "novaLauncher"
    ''
      novaInstall --username ${username} --hostname ${hostname} --repo https://${nixos_gitrepo} --branch main
    '';
in {
  environment.systemPackages = [
    novaInstall
    novaLauncher
  ];
}
