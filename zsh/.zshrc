# load zgen
source "${HOME}/locale.sh"
#source "${HOME}/.zgen/zgen.zsh"
source "/usr/share/zgen/zgen.zsh"

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
    zgen oh-my-zsh plugins/tmux
    zgen oh-my-zsh plugins/docker
    zgen oh-my-zsh plugins/npm
    zgen load lukechilds/zsh-better-npm-completion

    # Syntax highlighting bundle.
    zgen load zsh-users/zsh-syntax-highlighting

    zgen load zsh-users/zsh-autosuggestions

    zgen oh-my-zsh themes/agnoster

    # generate the init script from plugins above
    zgen save
fi

#case "$TERM" in
#	xterm*) TERM=xterm-256color;;
#	screen*) TERM=screen-256color-bce;;
#
#esac

# hide username@host in prompt
export DEFAULT_USER="$USER"

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl

alias docker-cc='docker rm $(docker ps -a -fstatus=exited -q)'
alias docker-ci='docker rmi $(docker images -f "dangling=true" -q)'
alias rg=rgrep

docker_debug() {
	docker commit $1 docker_debug/debug_image && docker run --rm -it docker_debug/debug_image /bin/bash
}
alias docker-debug=docker_debug

alias ba_git_prune_branches="git fetch -p && git branch -vva | grep ': gone]' | awk '{print $1}' | xargs git branch -d"
#Find all changes to FILENAME not merged to master:
alias ba_git_find_all_branches='git for-each-ref --format="%(refname:short)" refs/heads | grep -v master | while read br; do git cherry master $br | while read x h; do if [ \"`git log -n 1 --format=%H $h -- $FILENAME`\" = \"$h\" ]; then echo $br; fi; done; done | sort -u'


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

[[ -s "$HOME/.local/share/marker/marker.sh" ]] && source "$HOME/.local/share/marker/marker.sh"

export PATH=$PATH:$HOME/bin

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('$HOME/data/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/data/miniconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/data/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/data/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export HISTORY_IGNORE="ls *:cd *:pwd:exit::man*:env*:?:??:df *:du *"

function azp_git_on() {
    echo "injecting secret for internal server"
    B64=$(echo -n $USER:$(pass show ${INTERNAL_GIT_SERVER}/AZP_CODE_TOKEN) | base64 -w0 )
    export GIT_EXTRA_HEADER="Authorization: Basic $B64"
    alias git='git -c http.extraheader=$GIT_EXTRA_HEADER'
}

function azp_git(){

    if [[ $(git remote get-url --all origin | sed "s!https://${INTERNAL_GIT_SERVER}/.*!internal!") == "internal" ]]; then
        azp_git_on
    else
        alias git=git
        export AZP_CODE_TOKEN=
    fi
}

function ba_git_curl_debug(){
    if [[ -z "$GIT_CURL_VERBOSE" ]]; then
        echo "turning on git debugging"
        export GIT_CURL_VERBOSE=1
        export GIT_TRACE=1
    else
        echo "turning off git debugging"
        unset GIT_CURL_VERBOSE
        unset GIT_TRACE
    fi
}


