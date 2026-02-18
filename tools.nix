{ pkgs, ... }:
{
  environment.defaultPackages = with pkgs; [
    # tools
    doggo
    jq
    yq-go
    unzip
    vim
    tree
  ];
}
