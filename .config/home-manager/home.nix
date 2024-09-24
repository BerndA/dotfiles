{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "bahues";
  home.homeDirectory = "/home/bahues";

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
    pkgs.azure-cli
    pkgs.bat
    pkgs.btop
    pkgs.binwalk
    pkgs.curl
    pkgs.conmon
    pkgs.crun
    #pkgs.docker
    pkgs.docker-credential-helpers
    pkgs.dhex
    pkgs.fd
    pkgs.fzf
    pkgs.gh
    pkgs.gitFull
    pkgs.git-cliff
    pkgs.git-lfs
    pkgs.git-sizer
    pkgs.git-filter-repo
    pkgs.graphviz
    pkgs.gnupg
    pkgs.htop
    pkgs.jq
    pkgs.libyubikey
    pkgs.nss
    pkgs.opensc
    pkgs.openssh
    pkgs.navi
    pkgs.podman
    pkgs.poetry
    pkgs.python3Full
    pkgs.ripgrep
    pkgs.rdfind
    pkgs.rofi
    pkgs.rofi-pass
    pkgs.skopeo
    pkgs.ssss
    pkgs.sshpass
    pkgs.tig
    pkgs.tmux
    pkgs.tmuxp
    pkgs.up
    pkgs.yubico-piv-tool
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
  home.file.".config/zsh/zshrc".source = ~/data/repos/dotfiles/.config/zsh/zshrc;
  home.file.".zshenv".source = ~/data/repos/dotfiles/.config/zsh/zshenv;
  #home.file.".config/rofi-pass/config".source = ~/data/repos/dotfiles/.config/rofi-pass/config;

  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    EDITOR = "nvim";
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
    #autosuggestions = {
    #  enable = true;
    #};
    initExtra = "
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
  
  programs.rofi.pass = {
    enable = true;
  };

  programs.tmux = {
   enable = true;
   extraConfig = ''
   bind-key -T prefix C-g split-window \
  "$SHELL --login -i -c 'navi --print | head -n 1 | tmux load-buffer -b tmp - ; tmux paste-buffer -p -t {last} -b tmp -d'"
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

