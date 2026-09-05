FROM archlinux@sha256:82b1b08faae9d61e3e7e13d562f4d09114d939105b0d59ff34140f3bd418593a

LABEL org.opencontainers.image.source="https://github.com/bolens/omarchy-app-drawer"
LABEL org.opencontainers.image.description="Pinned test toolchain for bolens Omarchy plugins"

RUN pacman -Syu --noconfirm \
      diffutils \
      git \
      jq \
      nodejs \
      npm \
      python \
      quickshell \
      qt6-declarative \
      ruby \
      shellcheck \
    && npm install --global npm@11.19.0 \
    && npm cache clean --force \
    && pacman -Scc --noconfirm

WORKDIR /workspace
