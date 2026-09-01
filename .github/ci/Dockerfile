FROM archlinux@sha256:4bf33b21a715aac0b48ce6e9eaed4782a898eae96f88f5da3635572129c2584a

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
