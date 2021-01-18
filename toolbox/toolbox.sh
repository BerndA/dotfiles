#!/usr/bin/env bash

TOOLBOX_IMAGE=localhost/bernda/toolbox:latest
enter() {
  podman run --rm -it --userns=keep-id -e HOME -w $HOME -v ${HOME}:${HOME} ${TOOLBOX_IMAGE}  
}

enter
