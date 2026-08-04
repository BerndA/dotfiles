{ config, pkgs, lib, ... }:

{

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  imports = [ 
      ./user.nix
      ./modules/dotfiles.nix 
  ];
  home.homeDirectory = "/home/${config.home.username}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.bat
    pkgs.binwalk
    pkgs.btop
    pkgs.buku
    pkgs.curl
    pkgs.conmon
    pkgs.crun
    pkgs.direnv
    pkgs.docker-credential-helpers
    pkgs.dhex
    pkgs.fd
    pkgs.fzf
    pkgs.gh
    pkgs.git-absorb
    pkgs.git
    pkgs.git-cliff
    pkgs.git-lfs
    pkgs.git-sizer
    pkgs.git-filter-repo
    pkgs.gopass
    pkgs.graphviz
    pkgs.gnupg
    pkgs.htop
    pkgs.jq
    pkgs.jnv
    pkgs.lsd
    pkgs.nss
    pkgs.openssh
    pkgs.navi
    pkgs.podman
    pkgs.ripgrep
    pkgs.rdfind
    pkgs.rofi
    pkgs.rofi-pass
    pkgs.skopeo
    pkgs.ssss
    pkgs.sshpass
    pkgs.tig
    pkgs.tio
    pkgs.tmux
    pkgs.tmuxp
    pkgs.trash-cli
    pkgs.up
    pkgs.watson
    pkgs.zsh

    #graphical stuff (disabled)
    #pkgs.firefox
    #pkgs.element-desktop

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

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
  };

  # Raw configuration files
  home.file.".config/zsh/zshrc".source = "${config.dotfiles.repoDir}/.config/zsh/zshrc";
  #home.file.".zshenv".source = ~/dotfiles/.config/zsh/zshenv;
  home.file.".ssh/config".source = "${config.dotfiles.repoDir}/ssh/config";

  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    ZSH_TMUX_AUTOSTART="true";
    ZSH_TMUX_AUTOQUIT="false";
    DOTFILES="home-manager";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
      plenary-nvim
      mini-nvim
      lsp-zero-nvim
      dracula-nvim
    ];
    extraConfig = ''
        set number relativenumber
        colorscheme industry
        set tabstop=4 shiftwidth=4 expandtab
    '';
 };

  programs.password-store.enable = true;

  programs.zsh = {
    enable = true;
    autocd = true;
    autosuggestion = {
      enable = true;
    };
    initContent= "
    alias rip=trash
    if [ -f $HOME/.config/zsh/zshrc ];
    then
      source $HOME/.config/zsh/zshrc
    fi";

    zplug = {
      enable = true;
      plugins = [
        { name = "zsh-users/zsh-autosuggestions"; } # Simple plugin installation
        { name = "zsh-users/zsh-syntax-highlighting"; } # Simple plugin installation
      ];
    };
    # Syntax highlighting bundle.
    #oh-my-zsh = {
    #  enable = true;
    #  plugins = [ "docker" "git" "git-extras" "profiles" ];
      #plugins = [ "docker" "git" "git-extras" "profiles" "tmux" ];
    #};
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    includes = [
      { path = "${config.dotfiles.repoDir}/.gitconfig"; }
    ];
  };
  
  programs.rofi.pass = {
    enable = true;
  };

  programs.tmux = {
   enable = true;
   extraConfig = ''
    source-file "${config.dotfiles.repoDir}/.config/tmux/tmux.conf"
    '';

  };
  
#  programs.vscode = {
#    enable = true;
#    package = pkgs.vscode.fhs;
#  };
  programs.watson = {
    enableZshIntegration = true;
  };

  programs.navi = {
    enable = true; 
    enableZshIntegration = true;
  };
}

