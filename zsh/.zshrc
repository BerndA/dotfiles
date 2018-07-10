# load zgen
source "${HOME}/.zgen/zgen.zsh"

# if the init scipt doesn't exist
if ! zgen saved; then
#
# specify plugins here

# Load the oh-my-zsh's library.
zgen oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
zgen oh-my-zsh plugins/profiles
zgen oh-my-zsh plugins/git
zgen oh-my-zsh plugins/git-extras
zgen oh-my-zsh plugins/pip
zgen oh-my-zsh plugins/tmux
zgen oh-my-zsh plugins/docker

#zgen oh-my-zsh plugins/rsync
#
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

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl

if [ -d ${HOME}/miniconda2/bin ]; then
  export PATH=${PATH}:${HOME}/miniconda2/bin
fi

alias ssh-agent-proxy='if [[ -e ~/.ssh-agent-proxy ]]; then source ~/.ssh-agent-proxy; fi; ssh-add -l'
alias ssh-agent-proxy-set='echo export SSH_AUTH_SOCK=${SSH_AUTH_SOCK} > ~/.ssh-agent-proxy'

alias sshap=ssh-agent-proxy
alias sshaps=ssh-agent-proxy-set

alias docker-cc='docker rm $(docker ps -a -fstatus=exited -q)'
alias docker-ci='docker rmi $(docker images -f "dangling=true" -q)'

docker_debug() {
	docker commit $1 docker_debug/debug_image && docker run --rm -it docker_debug/debug_image /bin/bash
}
alias docker-debug=docker_debug

#sudo stuff
alias service='sudo service'
alias iptables='sudo iptables'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

