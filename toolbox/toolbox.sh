#!/usr/bin/env bash

TOOLBOX_IMAGE=localhost/bernda/toolbox:latest

build() {
  podman build -f Dockerfile .. -t ${TOOLBOX_IMAGE}
}

enter() {
  podman run --rm -it --userns=keep-id -w $HOME -v ${HOME}:${HOME} ${TOOLBOX_IMAGE}  
}

enter
