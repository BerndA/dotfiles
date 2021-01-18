FROM ubuntu:20.04
LABEL Maintainer bernd@idk.invalid

RUN apt update && \
    apt install -y \ 
    jq vim tmux tmuxinator\
    silversearcher-ag \
    bat prettyping htop tldr fzf zgen zsh

CMD [ "/usr/bin/zsh" ]
