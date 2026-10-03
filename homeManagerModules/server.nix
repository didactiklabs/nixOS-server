# zsh and git for server users (imported by nixosModules/userConfig.nix next
# to nixbook's sshConfig). Replaces nixbook's zshConfig/gitConfig, which are
# built for laptops.
#
# Lean on purpose: every user profile is installed on every host and every
# generation is kept for days, so laptop tooling is left out (devenv pulled
# llvm, fastfetch pulled EFL/icon themes/SDL, yazi pulls ffmpeg/imagemagick,
# gh + extensions, difftastic, full git). Interactive comfort stays: zsh with
# oh-my-zsh, autosuggestions and syntax highlighting, atuin, fzf, zoxide, eza,
# bat, ripgrep, fd, tmux, git aliases.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.customHomeManagerModules;
in
{
  options.customHomeManagerModules = {
    zshConfig.enable = lib.mkEnableOption "zsh with the common CLI tools";
    gitConfig.enable = lib.mkEnableOption "git with the common aliases and settings";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.zshConfig.enable {
      home.packages = with pkgs; [
        any-nix-shell
        duf
        sd
        trippy
        viddy
      ];
      programs = {
        atuin = {
          enable = true;
          enableZshIntegration = true;
          flags = [ "--disable-up-arrow" ];
        };
        bat.enable = true;
        eza = {
          enable = true;
          enableZshIntegration = true;
        };
        fd.enable = true;
        fzf = {
          enable = true;
          enableZshIntegration = true;
          tmux.enableShellIntegration = true;
        };
        ripgrep.enable = true;
        zoxide = {
          enable = true;
          enableZshIntegration = true;
        };
        tmux = {
          enable = true;
          mouse = true;
          plugins = [ pkgs.tmuxPlugins.sensible ];
          extraConfig = ''
            set-option -ga terminal-overrides ",*:Tc"
            set -g visual-activity off
            set -g visual-bell off
            set -g visual-silence off
            setw -g monitor-activity off
            set -g bell-action none
            set -g status-position bottom
            set -g status-justify left
            set -g status-style 'fg=colour1'
            set -g status-left ""
            set -g status-right "%Y-%m-%d %H:%M "
            setw -g window-status-current-style 'fg=colour0 bg=colour1 bold'
            setw -g window-status-current-format ' #I #W #F '
            setw -g window-status-style 'fg=colour1 dim'
            setw -g window-status-format ' #I #[fg=colour7]#W #[fg=colour1]#F '
            set -g message-style 'fg=colour2 bg=colour0 bold'
          '';
        };
        zsh = {
          enable = true;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;
          oh-my-zsh.enable = true;
          shellAliases = {
            watch = "viddy";
            df = "duf";
            cd = "z";
          };
          initContent = ''
            any-nix-shell zsh --info-right | source /dev/stdin
          '';
        };
      };
    })

    (lib.mkIf cfg.gitConfig.enable {
      programs.git = {
        enable = true;
        lfs.enable = true;
        ignores = [
          "*.vscode"
          "*.direnv"
        ];
        settings = {
          alias = {
            lg = "log --graph --pretty=tformat:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%an %ai)%Creset'";
            d = "diff";
            s = "status";
            sw = "switch";
            swcr = "switch -C";
            del = "branch -D";
            br = "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate";
            undo = "reset HEAD~1 --mixed";
            done = "!git push origin HEAD";
          };
          push.autoSetupRemote = true;
          pull.rebase = true;
          init.defaultBranch = "main";
        };
      };
    })

  ];
}
