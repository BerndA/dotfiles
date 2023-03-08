#!/usr/bin/env sh

set -x 
REPO_DIR=$(dirname $(realpath $0))
ln -s ${REPO_DIR}/zsh/.zshrc ~/.zshrc
ln -s ${REPO_DIR}/tmux/tmux.conf ~/.tmux.conf
