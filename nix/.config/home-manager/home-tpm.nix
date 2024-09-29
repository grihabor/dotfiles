{pkgs, ...}: let
  tpm = pkgs.callPackage ./tpm.nix {};
in {
  home.file.".tmux.conf".text = ''
    # plugin manager
    set -g @plugin 'tmux-plugins/tpm'
    # sensible defaults
    set -g @plugin 'tmux-plugins/tmux-sensible'
    # theme
    set -g @plugin 'dracula/tmux'
    # pane navigation bindings
    set -g @plugin 'tmux-plugins/tmux-pain-control'

    # search tmux windows with fzf
    set -g @plugin 'sainnhe/tmux-fzf'

    bind-key x kill-pane # skip "kill-pane 1? (y/n)" prompt
    set -g detach-on-destroy off  # don't exit from tmux when closing a session

    # available plugins: battery, cpu-usage, git, gpu-usage, ram-usage, network, network-bandwidth, network-ping, attached-clients, network-vpn, weather, time, spotify-tui, kubernetes-context
    set -g @dracula-plugins "cpu-usage ram-usage"

    # colors
    set -g default-terminal "screen-256color"
    set-option -sa terminal-overrides ",alacritty:Tc"

    # Start windows and panes at 1, not 0
    set -g base-index 1
    setw -g pane-base-index 1

    # Disable prefix on F12 for remote tmux
    # https://gist.github.com/samoshkin/05e65f7f1c9b55d3fc7690b59d678734
    bind -T root F12  \
      set prefix None \;\
      set key-table off \;\
      refresh-client -S \;\

    bind -T off F12 \
      set -u prefix \;\
      set -u key-table \;\
      refresh-client -S \;\

    ###
    # Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
    ###
    run '${tpm}/tpm'
  '';
}
