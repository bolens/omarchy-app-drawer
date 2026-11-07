FROM archlinux@sha256:82b1b08faae9d61e3e7e13d562f4d09114d939105b0d59ff34140f3bd418593a

LABEL org.opencontainers.image.source="https://github.com/bolens/omarchy-app-drawer"
LABEL org.opencontainers.image.description="Pinned test toolchain for bolens Omarchy plugins"

RUN printf '%s\n' 'Server = https://archive.archlinux.org/repos/2026/11/06/$repo/os/$arch' > /etc/pacman.d/mirrorlist \
    && pacman -Syu --noconfirm \
      diffutils \
      git \
      jq \
      labwc \
      nodejs \
      npm \
      pipewire \
      python \
      quickshell \
      qt6-declarative \
      ruby \
      shellcheck \
      ttf-dejavu \
      xorg-xwayland \
    && test "$(pacman -Q pipewire)" = 'pipewire 1:1.6.10-1' \
    && test "$(pacman -Q libpipewire)" = 'libpipewire 1:1.6.10-1' \
    && test -f /usr/share/pipewire/client.conf \
    && test "$(pacman -Q xorg-xwayland)" = 'xorg-xwayland 24.1.14-1' \
    && test "$(pacman -Q labwc)" = 'labwc 0.20.2-1' \
    && test "$(pacman -Q quickshell)" = 'quickshell 0.3.2-1' \
    && test "$(pacman -Q qt6-base)" = 'qt6-base 6.12.0-3' \
    && test "$(pacman -Q qt6-declarative)" = 'qt6-declarative 6.12.0-4' \
    && npm install --global npm@11.19.0 \
    && npm cache clean --force \
    && pacman -Scc --noconfirm

WORKDIR /workspace
