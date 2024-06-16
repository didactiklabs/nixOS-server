{
  pkgs,
  username,
  hostname,
  ...
}: let
  novaInstall = pkgs.writeShellScriptBin "novaInstall" (builtins.readFile ../install.sh);
  novaLauncher =
    pkgs.writeShellScriptBin "novaLauncher"
    ''
      novaInstall --username ${username} --hostname ${hostname} --repo https://github.com/didactiklabs/nixOS-server.git --branch $NOVA_BRANCH
    '';
in {
  environment.systemPackages = [
    novaInstall
    novaLauncher
  ];
}
