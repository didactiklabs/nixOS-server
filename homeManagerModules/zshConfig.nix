{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.customHomeManagerModules;
in {
  config = {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    programs.bat = {
      enable = true;
      ## cf https://github.com/sharkdp/bat#customization
      config = {
        map-syntax = ["*.jenkinsfile:Groovy" "*.props:Java Properties"];
        theme = "ansi";
      };
    };
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    programs.eza = {
      enable = true;
      enableZshIntegration = true;
    };
    programs.ripgrep = {
      enable = true;
    };
    home.packages = [];
    programs.zsh = {
      autosuggestion.enable = true;
      plugins = [
        {
          # will source zsh-autosuggestions.plugin.zsh
          name = "zsh-syntax-highlighting";
          src = pkgs.fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-syntax-highlighting";
            rev = "refs/tags/0.8.0";
            sha256 = "sha256-iJdWopZwHpSyYl5/FQXEW7gl/SrKaYDEtTH9cGP7iPo=";
          };
        }
        {
          # will source zsh-autosuggestions.plugin.zsh
          name = "zsh-bat";
          src = pkgs.fetchFromGitHub {
            owner = "fdellwing";
            repo = "zsh-bat";
            rev = "master";
            sha256 = "sha256-7TL47mX3eUEPbfK8urpw0RzEubGF2x00oIpRKR1W43k=";
          };
        }
      ];
      enable = true;
      shellAliases = {
        vpn = "sudo ${pkgs.openvpn}/bin/openvpn --up ${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved --down ${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved --config";
        k = "kubectl";
        top = "btop";
        df = "duf";
        dig = "dog";
        cd = "z";
        neofetch = "fastfetch";
        grep = "rg";
      };
      initExtra = ''
        fastfetch
      '';
      oh-my-zsh = {
        enable = true;
      };
    };
  };
}
