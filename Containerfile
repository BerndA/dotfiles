# Containerfile for testing dotfiles installation
FROM ubuntu:24.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
    sudo \
    sudo-util \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Create test user with UID/GID matching host
ARG UID=$(id -u)
ARG GID=$(id -g)
RUN useradd -m -s /bin/bash -G sudo testuser -g "${GID}" -G sudo

WORKDIR /install

# Copy installation scripts
COPY --chown=testuser install.sh /install/
COPY --chown=testuser install_anacron.sh /install/

HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost/health || exit 1

SHELL ["/bin/bash", "-c"]
