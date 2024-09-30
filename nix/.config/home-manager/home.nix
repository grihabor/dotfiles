{
  config,
  pkgs,
  ...
}: let
  python3 = (
    pkgs.python3.withPackages (ps: let
      debugpy = ps.debugpy.overrideAttrs (self: super: {pytestCheckPhase = ''true'';});
      ropemode = ps.callPackage ./ropemode.nix {};
      ropevim = ps.callPackage ./ropevim.nix {ropemode = ropemode;};
      pytest-custom_exit_code = ps.callPackage ./pytest-custom_exit_code.nix {};
    in [
      debugpy
      ps.pip-tools
      ps.pynvim
      ps.pytest
      ps.sphinx
      pytest-custom_exit_code
      ropevim
    ])
  );
  complete-alias = pkgs.callPackage ./complete_alias.nix {};
in {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "grihabor";
  home.homeDirectory = "/home/grihabor";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    python3

    pkgs.alejandra
    pkgs.ausweisapp
    pkgs.clang-tools
    pkgs.comby
    pkgs.fd
    pkgs.fzf
    pkgs.git
    pkgs.git-filter-repo
    pkgs.go
    pkgs.google-cloud-sdk
    pkgs.google-java-format
    pkgs.haskell.compiler.ghc98
    pkgs.isort
    pkgs.jq
    pkgs.just
    pkgs.kubectl
    pkgs.lua-language-server
    pkgs.meld
    pkgs.neovim
    pkgs.neovim-remote
    pkgs.nil
    pkgs.nodePackages.prettier
    pkgs.nodePackages.pyright
    pkgs.nodePackages.typescript-language-server
    pkgs.pmd
    pkgs.pre-commit
    pkgs.ripgrep
    pkgs.rubyPackages.htmlbeautifier
    pkgs.ruff
    pkgs.shfmt
    pkgs.sqlfluff
    pkgs.stow
    pkgs.stylua
    pkgs.telegram-desktop
    pkgs.tmux
    pkgs.tree-sitter
    pkgs.vscode-extensions.vadimcn.vscode-lldb
    pkgs.xclip
    pkgs.xmlformat
    pkgs.yaml-language-server
    pkgs.yamllint

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    (pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];})

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';

    ".bash_completion".text = ''
      . ${complete-alias}/complete_alias
    '';

  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/grihabor/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    firefox = {
      enable = true;
      profiles = {
        default = {
          id = 0;
          name = "Personal";
        };
        pulsepoint = {
          id = 1;
          name = "PulsePoint";
        };
      };
    };

    bash = {
      enable = true;
      profileExtra = ''
        . ~/.profile.old
      '';
      bashrcExtra = ''
        . ~/.bashrc.old
      '';
    };

    pyenv.enable = true;
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };
}
