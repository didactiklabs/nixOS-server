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
      NOVA_BRANCH=${NOVA_BRANCH:- "main"}
      novaInstall --username ${username} --hostname ${hostname} --repo https://${nixos_gitrepo} --branch $NOVA_BRANCH
    '';
in {
  environment.systemPackages = [
    novaInstall
    novaLauncher
  ];
  environment.variables = {
    NOVA_BRANCH = "main";
  };
}
