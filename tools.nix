{ pkgs, ... }:
{
  environment.defaultPackages = with pkgs; [
    # tools
    dogdns
    jq
    yq-go
    unzip
    vim
    tree
    openvpn
  ];
}
