#!/usr/bin/env bash

TOOLBOX_IMAGE=localhost/bernda/toolbox:latest
TOOLBOX_DIR=/home/bernda/repos/dotfiles/toolbox

build() {
  container=$(buildah from ubuntu:21.04)
  # run apt non-interactive
  # configure buildah to use only chroot since we are already inside a user ns
  buildah config --env LANG=POSIX --env DEBIAN_FRONTEND="noninteractive" --env _BUILDAH_STARTED_IN_USERNS="" --env BUILDAH_ISOLATION=chroot ${container} 
  buildah run $container --  sh -c '\
	  apt update && \
          apt install -y \
	      bat \
	      buildah \
	      curl \
	      fuse-overlayfs \
	      fzf \
	      git \
	      htop \
	      jq \
	      ncdu \
	      silversearcher-ag \
	      skopeo \
	      tig \
	      tmux \
	      tmuxinator \
	      podman \
	      powerline \
	      prettyping \
	      python3-powerline \
	      tldr \
	      vim \
	      wget \
	      zgen \
	      zsh &&
	      unminimize &&
	      mkdir -p /zdotdir'
  buildah copy ${container} ../zsh/.zshrc /etc/zsh/zshrc
  buildah config --env ZDOTDIR=/zdotdir --cmd /usr/bin/zsh ${container}
  buildah run ${container} --  git clone https://github.com/VundleVim/Vundle.vim.git ./bundle/Vundle.vim
  buildah commit ${container} ${TOOLBOX_IMAGE}

#RUN https://github.com/cli/cli/releases/download/v1.5.0/gh_1.5.0_linux_amd64.deb
#  podman build -f Dockerfile .. -t ${TOOLBOX_IMAGE}
}

enter() {
  podman run --rm -it --net=host --device /dev/fuse --userns=keep-id -e INSIDE_TOOLBOX=1 -e TOOLBOX_DIR -w $HOME -v ${HOME}:${HOME} ${TOOLBOX_IMAGE}  
  #podman run --rm -it -w $HOME -v ${HOME}:${HOME} ${TOOLBOX_IMAGE}  
}

#enter
