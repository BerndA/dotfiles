FROM ubuntu:20.04
LABEL Maintainer bernd@idk.invalid

RUN apt update && \
    apt install -y \ 
    jq git vim tmux tmuxinator\
    silversearcher-ag \
    bat prettyping python3-powerline powerline htop tldr fzf zgen zsh

COPY zsh/.zshrc /root/.zshrc
COPY vim/vimrc /root/.vimrc

RUN git clone https://github.com/VundleVim/Vundle.vim.git ./bundle/Vundle.vim

CMD [ "/usr/bin/zsh" ]
