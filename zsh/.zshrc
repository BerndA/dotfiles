# load zgen
source "${HOME}/.zgen/zgen.zsh"

# if the init scipt doesn't exist
if ! zgen saved; then
#
# specify plugins here

# Load the oh-my-zsh's library.
zgen oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
zgen oh-my-zsh plugins/git
zgen oh-my-zsh plugins/git-flow
zgen oh-my-zsh plugins/pip
zgen oh-my-zsh plugins/command-not-found
zgen oh-my-zsh plugins/tmux
zgen oh-my-zsh plugins/profiles
zgen oh-my-zsh plugins/rsync

# Syntax highlighting bundle.
zgen load zsh-users/zsh-syntax-highlighting

zgen oh-my-zsh themes/agnoster

# generate the init script from plugins above
zgen save
fi

case "$TERM" in
	xterm*) TERM=xterm-256color;;
	screen*) TERM=screen-256color-bce;;

esac

# hide username@host in prompt
export DEFAULT_USER="$USER"

export PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl

if [ -d ${HOME}/anaconda3/bin ]; then
  export PATH=${HOME}/anaconda3/bin:${PATH}
fi

