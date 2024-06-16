{
  config,
  pkgs,
  ...
}: {
  environment.defaultPackages = with pkgs; [
    # tools
    dogdns
    jq
    yq-go
    unzip
    vim
    tree
    openvpn
    btop # top replacer
    duf # df replacer
    sd # sd alternative
  ];
}
