#podman build -t vspodium-dev-env -f .devcontainer/Dockerfile ./

FROM archlinux:latest

# Pre-install essential tools using pacman so Dev Containers doesn't break
RUN pacman -Syu --noconfirm && pacman -S --noconfirm \
    base-devel \
    git \
    curl \
    sudo \
    bash \
    ca-certificates \
    avr-gcc \
    avr-libc \
    avrdude \
    bear \
    && pacman -Scc --noconfirm

# Create a non-root dev user
RUN useradd -m -s /bin/bash vscode && \
    echo 'vscode ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
